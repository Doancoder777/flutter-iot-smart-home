/// Cấu hình MQTT tập trung - TẤT CẢ các file khác sẽ import từ đây
/// Để thay đổi cấu hình MQTT, chỉ cần sửa file này duy nhất
class MqttConfig {
  // ===========================
  // 🔧 MQTT BROKER CONFIGURATION
  // ===========================

  /// MQTT Broker URL
  /// Broker hiện tại: '16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud'
  /// Broker khác: '26d1fcc0724b46c495e45a93d79c78d2.s1.eu.hivemq.cloud'
  static const String broker =
      '16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud';

  /// MQTT Broker Port (SSL)
  static const int port = 8883;

  /// MQTT Authentication
  static const String username = 'sigma';
  static const String password = '35386Doan';

  /// Client ID Template (sẽ được tạo unique cho mỗi kết nối)
  static const String clientIdTemplate = 'flutter_smart_home';

  // ===========================
  // ⚙️ CONNECTION SETTINGS
  // ===========================

  /// Keep Alive Period (seconds)
  static const int keepAlivePeriod = 30;

  /// Connection Timeout (seconds)
  static const int connectionTimeout = 10;

  /// Reconnect Delay (seconds)
  static const int reconnectDelay = 2;

  /// Use SSL/TLS
  static const bool useSsl = true;

  // ===========================
  // 📋 CONVENIENCE METHODS
  // ===========================

  /// Tạo MqttConfig object cho các service khác sử dụng
  static Map<String, dynamic> toJson() {
    return {
      'broker': broker,
      'port': port,
      'username': username,
      'password': password,
      'useSsl': useSsl,
    };
  }

  /// Tạo unique client ID với timestamp
  static String generateUniqueClientId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final microseconds = DateTime.now().microsecond % 1000;
    return '${clientIdTemplate}_${timestamp}_$microseconds';
  }

  /// Debug info
  static String get debugInfo =>
      '''
MQTT Configuration:
- Broker: $broker:$port
- Username: $username
- SSL: $useSsl
- Keep Alive: ${keepAlivePeriod}s
- Timeout: ${connectionTimeout}s
''';
}
