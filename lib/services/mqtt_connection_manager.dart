import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';
import '../models/device_model.dart';

/// 📡 MQTT Connection Manager
/// Quản lý MQTT connections - SHARED PER BROKER
/// Các devices cùng broker sẽ SHARE 1 connection để tránh limit
class MqttConnectionManager extends ChangeNotifier {
  // Map<brokerKey, MqttClient> - Group by broker instead of device
  final Map<String, MqttServerClient> _clientsByBroker = {};

  // Map<deviceId, brokerKey> - Track which device uses which broker
  final Map<String, String> _deviceToBroker = {};

  // Map<deviceId, connectionStatus>
  final Map<String, MqttConnectionState> _connectionStates = {};

  // Map<brokerKey, StreamSubscription> để cleanup
  final Map<String, StreamSubscription?> _subscriptions = {};

  // 📨 Callback để nhận messages từ MQTT
  void Function(String topic, String message)? onMessageReceived;

  /// Tạo broker key từ broker + port + username
  String _getBrokerKey(String broker, int port, String? username) {
    return '$broker:$port:${username ?? "anon"}';
  }

  /// Lấy connection status của device
  MqttConnectionState getConnectionStatus(String deviceId) {
    return _connectionStates[deviceId] ?? MqttConnectionState.disconnected;
  }

  /// Check device có connected không
  bool isDeviceConnected(String deviceId) {
    return _connectionStates[deviceId] == MqttConnectionState.connected;
  }

  /// Đếm số devices đã connected
  int get connectedDevicesCount {
    final count = _connectionStates.values
        .where((state) => state == MqttConnectionState.connected)
        .length;
    debugPrint('📊 Connected devices: $count / ${_connectionStates.length}');
    debugPrint('📊 Connection states: $_connectionStates');
    return count;
  }

  /// Tổng số devices đang được manage
  int get totalDevicesCount => _deviceToBroker.length;

  /// Lấy danh sách device IDs đã connected
  List<String> get connectedDeviceIds {
    return _connectionStates.entries
        .where((entry) => entry.value == MqttConnectionState.connected)
        .map((entry) => entry.key)
        .toList();
  }

  /// Lấy danh sách device IDs bị disconnected
  List<String> get disconnectedDeviceIds {
    return _connectionStates.entries
        .where((entry) => entry.value != MqttConnectionState.connected)
        .map((entry) => entry.key)
        .toList();
  }

  /// 🔌 Connect device's MQTT (SHARED CONNECTION)
  Future<bool> connectDevice(Device device) async {
    if (device.mqttBroker == null || device.mqttBroker!.isEmpty) {
      debugPrint('❌ Device ${device.name} không có MQTT config');
      return false;
    }

    final deviceId = device.id;
    final brokerKey = _getBrokerKey(
      device.mqttBroker!,
      device.mqttPort ?? 1883,
      device.mqttUsername,
    );

    // Nếu đã connected rồi thì skip
    if (isDeviceConnected(deviceId)) {
      debugPrint('✅ Device ${device.name} đã connected rồi');
      return true;
    }

    // ✨ KIỂM TRA XEM ĐÃ CÓ CONNECTION CHO BROKER NÀY CHƯA
    if (_clientsByBroker.containsKey(brokerKey)) {
      final existingClient = _clientsByBroker[brokerKey];
      if (existingClient?.connectionStatus?.state ==
          MqttConnectionState.connected) {
        debugPrint(
          '♻️ Reusing existing connection for ${device.name} (broker: $brokerKey)',
        );
        _deviceToBroker[deviceId] = brokerKey;
        _connectionStates[deviceId] = MqttConnectionState.connected;
        notifyListeners();
        return true;
      }
    }

    try {
      // Disconnect nếu đang có client cũ cho device này
      await disconnectDevice(deviceId); // Tạo client mới với client ID ngắn hơn
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final shortId = 'flutter_${timestamp % 1000000}'; // Chỉ lấy 6 số cuối
      final client = MqttServerClient(device.mqttBroker!, shortId);

      client.port = device.mqttPort ?? 1883;
      client.keepAlivePeriod = 60;
      client.connectTimeoutPeriod = 10000; // 10 giây timeout
      client.logging(on: false); // Tắt log spam
      client.setProtocolV311();

      // SSL/TLS
      if (device.mqttUseSsl == true) {
        client.secure = true;
        client.securityContext = SecurityContext.defaultContext;
        debugPrint('🔒 SSL/TLS enabled for device ${device.name}');
      } else {
        debugPrint('⚠️ SSL/TLS disabled for device ${device.name}');
      }

      // Auth
      if (device.mqttUsername != null && device.mqttUsername!.isNotEmpty) {
        client.connectionMessage = MqttConnectMessage()
            .withClientIdentifier(client.clientIdentifier)
            .authenticateAs(device.mqttUsername!, device.mqttPassword ?? '')
            .startClean()
            .withWillQos(MqttQos.atLeastOnce);
      } else {
        client.connectionMessage = MqttConnectMessage()
            .withClientIdentifier(client.clientIdentifier)
            .startClean()
            .withWillQos(MqttQos.atLeastOnce);
      }

      // Update state: connecting
      _connectionStates[deviceId] = MqttConnectionState.connecting;
      notifyListeners();

      // Connect
      debugPrint(
        '🔌 Connecting device ${device.name} to ${device.mqttBroker}:${device.mqttPort}...',
      );
      debugPrint('📝 Username: ${device.mqttUsername ?? "none"}');
      debugPrint(
        '🔐 Password: ${device.mqttPassword != null && device.mqttPassword!.isNotEmpty ? "***" : "none"}',
      );
      debugPrint('🔒 SSL: ${device.mqttUseSsl}');
      debugPrint('🆔 Client ID: $shortId');

      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        debugPrint('✅ Device ${device.name} connected successfully!');
        _clientsByBroker[brokerKey] = client;
        _deviceToBroker[deviceId] = brokerKey;
        _connectionStates[deviceId] = MqttConnectionState.connected;

        // 📥 SUBSCRIBE VÀO TOPIC CỦA DEVICE (chỉ subscribe nếu chưa subscribe)
        final topic = device.mqttTopic;
        debugPrint('📥 Subscribing to topic: $topic');
        client.subscribe(topic, MqttQos.atMostOnce);

        // Listen to connection changes & messages (chỉ setup 1 lần per broker)
        if (!_subscriptions.containsKey(brokerKey)) {
          _subscriptions[brokerKey] = client.updates?.listen((events) {
            for (final event in events) {
              if (event is MqttDisconnectMessage) {
                debugPrint('❌ Broker $brokerKey disconnected');
                // Mark TẤT CẢ devices dùng broker này là disconnected
                for (final entry in _deviceToBroker.entries) {
                  if (entry.value == brokerKey) {
                    _connectionStates[entry.key] =
                        MqttConnectionState.disconnected;
                  }
                }
                notifyListeners();
              }

              // 📨 XỬ LÝ MESSAGE NHẬN ĐƯỢC (check nếu là publish message)
              final topic = event.topic;
              if (event.payload is MqttPublishMessage) {
                final MqttPublishMessage publishMessage =
                    event.payload as MqttPublishMessage;
                final payload = MqttPublishPayload.bytesToStringAsString(
                  publishMessage.payload.message,
                );

                debugPrint('📨 Message from $topic: $payload');

                // Gọi callback để notify DeviceProvider
                if (onMessageReceived != null) {
                  onMessageReceived!(topic, payload);
                }
              }
            }
          });
        }

        notifyListeners();
        return true;
      } else {
        final status = client.connectionStatus;
        debugPrint(
          '❌ Device ${device.name} connection failed: ${status?.state}',
        );
        debugPrint('   Return code: ${status?.returnCode}');
        if (status?.returnCode == MqttConnectReturnCode.notAuthorized) {
          debugPrint('   💡 Hint: Check username/password');
        } else if (status?.returnCode ==
            MqttConnectReturnCode.badUsernameOrPassword) {
          debugPrint('   💡 Hint: Wrong credentials');
        } else if (status?.returnCode == MqttConnectReturnCode.noneSpecified) {
          debugPrint(
            '   💡 Hint: Connection timeout - check broker address or SSL settings',
          );
        }
        _connectionStates[deviceId] = MqttConnectionState.disconnected;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error connecting device ${device.name}: $e');

      // Specific hints for common errors
      if (e.toString().contains('Missing Connection Acknowledgement')) {
        debugPrint('');
        debugPrint('💡 TROUBLESHOOTING HINTS:');
        debugPrint('   1. Kiểm tra Username/Password có chính xác không');
        debugPrint('   2. Đảm bảo HiveMQ Cloud cluster đang running');
        debugPrint(
          '   3. Kiểm tra Access Management trong HiveMQ Cloud Console',
        );
        debugPrint('   4. Thử test với MQTT client khác (MQTTX, mosquitto)');
        debugPrint('');
      }

      debugPrint('   Stack trace: $stackTrace');
      _connectionStates[deviceId] = MqttConnectionState.faulted;
      notifyListeners();
      return false;
    }
  }

  /// 🔌 Disconnect device's MQTT
  Future<void> disconnectDevice(String deviceId) async {
    try {
      final brokerKey = _deviceToBroker[deviceId];
      if (brokerKey == null) return;

      // Remove device mapping
      _deviceToBroker.remove(deviceId);
      _connectionStates[deviceId] = MqttConnectionState.disconnected;

      // ✨ CHỈ DISCONNECT CLIENT NẾU KHÔNG CÒN DEVICE NÀO DÙNG BROKER NÀY
      final stillUsedByOtherDevices = _deviceToBroker.values.contains(
        brokerKey,
      );

      if (!stillUsedByOtherDevices) {
        debugPrint(
          '🔌 No more devices using broker $brokerKey, disconnecting...',
        );

        await _subscriptions[brokerKey]?.cancel();
        _subscriptions.remove(brokerKey);

        final client = _clientsByBroker[brokerKey];
        if (client != null) {
          client.disconnect();
          _clientsByBroker.remove(brokerKey);
        }
      } else {
        debugPrint(
          '♻️ Broker $brokerKey still in use by other devices, keeping connection',
        );
      }

      notifyListeners();
      debugPrint('🔌 Device $deviceId disconnected');
    } catch (e) {
      debugPrint('❌ Error disconnecting device $deviceId: $e');
    }
  }

  /// � Subscribe to topic and handle messages
  void subscribeToTopic(
    String deviceId,
    String topic,
    void Function(String topic, String message) onMessage,
  ) {
    final brokerKey = _deviceToBroker[deviceId];
    if (brokerKey == null) {
      debugPrint('❌ Device $deviceId not mapped to any broker');
      return;
    }

    final client = _clientsByBroker[brokerKey];
    if (client == null || !isDeviceConnected(deviceId)) {
      debugPrint('❌ Device $deviceId not connected, cannot subscribe');
      return;
    }

    try {
      client.subscribe(topic, MqttQos.atLeastOnce);
      debugPrint('📥 Subscribed to: $topic');

      // Setup listener
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (final message in messages) {
          final recTopic = message.topic;
          final payload = message.payload as MqttPublishMessage;
          final messageStr = MqttPublishPayload.bytesToStringAsString(
            payload.payload.message,
          );

          if (recTopic == topic) {
            debugPrint('📩 Received: $recTopic = $messageStr');
            onMessage(recTopic, messageStr);
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error subscribing to $topic: $e');
    }
  }

  /// �📤 Publish message to device's MQTT broker
  Future<bool> publishToDevice(
    String deviceId,
    String topic,
    String message,
  ) async {
    final brokerKey = _deviceToBroker[deviceId];
    if (brokerKey == null) {
      debugPrint('❌ Device $deviceId not mapped to any broker');
      return false;
    }

    final client = _clientsByBroker[brokerKey];
    if (client == null || !isDeviceConnected(deviceId)) {
      debugPrint('❌ Device $deviceId not connected, cannot publish');
      return false;
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('📤 Published to $deviceId: $topic = $message');
      return true;
    } catch (e) {
      debugPrint('❌ Error publishing to device $deviceId: $e');
      return false;
    }
  }

  /// 🔄 Reconnect device
  Future<bool> reconnectDevice(Device device) async {
    await disconnectDevice(device.id);
    await Future.delayed(const Duration(seconds: 1));
    return await connectDevice(device);
  }

  /// 🔄 Reconnect all devices
  Future<void> reconnectAll(List<Device> devices) async {
    for (final device in devices) {
      if (device.mqttBroker != null && device.mqttBroker!.isNotEmpty) {
        await connectDevice(device);
      }
    }
  }

  /// 🧹 Cleanup - disconnect all
  Future<void> disconnectAll() async {
    final deviceIds = _deviceToBroker.keys.toList();
    for (final deviceId in deviceIds) {
      await disconnectDevice(deviceId);
    }
  }

  @override
  void dispose() {
    disconnectAll();
    super.dispose();
  }
}
