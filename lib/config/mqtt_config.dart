class MqttConfig {
  static const String broker =
      '16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud'; // HiveMQ Cloud từ code mẫu
  static const int port = 8883; // SSL port
  static const String username = 'sigma'; // Username từ code mẫu
  static const String password = '35386Doan'; // Password từ code mẫu
  static const String clientId = 'flutter_smart_home';

  static const int keepAlivePeriod = 30; // Giảm từ 60 xuống 30
  static const int connectionTimeout = 10; // Giảm từ 30 xuống 10 giây
  static const int reconnectDelay = 2; // Giảm từ 5 xuống 2 giây
}
