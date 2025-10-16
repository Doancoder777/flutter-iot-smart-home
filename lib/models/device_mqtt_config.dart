/// Cấu hình MQTT riêng cho từng thiết bị
/// Cho phép mỗi thiết bị kết nối đến broker MQTT khác nhau
class DeviceMqttConfig {
  final String deviceId;
  final String broker;
  final int port;
  final String? username;
  final String? password;
  final bool useSsl;
  final String? clientId;
  final String? customTopic; // Topic tùy chỉnh cho thiết bị

  /// Có sử dụng cấu hình MQTT riêng hay dùng global
  final bool useCustomConfig;

  /// Thời gian tạo/cập nhật cấu hình
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DeviceMqttConfig({
    required this.deviceId,
    required this.broker,
    required this.port,
    this.username,
    this.password,
    this.useSsl = true,
    this.clientId,
    this.customTopic,
    this.useCustomConfig = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Tạo từ JSON
  factory DeviceMqttConfig.fromJson(Map<String, dynamic> json) {
    return DeviceMqttConfig(
      deviceId: json['deviceId'],
      broker: json['broker'],
      port: json['port'] ?? 8883,
      username: json['username'],
      password: json['password'],
      useSsl: json['useSsl'] ?? true,
      clientId: json['clientId'],
      customTopic: json['customTopic'],
      useCustomConfig: json['useCustomConfig'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// Chuyển thành JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'broker': broker,
      'port': port,
      'username': username,
      'password': password,
      'useSsl': useSsl,
      'clientId': clientId,
      'customTopic': customTopic,
      'useCustomConfig': useCustomConfig,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with method
  DeviceMqttConfig copyWith({
    String? deviceId,
    String? broker,
    int? port,
    String? username,
    String? password,
    bool? useSsl,
    String? clientId,
    String? customTopic,
    bool? useCustomConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceMqttConfig(
      deviceId: deviceId ?? this.deviceId,
      broker: broker ?? this.broker,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      useSsl: useSsl ?? this.useSsl,
      clientId: clientId ?? this.clientId,
      customTopic: customTopic ?? this.customTopic,
      useCustomConfig: useCustomConfig ?? this.useCustomConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Tạo unique client ID cho thiết bị này
  String generateClientId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final microseconds = DateTime.now().microsecond % 1000;
    final baseClientId = clientId ?? 'device_${deviceId}';
    return '${baseClientId}_${timestamp}_$microseconds';
  }

  /// Lấy topic cho thiết bị (dùng custom topic nếu có)
  String getTopic(String defaultTopic) {
    return customTopic ?? defaultTopic;
  }

  /// Kiểm tra cấu hình có hợp lệ không
  bool get isValid {
    return broker.isNotEmpty &&
        port > 0 &&
        port <= 65535 &&
        deviceId.isNotEmpty;
  }

  /// Hiển thị thông tin cấu hình
  String get displayInfo {
    return '''
MQTT Config for Device: $deviceId
Broker: $broker:$port
Username: ${username ?? 'None'}
SSL: $useSsl
Custom Topic: ${customTopic ?? 'Use default'}
''';
  }

  @override
  String toString() {
    return 'DeviceMqttConfig(deviceId: $deviceId, broker: $broker:$port, useCustom: $useCustomConfig)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceMqttConfig &&
        other.deviceId == deviceId &&
        other.broker == broker &&
        other.port == port &&
        other.username == username &&
        other.password == password &&
        other.useSsl == useSsl &&
        other.customTopic == customTopic &&
        other.useCustomConfig == useCustomConfig;
  }

  @override
  int get hashCode {
    return deviceId.hashCode ^
        broker.hashCode ^
        port.hashCode ^
        username.hashCode ^
        password.hashCode ^
        useSsl.hashCode ^
        customTopic.hashCode ^
        useCustomConfig.hashCode;
  }
}

