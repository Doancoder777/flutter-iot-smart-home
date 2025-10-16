import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/constants.dart';
import '../models/mqtt_config.dart' as custom;

class MqttService {
  late MqttServerClient client;

  // Callbacks
  Function(String topic, String message)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected =>
      client.connectionStatus?.state == MqttConnectionState.connected;

  String get connectionState {
    final state = client.connectionStatus?.state;
    switch (state) {
      case MqttConnectionState.connected:
        return 'Connected';
      case MqttConnectionState.connecting:
        return 'Connecting...';
      case MqttConnectionState.disconnected:
        return 'Disconnected';
      case MqttConnectionState.disconnecting:
        return 'Disconnecting...';
      default:
        return 'Unknown';
    }
  }

  Future<bool> connect(custom.MqttConfig config) async {
    try {
      // Tạo client với unique ID
      final uniqueId = _generateUniqueClientId();
      client = MqttServerClient.withPort(config.broker, uniqueId, config.port);

      // Configure client
      client.logging(on: false);
      client.keepAlivePeriod = 30; // 30 seconds
      client.connectTimeoutPeriod = 10 * 1000; // 10 seconds
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true;

      // SSL/TLS
      client.secure = config.useSsl;
      if (config.useSsl) {
        client.securityContext = SecurityContext.defaultContext;
      }

      // Set protocol
      client.setProtocolV311();

      // Callbacks
      client.onConnected = _onConnected;
      client.onDisconnected = _onDisconnected;
      client.onSubscribed = _onSubscribed;
      client.onAutoReconnect = _onAutoReconnect;
      client.onAutoReconnected = _onAutoReconnected;

      // Connection message with Last Will Testament
      final connMessage = MqttConnectMessage()
          .authenticateAs(config.username, config.password)
          .withWillTopic('${MqttTopics.base}/status/app_online')
          .withWillMessage('offline')
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain()
          .startClean()
          .keepAliveFor(30); // 30 seconds

      client.connectionMessage = connMessage;

      // Connect
      print('🔄 MQTT: Connecting to ${config.broker}:${config.port}...');
      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('✅ MQTT: Connected successfully!');
        return true;
      } else {
        print(
          '❌ MQTT: Connection failed - ${client.connectionStatus?.returnCode}',
        );
        client.disconnect();
        return false;
      }
    } catch (e) {
      print('❌ MQTT Connection Error: $e');
      try {
        client.disconnect();
      } catch (_) {}
      return false;
    }
  }

  void subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    if (!isConnected) {
      print('⚠️ MQTT: Cannot subscribe - not connected');
      return;
    }

    try {
      client.subscribe(topic, qos);
      print('📥 MQTT: Subscribed to $topic');
    } catch (e) {
      print('❌ MQTT Subscribe Error: $e');
    }
  }

  void subscribeToAll() {
    // Subscribe to all sensor topics
    subscribe('${MqttTopics.base}/sensors/#');

    // Subscribe to all alert topics
    subscribe('${MqttTopics.base}/alerts/#');

    // Subscribe to status topics
    subscribe('${MqttTopics.base}/status/#');

    print('✅ MQTT: Subscribed to all topics');
  }

  void publish(String topic, String message, {bool retain = false}) {
    if (!isConnected) {
      print('⚠️ MQTT: Cannot publish - not connected');
      return;
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      client.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: retain,
      );

      print('📤 MQTT: Published to $topic: $message');
    } catch (e) {
      print('❌ MQTT Publish Error: $e');
    }
  }

  void unsubscribe(String topic) {
    if (!isConnected) return;

    try {
      client.unsubscribe(topic);
      print('📤 MQTT: Unsubscribed from $topic');
    } catch (e) {
      print('❌ MQTT Unsubscribe Error: $e');
    }
  }

  void disconnect() {
    try {
      if (isConnected) {
        // Publish offline status before disconnect
        publish(
          '${MqttTopics.base}/status/app_online',
          'offline',
          retain: true,
        );
        client.disconnect();
        print('🔌 MQTT: Disconnected');
      }
    } catch (e) {
      print('❌ MQTT Disconnect Error: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // PRIVATE CALLBACKS
  // ════════════════════════════════════════════════════════

  void _onConnected() {
    print('✅ MQTT: Connected callback');

    // Publish online status
    publish('${MqttTopics.base}/status/app_online', 'online', retain: true);

    // Subscribe to topics
    subscribeToAll();

    // Setup message listener
    _setupMessageListener();

    // Notify provider
    onConnected?.call();
  }

  void _onDisconnected() {
    print('❌ MQTT: Disconnected callback');
    onDisconnected?.call();
  }

  void _onSubscribed(String topic) {
    print('📥 MQTT: Subscribed confirmed - $topic');
  }

  void _onAutoReconnect() {
    print('🔄 MQTT: Auto reconnecting...');
  }

  void _onAutoReconnected() {
    print('✅ MQTT: Auto reconnected!');
    onConnected?.call();
  }

  void _setupMessageListener() {
    client.updates!.listen(
      (List<MqttReceivedMessage<MqttMessage>> messages) {
        final recMess = messages[0].payload as MqttPublishMessage;
        final topic = messages[0].topic;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        // Debug log
        print('📨 MQTT: Received [$topic]: $payload');

        // Notify listeners
        onMessageReceived?.call(topic, payload);
      },
      onError: (error) {
        print('❌ MQTT Stream Error: $error');
      },
      onDone: () {
        print('🔚 MQTT Stream Done');
      },
    );
  }

  /// Generate unique client ID
  String _generateUniqueClientId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final microseconds = DateTime.now().microsecond % 1000;
    return 'flutter_smart_home_${timestamp}_$microseconds';
  }
}
