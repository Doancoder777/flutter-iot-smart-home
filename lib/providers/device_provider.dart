import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/device_model.dart';
import '../services/image_picker_service.dart';
import '../services/device_storage_service.dart';
import 'mqtt_provider.dart';

class DeviceProvider extends ChangeNotifier {
  List<Device> _devices = [];
  MqttProvider? _mqttProvider;
  final DeviceStorageService _storageService = DeviceStorageService();
  String? _currentUserId;

  List<Device> get devices => _devices;
  List<Device> get relays =>
      _devices.where((d) => d.type == DeviceType.relay).toList();
  List<Device> get servos =>
      _devices.where((d) => d.type == DeviceType.servo).toList();
  List<Device> get fans =>
      _devices.where((d) => d.type == DeviceType.fan).toList();
  int get devicesCount => _devices.length;
  String? get currentUserId => _currentUserId;

  DeviceProvider() {
    // Không khởi tạo devices ngay, chờ setCurrentUser
  }

  void setMqttProvider(MqttProvider mqttProvider) {
    _mqttProvider = mqttProvider;
    debugPrint(
      '🔧 DeviceProvider: setMqttProvider called, currentUserId: $_currentUserId',
    );

    // Auto-initialize with default user if no current user
    if (_currentUserId == null) {
      debugPrint('🔧 DeviceProvider: No current user, auto-initializing...');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        debugPrint('🔧 DeviceProvider: Auto-initializing with default user');
        await setCurrentUser('default_user');
      });
    }
  }

  /// Set current user và load devices của user đó
  Future<void> setCurrentUser(String? userId) async {
    if (_currentUserId == userId) return;

    _currentUserId = userId;

    if (userId != null) {
      await loadUserDevices(userId);
    } else {
      _devices = [];
      _safeNotify();
    }
  }

  /// Load devices của user từ storage
  Future<void> loadUserDevices(String userId) async {
    try {
      final devices = await _storageService.loadUserDevices(userId);
      _devices = devices;
      _safeNotify();
      debugPrint('✅ Loaded ${devices.length} devices for user $userId');

      // 🐞 DEBUG: Print MQTT topics after loading
      debugPrintMqttTopics();
    } catch (e) {
      debugPrint('❌ Error loading user devices: $e');
    }
  }

  /// Save devices của user hiện tại
  Future<void> saveUserDevices() async {
    if (_currentUserId == null) return;

    try {
      await _storageService.saveUserDevices(_currentUserId!, _devices);
      debugPrint('✅ Saved ${_devices.length} devices for user $_currentUserId');
    } catch (e) {
      debugPrint('❌ Error saving user devices: $e');
    }
  }

  /// Thêm device mới
  Future<bool> addDevice({
    required String name,
    required DeviceType type,
    required String room,
    String? icon,
    int? initialValue,
  }) async {
    if (_currentUserId == null) {
      debugPrint('❌ Cannot add device: No current user');
      return false;
    }

    try {
      // Tạo ID unique cho device
      final deviceId = await _storageService.generateDeviceId();

      final newDevice = Device(
        id: deviceId,
        name: name,
        type: type,
        state: false,
        value: type == DeviceType.servo ? (initialValue ?? 0) : null,
        icon: icon ?? (type == DeviceType.relay ? '⚡' : '🎚️'),
        room: room,
        userId: _currentUserId,
        createdAt: DateTime.now(),
      );

      // 🚨 Sử dụng service method để có validation MQTT topic
      final success = await _storageService.addUserDevice(
        _currentUserId!,
        newDevice,
      );

      if (success) {
        // Reload danh sách từ storage để đồng bộ
        await loadUserDevices(_currentUserId!);
        debugPrint(
          '✅ Added device: ${newDevice.name} -> ${newDevice.mqttTopic}',
        );
        return true;
      } else {
        debugPrint('❌ Failed to add device: ${newDevice.name}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error adding device: $e');
      rethrow; // Rethrow để UI có thể hiển thị lỗi chi tiết
    }
  }

  /// Xóa device
  Future<bool> removeDevice(String deviceId) async {
    if (_currentUserId == null) {
      debugPrint('❌ Cannot remove device: No current user');
      return false;
    }

    try {
      final deviceIndex = _devices.indexWhere(
        (device) => device.id == deviceId,
      );
      if (deviceIndex == -1) {
        debugPrint('❌ Device not found: $deviceId');
        return false;
      }

      final removedDevice = _devices[deviceIndex];

      // Xóa avatar nếu có
      if (removedDevice.avatarPath != null) {
        await ImagePickerService.deleteOldAvatar(removedDevice.avatarPath);
      }

      // Xóa khỏi danh sách
      _devices.removeAt(deviceIndex);

      // Lưu vào storage
      await saveUserDevices();

      _safeNotify();

      debugPrint(
        '✅ Removed device: ${removedDevice.name} (${removedDevice.id})',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error removing device: $e');
      return false;
    }
  }

  Device? getDeviceById(String id) {
    try {
      return _devices.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateDeviceState(String id, bool state) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(state: state);

      // Gửi lệnh qua MQTT
      if (_mqttProvider != null) {
        String topic = _devices[index].mqttTopic;
        String message = state ? '1' : '0';
        _mqttProvider!.publish(topic, message);
        print('📡 MQTT: $topic -> $message');
      }

      _safeNotify();
      print('🔄 Device ${_devices[index].name}: ${state ? "ON" : "OFF"}');
    }
  }

  void updateServoValue(String id, int value) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1 &&
        (_devices[index].type == DeviceType.servo ||
            _devices[index].type == DeviceType.fan)) {
      _devices[index] = _devices[index].copyWith(value: value);

      // Gửi lệnh qua MQTT
      if (_mqttProvider != null) {
        String topic = _devices[index].mqttTopic;
        String message;

        // Quạt gửi JSON với tốc độ
        if (_devices[index].type == DeviceType.fan) {
          message = '{"command": "set_speed", "speed": $value}';
          print('📡 MQTT Fan JSON: $topic -> $message');
        } else {
          // Servo thông thường gửi số đơn giản
          message = value.toString();
          print('📡 MQTT Servo: $topic -> $message');
        }

        _mqttProvider!.publish(topic, message);
      }

      _safeNotify();

      // Auto save changes
      await saveUserDevices();

      if (id == 'fan_living') {
        int percentage = ((value / 255) * 100).round();
        print('🔄 Fan ${_devices[index].name}: $percentage% (PWM: $value)');
      } else {
        print('🔄 Servo ${_devices[index].name}: $value°');
      }
    }
  }

  void toggleDevice(String id) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final device = _devices[index];
      final currentState = device.state;

      // 🌪️ Xử lý riêng cho quạt
      if (device.isFan) {
        // Toggle quạt: OFF -> Low -> Medium -> High -> OFF
        int newSpeed = 0;
        bool newState = false;

        if (!currentState || device.fanSpeed == 0) {
          // Hiện tại OFF -> Chuyển sang Low
          newSpeed = Device.fanSpeedLow;
          newState = true;
        } else if (device.fanSpeed <= Device.fanSpeedLow) {
          // Hiện tại Low -> Chuyển sang Medium
          newSpeed = Device.fanSpeedMedium;
          newState = true;
        } else if (device.fanSpeed <= Device.fanSpeedMedium) {
          // Hiện tại Medium -> Chuyển sang High
          newSpeed = Device.fanSpeedHigh;
          newState = true;
        } else {
          // Hiện tại High -> Chuyển sang OFF
          newSpeed = 0;
          newState = false;
        }

        _devices[index] = device.copyWith(state: newState, value: newSpeed);

        // Gửi JSON command cho quạt
        if (_mqttProvider != null) {
          String topic = _devices[index].mqttTopic;
          String message = newState
              ? '{"command": "speed", "speed": $newSpeed, "mode": "${_devices[index].fanMode}"}'
              : '{"command": "off"}';
          _mqttProvider!.publish(topic, message);
          print('📡 MQTT Fan: $topic -> $message');
        }

        print(
          '🌪️ Fan ${device.name}: ${_devices[index].fanMode.toUpperCase()} (${((_devices[index].fanSpeed / 255) * 100).round()}%)',
        );
      } else {
        // 🔌 Xử lý relay thông thường
        _devices[index] = device.copyWith(state: !currentState);

        if (_mqttProvider != null) {
          String topic = _devices[index].mqttTopic;
          String message = (!currentState) ? '1' : '0';
          _mqttProvider!.publish(topic, message);
          print('📡 MQTT: $topic -> $message');
        }

        print('🔄 Toggled ${device.name}: ${!currentState ? "ON" : "OFF"}');
      }

      _safeNotify();
      await saveUserDevices(); // Auto-save
    }
  }

  // 📌 TOGGLE PIN CHO ĐIỀU KHIỂN NHANH
  void togglePin(String id) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(
        isPinned: !_devices[index].isPinned,
      );
      _safeNotify();
      await saveUserDevices(); // Auto-save

      print(
        '📌 ${_devices[index].isPinned ? "Pinned" : "Unpinned"} device: ${_devices[index].name}',
      );
    }
  }

  // 🌪️ ĐIỀU KHIỂN QUẠT CHI TIẾT
  void setFanSpeed(String id, int speed) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1 || !_devices[index].isFan) return;

    // Giới hạn speed 0-255
    speed = speed.clamp(0, 255);
    final newState = speed > 0;

    _devices[index] = _devices[index].copyWith(state: newState, value: speed);

    // Gửi JSON command
    if (_mqttProvider != null) {
      String topic = _devices[index].mqttTopic;
      String message = newState
          ? '{"command": "speed", "speed": $speed, "mode": "${_devices[index].fanMode}"}'
          : '{"command": "off"}';
      _mqttProvider!.publish(topic, message);
      print('📡 MQTT Fan Speed: $topic -> $message');
    }

    _safeNotify();
    await saveUserDevices(); // Auto-save
    print(
      '🌪️ Fan ${_devices[index].name}: Speed $speed (${((speed / 255) * 100).round()}%)',
    );
  }

  // 🌪️ ĐẶT CHẾ ĐỘ QUẠT
  void setFanMode(String id, String mode) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1 || !_devices[index].isFan) return;

    int speed = 0;
    switch (mode.toLowerCase()) {
      case 'low':
        speed = Device.fanSpeedLow;
        break;
      case 'medium':
        speed = Device.fanSpeedMedium;
        break;
      case 'high':
        speed = Device.fanSpeedHigh;
        break;
      case 'off':
        speed = 0;
        break;
      default:
        return; // Invalid mode
    }

    final newState = speed > 0;
    _devices[index] = _devices[index].copyWith(state: newState, value: speed);

    // Gửi JSON command
    if (_mqttProvider != null) {
      String topic = _devices[index].mqttTopic;
      String message = newState
          ? '{"command": "preset", "preset": "$mode", "speed": $speed}'
          : '{"command": "off"}';
      _mqttProvider!.publish(topic, message);
      print('📡 MQTT Fan Mode: $topic -> $message');
    }

    _safeNotify();
    await saveUserDevices(); // Auto-save
    print(
      '🌪️ Fan ${_devices[index].name}: ${mode.toUpperCase()} (${((speed / 255) * 100).round()}%)',
    );
  }

  // Preset speeds cho quạt phòng khách
  void setFanPreset(String id, String preset) {
    if (id != 'fan_living' || _mqttProvider == null) return;

    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1) return;

    // Cập nhật trạng thái local
    int speed = 150; // default medium
    switch (preset) {
      case 'low':
        speed = 80;
        break;
      case 'medium':
        speed = 150;
        break;
      case 'high':
        speed = 255;
        break;
    }

    _devices[index] = _devices[index].copyWith(value: speed, state: speed > 0);

    // Gửi JSON command
    String topic = _devices[index].mqttTopic;
    String message = '{"command": "preset", "preset": "$preset"}';
    _mqttProvider!.publish(topic, message);

    _safeNotify();
    print('📡 MQTT Preset: $topic -> $message');
    print(
      '🔄 Fan ${_devices[index].name}: $preset (${((speed / 255) * 100).round()}%)',
    );
  }

  void clearAllDevices() {
    _devices.clear();
    _safeNotify();
    print('🗑️ All devices cleared');
  }

  // 🐞 DEBUG: Print all device MQTT topics
  void debugPrintMqttTopics() {
    print('🐞 DEBUG: Device MQTT Topics:');
    for (final device in _devices) {
      print('   ${device.name} -> ${device.mqttTopic}');
      print('   Legacy: ${device.legacyMqttTopic}');
      print('   Room: ${device.room ?? "null"}');
      print('   ---');
    }
  }

  // Shortcut getters cho các thiết bị cụ thể
  bool get pumpState => getDeviceById('pump')?.state ?? false;
  bool get lightLivingState => getDeviceById('light_living')?.state ?? false;
  bool get lightYardState => getDeviceById('light_yard')?.state ?? false;
  bool get mistMakerState => getDeviceById('mist_maker')?.state ?? false;
  int get roofServoValue => getDeviceById('roof_servo')?.value ?? 0;
  int get gateServoValue => getDeviceById('gate_servo')?.value ?? 0;

  // Shortcut methods
  void togglePump(bool value) => updateDeviceState('pump', value);
  void toggleLightLiving(bool value) =>
      updateDeviceState('light_living', value);
  void toggleLightYard(bool value) => updateDeviceState('light_yard', value);
  void toggleMistMaker(bool value) => updateDeviceState('mist_maker', value);
  void updateRoofServo(int value) => updateServoValue('roof_servo', value);
  void updateGateServo(int value) => updateServoValue('gate_servo', value);

  // ✅ THÊM CÁC METHODS BỊ THIẾU
  int getActiveDevicesCount() {
    return _devices.where((device) => device.state).length;
  }

  void turnOnAllDevices() {
    for (var device in _devices) {
      if (device.type == DeviceType.relay) {
        updateDeviceState(device.id, true);
      }
    }
  }

  void turnOffAllDevices() {
    for (var device in _devices) {
      if (device.type == DeviceType.relay) {
        updateDeviceState(device.id, false);
      }
    }
  }

  // ✅ THÊM METHOD ĐỔI AVATAR
  /// Cập nhật avatar cho thiết bị
  Future<void> updateDeviceAvatar(
    String deviceId,
    String? newAvatarPath,
  ) async {
    final deviceIndex = _devices.indexWhere((device) => device.id == deviceId);
    if (deviceIndex == -1) return;

    final oldDevice = _devices[deviceIndex];

    // Xóa ảnh avatar cũ nếu có
    if (oldDevice.avatarPath != null) {
      await ImagePickerService.deleteOldAvatar(oldDevice.avatarPath);
    }

    // Cập nhật device với avatar mới
    _devices[deviceIndex] = oldDevice.copyWith(avatarPath: newAvatarPath);

    _safeNotify();
  }

  /// Chọn avatar mới từ gallery/camera
  Future<void> pickAndUpdateAvatar(
    BuildContext context,
    String deviceId,
  ) async {
    final newAvatarPath = await ImagePickerService.pickDeviceAvatar(context);
    if (newAvatarPath != null) {
      await updateDeviceAvatar(deviceId, newAvatarPath);
    }
  }

  /// Xóa avatar thiết bị (quay về icon mặc định)
  Future<void> removeDeviceAvatar(String deviceId) async {
    await updateDeviceAvatar(deviceId, null);
  }

  /// Cleanup các avatar không sử dụng
  Future<void> cleanupUnusedAvatars() async {
    final usedAvatars = _devices
        .where((device) => device.avatarPath != null)
        .map((device) => device.avatarPath!)
        .toList();

    await ImagePickerService.cleanupUnusedAvatars(usedAvatars);
  }

  /// Cập nhật tên thiết bị
  void updateDeviceName(String deviceId, String newName) async {
    final deviceIndex = _devices.indexWhere((device) => device.id == deviceId);
    if (deviceIndex == -1) return;

    final oldDevice = _devices[deviceIndex];
    _devices[deviceIndex] = oldDevice.copyWith(name: newName);

    await _saveAndNotify();
  }

  // 🗑️ CLEAR ALL USER DATA (for logout)
  Future<void> clearUserData() async {
    debugPrint('🗑️ DeviceProvider: Clearing all user data...');

    try {
      // Disconnect MQTT first
      if (_mqttProvider != null) {
        _mqttProvider!.disconnect();
        debugPrint('🔌 DeviceProvider: MQTT disconnected');
      }

      // Clear all devices
      _devices.clear();

      // Clear current user
      _currentUserId = null;

      // Clear MQTT provider reference
      _mqttProvider = null;

      // Notify listeners
      _safeNotify();

      debugPrint('✅ DeviceProvider: All user data cleared');
    } catch (e) {
      debugPrint('❌ DeviceProvider: Error clearing user data: $e');
      rethrow;
    }
  }

  /// Clear tất cả dữ liệu của user hiện tại (for testing/debugging)
  Future<bool> clearAllUserData() async {
    if (_currentUserId == null) return false;

    try {
      // Clear from memory
      _devices.clear();

      // Clear from storage
      final success = await _storageService.clearUserDevices(_currentUserId!);

      if (success) {
        _safeNotify();
        debugPrint('✅ Cleared all data for user $_currentUserId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error clearing user data: $e');
      return false;
    }
  }

  /// Helper method để save và notify
  Future<void> _saveAndNotify() async {
    _safeNotify();
    await saveUserDevices();
  }

  void _safeNotify() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}
