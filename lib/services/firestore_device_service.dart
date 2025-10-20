import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device_model.dart';

/// Service để quản lý devices trên Firestore
///
/// Features:
/// - CRUD operations cho devices
/// - Real-time listeners để auto-sync
/// - Offline support tự động (Firestore cache)
/// - Query theo userId
class FirestoreDeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 📍 COLLECTION PATHS
  // ========================================

  /// Lấy collection reference cho devices của user
  CollectionReference _devicesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('devices');
  }

  // ========================================
  // 📖 READ OPERATIONS
  // ========================================

  /// Load tất cả devices của user (1 lần)
  Future<List<Device>> loadUserDevices(String userId) async {
    try {
      print('🔍 Firestore: Loading devices for user $userId...');

      final snapshot = await _devicesCollection(userId).get();

      final devices = snapshot.docs
          .map((doc) {
            try {
              return Device.fromJson(doc.data() as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing device ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Device>() // Lọc bỏ null
          .toList();

      print('✅ Firestore: Loaded ${devices.length} devices');
      return devices;
    } catch (e) {
      print('❌ Firestore: Error loading devices: $e');
      return [];
    }
  }

  /// Load 1 device theo ID
  Future<Device?> getDevice(String userId, String deviceId) async {
    try {
      final doc = await _devicesCollection(userId).doc(deviceId).get();

      if (!doc.exists) {
        print('⚠️ Device $deviceId not found');
        return null;
      }

      return Device.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error getting device: $e');
      return null;
    }
  }

  // ========================================
  // ✍️ WRITE OPERATIONS
  // ========================================

  /// Thêm device mới
  Future<bool> addDevice(String userId, Device device) async {
    try {
      print('➕ Firestore: Adding device ${device.name}...');

      await _devicesCollection(userId).doc(device.id).set(device.toJson());

      print('✅ Firestore: Device added successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error adding device: $e');
      return false;
    }
  }

  /// Update device (toàn bộ)
  Future<bool> updateDevice(String userId, Device device) async {
    try {
      print('🔄 Firestore: Updating device ${device.name}...');

      await _devicesCollection(userId)
          .doc(device.id)
          .set(
            device.toJson(),
            SetOptions(merge: false), // Overwrite toàn bộ
          );

      print('✅ Firestore: Device updated successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error updating device: $e');
      return false;
    }
  }

  /// Update một số fields (partial update)
  Future<bool> updateDeviceFields(
    String userId,
    String deviceId,
    Map<String, dynamic> fields,
  ) async {
    try {
      print('🔄 Firestore: Updating device fields for $deviceId...');

      await _devicesCollection(userId).doc(deviceId).update(fields);

      print('✅ Firestore: Device fields updated');
      return true;
    } catch (e) {
      print('❌ Firestore: Error updating device fields: $e');
      return false;
    }
  }

  /// Xóa device
  Future<bool> deleteDevice(String userId, String deviceId) async {
    try {
      print('🗑️ Firestore: Deleting device $deviceId...');

      await _devicesCollection(userId).doc(deviceId).delete();

      print('✅ Firestore: Device deleted successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error deleting device: $e');
      return false;
    }
  }

  /// Lưu tất cả devices (bulk save)
  Future<bool> saveAllDevices(String userId, List<Device> devices) async {
    try {
      print('💾 Firestore: Saving ${devices.length} devices...');

      // Sử dụng batch write để tăng performance
      final batch = _firestore.batch();

      for (final device in devices) {
        final docRef = _devicesCollection(userId).doc(device.id);
        batch.set(docRef, device.toJson());
      }

      await batch.commit();

      print('✅ Firestore: All devices saved successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error saving devices: $e');
      return false;
    }
  }

  // ========================================
  // 🔴 REAL-TIME LISTENERS
  // ========================================

  /// Lắng nghe thay đổi của tất cả devices (Real-time)
  ///
  /// Trả về Stream để Provider có thể listen
  /// Mỗi khi có thay đổi → emit danh sách devices mới
  Stream<List<Device>> watchUserDevices(String userId) {
    print('👂 Firestore: Setting up real-time listener for user $userId');

    return _devicesCollection(userId).snapshots().map((snapshot) {
      print('📡 Firestore: Received update - ${snapshot.docs.length} devices');

      return snapshot.docs
          .map((doc) {
            try {
              return Device.fromJson(doc.data() as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing device ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Device>()
          .toList();
    });
  }

  /// Lắng nghe 1 device cụ thể
  Stream<Device?> watchDevice(String userId, String deviceId) {
    return _devicesCollection(userId).doc(deviceId).snapshots().map((doc) {
      if (!doc.exists) return null;

      try {
        return Device.fromJson(doc.data() as Map<String, dynamic>);
      } catch (e) {
        print('❌ Error parsing device: $e');
        return null;
      }
    });
  }

  // ========================================
  // 🔍 QUERY OPERATIONS
  // ========================================

  /// Lấy devices theo room
  Future<List<Device>> getDevicesByRoom(String userId, String room) async {
    try {
      final snapshot = await _devicesCollection(
        userId,
      ).where('room', isEqualTo: room).get();

      return snapshot.docs
          .map((doc) => Device.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting devices by room: $e');
      return [];
    }
  }

  /// Lấy devices theo type
  Future<List<Device>> getDevicesByType(String userId, DeviceType type) async {
    try {
      final snapshot = await _devicesCollection(
        userId,
      ).where('type', isEqualTo: type.toString().split('.').last).get();

      return snapshot.docs
          .map((doc) => Device.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting devices by type: $e');
      return [];
    }
  }

  /// Đếm số lượng devices
  Future<int> getDeviceCount(String userId) async {
    try {
      final snapshot = await _devicesCollection(userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error counting devices: $e');
      return 0;
    }
  }

  // ========================================
  // 🧹 UTILITY
  // ========================================

  /// Xóa tất cả devices của user (NGUY HIỂM!)
  Future<bool> deleteAllDevices(String userId) async {
    try {
      print('⚠️ Firestore: Deleting ALL devices for user $userId...');

      final snapshot = await _devicesCollection(userId).get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('✅ Firestore: All devices deleted');
      return true;
    } catch (e) {
      print('❌ Firestore: Error deleting all devices: $e');
      return false;
    }
  }
}
