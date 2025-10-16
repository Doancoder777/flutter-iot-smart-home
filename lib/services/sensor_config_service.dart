import 'dart:convert';
import '../models/user_sensor.dart';
import '../models/sensor_type.dart';
import '../models/device_mqtt_config.dart';
import 'local_storage_service.dart';

class SensorConfigService {
  final LocalStorageService _storage;
  static const String _storageKey = 'user_sensors';

  SensorConfigService(this._storage);

  /// Lấy tất cả sensors của user
  Future<List<UserSensor>> getUserSensors(String userId) async {
    try {
      final key = '${_storageKey}_$userId';
      final jsonString = _storage.getSetting(key, defaultValue: '[]') as String;

      final List<dynamic> sensorsJson = json.decode(jsonString);
      return sensorsJson
          .map((json) => UserSensor.fromJson(json))
          .where((sensor) => sensor.userId == userId)
          .toList();
    } catch (e) {
      print('❌ Error loading user sensors: $e');
      return [];
    }
  }

  /// Lưu sensors của user
  Future<void> saveUserSensors(String userId, List<UserSensor> sensors) async {
    try {
      final sensorsJson = sensors.map((s) => s.toJson()).toList();
      final key = '${_storageKey}_$userId';
      final jsonString = json.encode(sensorsJson);
      await _storage.saveSetting(key, jsonString);
      print('💾 Saved ${sensors.length} sensors for user: $userId');
    } catch (e) {
      print('❌ Error saving user sensors: $e');
      throw Exception('Failed to save sensors: $e');
    }
  }

  /// Thêm sensor mới cho user
  Future<UserSensor> addUserSensor({
    required String userId,
    required String sensorTypeId,
    required String displayName,
    String? customMqttTopic,
    Map<String, dynamic>? configuration,
    DeviceMqttConfig? mqttConfig,
  }) async {
    try {
      // Kiểm tra sensor type có tồn tại không
      final sensorType = AvailableSensorTypes.getById(sensorTypeId);
      if (sensorType == null) {
        throw Exception('Sensor type not found: $sensorTypeId');
      }

      // Lấy danh sách sensors hiện tại
      final existingSensors = await getUserSensors(userId);

      // Tạo sensor mới
      final newSensor = UserSensor.fromSensorType(
        userId: userId,
        sensorType: sensorType,
        displayName: displayName,
        customMqttTopic: customMqttTopic,
        configuration: configuration,
        mqttConfig: mqttConfig,
      );

      // Kiểm tra MQTT topic có bị trùng không
      final topicExists = existingSensors.any(
        (s) => s.mqttTopic == newSensor.mqttTopic,
      );
      if (topicExists) {
        throw Exception('MQTT topic already exists: ${newSensor.mqttTopic}');
      }

      // Thêm vào danh sách và lưu
      existingSensors.add(newSensor);
      await saveUserSensors(userId, existingSensors);

      print(
        '✅ Added sensor: ${newSensor.displayName} (${newSensor.mqttTopic})',
      );
      return newSensor;
    } catch (e) {
      print('❌ Error adding sensor: $e');
      rethrow;
    }
  }

  /// Cập nhật sensor
  Future<void> updateUserSensor(String userId, UserSensor updatedSensor) async {
    try {
      final sensors = await getUserSensors(userId);
      final index = sensors.indexWhere((s) => s.id == updatedSensor.id);

      if (index == -1) {
        throw Exception('Sensor not found: ${updatedSensor.id}');
      }

      sensors[index] = updatedSensor;
      await saveUserSensors(userId, sensors);

      print('✅ Updated sensor: ${updatedSensor.displayName}');
    } catch (e) {
      print('❌ Error updating sensor: $e');
      rethrow;
    }
  }

  /// Xóa sensor
  Future<void> deleteUserSensor(String userId, String sensorId) async {
    try {
      final sensors = await getUserSensors(userId);
      sensors.removeWhere((s) => s.id == sensorId);
      await saveUserSensors(userId, sensors);

      print('🗑️ Deleted sensor: $sensorId');
    } catch (e) {
      print('❌ Error deleting sensor: $e');
      rethrow;
    }
  }

  /// Cập nhật giá trị sensor từ MQTT
  Future<void> updateSensorValue(
    String userId,
    String mqttTopic,
    dynamic value,
  ) async {
    try {
      final sensors = await getUserSensors(userId);
      final sensorIndex = sensors.indexWhere((s) => s.mqttTopic == mqttTopic);

      if (sensorIndex == -1) {
        print('⚠️ No sensor found for MQTT topic: $mqttTopic');
        return;
      }

      final updatedSensor = sensors[sensorIndex].copyWith(
        lastValue: value,
        lastUpdateAt: DateTime.now(),
      );

      sensors[sensorIndex] = updatedSensor;
      await saveUserSensors(userId, sensors);

      print('📊 Updated sensor value: $mqttTopic = $value');
    } catch (e) {
      print('❌ Error updating sensor value: $e');
    }
  }

  /// Lấy sensors theo type
  Future<List<UserSensor>> getSensorsByType(
    String userId,
    String sensorTypeId,
  ) async {
    final sensors = await getUserSensors(userId);
    return sensors
        .where((s) => s.sensorTypeId == sensorTypeId && s.isActive)
        .toList();
  }

  /// Kiểm tra user có sensor type cụ thể không
  Future<bool> hasSensorType(String userId, String sensorTypeId) async {
    final sensors = await getSensorsByType(userId, sensorTypeId);
    return sensors.isNotEmpty;
  }

  /// Kiểm tra user có đủ sensors cho weather widget không
  Future<bool> hasWeatherSensors(String userId) async {
    for (final requiredType in AvailableSensorTypes.weatherRequiredSensors) {
      final hasType = await hasSensorType(userId, requiredType);
      if (!hasType) return false;
    }
    return true;
  }

  /// Lấy sensor đầu tiên của type (cho weather widget)
  Future<UserSensor?> getFirstSensorOfType(
    String userId,
    String sensorTypeId,
  ) async {
    final sensors = await getSensorsByType(userId, sensorTypeId);
    return sensors.isNotEmpty ? sensors.first : null;
  }

  /// Tạo default sensors cho user mới
  Future<void> createDefaultSensorsForUser(String userId) async {
    try {
      final existingSensors = await getUserSensors(userId);
      if (existingSensors.isNotEmpty) {
        print('⚠️ User $userId already has sensors, skipping default creation');
        return;
      }

      final defaultSensors = UserSensor.createDefaultSensors(userId);
      await saveUserSensors(userId, defaultSensors);

      print(
        '✅ Created ${defaultSensors.length} default sensors for user: $userId',
      );
    } catch (e) {
      print('❌ Error creating default sensors: $e');
      rethrow;
    }
  }

  /// Xóa tất cả sensors của user (khi logout)
  Future<void> clearUserSensors(String userId) async {
    try {
      await _storage.saveSetting('${_storageKey}_$userId', '[]');
      print('🧹 Cleared all sensors for user: $userId');
    } catch (e) {
      print('❌ Error clearing user sensors: $e');
    }
  }

  /// Lấy tất cả sensor types có thể thêm
  List<SensorType> getAvailableSensorTypes() {
    return AvailableSensorTypes.all;
  }

  /// Tạo unique MQTT topic cho sensor type
  String generateUniqueMqttTopic(
    String userId,
    String sensorTypeId,
    List<UserSensor> existingSensors,
  ) {
    final baseType = AvailableSensorTypes.getById(sensorTypeId);
    if (baseType == null) return 'smart_home/sensors/unknown';

    var counter = 1;
    String topic;

    do {
      if (counter == 1) {
        topic = '${baseType.defaultMqttTopic}/$userId';
      } else {
        topic = '${baseType.defaultMqttTopic}/$userId/$counter';
      }
      counter++;
    } while (existingSensors.any((s) => s.mqttTopic == topic));

    return topic;
  }
}
