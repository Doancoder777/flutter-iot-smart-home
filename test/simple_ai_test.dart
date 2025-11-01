import 'package:version3/services/ai_voice_service.dart';
import 'package:version3/models/device_model.dart';
import 'package:version3/models/sensor_data.dart';

/// 🧪 SIMPLE TEST SCRIPT
/// 
/// Chạy: dart run test/simple_ai_test.dart
void main() async {
  print('🧪 AI VOICE SERVICE - SIMPLE TEST');
  print('═══════════════════════════════════════════════════════════');
  
  final aiService = AiVoiceService();
  
  // Mock sensor data
  final sensorData = SensorData(
    temperature: 28.5,
    humidity: 65.0,
    rain: 0,
    light: 500,
    soilMoisture: 45,
    gas: 400,
    dust: 35, // int, not double
    motionDetected: false,
    timestamp: DateTime.now(),
  );

  // Mock devices
  final devices = [
    Device(
      id: '1',
      name: 'Đèn phòng ngủ',
      keyName: 'led_bedroom',
      deviceCode: 'LED01',
      type: DeviceType.relay, // Sử dụng enum
      room: 'Phòng ngủ',
      state: false,
      userId: 'test_user',
    ),
    Device(
      id: '2',
      name: 'Quạt phòng khách',
      keyName: 'fan_living',
      deviceCode: 'FAN01',
      type: DeviceType.fan, // Sử dụng enum
      room: 'Phòng khách',
      state: false,
      userId: 'test_user',
    ),
  ];

  // TEST 1: Sensor Query - Nhiệt độ
  print('\n📝 TEST 1: Nhiệt độ bao nhiêu?');
  print('───────────────────────────────────────────────────────────');
  try {
    final result1 = await aiService.processVoiceCommand(
      userId: 'test_user',
      voiceCommand: 'Nhiệt độ bao nhiêu?',
      devices: devices,
      sensorData: sensorData,
    );
    
    _printResult(result1);
  } catch (e) {
    print('❌ ERROR: $e');
  }

  // TEST 2: Sensor Query - Có nóng không
  print('\n\n📝 TEST 2: Giờ nhà tôi có nóng không?');
  print('───────────────────────────────────────────────────────────');
  try {
    final result2 = await aiService.processVoiceCommand(
      userId: 'test_user',
      voiceCommand: 'Giờ nhà tôi có nóng không?',
      devices: devices,
      sensorData: sensorData,
    );
    
    _printResult(result2);
  } catch (e) {
    print('❌ ERROR: $e');
  }

  // TEST 3: Sensor Query - Mưa
  print('\n\n📝 TEST 3: Trời có mưa không?');
  print('───────────────────────────────────────────────────────────');
  try {
    final result3 = await aiService.processVoiceCommand(
      userId: 'test_user',
      voiceCommand: 'Trời có mưa không?',
      devices: devices,
      sensorData: sensorData,
    );
    
    _printResult(result3);
  } catch (e) {
    print('❌ ERROR: $e');
  }

  // TEST 4: Device Control - Bật đèn
  print('\n\n📝 TEST 4: Bật đèn phòng ngủ');
  print('───────────────────────────────────────────────────────────');
  try {
    final result4 = await aiService.processVoiceCommand(
      userId: 'test_user',
      voiceCommand: 'Bật đèn phòng ngủ',
      devices: devices,
      sensorData: sensorData,
    );
    
    _printResult(result4);
  } catch (e) {
    print('❌ ERROR: $e');
  }

  // TEST 5: Device Control - Tắt quạt
  print('\n\n📝 TEST 5: Tắt quạt phòng khách');
  print('───────────────────────────────────────────────────────────');
  try {
    final result5 = await aiService.processVoiceCommand(
      userId: 'test_user',
      voiceCommand: 'Tắt quạt phòng khách',
      devices: devices,
      sensorData: sensorData,
    );
    
    _printResult(result5);
  } catch (e) {
    print('❌ ERROR: $e');
  }

  print('\n═══════════════════════════════════════════════════════════');
  print('✅ ALL TESTS COMPLETED');
  print('═══════════════════════════════════════════════════════════\n');
}

void _printResult(CommandResult? result) {
  if (result == null) {
    print('❌ Result is NULL');
    return;
  }

  print('📊 RESULT:');
  print('   Success: ${result.success}');
  
  if (result.success) {
    print('   Response Type: ${result.responseType}');
    
    if (result.responseType == ResponseType.sensorQuery) {
      print('   ├─ Sensor Type: ${result.sensorType}');
      print('   └─ Sensor Value: ${result.sensorValue}');
      
      // Format output
      final formatted = _formatSensorValue(result.sensorType!, result.sensorValue);
      print('   💬 Display: $formatted');
    } else {
      print('   ├─ Device: ${result.deviceKeyName}');
      print('   ├─ Action: ${result.action}');
      print('   └─ Value: ${result.value}');
      
      // Format output
      final formatted = _formatDeviceAction(result);
      print('   💬 Display: $formatted');
    }
  } else {
    print('   ❌ Error: ${result.error}');
  }
}

String _formatSensorValue(String sensorType, dynamic value) {
  switch (sensorType) {
    case 'temperature':
      final temp = value as double;
      String condition = temp < 20 ? '(Lạnh)' 
                       : temp < 26 ? '(Mát)'
                       : temp < 30 ? '(Ấm)' 
                       : '(Nóng)';
      return '🌡️ Nhiệt độ: ${temp.toStringAsFixed(1)}°C $condition';
      
    case 'humidity':
      final humidity = value as double;
      String condition = humidity < 30 ? '(Khô)' 
                       : humidity < 60 ? '(Bình thường)' 
                       : '(Ẩm)';
      return '💧 Độ ẩm: ${humidity.toStringAsFixed(0)}% $condition';
      
    case 'rain':
      return value == 1 ? '🌧️ Đang mưa' : '🌤️ Không mưa';
      
    case 'gas':
      final gas = value as double;
      String condition = gas < 1000 ? '(An toàn)' : '(⚠️ Cảnh báo!)';
      return '💨 Khí gas: ${gas.toStringAsFixed(0)} ppm $condition';
      
    case 'dust':
      final dust = value as double;
      String condition = dust < 50 ? '(Tốt)' 
                       : dust < 100 ? '(Trung bình)' 
                       : '(⚠️ Xấu)';
      return '🌫️ Bụi PM2.5: ${dust.toStringAsFixed(1)} µg/m³ $condition';
      
    default:
      return 'Sensor $sensorType: $value';
  }
}

String _formatDeviceAction(CommandResult result) {
  if (result.action == 'turn_on') {
    return '✅ Đã bật ${result.deviceKeyName}';
  } else if (result.action == 'turn_off') {
    return '✅ Đã tắt ${result.deviceKeyName}';
  } else {
    return '✅ Đã ${result.action} ${result.deviceKeyName}';
  }
}
