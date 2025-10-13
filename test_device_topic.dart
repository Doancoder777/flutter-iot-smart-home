// Test file để verify MQTT topic logic
import 'lib/models/device_model.dart';

void main() {
  print('🧪 Testing Device MQTT Topic Generation...\n');

  // Test case 1: Normal device
  final device1 = Device(
    id: 'device_1001_1760278856807',
    name: 'test1',
    type: DeviceType.relay,
    room: 'Phòng khách',
  );

  print('Device 1:');
  print('  Name: ${device1.name}');
  print('  Room: ${device1.room}');
  print('  MQTT Topic: ${device1.mqttTopic}');
  print('  Legacy Topic: ${device1.legacyMqttTopic}');
  print('');

  // Test case 2: Same name and room (should generate same topic)
  final device2 = Device(
    id: 'device_1002_1760278856808',
    name: 'test1',
    type: DeviceType.relay,
    room: 'Phòng khách',
  );

  print('Device 2 (same name & room):');
  print('  Name: ${device2.name}');
  print('  Room: ${device2.room}');
  print('  MQTT Topic: ${device2.mqttTopic}');
  print('  Legacy Topic: ${device2.legacyMqttTopic}');
  print('');

  // Test case 3: Special characters in name/room
  final device3 = Device(
    id: 'device_1003_1760278856809',
    name: 'Đèn LED #1',
    type: DeviceType.relay,
    room: 'Phòng ngủ 2 (tầng 2)',
  );

  print('Device 3 (special chars):');
  print('  Name: ${device3.name}');
  print('  Room: ${device3.room}');
  print('  MQTT Topic: ${device3.mqttTopic}');
  print('  Legacy Topic: ${device3.legacyMqttTopic}');
  print('');

  // Verify duplicate detection
  print('🔍 Duplicate Detection:');
  print('Device 1 vs Device 2 MQTT Topics:');
  print('  Same? ${device1.mqttTopic == device2.mqttTopic}');
  print('  Device 1: ${device1.mqttTopic}');
  print('  Device 2: ${device2.mqttTopic}');

  if (device1.mqttTopic == device2.mqttTopic) {
    print('✅ Duplicate detection will work!');
  } else {
    print('❌ Duplicate detection failed!');
  }
}
