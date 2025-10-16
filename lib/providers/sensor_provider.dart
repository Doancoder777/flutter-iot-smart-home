import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/sensor_data.dart';
import '../models/user_sensor.dart';
import '../models/sensor_type.dart';
import '../models/device_mqtt_config.dart';
import '../services/local_storage_service.dart';
import '../services/sensor_config_service.dart';
import '../services/notification_service.dart';
import '../config/constants.dart';

class SensorProvider extends ChangeNotifier {
  final LocalStorageService _storageService;
  final NotificationService _notificationService;
  late final SensorConfigService _sensorConfigService;

  SensorData _currentData = SensorData.empty();
  List<SensorData> _history = [];
  List<UserSensor> _userSensors = [];
  bool _gasAlertShown = false;
  bool _rainAlertShown = false;
  bool _soilAlertShown = false;
  bool _dustAlertShown = false;
  String? _currentUserId; // User isolation

  SensorData get currentData => _currentData;
  List<SensorData> get history => _history;
  List<UserSensor> get userSensors => _userSensors;

  // Individual sensor getters for backward compatibility
  double get temperature => _currentData.temperature;
  double get humidity => _currentData.humidity;
  int get rain => _currentData.rain;
  int get light => _currentData.light;
  int get soilMoisture => _currentData.soilMoisture;
  int get gas => _currentData.gas;
  int get dust => _currentData.dust;
  bool get motionDetected => _currentData.motionDetected;

  SensorProvider(this._storageService, this._notificationService) {
    _sensorConfigService = SensorConfigService(_storageService);
    // Không load history ngay, chờ setCurrentUser
  }

  /// Set current user và load sensor history và user sensors của user đó
  Future<void> setCurrentUser(String? userId) async {
    if (_currentUserId == userId) return;

    _currentUserId = userId;

    if (userId != null) {
      await _loadUserSensors();
      _loadHistory();
    } else {
      _history = [];
      _userSensors = [];
      _safeNotify();
    }
  }

  /// Load user sensors từ storage
  Future<void> _loadUserSensors() async {
    if (_currentUserId == null) return;

    try {
      _userSensors = await _sensorConfigService.getUserSensors(_currentUserId!);
      _safeNotify();
      print(
        '📊 Loaded ${_userSensors.length} sensors for user: $_currentUserId',
      );
    } catch (e) {
      print('❌ Error loading user sensors: $e');
      _userSensors = [];
    }
  }

  /// Kiểm tra user có đủ sensors để hiển thị weather widget
  bool hasWeatherSensors() {
    if (_currentUserId == null) return false;

    final requiredTypes = ['temperature', 'humidity', 'rain'];
    for (final type in requiredTypes) {
      final hasSensor = _userSensors.any(
        (s) => s.sensorTypeId == type && s.isActive,
      );
      if (!hasSensor) return false;
    }
    return true;
  }

  /// Lấy sensor theo type (sensor đầu tiên)
  UserSensor? getSensorByType(String sensorTypeId) {
    try {
      return _userSensors.firstWhere(
        (s) => s.sensorTypeId == sensorTypeId && s.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// Xử lý MQTT message đến từ topic động
  Future<void> handleMqttMessage(String topic, String message) async {
    if (_currentUserId == null) return;

    try {
      // Tìm sensor theo MQTT topic
      final sensor = _userSensors.firstWhere(
        (s) => s.mqttTopic == topic && s.isActive,
        orElse: () => throw StateError('No sensor found'),
      );

      // Parse value theo data type
      dynamic value;
      switch (sensor.sensorType!.dataType) {
        case SensorDataType.double:
          value = double.parse(message);
          break;
        case SensorDataType.int:
          value = int.parse(message);
          break;
        case SensorDataType.bool:
          value = message == '1' || message.toLowerCase() == 'true';
          break;
      }

      // Cập nhật sensor value
      await _sensorConfigService.updateSensorValue(
        _currentUserId!,
        topic,
        value,
      );

      // Reload sensors để cập nhật lastValue
      await _loadUserSensors();

      // Cập nhật currentData cho backward compatibility
      _updateCurrentDataFromSensors();

      print('📊 Updated sensor: ${sensor.displayName} = $value');
    } catch (e) {
      print('⚠️ No sensor found for topic: $topic (message: $message)');
    }
  }

  /// Cập nhật currentData từ user sensors (backward compatibility)
  void _updateCurrentDataFromSensors() {
    double temperature = 0.0;
    double humidity = 0.0;
    int rain = 0;
    int light = 0;
    int soilMoisture = 0;
    int gas = 0;
    int dust = 0;
    bool motionDetected = false;

    for (final sensor in _userSensors.where(
      (s) => s.isActive && s.lastValue != null,
    )) {
      switch (sensor.sensorTypeId) {
        case 'temperature':
          temperature = (sensor.lastValue as num).toDouble();
          break;
        case 'humidity':
          humidity = (sensor.lastValue as num).toDouble();
          break;
        case 'rain':
          rain = sensor.lastValue as int;
          break;
        case 'light':
          light = sensor.lastValue as int;
          break;
        case 'soil_moisture':
          soilMoisture = sensor.lastValue as int;
          break;
        case 'gas':
          gas = sensor.lastValue as int;
          break;
        case 'dust':
          dust = sensor.lastValue as int;
          break;
        case 'motion':
          motionDetected = sensor.lastValue as bool;
          break;
      }
    }

    _currentData = SensorData(
      temperature: temperature,
      humidity: humidity,
      rain: rain,
      light: light,
      soilMoisture: soilMoisture,
      gas: gas,
      dust: dust,
      motionDetected: motionDetected,
      timestamp: DateTime.now(),
    );

    _addToHistory(_currentData);
    _checkAlerts(_currentData);
    _safeNotify();
  }

  /// Clear user data when logout
  void clearUserData() {
    _currentUserId = null;
    _history = [];
    _userSensors = [];
    _currentData = SensorData.empty();
    _gasAlertShown = false;
    _rainAlertShown = false;
    _soilAlertShown = false;
    _dustAlertShown = false;
    _safeNotify();
    print('🧹 SensorProvider: Cleared user data');
  }

  /// Cập nhật sensor
  Future<void> updateSensor(UserSensor sensor) async {
    if (_currentUserId == null) return;

    await _sensorConfigService.updateUserSensor(_currentUserId!, sensor);
    await _loadUserSensors();
  }

  /// Xóa sensor
  Future<void> deleteSensor(String sensorId) async {
    if (_currentUserId == null) return;

    await _sensorConfigService.deleteUserSensor(_currentUserId!, sensorId);
    await _loadUserSensors();
  }

  /// Tạo default sensors cho user mới
  Future<void> createDefaultSensors() async {
    if (_currentUserId == null) return;

    await _sensorConfigService.createDefaultSensorsForUser(_currentUserId!);
    await _loadUserSensors();
  }

  void updateSensorData(SensorData data) {
    _currentData = data;
    _addToHistory(data);
    _checkAlerts(data);
    _safeNotify();
  }

  void updateTemperature(double value) {
    _currentData = SensorData(
      temperature: value,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );
    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateHumidity(double value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: value,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );
    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateRain(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: value,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );

    // Rain alert
    if (value == 1 && !_rainAlertShown) {
      _notificationService.showRainAlert();
      _rainAlertShown = true;
    } else if (value == 0) {
      _rainAlertShown = false;
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateLight(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: value,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );
    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateSoilMoisture(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: value,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );

    // Soil moisture alert
    if (value < AppConstants.lowSoilMoisture && !_soilAlertShown) {
      _notificationService.showLowSoilMoistureAlert();
      _soilAlertShown = true;
    } else if (value >= AppConstants.lowSoilMoisture) {
      _soilAlertShown = false;
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateGas(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: value,
      dust: _currentData.dust,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );

    // Gas alert
    if (value > AppConstants.gasWarningLevel && !_gasAlertShown) {
      _notificationService.showGasAlert(value);
      _gasAlertShown = true;
    } else if (value <= AppConstants.gasWarningLevel) {
      _gasAlertShown = false;
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateDust(int value) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: value,
      motionDetected: _currentData.motionDetected,
      timestamp: DateTime.now(),
    );

    // Dust alert
    if (value > AppConstants.dustWarningLevel && !_dustAlertShown) {
      _notificationService.showHighDustAlert(value);
      _dustAlertShown = true;
    } else if (value <= AppConstants.dustWarningLevel) {
      _dustAlertShown = false;
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void updateMotion(bool detected) {
    _currentData = SensorData(
      temperature: _currentData.temperature,
      humidity: _currentData.humidity,
      rain: _currentData.rain,
      light: _currentData.light,
      soilMoisture: _currentData.soilMoisture,
      gas: _currentData.gas,
      dust: _currentData.dust,
      motionDetected: detected,
      timestamp: DateTime.now(),
    );

    if (detected) {
      _notificationService.showMotionDetectedAlert();
    }

    _addToHistory(_currentData);
    _safeNotify();
  }

  void _addToHistory(SensorData data) {
    _history.add(data);

    // Keep only last 100 data points
    if (_history.length > AppConstants.maxDataPoints) {
      _history.removeAt(0);
    }

    _saveHistory();
  }

  void _checkAlerts(SensorData data) {
    // Gas alert
    if (data.gas > AppConstants.gasWarningLevel && !_gasAlertShown) {
      _notificationService.showGasAlert(data.gas);
      _gasAlertShown = true;
    } else if (data.gas <= AppConstants.gasWarningLevel) {
      _gasAlertShown = false;
    }

    // Rain alert
    if (data.rain == 1 && !_rainAlertShown) {
      _notificationService.showRainAlert();
      _rainAlertShown = true;
    } else if (data.rain == 0) {
      _rainAlertShown = false;
    }

    // Soil moisture alert
    if (data.soilMoisture < AppConstants.lowSoilMoisture && !_soilAlertShown) {
      _notificationService.showLowSoilMoistureAlert();
      _soilAlertShown = true;
    } else if (data.soilMoisture >= AppConstants.lowSoilMoisture) {
      _soilAlertShown = false;
    }

    // Dust alert
    if (data.dust > AppConstants.dustWarningLevel && !_dustAlertShown) {
      _notificationService.showHighDustAlert(data.dust);
      _dustAlertShown = true;
    } else if (data.dust <= AppConstants.dustWarningLevel) {
      _dustAlertShown = false;
    }

    // Motion detected
    if (data.motionDetected) {
      _notificationService.showMotionDetectedAlert();
    }
  }

  void _loadHistory() {
    if (_currentUserId == null) {
      _history = [];
      return;
    }

    final stored = _storageService.getSensorHistory(
      'all',
      userId: _currentUserId,
    );
    _history = stored.map((json) => SensorData.fromJson(json)).toList();
    print(
      '📊 Loaded ${_history.length} sensor history records for user: $_currentUserId',
    );
  }

  void _saveHistory() {
    if (_currentUserId == null) return;

    final jsonList = _history.map((data) => data.toJson()).toList();
    _storageService.saveSensorHistory('all', jsonList, userId: _currentUserId);
  }

  void clearHistory() {
    _history.clear();
    _saveHistory();
    _safeNotify();
  }

  List<SensorData> getHistoryByTimeRange(DateTime start, DateTime end) {
    return _history.where((data) {
      return data.timestamp.isAfter(start) && data.timestamp.isBefore(end);
    }).toList();
  }

  List<SensorData> getRecentHistory(int count) {
    if (_history.length <= count) {
      return _history;
    }
    return _history.sublist(_history.length - count);
  }

  /// Add new user sensor
  Future<void> addSensor({
    required String sensorTypeId,
    required String displayName,
    required String customMqttTopic,
    required String deviceCode,
    Map<String, dynamic>? configuration,
    DeviceMqttConfig? mqttConfig,
  }) async {
    if (_currentUserId == null) {
      throw Exception('No current user set');
    }

    final sensorId = 'sensor_${DateTime.now().millisecondsSinceEpoch}';

    final userSensor = UserSensor(
      id: sensorId,
      userId: _currentUserId!,
      sensorTypeId: sensorTypeId,
      displayName: displayName,
      mqttTopic: customMqttTopic,
      deviceCode: deviceCode,
      isActive: true,
      configuration: configuration,
      displayConfig: configuration?['displayConfig'] != null
          ? DisplayConfig.fromJson(configuration!['displayConfig'])
          : null,
      customIcon: configuration?['customIcon'],
      mqttConfig: mqttConfig,
      createdAt: DateTime.now(),
    );

    _userSensors.add(userSensor);
    // Save to storage - using sensor history method as fallback
    final jsonList = _userSensors.map((sensor) => sensor.toJson()).toList();
    await _storageService.saveSensorHistory(
      'user_sensors',
      jsonList,
      userId: _currentUserId,
    );
    _safeNotify();

    print('✅ Added sensor: $displayName with device code: $deviceCode');
  }

  void _safeNotify() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}
