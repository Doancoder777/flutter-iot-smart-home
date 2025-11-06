import 'package:flutter_test/flutter_test.dart';
import 'package:version3/services/ai_voice_service.dart';
import 'package:version3/models/device_model.dart';
import 'package:version3/models/sensor_data.dart';

/// 🧪 Test AI Voice Service
///
/// Chạy test: flutter test test/ai_voice_service_test.dart
void main() {
  group('AI Voice Service Tests', () {
    late AiVoiceService aiService;

    setUp(() {
      aiService = AiVoiceService();
    });

    test('Test 1: Sensor Query - Nhiệt độ bao nhiêu?', () async {
      // Mock data
      final sensorData = SensorData(
        temperature: 28.5,
        humidity: 65.0,
        rain: 0,
        light: 500,
        soilMoisture: 45,
        gas: 400,
        dust: 35,
        motionDetected: false,
        timestamp: DateTime.now(),
      );

      final devices = <Device>[];

      // Call AI
      print('\n🧪 TEST 1: Hỏi nhiệt độ');
      print('═══════════════════════════════════════');

      final result = await aiService.processVoiceCommand(
        userId: 'test_user',
        voiceCommand: 'Nhiệt độ bao nhiêu?',
        devices: devices,
        sensorData: sensorData,
      );

      print('\n📊 RESULT:');
      print('Success: ${result?.success}');
      print('Response Type: ${result?.responseType}');
      print('Sensor Type: ${result?.sensorType}');
      print('Sensor Value: ${result?.sensorValue}');
      print('Error: ${result?.error}');

      // Assertions
      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.responseType, ResponseType.sensorQuery);
      expect(result.sensorType, 'temperature');
      expect(result.sensorValue, 28.5);
    });

    test('Test 2: Sensor Query - Có nóng không?', () async {
      final sensorData = SensorData(
        temperature: 32.0,
        humidity: 70.0,
        rain: 0,
        light: 600,
        soilMoisture: 40,
        gas: 380,
        dust: 45,
        motionDetected: false,
        timestamp: DateTime.now(),
      );

      final devices = <Device>[];

      print('\n🧪 TEST 2: Có nóng không?');
      print('═══════════════════════════════════════');

      final result = await aiService.processVoiceCommand(
        userId: 'test_user',
        voiceCommand: 'Giờ nhà tôi có nóng không?',
        devices: devices,
        sensorData: sensorData,
      );

      print('\n📊 RESULT:');
      print('Success: ${result?.success}');
      print('Response Type: ${result?.responseType}');
      print('Sensor Type: ${result?.sensorType}');
      print('Sensor Value: ${result?.sensorValue}');

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.responseType, ResponseType.sensorQuery);
      expect(result.sensorType, 'temperature');
    });

    test('Test 3: Sensor Query - Có mưa không?', () async {
      final sensorData = SensorData(
        temperature: 25.0,
        humidity: 80.0,
        rain: 1, // Đang mưa
        light: 200,
        soilMoisture: 60,
        gas: 350,
        dust: 25,
        motionDetected: false,
        timestamp: DateTime.now(),
      );

      final devices = <Device>[];

      print('\n🧪 TEST 3: Có mưa không?');
      print('═══════════════════════════════════════');

      final result = await aiService.processVoiceCommand(
        userId: 'test_user',
        voiceCommand: 'Trời có mưa không?',
        devices: devices,
        sensorData: sensorData,
      );

      print('\n📊 RESULT:');
      print('Success: ${result?.success}');
      print('Response Type: ${result?.responseType}');
      print('Sensor Type: ${result?.sensorType}');
      print('Sensor Value: ${result?.sensorValue}');

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.responseType, ResponseType.sensorQuery);
      expect(result.sensorType, 'rain');
      expect(result.sensorValue, 1);
    });

    test('Test 4: Device Control - Bật đèn', () async {
      final sensorData = SensorData.empty();

      final devices = [
        Device(
          id: '1',
          name: 'Đèn phòng ngủ',
          keyName: 'led_bedroom',
          deviceCode: 'LED01',
          type: DeviceType.relay,
          room: 'Phòng ngủ',
          state: false,
          userId: 'test_user',
        ),
      ];

      print('\n🧪 TEST 4: Bật đèn phòng ngủ');
      print('═══════════════════════════════════════');

      final result = await aiService.processVoiceCommand(
        userId: 'test_user',
        voiceCommand: 'Bật đèn phòng ngủ',
        devices: devices,
        sensorData: sensorData,
      );

      print('\n📊 RESULT:');
      print('Success: ${result?.success}');
      print('Response Type: ${result?.responseType}');
      print('Device Key: ${result?.deviceKeyName}');
      print('Action: ${result?.action}');

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.responseType, ResponseType.deviceControl);
      expect(result.deviceKeyName, 'led_bedroom');
      expect(result.action, 'turn_on');
    });

    test('Test 5: Sensor Query - Tất cả sensors', () async {
      final sensorData = SensorData(
        temperature: 27.0,
        humidity: 60.0,
        rain: 0,
        light: 450,
        soilMoisture: 50,
        gas: 390,
        dust: 38,
        motionDetected: true,
        timestamp: DateTime.now(),
      );

      final devices = <Device>[];

      print('\n🧪 TEST 5: Tình trạng nhà thế nào?');
      print('═══════════════════════════════════════');

      final result = await aiService.processVoiceCommand(
        userId: 'test_user',
        voiceCommand: 'Tình trạng nhà tôi thế nào?',
        devices: devices,
        sensorData: sensorData,
      );

      print('\n📊 RESULT:');
      print('Success: ${result?.success}');
      print('Response Type: ${result?.responseType}');
      print('Sensor Type: ${result?.sensorType}');
      print('Sensor Value: ${result?.sensorValue}');

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.responseType, ResponseType.sensorQuery);
    });

    test('Test 6: Error case - Không hiểu lệnh', () async {
      final sensorData = SensorData.empty();
      final devices = <Device>[];

      print('\n🧪 TEST 6: Câu lệnh không hợp lệ');
      print('═══════════════════════════════════════');

      final result = await aiService.processVoiceCommand(
        userId: 'test_user',
        voiceCommand: 'xyz abc 123',
        devices: devices,
        sensorData: sensorData,
      );

      print('\n📊 RESULT:');
      print('Success: ${result?.success}');
      print('Error: ${result?.error}');

      // Có thể success hoặc có error message
      expect(result, isNotNull);
    });
  });
}
