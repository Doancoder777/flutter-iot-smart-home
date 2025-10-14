import 'package:flutter/foundation.dart';
import '../services/mqtt_connection_manager.dart';
import '../models/device_model.dart';

/// Debug wrapper for MqttConnectionManager with detailed logging
class MqttDebugManager {
  final MqttConnectionManager _manager = MqttConnectionManager();

  Future<bool> connectDevice(Device device) async {
    debugPrint('🔌 [DEBUG] Connecting device: ${device.name}');
    debugPrint('   ID: ${device.id}');
    debugPrint('   Broker: ${device.mqttBroker}:${device.mqttPort}');
    debugPrint('   DeviceID: ${device.deviceId}');

    final result = await _manager.connectDevice(device);

    debugPrint('   Result: ${result ? "✅ Connected" : "❌ Failed"}');
    return result;
  }

  Future<bool> publishToDevice(
    String deviceId,
    String topic,
    String message,
  ) async {
    debugPrint('📤 [DEBUG] Publishing...');
    debugPrint('   DeviceID: $deviceId');
    debugPrint('   Topic: $topic');
    debugPrint('   Message: $message');

    final result = await _manager.publishToDevice(deviceId, topic, message);

    debugPrint('   Result: ${result ? "✅ Published" : "❌ Failed"}');

    if (!result) {
      debugPrint('   ⚠️ Checking device state...');
      final connected = _manager.isDeviceConnected(deviceId);
      debugPrint('   Connected: $connected');
    }

    return result;
  }

  void subscribeToTopic(
    String deviceId,
    String topic,
    void Function(String topic, String message) onMessage,
  ) {
    debugPrint('📥 [DEBUG] Subscribing...');
    debugPrint('   DeviceID: $deviceId');
    debugPrint('   Topic: $topic');

    _manager.subscribeToTopic(deviceId, topic, (t, m) {
      debugPrint('📩 [DEBUG] Message received');
      debugPrint('   Topic: $t');
      debugPrint('   Message: $m');
      onMessage(t, m);
    });
  }

  Future<void> disconnectDevice(String deviceId) async {
    debugPrint('🔌 [DEBUG] Disconnecting: $deviceId');
    await _manager.disconnectDevice(deviceId);
  }

  bool isDeviceConnected(String deviceId) {
    return _manager.isDeviceConnected(deviceId);
  }

  void dispose() {
    _manager.dispose();
  }
}
