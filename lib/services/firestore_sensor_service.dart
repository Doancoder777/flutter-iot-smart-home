import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_sensor.dart';

/// Service để quản lý sensors trên Firestore
///
/// Features:
/// - CRUD operations cho sensors
/// - Real-time listeners để auto-sync
/// - Offline support tự động (Firestore cache)
/// - Query theo userId và sensorType
class FirestoreSensorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 📍 COLLECTION PATHS
  // ========================================

  /// Lấy collection reference cho sensors của user
  CollectionReference _sensorsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('sensors');
  }

  /// Lấy collection reference cho sensor history
  CollectionReference _sensorHistoryCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sensor_history');
  }

  // ========================================
  // 📖 READ OPERATIONS
  // ========================================

  /// Load tất cả sensors của user
  Future<List<UserSensor>> loadUserSensors(String userId) async {
    try {
      print('🔍 Firestore: Loading sensors for user $userId...');

      final snapshot = await _sensorsCollection(userId).get();

      final sensors = snapshot.docs
          .map((doc) {
            try {
              return UserSensor.fromJson(doc.data() as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing sensor ${doc.id}: $e');
              return null;
            }
          })
          .whereType<UserSensor>()
          .toList();

      print('✅ Firestore: Loaded ${sensors.length} sensors');
      return sensors;
    } catch (e) {
      print('❌ Firestore: Error loading sensors: $e');
      return [];
    }
  }

  /// Load 1 sensor theo ID
  Future<UserSensor?> getSensor(String userId, String sensorId) async {
    try {
      final doc = await _sensorsCollection(userId).doc(sensorId).get();

      if (!doc.exists) {
        print('⚠️ Sensor $sensorId not found');
        return null;
      }

      return UserSensor.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error getting sensor: $e');
      return null;
    }
  }

  // ========================================
  // ✍️ WRITE OPERATIONS
  // ========================================

  /// Thêm sensor mới
  Future<bool> addSensor(String userId, UserSensor sensor) async {
    try {
      print('➕ Firestore: Adding sensor ${sensor.displayName}...');

      await _sensorsCollection(userId).doc(sensor.id).set(sensor.toJson());

      print('✅ Firestore: Sensor added successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error adding sensor: $e');
      return false;
    }
  }

  /// Update sensor
  Future<bool> updateSensor(String userId, UserSensor sensor) async {
    try {
      print('🔄 Firestore: Updating sensor ${sensor.displayName}...');

      await _sensorsCollection(
        userId,
      ).doc(sensor.id).set(sensor.toJson(), SetOptions(merge: false));

      print('✅ Firestore: Sensor updated successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error updating sensor: $e');
      return false;
    }
  }

  /// Update sensor value (cho real-time data)
  Future<bool> updateSensorValue(
    String userId,
    String sensorId,
    dynamic value,
  ) async {
    try {
      await _sensorsCollection(userId).doc(sensorId).update({
        'lastValue': value,
        'lastUpdateAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('❌ Error updating sensor value: $e');
      return false;
    }
  }

  /// Xóa sensor
  Future<bool> deleteSensor(String userId, String sensorId) async {
    try {
      print('🗑️ Firestore: Deleting sensor $sensorId...');

      await _sensorsCollection(userId).doc(sensorId).delete();

      print('✅ Firestore: Sensor deleted successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error deleting sensor: $e');
      return false;
    }
  }

  /// Lưu tất cả sensors (bulk save)
  Future<bool> saveAllSensors(String userId, List<UserSensor> sensors) async {
    try {
      print('💾 Firestore: Saving ${sensors.length} sensors...');

      final batch = _firestore.batch();

      for (final sensor in sensors) {
        final docRef = _sensorsCollection(userId).doc(sensor.id);
        batch.set(docRef, sensor.toJson());
      }

      await batch.commit();

      print('✅ Firestore: All sensors saved successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error saving sensors: $e');
      return false;
    }
  }

  // ========================================
  // 🔴 REAL-TIME LISTENERS
  // ========================================

  /// Lắng nghe thay đổi của tất cả sensors (Real-time)
  Stream<List<UserSensor>> watchUserSensors(String userId) {
    print('👂 Firestore: Setting up real-time listener for sensors');

    return _sensorsCollection(userId).snapshots().map((snapshot) {
      print(
        '📡 Firestore: Received sensor update - ${snapshot.docs.length} sensors',
      );

      return snapshot.docs
          .map((doc) {
            try {
              return UserSensor.fromJson(doc.data() as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing sensor ${doc.id}: $e');
              return null;
            }
          })
          .whereType<UserSensor>()
          .toList();
    });
  }

  /// Lắng nghe 1 sensor cụ thể
  Stream<UserSensor?> watchSensor(String userId, String sensorId) {
    return _sensorsCollection(userId).doc(sensorId).snapshots().map((doc) {
      if (!doc.exists) return null;

      try {
        return UserSensor.fromJson(doc.data() as Map<String, dynamic>);
      } catch (e) {
        print('❌ Error parsing sensor: $e');
        return null;
      }
    });
  }

  // ========================================
  // 📊 SENSOR HISTORY
  // ========================================

  /// Lưu sensor reading vào history
  Future<bool> saveSensorHistory({
    required String userId,
    required String sensorId,
    required dynamic value,
    DateTime? timestamp,
  }) async {
    try {
      final historyData = {
        'sensorId': sensorId,
        'value': value,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      };

      await _sensorHistoryCollection(userId).add(historyData);

      return true;
    } catch (e) {
      print('❌ Error saving sensor history: $e');
      return false;
    }
  }

  /// Load sensor history (có giới hạn)
  Future<List<Map<String, dynamic>>> loadSensorHistory({
    required String userId,
    String? sensorId,
    int limit = 100,
  }) async {
    try {
      Query query = _sensorHistoryCollection(userId);

      // Filter by sensorId nếu có
      if (sensorId != null) {
        query = query.where('sensorId', isEqualTo: sensorId);
      }

      // Sắp xếp theo thời gian mới nhất
      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('❌ Error loading sensor history: $e');
      return [];
    }
  }

  /// Xóa sensor history cũ (dọn dẹp)
  Future<bool> cleanupOldHistory({
    required String userId,
    required Duration olderThan,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan);

      final snapshot = await _sensorHistoryCollection(
        userId,
      ).where('timestamp', isLessThan: cutoffDate.toIso8601String()).get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ No old history to clean up');
        return true;
      }

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('✅ Cleaned up ${snapshot.docs.length} old history records');
      return true;
    } catch (e) {
      print('❌ Error cleaning up history: $e');
      return false;
    }
  }

  // ========================================
  // 🔍 QUERY OPERATIONS
  // ========================================

  /// Lấy sensors theo type
  Future<List<UserSensor>> getSensorsByType(
    String userId,
    String sensorTypeId,
  ) async {
    try {
      final snapshot = await _sensorsCollection(
        userId,
      ).where('sensorTypeId', isEqualTo: sensorTypeId).get();

      return snapshot.docs
          .map((doc) => UserSensor.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting sensors by type: $e');
      return [];
    }
  }

  /// Lấy active sensors
  Future<List<UserSensor>> getActiveSensors(String userId) async {
    try {
      final snapshot = await _sensorsCollection(
        userId,
      ).where('isActive', isEqualTo: true).get();

      return snapshot.docs
          .map((doc) => UserSensor.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting active sensors: $e');
      return [];
    }
  }

  /// Đếm số lượng sensors
  Future<int> getSensorCount(String userId) async {
    try {
      final snapshot = await _sensorsCollection(userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error counting sensors: $e');
      return 0;
    }
  }

  // ========================================
  // 🧹 UTILITY
  // ========================================

  /// Xóa tất cả sensors của user
  Future<bool> deleteAllSensors(String userId) async {
    try {
      print('⚠️ Firestore: Deleting ALL sensors for user $userId...');

      final snapshot = await _sensorsCollection(userId).get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('✅ Firestore: All sensors deleted');
      return true;
    } catch (e) {
      print('❌ Firestore: Error deleting all sensors: $e');
      return false;
    }
  }
}
