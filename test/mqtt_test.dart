import 'package:flutter/material.dart';
import 'package:version3/models/device_model.dart';
import 'package:version3/services/mqtt_connection_manager.dart';

/// 🧪 Quick MQTT Test
/// Run this to test your HiveMQ credentials
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 MQTT Connection Test Starting...');
  print('');

  final testDevice = Device(
    id: 'test_device',
    name: 'Test Device',
    type: DeviceType.relay,
    state: false,
    room: 'test',
    mqttBroker: '26d1fcc0724b46c495e45a93d79c78d2.s1.eu.hivemq.cloud',
    mqttPort: 8883,
    mqttUsername: 'sigma',
    mqttPassword: '35386Doan',
    mqttUseSsl: true,
  );

  print('📋 Test Configuration:');
  print('   Broker: ${testDevice.mqttBroker}');
  print('   Port: ${testDevice.mqttPort}');
  print('   Username: ${testDevice.mqttUsername}');
  print('   Password: ***');
  print('   SSL: ${testDevice.mqttUseSsl}');
  print('');

  final mqttManager = MqttConnectionManager();

  try {
    print('🔌 Attempting to connect...');
    final success = await mqttManager.connectDevice(testDevice);

    if (success) {
      print('');
      print('✅ ✅ ✅ SUCCESS! ✅ ✅ ✅');
      print('MQTT connection is working!');
      print('Your credentials are CORRECT.');
      print('');

      // Test publish
      print('📤 Testing publish...');
      final published = await mqttManager.publishToDevice(
        testDevice.id,
        'test/topic',
        'Hello from Flutter!',
      );

      if (published) {
        print('✅ Publish successful!');
      }

      // Disconnect
      await mqttManager.disconnectDevice(testDevice.id);
      print('🔌 Disconnected.');
    } else {
      print('');
      print('❌ ❌ ❌ FAILED! ❌ ❌ ❌');
      print('MQTT connection FAILED.');
      print('');
      print('💡 Possible reasons:');
      print('   1. Username or Password is WRONG');
      print('   2. HiveMQ cluster is not running');
      print('   3. SSL settings incorrect');
      print('   4. Firewall blocking port 8883');
      print('');
    }
  } catch (e) {
    print('');
    print('❌ ERROR: $e');
    print('');
  }

  mqttManager.dispose();
  print('🏁 Test completed.');
}
