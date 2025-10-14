import 'sensor_type.dart';

class UserSensor {
  final String id;
  final String userId;
  final String sensorTypeId;
  final String displayName;
  final String mqttTopic;
  final bool isActive;
  final Map<String, dynamic>? configuration;
  final DisplayConfig? displayConfig; // 🆕 Cấu hình hiển thị
  final String? customIcon; // 🆕 Icon tùy chỉnh
  final DateTime createdAt;
  final DateTime? lastUpdateAt;
  final dynamic lastValue;

  // 📡 MQTT Configuration (giống Device model)
  final String? sensorId; // ESP32 MAC-based ID (giống deviceId)
  final String? mqttBroker;
  final int? mqttPort;
  final String? mqttUsername;
  final String? mqttPassword;
  final bool mqttUseSsl;

  const UserSensor({
    required this.id,
    required this.userId,
    required this.sensorTypeId,
    required this.displayName,
    required this.mqttTopic,
    this.isActive = true,
    this.configuration,
    this.displayConfig,
    this.customIcon,
    required this.createdAt,
    this.lastUpdateAt,
    this.lastValue,
    // MQTT config
    this.sensorId,
    this.mqttBroker,
    this.mqttPort,
    this.mqttUsername,
    this.mqttPassword,
    this.mqttUseSsl = false,
  });

  /// Lấy thông tin SensorType
  SensorType? get sensorType => AvailableSensorTypes.getById(sensorTypeId);

  /// Lấy icon (ưu tiên custom icon)
  String get icon => customIcon ?? sensorType?.icon ?? '📊';

  /// Lấy unit (ưu tiên từ displayConfig)
  String get unit => displayConfig?.unit ?? sensorType?.unit ?? '';

  /// Lấy formatted value theo displayConfig
  String get formattedValue {
    if (lastValue == null) return '--';

    // Nếu có displayConfig, sử dụng nó
    if (displayConfig != null) {
      return _formatWithDisplayConfig(lastValue);
    }

    // Fallback về format mặc định
    final type = sensorType;
    if (type == null) return lastValue.toString();

    switch (type.dataType) {
      case SensorDataType.double:
        final value = (lastValue as num).toDouble();
        return '${value.toStringAsFixed(1)}${unit}';
      case SensorDataType.int:
        return '${lastValue}${unit}';
      case SensorDataType.bool:
        return lastValue == true ? 'Có' : 'Không';
    }
  }

  /// Format value theo DisplayConfig
  String _formatWithDisplayConfig(dynamic value) {
    if (displayConfig == null) return value.toString();

    switch (displayConfig!.type) {
      case DisplayType.boolean:
        final boolValue = value == true || value == 1 || value == '1';
        return boolValue
            ? (displayConfig!.trueLabel ?? 'Có')
            : (displayConfig!.falseLabel ?? 'Không');

      case DisplayType.pulse:
        return '${value}${unit}';

      case DisplayType.percentage:
        if (displayConfig!.maxValue != null && displayConfig!.maxValue! > 0) {
          final numValue = (value as num).toDouble();
          final percentage = (numValue / displayConfig!.maxValue! * 100).clamp(
            0,
            100,
          );
          return '${percentage.toStringAsFixed(1)}%';
        }
        return '${value}${unit}';
    }
  }

  /// Kiểm tra có phải weather sensor không
  bool get isWeatherSensor =>
      AvailableSensorTypes.isWeatherSensor(sensorTypeId);

  UserSensor copyWith({
    String? id,
    String? userId,
    String? sensorTypeId,
    String? displayName,
    String? mqttTopic,
    bool? isActive,
    Map<String, dynamic>? configuration,
    DisplayConfig? displayConfig,
    String? customIcon,
    DateTime? createdAt,
    DateTime? lastUpdateAt,
    dynamic lastValue,
    // MQTT config
    String? sensorId,
    String? mqttBroker,
    int? mqttPort,
    String? mqttUsername,
    String? mqttPassword,
    bool? mqttUseSsl,
  }) {
    return UserSensor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sensorTypeId: sensorTypeId ?? this.sensorTypeId,
      displayName: displayName ?? this.displayName,
      mqttTopic: mqttTopic ?? this.mqttTopic,
      isActive: isActive ?? this.isActive,
      configuration: configuration ?? this.configuration,
      displayConfig: displayConfig ?? this.displayConfig,
      customIcon: customIcon ?? this.customIcon,
      createdAt: createdAt ?? this.createdAt,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      lastValue: lastValue ?? this.lastValue,
      // MQTT config
      sensorId: sensorId ?? this.sensorId,
      mqttBroker: mqttBroker ?? this.mqttBroker,
      mqttPort: mqttPort ?? this.mqttPort,
      mqttUsername: mqttUsername ?? this.mqttUsername,
      mqttPassword: mqttPassword ?? this.mqttPassword,
      mqttUseSsl: mqttUseSsl ?? this.mqttUseSsl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sensorTypeId': sensorTypeId,
      'displayName': displayName,
      'mqttTopic': mqttTopic,
      'isActive': isActive,
      'configuration': configuration,
      'displayConfig': displayConfig?.toJson(),
      'customIcon': customIcon,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdateAt': lastUpdateAt?.toIso8601String(),
      'lastValue': lastValue,
      // MQTT config
      'sensorId': sensorId,
      'mqttBroker': mqttBroker,
      'mqttPort': mqttPort,
      'mqttUsername': mqttUsername,
      'mqttPassword': mqttPassword,
      'mqttUseSsl': mqttUseSsl,
    };
  }

  factory UserSensor.fromJson(Map<String, dynamic> json) {
    return UserSensor(
      id: json['id'],
      userId: json['userId'],
      sensorTypeId: json['sensorTypeId'],
      displayName: json['displayName'],
      mqttTopic: json['mqttTopic'],
      isActive: json['isActive'] ?? true,
      configuration: json['configuration'],
      displayConfig: json['displayConfig'] != null
          ? DisplayConfig.fromJson(json['displayConfig'])
          : null,
      customIcon: json['customIcon'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdateAt: json['lastUpdateAt'] != null
          ? DateTime.parse(json['lastUpdateAt'])
          : null,
      lastValue: json['lastValue'],
      // MQTT config
      sensorId: json['sensorId'],
      mqttBroker: json['mqttBroker'],
      mqttPort: json['mqttPort'],
      mqttUsername: json['mqttUsername'],
      mqttPassword: json['mqttPassword'],
      mqttUseSsl: json['mqttUseSsl'] ?? false,
    );
  }

  /// Tạo UserSensor từ SensorType với custom config
  factory UserSensor.fromSensorType({
    required String userId,
    required SensorType sensorType,
    required String displayName,
    String? customMqttTopic,
    Map<String, dynamic>? configuration,
    DisplayConfig? displayConfig,
    String? customIcon,
  }) {
    final now = DateTime.now();
    final sensorId = '${sensorType.id}_${userId}_${now.millisecondsSinceEpoch}';

    // Parse DisplayConfig và customIcon từ configuration nếu có
    DisplayConfig? finalDisplayConfig = displayConfig;
    String? finalCustomIcon = customIcon;

    if (configuration != null) {
      if (configuration['displayConfig'] != null) {
        try {
          finalDisplayConfig = DisplayConfig.fromJson(
            configuration['displayConfig'] as Map<String, dynamic>,
          );
        } catch (e) {
          print('Error parsing displayConfig: $e');
        }
      }
      if (configuration['customIcon'] != null) {
        finalCustomIcon = configuration['customIcon'] as String;
      }
    }

    return UserSensor(
      id: sensorId,
      userId: userId,
      sensorTypeId: sensorType.id,
      displayName: displayName,
      mqttTopic: customMqttTopic ?? '${sensorType.defaultMqttTopic}/$sensorId',
      isActive: true,
      configuration: configuration,
      displayConfig: finalDisplayConfig,
      customIcon: finalCustomIcon,
      createdAt: now,
    );
  }

  /// Tạo default sensors cho user mới
  static List<UserSensor> createDefaultSensors(String userId) {
    return [
      UserSensor.fromSensorType(
        userId: userId,
        sensorType: AvailableSensorTypes.getById('temperature')!,
        displayName: 'Nhiệt độ phòng khách',
      ),
      UserSensor.fromSensorType(
        userId: userId,
        sensorType: AvailableSensorTypes.getById('humidity')!,
        displayName: 'Độ ẩm phòng khách',
      ),
      UserSensor.fromSensorType(
        userId: userId,
        sensorType: AvailableSensorTypes.getById('rain')!,
        displayName: 'Cảm biến mưa',
      ),
    ];
  }
}
