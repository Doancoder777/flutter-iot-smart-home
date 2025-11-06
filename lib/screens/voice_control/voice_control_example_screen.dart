import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_voice_service.dart';
import '../../config/app_colors.dart';

/// 🎙️ Voice Control Screen với hỗ trợ SENSOR QUERY
///
/// Features:
/// - Device Control: "Bật đèn phòng ngủ"
/// - Sensor Query (MỚI): "Nhiệt độ bao nhiêu?"
/// - Text-to-Speech response
/// - Chat-style UI
class VoiceControlExampleScreen extends StatefulWidget {
  const VoiceControlExampleScreen({Key? key}) : super(key: key);

  @override
  State<VoiceControlExampleScreen> createState() =>
      _VoiceControlExampleScreenState();
}

class _VoiceControlExampleScreenState extends State<VoiceControlExampleScreen> {
  final AiVoiceService _aiService = AiVoiceService();
  final TextEditingController _commandController = TextEditingController();

  bool _isProcessing = false;
  String? _responseText;
  ResponseType? _lastResponseType;

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Voice Control (with Sensor Query)'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Response display
          if (_responseText != null) _buildResponseCard(),

          // Example commands
          _buildExampleCommands(),

          Spacer(),

          // Input field
          _buildCommandInput(),
        ],
      ),
    );
  }

  /// Response card
  Widget _buildResponseCard() {
    final icon = _lastResponseType == ResponseType.sensorQuery
        ? Icons.sensors
        : Icons.lightbulb;
    final color = _lastResponseType == ResponseType.sensorQuery
        ? AppColors.info
        : AppColors.success;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastResponseType == ResponseType.sensorQuery
                      ? '📊 Sensor Info'
                      : '⚡ Device Control',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(_responseText!, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Example commands (clickable)
  Widget _buildExampleCommands() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Ví dụ:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Sensor queries
              _buildExampleChip('Nhiệt độ bao nhiêu?', Icons.thermostat),
              _buildExampleChip('Có nóng không?', Icons.whatshot),
              _buildExampleChip('Độ ẩm thế nào?', Icons.water_drop),
              _buildExampleChip('Có mưa không?', Icons.cloud),

              // Device control
              _buildExampleChip('Bật đèn phòng khách', Icons.lightbulb),
              _buildExampleChip('Tắt quạt', Icons.mode_fan_off),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String command, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(command),
      onPressed: () {
        _commandController.text = command;
        _processCommand();
      },
    );
  }

  /// Command input field
  Widget _buildCommandInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commandController,
              decoration: InputDecoration(
                hintText: 'Nói gì đó... (VD: Nhiệt độ bao nhiêu?)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _processCommand(),
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isProcessing ? null : _processCommand,
            child: _isProcessing
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  /// Process voice command
  Future<void> _processCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    final deviceProvider = context.read<DeviceProvider>();
    final sensorProvider = context.read<SensorProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.currentUser == null) {
      _showError('Vui lòng đăng nhập');
      return;
    }

    setState(() {
      _isProcessing = true;
      _responseText = null;
    });

    try {
      // 🤖 Call AI with sensor data support
      final sensorData = sensorProvider.currentData;

      print('═══════════════════════════════════════');
      print('🔍 DEBUG INFO:');
      print('   Command: "$command"');
      print('   User ID: ${authProvider.currentUser!.id}');
      print('   Devices count: ${deviceProvider.devices.length}');
      print('   Sensor data (REAL from ESP32):');
      print('      Temperature: ${sensorData.temperature}°C');
      print('      Humidity: ${sensorData.humidity}%');
      print('      Rain: ${sensorData.rain}');
      print('      Light: ${sensorData.light} lux');
      print('      Gas: ${sensorData.gas} ppm');
      print('      Dust: ${sensorData.dust}');
      print('═══════════════════════════════════════');

      final result = await _aiService.processVoiceCommand(
        userId: authProvider.currentUser!.id,
        voiceCommand: command,
        devices: deviceProvider.devices,
        sensorData: sensorData, // ⬅️ REAL SENSOR DATA
      );

      print('📥 AI RESULT:');
      print('   Success: ${result?.success}');
      print('   Response Type: ${result?.responseType}');
      print('   Error: ${result?.error}');
      if (result?.responseType == ResponseType.sensorQuery) {
        print('   Sensor Type: ${result?.sensorType}');
        print('   Sensor Value: ${result?.sensorValue}');
      } else {
        print('   Device: ${result?.deviceKeyName}');
        print('   Action: ${result?.action}');
      }
      print('═══════════════════════════════════════');

      if (result?.success == true) {
        print('');
        print('✅✅✅ SUCCESS! ✅✅✅');
        print('📝 BẠN NÓI: "$command"');

        if (result!.responseType == ResponseType.deviceControl) {
          print('🎯 LOẠI: Điều khiển thiết bị');
          print('🔌 THIẾT BỊ: ${result.deviceKeyName}');
          print('⚡ HÀNH ĐỘNG: ${result.action}');
          if (result.value != null) {
            print('📊 GIÁ TRỊ: ${result.value}');
          }
          // ⚡ Device Control
          await _handleDeviceControl(result, deviceProvider);
        } else if (result.responseType == ResponseType.sensorQuery) {
          print('🎯 LOẠI: Hỏi cảm biến');
          print('📡 CẢM BIẾN: ${result.sensorType}');
          print('📊 GIÁ TRỊ: ${result.sensorValue}');
          // 📊 Sensor Query
          _handleSensorQuery(result);
        }

        print('💬 HIỂN THỊ: $_responseText');
        print('✅✅✅✅✅✅✅✅✅✅✅✅✅');
        print('');
      } else {
        print('');
        print('❌❌❌ FAILED! ❌❌❌');
        print('📝 BẠN NÓI: "$command"');
        print('⚠️ LỖI: ${result?.error ?? 'Không hiểu lệnh'}');
        print('❌❌❌❌❌❌❌❌❌❌❌❌❌');
        print('');
        _showError(result?.error ?? 'Không hiểu lệnh');
      }
    } catch (e) {
      print('');
      print('❌❌❌ EXCEPTION! ❌❌❌');
      print('📝 BẠN NÓI: "$command"');
      print('💥 LỖI: $e');
      print('❌❌❌❌❌❌❌❌❌❌❌❌❌');
      print('');
      _showError('Lỗi: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Handle device control
  Future<void> _handleDeviceControl(
    CommandResult result,
    DeviceProvider deviceProvider,
  ) async {
    final device = deviceProvider.devices.firstWhere(
      (d) => d.keyName == result.deviceKeyName,
      orElse: () => throw Exception('Không tìm thấy thiết bị'),
    );

    String actionText = '';

    if (result.action == 'turn_on' || result.action == 'on') {
      deviceProvider.toggleDevice(device.id);
      actionText = 'Đã bật ${device.name}';
    } else if (result.action == 'turn_off' || result.action == 'off') {
      deviceProvider.toggleDevice(device.id);
      actionText = 'Đã tắt ${device.name}';
    } else if (result.action == 'set_value') {
      // Handle set_value for servo/motor
      if (device.type == 'servo') {
        actionText = 'Đã chỉnh ${device.name} về ${result.value}°';
      } else if (device.type == 'fan') {
        actionText = 'Đã chỉnh ${device.name} về ${result.value}%';
      }
    }

    setState(() {
      _responseText = actionText;
      _lastResponseType = ResponseType.deviceControl;
    });

    // Optional: Text-to-speech
    // await _tts.speak(actionText);
  }

  /// Handle sensor query
  void _handleSensorQuery(CommandResult result) {
    final formattedText = _formatSensorData(
      result.sensorType!,
      result.sensorValue,
    );

    print('🔄 Formatting sensor data...');
    print('   Input: ${result.sensorType} = ${result.sensorValue}');
    print('   Output: $formattedText');

    setState(() {
      _responseText = formattedText;
      _lastResponseType = ResponseType.sensorQuery;
    });

    // Optional: Text-to-speech
    // await _tts.speak(formattedText);
  }

  /// Format sensor data thành text hiển thị
  String _formatSensorData(String sensorType, dynamic value) {
    switch (sensorType) {
      case 'temperature':
        final temp = value as double;
        String condition = '';
        if (temp < 20) {
          condition = ' (Lạnh)';
        } else if (temp < 26) {
          condition = ' (Mát)';
        } else if (temp < 30) {
          condition = ' (Ấm)';
        } else {
          condition = ' (Nóng)';
        }
        return '🌡️ Nhiệt độ: ${temp.toStringAsFixed(1)}°C$condition';

      case 'humidity':
        final humidity = value as double;
        String condition = '';
        if (humidity < 30) {
          condition = ' (Khô)';
        } else if (humidity < 60) {
          condition = ' (Bình thường)';
        } else {
          condition = ' (Ẩm)';
        }
        return '💧 Độ ẩm: ${humidity.toStringAsFixed(0)}%$condition';

      case 'rain':
        return value == 1 ? '🌧️ Đang mưa' : '🌤️ Không mưa';

      case 'gas':
        final gas = value as double;
        String condition = gas < 1000 ? ' (An toàn)' : ' (⚠️ Cảnh báo!)';
        return '💨 Khí gas: ${gas.toStringAsFixed(0)} ppm$condition';

      case 'dust':
        final dust = value as double;
        String condition = '';
        if (dust < 50) {
          condition = ' (Tốt)';
        } else if (dust < 100) {
          condition = ' (Trung bình)';
        } else {
          condition = ' (⚠️ Xấu)';
        }
        return '🌫️ Bụi PM2.5: ${dust.toStringAsFixed(1)} µg/m³$condition';

      case 'light':
        final light = value as double;
        String condition = '';
        if (light < 100) {
          condition = ' (Tối)';
        } else if (light < 500) {
          condition = ' (Mờ)';
        } else {
          condition = ' (Sáng)';
        }
        return '💡 Ánh sáng: ${light.toStringAsFixed(0)} lux$condition';

      case 'soil':
        final soil = value as double;
        String condition = '';
        if (soil < 30) {
          condition = ' (Khô - Cần tưới)';
        } else if (soil < 70) {
          condition = ' (Ổn)';
        } else {
          condition = ' (Ướt)';
        }
        return '🌱 Độ ẩm đất: ${soil.toStringAsFixed(0)}%$condition';

      case 'motion':
        return value ? '🚶 Có chuyển động phát hiện' : '✅ Không có chuyển động';

      case 'all':
        // Value là Map với nhiều sensors
        final sensors = value as Map<String, dynamic>;
        final parts = <String>[];

        if (sensors['temperature'] != null) {
          parts.add('Nhiệt độ ${sensors['temperature']}°C');
        }
        if (sensors['humidity'] != null) {
          parts.add('Độ ẩm ${sensors['humidity']}%');
        }
        if (sensors['rain'] != null) {
          parts.add(sensors['rain'] == 1 ? 'Có mưa' : 'Không mưa');
        }

        return '📊 Tình trạng:\n${parts.join('\n')}';

      default:
        return 'Sensor $sensorType: $value';
    }
  }

  /// Show error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}
