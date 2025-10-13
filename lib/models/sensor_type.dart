class SensorType {
  final String id;
  final String name;
  final String icon;
  final String unit;
  final String defaultMqttTopic;
  final SensorDataType dataType;
  final double? minValue;
  final double? maxValue;
  final String description;

  const SensorType({
    required this.id,
    required this.name,
    required this.icon,
    required this.unit,
    required this.defaultMqttTopic,
    required this.dataType,
    this.minValue,
    this.maxValue,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'unit': unit,
      'defaultMqttTopic': defaultMqttTopic,
      'dataType': dataType.name,
      'minValue': minValue,
      'maxValue': maxValue,
      'description': description,
    };
  }

  factory SensorType.fromJson(Map<String, dynamic> json) {
    return SensorType(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      unit: json['unit'],
      defaultMqttTopic: json['defaultMqttTopic'],
      dataType: SensorDataType.values.firstWhere(
        (e) => e.name == json['dataType'],
        orElse: () => SensorDataType.double,
      ),
      minValue: json['minValue']?.toDouble(),
      maxValue: json['maxValue']?.toDouble(),
      description: json['description'],
    );
  }
}

enum SensorDataType {
  double, // temperature, humidity, etc.
  int, // light, gas, dust, etc.
  bool, // motion, rain detected
}

/// Kiểu hiển thị dữ liệu sensor
enum DisplayType {
  /// Boolean: Có/Không (true/false)
  boolean,

  /// Pulse: Đếm xung (counting)
  pulse,

  /// Percentage: Phần trăm với max value tùy chỉnh
  percentage,
}

/// Thông tin hiển thị cho DisplayType
class DisplayConfig {
  final DisplayType type;
  final double? maxValue; // Cho percentage type
  final String? unit; // Override unit mặc định
  final String? trueLabel; // Cho boolean type
  final String? falseLabel; // Cho boolean type

  const DisplayConfig({
    required this.type,
    this.maxValue,
    this.unit,
    this.trueLabel,
    this.falseLabel,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'maxValue': maxValue,
      'unit': unit,
      'trueLabel': trueLabel,
      'falseLabel': falseLabel,
    };
  }

  factory DisplayConfig.fromJson(Map<String, dynamic> json) {
    return DisplayConfig(
      type: DisplayType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DisplayType.percentage,
      ),
      maxValue: json['maxValue']?.toDouble(),
      unit: json['unit'],
      trueLabel: json['trueLabel'],
      falseLabel: json['falseLabel'],
    );
  }
}

/// Danh sách các loại sensor có thể thêm
class AvailableSensorTypes {
  static const List<SensorType> all = [
    SensorType(
      id: 'temperature',
      name: 'Nhiệt độ',
      icon: '🌡️',
      unit: '°C',
      defaultMqttTopic: 'smart_home/sensors/temperature',
      dataType: SensorDataType.double,
      minValue: -10,
      maxValue: 60,
      description: 'Cảm biến nhiệt độ môi trường',
    ),
    SensorType(
      id: 'humidity',
      name: 'Độ ẩm',
      icon: '💧',
      unit: '%',
      defaultMqttTopic: 'smart_home/sensors/humidity',
      dataType: SensorDataType.double,
      minValue: 0,
      maxValue: 100,
      description: 'Cảm biến độ ẩm không khí',
    ),
    SensorType(
      id: 'rain',
      name: 'Cảm biến mưa',
      icon: '🌧️',
      unit: '',
      defaultMqttTopic: 'smart_home/sensors/rain',
      dataType: SensorDataType.int,
      minValue: 0,
      maxValue: 1,
      description: 'Cảm biến phát hiện mưa (0=không mưa, 1=có mưa)',
    ),
    SensorType(
      id: 'light',
      name: 'Ánh sáng',
      icon: '☀️',
      unit: 'lux',
      defaultMqttTopic: 'smart_home/sensors/light',
      dataType: SensorDataType.int,
      minValue: 0,
      maxValue: 2000,
      description: 'Cảm biến cường độ ánh sáng',
    ),
    SensorType(
      id: 'soil_moisture',
      name: 'Độ ẩm đất',
      icon: '🌱',
      unit: '%',
      defaultMqttTopic: 'smart_home/sensors/soil_moisture',
      dataType: SensorDataType.int,
      minValue: 0,
      maxValue: 100,
      description: 'Cảm biến độ ẩm đất cho cây trồng',
    ),
    SensorType(
      id: 'gas',
      name: 'Khí gas',
      icon: '☁️',
      unit: 'ppm',
      defaultMqttTopic: 'smart_home/sensors/gas',
      dataType: SensorDataType.int,
      minValue: 0,
      maxValue: 5000,
      description: 'Cảm biến phát hiện khí gas/CO',
    ),
    SensorType(
      id: 'dust',
      name: 'Bụi PM2.5',
      icon: '🌫️',
      unit: 'µg/m³',
      defaultMqttTopic: 'smart_home/sensors/dust',
      dataType: SensorDataType.int,
      minValue: 0,
      maxValue: 500,
      description: 'Cảm biến chất lượng không khí PM2.5',
    ),
    SensorType(
      id: 'motion',
      name: 'Chuyển động',
      icon: '🚶',
      unit: '',
      defaultMqttTopic: 'smart_home/sensors/motion',
      dataType: SensorDataType.bool,
      description: 'Cảm biến chuyển động PIR',
    ),
    SensorType(
      id: 'pressure',
      name: 'Áp suất',
      icon: '🔽',
      unit: 'hPa',
      defaultMqttTopic: 'smart_home/sensors/pressure',
      dataType: SensorDataType.double,
      minValue: 900,
      maxValue: 1100,
      description: 'Cảm biến áp suất khí quyển',
    ),
    SensorType(
      id: 'uv',
      name: 'Tia UV',
      icon: '☢️',
      unit: 'index',
      defaultMqttTopic: 'smart_home/sensors/uv',
      dataType: SensorDataType.int,
      minValue: 0,
      maxValue: 15,
      description: 'Cảm biến chỉ số tia UV',
    ),
    // 🔥 CÁC SENSOR MỚI THÊM
    SensorType(
      id: 'smoke',
      name: 'Cảm biến khói',
      icon: '🔥',
      unit: 'ppm',
      defaultMqttTopic: 'smart_home/sensors/smoke',
      dataType: SensorDataType.int,
      minValue: 0,
      maxValue: 1000,
      description: 'Cảm biến phát hiện khói và cháy',
    ),
    SensorType(
      id: 'power',
      name: 'Điện năng',
      icon: '⚡',
      unit: 'W',
      defaultMqttTopic: 'smart_home/sensors/power',
      dataType: SensorDataType.double,
      minValue: 0,
      maxValue: 5000,
      description: 'Cảm biến công suất điện tiêu thụ',
    ),
    SensorType(
      id: 'water_meter',
      name: 'Công tơ nước',
      icon: '🚰',
      unit: 'L',
      defaultMqttTopic: 'smart_home/sensors/water_meter',
      dataType: SensorDataType.double,
      minValue: 0,
      maxValue: 999999,
      description: 'Đo lưu lượng nước tiêu thụ',
    ),
    SensorType(
      id: 'water_quality',
      name: 'Chất lượng nước',
      icon: '🧪',
      unit: 'TDS',
      defaultMqttTopic: 'smart_home/sensors/water_quality',
      dataType: SensorDataType.int,
      minValue: 0,
      maxValue: 1000,
      description: 'Cảm biến chất lượng nước (TDS)',
    ),
    SensorType(
      id: 'ultrasonic',
      name: 'Siêu âm',
      icon: '📡',
      unit: 'cm',
      defaultMqttTopic: 'smart_home/sensors/ultrasonic',
      dataType: SensorDataType.double,
      minValue: 0,
      maxValue: 400,
      description: 'Cảm biến khoảng cách siêu âm',
    ),
    SensorType(
      id: 'custom',
      name: 'Cảm biến tùy chỉnh',
      icon: '🔧',
      unit: '',
      defaultMqttTopic: 'smart_home/sensors/custom',
      dataType: SensorDataType.double,
      description: 'Cảm biến với cấu hình tùy chỉnh',
    ),
  ];

  /// Lấy sensor type theo ID
  static SensorType? getById(String id) {
    try {
      return all.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Các sensor cần thiết cho weather widget
  static const List<String> weatherRequiredSensors = [
    'temperature',
    'humidity',
    'rain',
  ];

  /// Kiểm tra sensor type có phải weather sensor không
  static bool isWeatherSensor(String sensorTypeId) {
    return weatherRequiredSensors.contains(sensorTypeId);
  }
}
