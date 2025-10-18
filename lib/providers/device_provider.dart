import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'dart:async';
import '../models/device_model.dart';
import '../services/image_picker_service.dart';
import '../services/device_storage_service.dart';
import '../services/device_mqtt_service.dart';
import 'mqtt_provider.dart';

class DeviceProvider extends ChangeNotifier {
  List<Device> _devices = [];
  MqttProvider? _mqttProvider;
  final DeviceStorageService _storageService = DeviceStorageService();
  final DeviceMqttService _deviceMqttService = DeviceMqttService();
  String? _currentUserId;

  // Thêm biến để theo dõi trạng thái kiểm tra kết nối
  bool _isCheckingConnection = false;
  String? _connectionCheckDeviceId;
  Timer? _connectionCheckTimer;

  // 📡 TRẠNG THÁI KẾT NỐI CỦA TỪNG THIẾT BỊ
  final Map<String, bool> _deviceConnectionStatus =
      {}; // deviceId -> isConnected
  Timer? _autoPingTimer; // Timer để tự động ping 5 phút 1 lần
  bool _isAutoPinging = false; // Đang auto-ping hay không

  bool get isCheckingConnection => _isCheckingConnection;
  String? get connectionCheckDeviceId => _connectionCheckDeviceId;

  // Lấy trạng thái kết nối của thiết bị
  bool isDeviceConnected(String deviceId) =>
      _deviceConnectionStatus[deviceId] ?? false;

  // Đếm số thiết bị đã kết nối
  int get connectedDevicesCount =>
      _deviceConnectionStatus.values.where((v) => v).length;

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

      // 📡 BẮT ĐẦU AUTO-PING SAU KHI LOAD DEVICES
      if (_devices.isNotEmpty) {
        debugPrint(
          '📡 Starting auto-ping after loading ${_devices.length} devices...',
        );
        startAutoPing();
      }
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

  /// Thêm thiết bị mới
  Future<void> addDevice(Device device) async {
    try {
      // Thêm device vào danh sách
      _devices.add(device);
      _safeNotify();

      // Auto save changes
      await saveUserDevices();

      print('✅ Added device: ${device.name}');
    } catch (e) {
      print('❌ Error adding device: $e');
      rethrow;
    }
  }

  /// Kiểm tra kết nối MQTT của thiết bị
  Future<bool> checkMqttConnection(Device device) async {
    // Ngăn gọi nhiều lần cùng lúc
    if (_isCheckingConnection) {
      print('⚠️ Connection check already in progress');
      return false;
    }

    _isCheckingConnection = true;
    _connectionCheckDeviceId = device.id;
    notifyListeners();

    // Sử dụng Completer để chỉ trả về kết quả 1 lần
    final completer = Completer<bool>();

    try {
      // Topic ping
      final pingTopic = 'smart_home/devices/${device.deviceCode}/ping';
      final pingPayload = 'ping';

      print('🔍 Starting connection check for device: ${device.name}');
      print('🔍 Ping topic: $pingTopic');

      // Subscribe đến ping topic trước
      await _deviceMqttService.subscribeToCustomTopic(device, pingTopic);

      // Timeout sau 5 giây
      _connectionCheckTimer = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print('⏱️ Connection check timeout for device: ${device.name}');
          _isCheckingConnection = false;
          _connectionCheckDeviceId = null;
          _deviceMqttService.removeDeviceCallback(device.id);
          notifyListeners();
          completer.complete(false);
        }
      });

      // Lắng nghe MQTT messages - CHỈ GỌI 1 LẦN
      _deviceMqttService.setDeviceCallback(
        device.id,
        onMessage: (message) {
          if (message == '1' && !completer.isCompleted) {
            print(
              '✅ MQTT connection check successful for device: ${device.name}',
            );
            _isCheckingConnection = false;
            _connectionCheckDeviceId = null;
            _connectionCheckTimer?.cancel();
            _deviceMqttService.removeDeviceCallback(device.id);
            notifyListeners();
            completer.complete(true);
          }
        },
      );

      // Gửi lệnh ping CHỈ 1 LẦN
      print('📤 Sending ping to: $pingTopic');
      await _deviceMqttService.publishToCustomTopic(
        device,
        pingTopic,
        pingPayload,
      );
      print('✅ Ping sent successfully');

      // Đợi kết quả (timeout hoặc nhận response)
      final result = await completer.future;

      // 📡 LƯU TRẠNG THÁI KẾT NỐI
      _deviceConnectionStatus[device.id] = result;
      notifyListeners();

      return result;
    } catch (e) {
      print('❌ MQTT connection check failed: $e');
      _isCheckingConnection = false;
      _connectionCheckDeviceId = null;
      _connectionCheckTimer?.cancel();
      _deviceMqttService.removeDeviceCallback(device.id);

      // 📡 LƯU TRẠNG THÁI KẾT NỐI THẤT BẠI
      _deviceConnectionStatus[device.id] = false;
      notifyListeners();

      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    }
  }

  /// Cập nhật device
  Future<void> updateDevice(Device updatedDevice) async {
    try {
      final index = _devices.indexWhere((d) => d.id == updatedDevice.id);
      if (index == -1) {
        throw Exception('Device not found: ${updatedDevice.id}');
      }

      // Cập nhật device trong danh sách
      _devices[index] = updatedDevice;
      _safeNotify();

      // Auto save changes
      await saveUserDevices();

      print('✅ Updated device: ${updatedDevice.name}');
    } catch (e) {
      print('❌ Error updating device: $e');
      rethrow;
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

      // Gửi lệnh qua MQTT - ưu tiên broker riêng của thiết bị
      final device = _devices[index];
      final topic = device.finalMqttTopic;
      final message =
          '{"name": "${device.keyName}", "action": "${state ? "turn_on" : "turn_off"}"}';

      print(
        '🔍 DEBUG: Device ${device.name} - hasCustomMqttConfig: ${device.hasCustomMqttConfig}',
      );
      print('🔍 DEBUG: mqttConfig is null: ${device.mqttConfig == null}');
      if (device.mqttConfig != null) {
        print(
          '🔍 DEBUG: useCustomConfig: ${device.mqttConfig!.useCustomConfig}',
        );
        print('🔍 DEBUG: broker: ${device.mqttConfig!.broker}');
        print('🔍 DEBUG: port: ${device.mqttConfig!.port}');
      }
      if (device.hasCustomMqttConfig) {
        print(
          '🔍 DEBUG: Custom MQTT Config - Broker: ${device.mqttConfig!.broker}:${device.mqttConfig!.port}',
        );
        print('🔍 DEBUG: Custom Topic: ${device.finalMqttTopic}');
      } else {
        print('🔍 DEBUG: Using global MQTT config');
        print('🔍 DEBUG: Global Topic: $topic');
      }

      // Gửi qua broker riêng của thiết bị
      final sentViaDeviceMqtt = await _deviceMqttService.publishToDevice(
        device,
        message,
      );

      if (sentViaDeviceMqtt) {
        print('✅ SUCCESS: Device MQTT - $topic -> $message (Custom Broker)');
      } else {
        print('❌ FAILED: No MQTT config for device ${device.name}');
      }

      _safeNotify();
      print('🔄 Device ${device.name}: ${state ? "ON" : "OFF"}');
    }
  }

  void updateServoValue(String id, int value) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1 &&
        (_devices[index].type == DeviceType.servo ||
            _devices[index].type == DeviceType.fan)) {
      _devices[index] = _devices[index].copyWith(value: value);

      // Gửi lệnh qua MQTT - ưu tiên broker riêng của thiết bị
      final device = _devices[index];
      final topic = device.finalMqttTopic;
      String message;

      // Quạt gửi JSON với tốc độ
      if (device.type == DeviceType.fan) {
        message =
            '{"name": "${device.keyName}", "command": "set_speed", "speed": $value}';
      } else {
        // Servo thông thường gửi JSON với góc
        message =
            '{"name": "${device.keyName}", "action": "set_angle", "angle": $value}';
      }

      // Gửi qua broker riêng của thiết bị
      final sentViaDeviceMqtt = await _deviceMqttService.publishToDevice(
        device,
        message,
      );

      if (sentViaDeviceMqtt) {
        print('📡 Device MQTT: $topic -> $message');
      } else {
        print('❌ FAILED: No MQTT config for device ${device.name}');
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

        // Gửi JSON command cho quạt - ưu tiên broker riêng của thiết bị
        String topic = _devices[index].finalMqttTopic;
        String message = newState
            ? '{"command": "speed", "speed": $newSpeed, "mode": "${_devices[index].fanMode}"}'
            : '{"command": "off"}';

        print(
          '🔍 DEBUG: Device ${device.name} - hasCustomMqttConfig: ${device.hasCustomMqttConfig}',
        );
        print('🔍 DEBUG: mqttConfig is null: ${device.mqttConfig == null}');
        if (device.mqttConfig != null) {
          print(
            '🔍 DEBUG: useCustomConfig: ${device.mqttConfig!.useCustomConfig}',
          );
          print('🔍 DEBUG: broker: ${device.mqttConfig!.broker}');
          print('🔍 DEBUG: port: ${device.mqttConfig!.port}');
        }

        final sentViaDeviceMqtt = await _deviceMqttService.publishToDevice(
          device,
          message,
        );

        if (sentViaDeviceMqtt) {
          print(
            '✅ SUCCESS: Device MQTT Fan - $topic -> $message (Custom Broker)',
          );
        } else {
          print('❌ FAILED: No MQTT config for device ${device.name}');
        }

        print(
          '🌪️ Fan ${device.name}: ${_devices[index].fanMode.toUpperCase()} (${((_devices[index].fanSpeed / 255) * 100).round()}%)',
        );
      } else {
        // 🔌 Xử lý relay thông thường - ưu tiên broker riêng của thiết bị
        _devices[index] = device.copyWith(state: !currentState);

        String topic = _devices[index].finalMqttTopic;
        String message =
            '{"name": "${device.keyName}", "action": "${(!currentState) ? "turn_on" : "turn_off"}"}';

        print(
          '🔍 DEBUG: Device ${device.name} - hasCustomMqttConfig: ${device.hasCustomMqttConfig}',
        );
        print('🔍 DEBUG: mqttConfig is null: ${device.mqttConfig == null}');
        if (device.mqttConfig != null) {
          print(
            '🔍 DEBUG: useCustomConfig: ${device.mqttConfig!.useCustomConfig}',
          );
          print('🔍 DEBUG: broker: ${device.mqttConfig!.broker}');
          print('🔍 DEBUG: port: ${device.mqttConfig!.port}');
        }

        final sentViaDeviceMqtt = await _deviceMqttService.publishToDevice(
          device,
          message,
        );

        if (sentViaDeviceMqtt) {
          print('✅ SUCCESS: Device MQTT - $topic -> $message (Custom Broker)');
        } else {
          print('❌ FAILED: No MQTT config for device ${device.name}');
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

  // 🏠 ROOM MANAGEMENT METHODS

  /// Thêm phòng trống mới (không tự động thêm thiết bị)
  Future<void> addEmptyRoom(String roomName, String avatar) async {
    if (_currentUserId == null) {
      throw Exception('No current user');
    }

    // Kiểm tra phòng đã tồn tại chưa
    if (_devices.any((d) => d.room == roomName)) {
      throw Exception('Phòng "$roomName" đã tồn tại');
    }

    // Tạo một thiết bị ẩn để đại diện cho phòng
    // Điều này giúp duy trì danh sách phòng mà không cần thay đổi cấu trúc dữ liệu
    final roomDevice = Device(
      id: 'room_${roomName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      name: roomName,
      keyName: _normalizeName(roomName),
      deviceCode: _generateDeviceCode(),
      type: DeviceType.relay,
      room: roomName,
      icon: avatar,
      avatarPath: null,
      state: false,
      value: 0,
      isServo360: null,
      mqttConfig: null, // Phòng không cần MQTT config
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    _devices.add(roomDevice);
    await _saveAndNotify();

    print('🏠 Added empty room: $roomName');
  }

  /// Cập nhật phòng (tên và avatar)
  Future<void> updateRoom(
    String oldRoomName,
    String newRoomName,
    String newAvatar,
  ) async {
    if (_currentUserId == null) {
      throw Exception('No current user');
    }

    // Kiểm tra phòng mới đã tồn tại chưa (nếu đổi tên)
    if (oldRoomName != newRoomName &&
        _devices.any((d) => d.room == newRoomName)) {
      throw Exception('Phòng "$newRoomName" đã tồn tại');
    }

    // Cập nhật tất cả thiết bị trong phòng
    for (int i = 0; i < _devices.length; i++) {
      if (_devices[i].room == oldRoomName) {
        _devices[i] = _devices[i].copyWith(
          room: newRoomName,
          icon: _devices[i].id.startsWith('room_')
              ? newAvatar
              : _devices[i].icon, // Chỉ cập nhật avatar cho room device
          lastUpdated: DateTime.now(),
        );
      }
    }

    await _saveAndNotify();
    print(
      '🏠 Updated room: "$oldRoomName" -> "$newRoomName" with avatar: $newAvatar',
    );
  }

  /// Đổi tên phòng
  Future<void> renameRoom(String oldRoomName, String newRoomName) async {
    if (_currentUserId == null) {
      throw Exception('No current user');
    }

    // Kiểm tra phòng mới đã tồn tại chưa
    if (oldRoomName != newRoomName &&
        _devices.any((d) => d.room == newRoomName)) {
      throw Exception('Phòng "$newRoomName" đã tồn tại');
    }

    // Cập nhật tất cả thiết bị trong phòng
    bool updated = false;
    for (int i = 0; i < _devices.length; i++) {
      if (_devices[i].room == oldRoomName) {
        _devices[i] = _devices[i].copyWith(room: newRoomName);
        updated = true;
      }
    }

    if (!updated) {
      throw Exception('Không tìm thấy phòng "$oldRoomName"');
    }

    await _saveAndNotify();
    print('🏠 Renamed room: "$oldRoomName" -> "$newRoomName"');
  }

  /// Xóa phòng (chỉ khi phòng trống)
  Future<void> deleteRoom(String roomName) async {
    if (_currentUserId == null) {
      throw Exception('No current user');
    }

    // Kiểm tra phòng có thiết bị không
    final devicesInRoom = _devices.where((d) => d.room == roomName).toList();
    if (devicesInRoom.isNotEmpty) {
      throw Exception('Không thể xóa phòng có thiết bị');
    }

    // Xóa tất cả thiết bị trong phòng (nếu có)
    _devices.removeWhere((d) => d.room == roomName);

    await _saveAndNotify();
    print('🏠 Deleted room: $roomName');
  }

  /// Di chuyển thiết bị sang phòng khác
  Future<void> moveDeviceToRoom(String deviceId, String newRoomName) async {
    if (_currentUserId == null) {
      throw Exception('No current user');
    }

    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) {
      throw Exception('Không tìm thấy thiết bị');
    }

    _devices[index] = _devices[index].copyWith(room: newRoomName);
    await _saveAndNotify();

    print('🏠 Moved device ${_devices[index].name} to room: $newRoomName');
  }

  /// Lấy danh sách phòng có sẵn (loại bỏ phòng trống)
  List<String> get availableRooms {
    final rooms = <String>{};
    for (final device in _devices) {
      if (device.room != null && device.room!.isNotEmpty) {
        // Chỉ đếm thiết bị thực sự, không đếm room marker
        if (!device.id.startsWith('room_')) {
          rooms.add(device.room!);
        }
      }
    }
    return rooms.toList()..sort();
  }

  /// Lấy số lượng thiết bị trong phòng
  int getDeviceCountInRoom(String roomName) {
    return _devices
        .where((d) => d.room == roomName && !d.id.startsWith('room_'))
        .length;
  }

  // 🛠️ HELPER METHODS FOR ROOM MANAGEMENT

  /// Chuẩn hóa tên phòng thành keyName
  String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd')
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Tạo mã thiết bị ngẫu nhiên
  String _generateDeviceCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // ========================================
  // 📡 AUTO-PING DEVICES
  // ========================================

  /// Ping tất cả thiết bị (không block UI, chạy background)
  Future<void> pingAllDevices({bool silent = true}) async {
    if (_isAutoPinging) {
      print('⚠️ Auto-ping already in progress, skipping...');
      return;
    }

    if (_devices.isEmpty) {
      print('ℹ️ No devices to ping');
      return;
    }

    _isAutoPinging = true;
    if (!silent) notifyListeners(); // Chỉ notify nếu không silent

    print('📡 Starting auto-ping for ${_devices.length} devices...');

    // Ping tất cả thiết bị song song (không đợi lẫn nhau)
    final pingFutures = _devices.map((device) async {
      try {
        // Tạo một version "lightweight" của checkMqttConnection
        // để không conflict với _isCheckingConnection flag
        await _pingDeviceSilent(device);
      } catch (e) {
        print('❌ Error ping device ${device.name}: $e');
        _deviceConnectionStatus[device.id] = false;
      }
    }).toList();

    // Đợi tất cả ping hoàn thành (hoặc timeout)
    await Future.wait(pingFutures);

    _isAutoPinging = false;
    notifyListeners(); // Luôn notify sau khi ping xong để update UI

    print(
      '✅ Auto-ping completed. Connected: $connectedDevicesCount/${_devices.length}',
    );
  }

  /// Ping một thiết bị (silent mode - không set _isCheckingConnection)
  Future<bool> _pingDeviceSilent(Device device) async {
    final completer = Completer<bool>();
    Timer? timeoutTimer;

    try {
      final pingTopic = 'smart_home/devices/${device.deviceCode}/ping';
      final pingPayload = 'ping';

      // Subscribe
      await _deviceMqttService.subscribeToCustomTopic(device, pingTopic);

      // Timeout ngắn hơn (3 giây thay vì 5)
      timeoutTimer = Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          _deviceMqttService.removeDeviceCallback(device.id);
          _deviceConnectionStatus[device.id] = false;
          completer.complete(false);
        }
      });

      // Callback nhận message
      _deviceMqttService.setDeviceCallback(
        device.id,
        onMessage: (message) {
          if (message == '1' && !completer.isCompleted) {
            timeoutTimer?.cancel();
            _deviceMqttService.removeDeviceCallback(device.id);
            _deviceConnectionStatus[device.id] = true;
            completer.complete(true);
          }
        },
      );

      // Gửi ping
      await _deviceMqttService.publishToCustomTopic(
        device,
        pingTopic,
        pingPayload,
      );

      return await completer.future;
    } catch (e) {
      print('❌ Ping device ${device.name} failed: $e');
      timeoutTimer?.cancel();
      _deviceMqttService.removeDeviceCallback(device.id);
      _deviceConnectionStatus[device.id] = false;

      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    }
  }

  /// Bắt đầu auto-ping timer (mỗi 5 phút)
  void startAutoPing() {
    // Hủy timer cũ nếu có
    stopAutoPing();

    print('🔄 Starting auto-ping timer (every 5 minutes)...');

    // Ping ngay lần đầu
    pingAllDevices(silent: true);

    // Ping mỗi 5 phút
    _autoPingTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      print('⏰ Auto-ping timer triggered');
      pingAllDevices(silent: true);
    });
  }

  /// Dừng auto-ping timer
  void stopAutoPing() {
    _autoPingTimer?.cancel();
    _autoPingTimer = null;
    print('⏹️ Auto-ping timer stopped');
  }

  @override
  void dispose() {
    stopAutoPing();
    _connectionCheckTimer?.cancel();
    super.dispose();
  }
}
