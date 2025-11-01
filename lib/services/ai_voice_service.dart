import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/ai_config.dart';
import '../models/device_model.dart';
import '../models/sensor_data.dart';

/// 🤖 AI Voice Service - Gemini 2.0 Flash
///
/// Xử lý voice commands bằng Gemini AI:
/// 1. Device Control: "Bật đèn" → JSON control command
/// 2. Sensor Query: "Nhiệt độ bao nhiêu?" → Trả lời bằng văn bản
class AiVoiceService {
  late final GenerativeModel _model;

  AiVoiceService() {
    _model = GenerativeModel(
      model: AiConfig.modelName,
      apiKey: AiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: AiConfig.temperature,
        maxOutputTokens: AiConfig.maxTokens,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  /// Parse voice command → CommandResult (Device Control hoặc Sensor Query)
  ///
  /// Example Device Control:
  /// ```dart
  /// final result = await service.processVoiceCommand(
  ///   userId: 'user123',
  ///   voiceCommand: 'Bật đèn phòng ngủ',
  ///   devices: [device1, device2, ...],
  /// );
  /// ```
  ///
  /// Example Sensor Query:
  /// ```dart
  /// final result = await service.processVoiceCommand(
  ///   userId: 'user123',
  ///   voiceCommand: 'Nhiệt độ bao nhiêu?',
  ///   devices: [],
  ///   sensorData: currentSensorData,
  /// );
  /// ```
  Future<CommandResult?> processVoiceCommand({
    required String userId,
    required String voiceCommand,
    required List<Device> devices,
    SensorData? sensorData,
  }) async {
    try {
      // 🎯 SMART PROMPT: Chỉ include sensor data nếu câu hỏi liên quan
      final needsSensorData = _isSensorQuery(voiceCommand);
      final effectiveSensorData = needsSensorData ? sensorData : null;

      // Bước 1: Build prompt (với sensor data nếu cần)
      final prompt = _buildPrompt(voiceCommand, devices, effectiveSensorData);

      print('🤖 AI Voice: Processing command: "$voiceCommand"');
      print('🤖 AI Voice: Available devices: ${devices.length}');
      print(
        '🤖 AI Voice: Sensor data included: ${effectiveSensorData != null}',
      );
      print(
        '💰 Token saved: ${!needsSensorData && sensorData != null ? "~400 tokens" : "0"}',
      );

      // Bước 2: Call Gemini API
      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(
            Duration(milliseconds: AiConfig.requestTimeout),
            onTimeout: () => throw Exception('AI request timeout'),
          );

      // Bước 3: Parse response
      final result = _parseAiResponse(response.text);

      if (result != null && result.success) {
        if (result.responseType == ResponseType.deviceControl) {
          print(
            '✅ AI Voice: Device Control - ${result.deviceKeyName}, ${result.action}',
          );
        } else {
          print(
            '✅ AI Voice: Sensor Query - ${result.sensorType}: ${result.sensorValue}',
          );
        }
      } else {
        print('❌ AI Voice: Failed - ${result?.error ?? "Unknown error"}');
      }

      return result;
    } catch (e) {
      print('❌ AI Voice: Error - $e');
      return CommandResult.error('Lỗi kết nối AI: $e');
    }
  }

  /// Build prompt cho Gemini AI (Device Control + Sensor Query)
  String _buildPrompt(
    String command,
    List<Device> devices,
    SensorData? sensorData,
  ) {
    // Tạo danh sách thiết bị với thông tin chi tiết
    final deviceList = devices
        .map((device) {
          return '''
- Tên hiển thị: "${device.name}"
  Key chuẩn hóa: "${device.keyName}"
  Mã thiết bị: "${device.deviceCode}"
  Loại: "${device.type}"
  Phòng: "${device.room ?? 'Không rõ'}"
  Trạng thái: ${device.state ? 'Đang bật' : 'Đang tắt'}''';
        })
        .join('\n');

    // Tạo thông tin sensor data nếu có
    final sensorInfo = sensorData != null
        ? '''
═══════════════════════════════════════════════════════════════════
📊 DỮ LIỆU CẢM BIẾN HIỆN TẠI
═══════════════════════════════════════════════════════════════════

🌡️ Nhiệt độ: ${sensorData.temperature.toStringAsFixed(1)}°C
💧 Độ ẩm: ${sensorData.humidity.toStringAsFixed(1)}%
🌧️ Mưa: ${sensorData.rain == 0 ? 'Không mưa' : 'Đang mưa'}
💡 Ánh sáng: ${sensorData.light} lux
🌱 Độ ẩm đất: ${sensorData.soilMoisture}%
☁️ Khí gas: ${sensorData.gas} ppm
🌫️ Bụi PM2.5: ${sensorData.dust} µg/m³
🚶 Chuyển động: ${sensorData.motionDetected ? 'Có người' : 'Không có người'}

Thời gian cập nhật: ${_formatTime(sensorData.timestamp)}
'''
        : '';

    return '''
BẠN LÀ TRỢ LÝ NHÀ THÔNG MINH BẰNG GIỌNG NÓI - Hỗ trợ 2 CHỨC NĂNG:
1. ⚡ ĐIỀU KHIỂN THIẾT BỊ (Device Control)
2. 📊 TRẢ LỜI VỀ CẢM BIẾN (Sensor Query)

═══════════════════════════════════════════════════════════════════
🎯 PHÂN LOẠI CÂU LỆNH
═══════════════════════════════════════════════════════════════════

� SENSOR QUERY (Hỏi về cảm biến):
Từ khóa: "bao nhiêu", "thế nào", "có ... không", "mấy độ", "nóng", "lạnh", "mát", "ẩm", "khô"

Ví dụ:
- "Nhiệt độ bao nhiêu?" → Trả lời: "Nhiệt độ hiện tại 28°C"
- "Nhà tôi có nóng không?" → Phân tích nhiệt độ, trả lời "Mát" hoặc "Nóng"
- "Độ ẩm thế nào?" → Trả lời: "Độ ẩm 65%, mức bình thường"
- "Có mưa không?" → Trả lời: "Đang mưa" hoặc "Không mưa"
- "Bụi có nhiều không?" → Phân tích PM2.5, trả lời mức độ
- "Có người trong nhà không?" → Trả lời dựa trên cảm biến chuyển động

⚡ DEVICE CONTROL (Điều khiển thiết bị):
Từ khóa: "bật", "tắt", "mở", "đóng", "chỉnh", "tăng", "giảm"

Ví dụ:
- "Bật đèn" → JSON control
- "Tắt quạt" → JSON control
- "Mở cửa" → JSON control

$sensorInfo

═══════════════════════════════════════════════════════════════════
📋 DANH SÁCH THIẾT BỊ CÓ THỂ ĐIỀU KHIỂN
═══════════════════════════════════════════════════════════════════

$deviceList

═══════════════════════════════════════════════════════════════════
❓ CÂU LỆNH NGƯỜI DÙNG
═══════════════════════════════════════════════════════════════════

"$command"

═══════════════════════════════════════════════════════════════════
📝 OUTPUT FORMAT
═══════════════════════════════════════════════════════════════════

🔹 NẾU LÀ SENSOR QUERY (Hỏi về cảm biến):
{
  "success": true,
  "response_type": "sensor_query",
  "sensor_type": "temperature",
  "sensor_value": 28.0
}

SENSOR TYPES:
- "temperature" → nhiệt độ
- "humidity" → độ ẩm
- "rain" → mưa (0 = không, 1 = có)
- "gas" → khí gas
- "dust" → bụi PM2.5
- "light" → ánh sáng
- "soil" → độ ẩm đất
- "motion" → chuyển động
- "all" → tất cả sensors (trả về object với nhiều sensor)

⚠️ QUAN TRỌNG:
- CHỈ TRẢ VỀ DATA, KHÔNG GIẢI THÍCH
- App sẽ tự format và hiển thị
- Tiết kiệm token AI

🔹 NẾU LÀ DEVICE CONTROL (Điều khiển thiết bị):
{
  "success": true,
  "response_type": "device_control",
  "device_key": "den_phong_ngu",
  "action": "turn_on",
  "value": null
}

HOẶC NẾU KHÔNG HIỂU/KHÔNG TÌM THẤY:
{
  "success": false,
  "error": "Không tìm thấy thiết bị trong câu lệnh"
}

LƯU Ý QUAN TRỌNG:
- "device_key" PHẢI khớp CHÍNH XÁC với "keyName" trong danh sách thiết bị
- "value" chỉ dùng khi action là "set_value"

QUY ƯỚC GIÁ TRỊ "value" VÀ HÀNH ĐỘNG MẶC ĐỊNH:

⚡ HỆ THỐNG HỖ TRỢ 2 FORMAT MQTT:
- Format 1 (STATE): {"state": true/false} - Dùng cho LED, Relay
- Format 2 (ACTION): {"action": "turn_on"/"turn_off"} - Alternative cho LED, Relay
- Format 3 (VALUE): {"angle": X} hoặc {"speed": X} - Dùng cho Servo, Motor/Fan

1. RELAY (loại: relay) - Chỉ có ON/OFF:
   MQTT Format hỗ trợ:
   - turn_on → App gửi: {"state": true} HOẶC {"action": "turn_on"}
   - turn_off → App gửi: {"state": false} HOẶC {"action": "turn_off"}
   
   Voice Command:
   - "Bật relay" → turn_on, value = null
   - "Tắt relay" → turn_off, value = null
   - KHÔNG BAO GIỜ dùng set_value cho relay
   
   Arduino nhận: Tự động hỗ trợ CẢ 2 FORMAT (state hoặc action)

2. ĐÈN (loại: light) - PHẦN TRĂM 0-100:
   MQTT Format hỗ trợ:
   - turn_on → App gửi: {"state": true} HOẶC {"action": "turn_on"}
   - turn_off → App gửi: {"state": false} HOẶC {"action": "turn_off"}
   - set_value → App gửi: {"brightness": X} (nếu dimmer hỗ trợ)
   
   Voice Command:
   - "Bật đèn" → turn_on, value = null
   - "Tắt đèn" → turn_off, value = null
   - "Chỉnh đèn X%" → set_value, value = X (0-100)
   
   Arduino nhận: Tự động hỗ trợ CẢ 2 FORMAT (state hoặc action)

3. QUẠT/MOTOR (loại: fan) - PHẦN TRĂM 0-100:
   MQTT Format hỗ trợ:
   - set_value → App gửi: {"speed": X} với X = 0-255 (PWM)
   - Alternative → App gửi: {"action": "turn_on"} → Arduino convert thành speed=255
   - Alternative → App gửi: {"action": "turn_off"} → Arduino convert thành speed=0
   
   Voice Command (AI trả về % 0-100, App convert sang 0-255):
   - "Bật quạt" → set_value, value = 67 (App convert: 67% = 171/255)
   - "Tắt quạt" → set_value, value = 0 (KHÔNG DÙNG turn_off)
   - "Quạt mạnh/nhanh/cao/full/max" → set_value, value = 100 (App convert: 255/255)
   - "Quạt khá/vừa/medium" → set_value, value = 67 (App convert: 171/255)
   - "Quạt nhẹ/yếu/chậm/thấp/low" → set_value, value = 33 (App convert: 84/255)
   - "Quạt X%" → set_value, value = X (App convert: X% * 255/100)
   
   ⚠️ QUAN TRỌNG:
   - Quạt LUÔN dùng set_value với value 0-100 (AI output)
   - App tự động convert 0-100 → 0-255 trước khi gửi MQTT
   - Arduino CHỈ nhận speed 0-255, CHỈ hỗ trợ chiều thuận (forward only)
   - KHÔNG BAO GIỜ dùng turn_on/turn_off cho quạt (dùng set_value với value=0 để tắt)
   
   Arduino Logic (L298N):
   - speed > 0: IN1=HIGH, IN2=LOW, PWM=speed (forward)
   - speed = 0: IN1=LOW, IN2=LOW, PWM=0 (stop)
   - KHÔNG hỗ trợ reverse (tránh lỗi cả 2 LED L298N sáng)

4. SERVO (loại: servo) - Góc 0-180:
   MQTT Format:
   - set_value → App gửi: {"angle": X} với X = 0-180 degrees
   
   Voice Command:
   - "Mở cửa/cổng/rèm/cửa sổ/mái che" → set_value, value = 180
   - "Đóng cửa/cổng/rèm/cửa sổ/mái che" → set_value, value = 0
   - "Mở một nửa/nửa chừng" → set_value, value = 90
   - "Xoay/quay X độ" → set_value, value = X (0-180)
   
   Arduino nhận: {"angle": X}, tự động publish {"angle": X, "state": true/false}
   
   ⚠️ QUAN TRỌNG:
   - Servo LUÔN dùng set_value với góc cụ thể
   - KHÔNG DÙNG turn_on/turn_off cho servo
   - Range: 0-180 degrees (chuẩn servo 180°)

PHÂN TÍCH CÂU LỆNH:
- "mở", "bật", "chạy", "sáng", "kích hoạt" → action = "turn_on" (RELAY, ĐÈN)
- "tắt", "đóng", "dừng", "off", "tối" → action = "turn_off"
- "chuyển", "đảo", "toggle" → action = "toggle"
- "đặt", "điều chỉnh", "chỉnh", "quay", "xoay", "set" + SỐ → action = "set_value"

⚠️ ĐẶC BIỆT QUAN TRỌNG:
- SERVO: LUÔN dùng "set_value" với góc cụ thể
  → "Mở cửa" = set_value với value = 180 (KHÔNG DÙNG turn_on)
  → "Đóng cửa" = set_value với value = 0 (KHÔNG DÙNG turn_off)
- QUẠT: LUÔN LUÔN dùng "set_value", KHÔNG BAO GIỜ dùng turn_on/turn_off
  → "Bật quạt" = set_value với value = 67
  → "Tắt quạt" = set_value với value = 0 (KHÔNG DÙNG turn_off)
  → "Quạt mạnh" = set_value với value = 100
- RELAY: CHỈ dùng turn_on/turn_off (KHÔNG BAO GIỜ dùng set_value)

TỪ ĐỒNG NGHĨA THIẾT BỊ:
- "đèn", "light", "sáng", "chiếu sáng" → loại: light
- "quạt", "fan", "gió" → loại: fan
- "cửa", "cửa sổ", "window", "door", "cổng" → loại: servo hoặc relay
- "rèm", "curtain", "mành" → loại: servo
- "điều hòa", "AC", "máy lạnh" → loại: relay hoặc fan
- "ổ cắm", "plug", "socket", "relay" → loại: relay

LOGIC CHỌN THIẾT BỊ:
1. Nếu câu lệnh có TÊN PHÒNG → ưu tiên thiết bị trong phòng đó
2. Nếu chỉ nói LOẠI THIẾT BỊ → chọn thiết bị đầu tiên cùng loại
3. Nếu có TỪ KHÓA GẦN KHỚP → chọn thiết bị có tên chứa từ khóa
4. CHỈ TRẢ VỀ JSON, KHÔNG GIẢI THÍCH THÊM

VÍ DỤ CHI TIẾT (với MQTT format mapping):

📌 RELAY (chỉ ON/OFF):
Lệnh: "Bật relay phòng khách"
→ AI Output: {"success": true, "device_key": "relay_phong_khach", "action": "turn_on", "value": null}
→ App gửi MQTT: {"state": true} hoặc {"action": "turn_on"}
→ Arduino nhận: Tự động parse CẢ 2 format → digitalWrite(RELAY_PIN, HIGH)
→ Arduino phản hồi: {"state": "ON", "timestamp": 12345678}

📌 ĐÈN (ON/OFF hoặc % 0-100):
Lệnh: "Bật đèn"
→ AI Output: {"success": true, "device_key": "den_phong_khach", "action": "turn_on", "value": null}
→ App gửi MQTT: {"state": true} hoặc {"action": "turn_on"}
→ Arduino phản hồi: {"state": "ON", "timestamp": 12345678}

Lệnh: "Chỉnh đèn 70%"
→ AI Output: {"success": true, "device_key": "den", "action": "set_value", "value": 70}
→ App gửi MQTT: {"brightness": 70} (nếu dimmer hỗ trợ)
→ Note: LED cơ bản chỉ ON/OFF, dimmer cần thêm hardware PWM

📌 QUẠT/MOTOR (% 0-100 → PWM 0-255):
Lệnh: "Tắt quạt"
→ AI Output: {"success": true, "device_key": "quat", "action": "set_value", "value": 0}
→ App convert: 0% → 0/255
→ App gửi MQTT: {"speed": 0}
→ Arduino nhận: speed=0 → IN1=LOW, IN2=LOW, PWM=0 (stop)
→ Arduino phản hồi: {"speed": 0, "state": false, "timestamp": 12345678}

Lệnh: "Bật quạt"
→ AI Output: {"success": true, "device_key": "quat", "action": "set_value", "value": 67}
→ App convert: 67% → 171/255
→ App gửi MQTT: {"speed": 171}
→ Arduino nhận: speed=171 → IN1=HIGH, IN2=LOW, PWM=171 (medium speed)
→ Arduino phản hồi: {"speed": 171, "state": true, "timestamp": 12345678}

Lệnh: "Quạt nhẹ"
→ AI Output: {"success": true, "device_key": "quat", "action": "set_value", "value": 33}
→ App convert: 33% → 84/255
→ App gửi MQTT: {"speed": 84}
→ Arduino nhận: speed=84 → IN1=HIGH, IN2=LOW, PWM=84 (low speed)

Lệnh: "Quạt mạnh"
→ AI Output: {"success": true, "device_key": "quat", "action": "set_value", "value": 100}
→ App convert: 100% → 255/255
→ App gửi MQTT: {"speed": 255}
→ Arduino nhận: speed=255 → IN1=HIGH, IN2=LOW, PWM=255 (full speed)

Alternative format (nếu app dùng action):
Lệnh: "Bật quạt full"
→ App có thể gửi: {"action": "turn_on"}
→ Arduino convert: action="turn_on" → speed=255 (full speed)

📌 SERVO (Góc 0-180):
Lệnh: "Mở cửa"
→ AI Output: {"success": true, "device_key": "servo_cua_so", "action": "set_value", "value": 180}
→ App gửi MQTT: {"angle": 180}
→ Arduino nhận: angle=180 → servo.write(180)
→ Arduino phản hồi: {"angle": 180, "state": true, "timestamp": 12345678}

Lệnh: "Đóng cổng"
→ AI Output: {"success": true, "device_key": "servo_cong", "action": "set_value", "value": 0}
→ App gửi MQTT: {"angle": 0}
→ Arduino nhận: angle=0 → servo.write(0)
→ Arduino phản hồi: {"angle": 0, "state": false, "timestamp": 12345678}

Lệnh: "Mở mái che một nửa"
→ AI Output: {"success": true, "device_key": "servo_mai_che", "action": "set_value", "value": 90}
→ App gửi MQTT: {"angle": 90}
→ Arduino nhận: angle=90 → servo.write(90)

📌 NÓI TẮT (FUZZY MATCHING):
Lệnh: "Bật đèn ngủ" (có thiết bị "Đèn phòng ngủ")
→ AI Output: {"success": true, "device_key": "den_phong_ngu", "action": "turn_on", "value": null}
→ App gửi MQTT: {"state": true}
→ AI tự động nhận diện "đèn ngủ" ≈ "Đèn phòng ngủ"

Lệnh: "Tắt quạt khách" (có thiết bị "Quạt phòng khách")
→ AI Output: {"success": true, "device_key": "quat_phong_khach", "action": "set_value", "value": 0}
→ App convert: 0% → 0/255
→ App gửi MQTT: {"speed": 0}

📌 MQTT TOPICS USED:
- Command (App → Arduino): smart_home/devices/{DEVICE_CODE}/cmd
- State (Arduino → App): smart_home/devices/{DEVICE_CODE}/state
- Ping (Health check): smart_home/devices/{DEVICE_CODE}/ping

📌 RESPONSE TIME:
- Arduino phản hồi state NGAY SAU khi nhận lệnh
- App subscribe topic /state để cập nhật UI real-time
- Ping/pong timeout: 5 seconds (offline detection)

BẮT ĐẦU XỬ LÝ:
''';
  }

  /// Parse AI response text → CommandResult
  CommandResult? _parseAiResponse(String? responseText) {
    if (responseText == null || responseText.isEmpty) {
      return CommandResult.error('AI không trả về kết quả');
    }

    try {
      // Extract JSON từ response (có thể có text bao quanh)
      final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(responseText);
      if (jsonMatch == null) {
        print('⚠️ AI Voice: No JSON found in response: $responseText');
        return CommandResult.error('AI không trả về JSON hợp lệ');
      }

      final jsonString = jsonMatch.group(0)!;
      print('🔍 AI Voice: Extracted JSON: $jsonString');

      final Map<String, dynamic> json = jsonDecode(jsonString);

      // Check success
      if (json['success'] != true) {
        final error = json['error'] ?? 'Không hiểu lệnh';
        return CommandResult.error(error);
      }

      // Check response type
      final responseType = json['response_type'] as String?;

      if (responseType == 'sensor_query') {
        // Sensor Query Response (CHỈ DATA, KHÔNG TEXT)
        final sensorType = json['sensor_type'] as String?;
        final sensorValue = json['sensor_value'];

        if (sensorType == null) {
          return CommandResult.error('JSON thiếu sensor_type');
        }

        return CommandResult.sensorQuery(
          sensorType: sensorType,
          sensorValue: sensorValue,
        );
      } else {
        // Device Control Response (default)
        final deviceKey = json['device_key'] as String?;
        final action = json['action'] as String?;
        final value = json['value'];

        if (deviceKey == null || action == null) {
          return CommandResult.error(
            'JSON thiếu thông tin device_key hoặc action',
          );
        }

        return CommandResult.deviceControl(
          deviceKeyName: deviceKey,
          action: action,
          value: value,
        );
      }
    } catch (e) {
      print('❌ AI Voice: Parse error - $e');
      print('   Response text: $responseText');
      return CommandResult.error('Lỗi parse JSON: $e');
    }
  }

  /// Format timestamp for sensor data
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 10) {
      return 'Vừa xong';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds} giây trước';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Kiểm tra xem câu lệnh có phải sensor query không (để tiết kiệm token)
  bool _isSensorQuery(String command) {
    final sensorKeywords = [
      // Từ khóa hỏi thông tin
      'bao nhiêu',
      'bao nhieu',
      'mấy độ',
      'may do',
      'thế nào',
      'the nao',
      'như thế nào',
      'nhu the nao',
      'có',
      'không',
      'ra sao',
      // Sensor types
      'nhiệt độ',
      'nhiet do',
      'độ ẩm',
      'do am',
      'nóng',
      'lạnh',
      'mát',
      'mat',
      'ấm',
      'am',
      'ẩm',
      'khô',
      'kho',
      'mưa',
      'mua',
      'bụi',
      'bui',
      'khí gas',
      'khi gas',
      'gas',
      'ánh sáng',
      'anh sang',
      'tối',
      'toi',
      'sáng',
      'sang',
      'đất',
      'dat',
      'chuyển động',
      'chuyen dong',
      'cảm biến',
      'cam bien',
      'sensor',
      'tình trạng',
      'tinh trang',
      'trạng thái',
      'trang thai',
    ];

    final lowerCommand = command.toLowerCase().trim();
    
    // Debug: In ra để check
    print('🔍 Checking if sensor query: "$lowerCommand"');
    final matched = sensorKeywords.where((kw) => lowerCommand.contains(kw)).toList();
    if (matched.isNotEmpty) {
      print('   ✅ Matched keywords: $matched');
      return true;
    } else {
      print('   ❌ No keywords matched');
      return false;
    }
  }
}

/// 📊 Response Type (Device Control hoặc Sensor Query)
enum ResponseType {
  deviceControl, // Điều khiển thiết bị
  sensorQuery, // Hỏi về cảm biến
}

/// 📊 Command Result từ AI (Hỗ trợ 2 loại: Device Control + Sensor Query)
class CommandResult {
  final bool success;
  final ResponseType responseType; // Loại response

  // Device Control fields
  final String? deviceKeyName; // keyName của device (chuẩn hóa)
  final String? action; // turn_on, turn_off, set_value, toggle
  final dynamic value; // Giá trị (nếu có)

  // Sensor Query fields (CHỈ DATA, không text response)
  final String? sensorType; // 'temperature', 'humidity', 'rain', etc.
  final dynamic sensorValue; // Giá trị sensor (số hoặc bool)

  // Error fields
  final String? error; // Error message (nếu thất bại)

  CommandResult({
    required this.success,
    required this.responseType,
    this.deviceKeyName,
    this.action,
    this.value,
    this.sensorType,
    this.sensorValue,
    this.error,
  });

  /// Constructor cho Device Control
  factory CommandResult.deviceControl({
    required String deviceKeyName,
    required String action,
    dynamic value,
  }) {
    return CommandResult(
      success: true,
      responseType: ResponseType.deviceControl,
      deviceKeyName: deviceKeyName,
      action: action,
      value: value,
    );
  }

  /// Constructor cho Sensor Query (CHỈ DATA)
  factory CommandResult.sensorQuery({
    required String sensorType,
    required dynamic sensorValue,
  }) {
    return CommandResult(
      success: true,
      responseType: ResponseType.sensorQuery,
      sensorType: sensorType,
      sensorValue: sensorValue,
    );
  }

  /// Constructor cho error case
  factory CommandResult.error(String errorMessage) {
    return CommandResult(
      success: false,
      responseType: ResponseType.deviceControl, // Default
      error: errorMessage,
    );
  }

  @override
  String toString() {
    if (!success) return 'CommandResult(error: $error)';
    if (responseType == ResponseType.sensorQuery) {
      return 'CommandResult(type: sensor_query, sensor: $sensorType, value: $sensorValue)';
    }
    return 'CommandResult(type: device_control, device: $deviceKeyName, action: $action, value: $value)';
  }
}
