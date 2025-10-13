class MqttConfig {
  final String broker;
  final int port;
  final String username;
  final String password;
  final bool useSsl;

  const MqttConfig({
    required this.broker,
    required this.port,
    required this.username,
    required this.password,
    this.useSsl = true,
  });

  // Default configuration
  static const MqttConfig defaultConfig = MqttConfig(
    broker: 'broker.hivemq.com',
    port: 8883,
    username: '',
    password: '',
    useSsl: true,
  );

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'broker': broker,
      'port': port,
      'username': username,
      'password': password,
      'useSsl': useSsl,
    };
  }

  factory MqttConfig.fromJson(Map<String, dynamic> json) {
    return MqttConfig(
      broker: json['broker'] ?? 'broker.hivemq.com',
      port: json['port'] ?? 8883,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      useSsl: json['useSsl'] ?? true,
    );
  }

  // Copy with method
  MqttConfig copyWith({
    String? broker,
    int? port,
    String? username,
    String? password,
    bool? useSsl,
  }) {
    return MqttConfig(
      broker: broker ?? this.broker,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      useSsl: useSsl ?? this.useSsl,
    );
  }

  @override
  String toString() {
    return 'MqttConfig(broker: $broker, port: $port, username: $username, useSsl: $useSsl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MqttConfig &&
        other.broker == broker &&
        other.port == port &&
        other.username == username &&
        other.password == password &&
        other.useSsl == useSsl;
  }

  @override
  int get hashCode {
    return broker.hashCode ^
        port.hashCode ^
        username.hashCode ^
        password.hashCode ^
        useSsl.hashCode;
  }
}
