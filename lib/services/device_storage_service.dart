import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';

class DeviceStorageService {
  static const String _devicesKey = 'user_devices';
  static const String _deviceCounterKey = 'device_counter';

  /// Lưu danh sách devices của user
  Future<bool> saveUserDevices(String userId, List<Device> devices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = devices.map((device) => device.toJson()).toList();
      final success = await prefs.setString(
        '${_devicesKey}_$userId',
        jsonEncode(devicesJson),
      );

      debugPrint(
        '💾 Saved ${devices.length} devices for user $userId: $success',
      );
      return success;
    } catch (e) {
      debugPrint('❌ Error saving devices: $e');
      return false;
    }
  }

  /// Load danh sách devices của user
  Future<List<Device>> loadUserDevices(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesString = prefs.getString('${_devicesKey}_$userId');
      if (devicesString == null || devicesString.isEmpty) {
        debugPrint(
          '📱 No devices found for user $userId, returning empty list',
        );
        return []; // 🔄 TRẢ VỀ DANH SÁCH TRỐNG THAY VÌ DEFAULT DEVICES
      }

      final List<dynamic> devicesJson = jsonDecode(devicesString);
      final devices = devicesJson.map((json) => Device.fromJson(json)).toList();

      debugPrint('📱 Loaded ${devices.length} devices for user $userId');
      return devices;
    } catch (e) {
      debugPrint('❌ Error loading devices: $e, returning empty list');
      return []; // 🔄 TRẢ VỀ DANH SÁCH TRỐNG KHI LỖI
    }
  }

  /// Tạo device ID unique
  Future<String> generateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int counter = prefs.getInt(_deviceCounterKey) ?? 1000;
      counter++;
      await prefs.setInt(_deviceCounterKey, counter);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'device_${counter}_$timestamp';
    } catch (e) {
      // Fallback to timestamp-based ID
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Thêm device mới cho user
  Future<bool> addUserDevice(String userId, Device device) async {
    try {
      final devices = await loadUserDevices(userId);

      // Kiểm tra trùng ID
      if (devices.any((d) => d.id == device.id)) {
        debugPrint('❌ Device ID ${device.id} already exists');
        return false;
      }

      // 🚨 Kiểm tra trùng MQTT topic (cùng tên và phòng)
      if (devices.any((d) => d.mqttTopic == device.mqttTopic)) {
        debugPrint('❌ Device MQTT topic ${device.mqttTopic} already exists');
        throw Exception(
          'Thiết bị với tên "${device.name}" đã tồn tại trong phòng "${device.room ?? "Chung"}"',
        );
      }

      devices.add(device);
      return await saveUserDevices(userId, devices);
    } catch (e) {
      debugPrint('❌ Error adding device: $e');
      rethrow; // Rethrow để UI có thể hiển thị lỗi cụ thể
    }
  }

  /// Xóa device của user
  Future<bool> removeUserDevice(String userId, String deviceId) async {
    try {
      final devices = await loadUserDevices(userId);
      devices.removeWhere((device) => device.id == deviceId);
      return await saveUserDevices(userId, devices);
    } catch (e) {
      debugPrint('❌ Error removing device: $e');
      return false;
    }
  }

  /// Cập nhật device của user
  Future<bool> updateUserDevice(String userId, Device updatedDevice) async {
    try {
      final devices = await loadUserDevices(userId);
      final index = devices.indexWhere(
        (device) => device.id == updatedDevice.id,
      );

      if (index == -1) {
        debugPrint('❌ Device ${updatedDevice.id} not found');
        return false;
      }

      devices[index] = updatedDevice;
      return await saveUserDevices(userId, devices);
    } catch (e) {
      debugPrint('❌ Error updating device: $e');
      return false;
    }
  }

  /// Clear tất cả devices của user (for debugging)
  Future<bool> clearUserDevices(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('${_devicesKey}_$userId');
    } catch (e) {
      debugPrint('❌ Error clearing devices: $e');
      return false;
    }
  }
}
