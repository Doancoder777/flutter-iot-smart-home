import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/ai_config.dart';
import '../models/device_model.dart';

/// 🤖 AI Voice Service - Gemini 2.0 Flash
///
/// Xử lý voice commands bằng Gemini AI:
/// 1. Nhận voice command (text)
/// 2. Parse command → JSON
/// 3. Trả về device + action + value
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

  /// Parse voice command → CommandResult
  ///
  /// Example:
  /// ```dart
  /// final result = await service.processVoiceCommand(
  ///   userId: 'user123',
  ///   voiceCommand: 'Bật đèn phòng ngủ',
  ///   devices: [device1, device2, ...],
  /// );
  /// ```
  Future<CommandResult?> processVoiceCommand({
    required String userId,
    required String voiceCommand,
    required List<Device> devices,
  }) async {
    try {
      // Bước 1: Build prompt
      final prompt = _buildPrompt(voiceCommand, devices);

      print('🤖 AI Voice: Processing command: "$voiceCommand"');
      print('🤖 AI Voice: Available devices: ${devices.length}');

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
        print(
          '✅ AI Voice: Success - Device: ${result.deviceKeyName}, Action: ${result.action}',
        );
      } else {
        print('❌ AI Voice: Failed - ${result?.error ?? "Unknown error"}');
      }

      return result;
    } catch (e) {
      print('❌ AI Voice: Error - $e');
      return CommandResult.error('Lỗi kết nối AI: $e');
    }
  }

  /// Build prompt cho Gemini AI
  String _buildPrompt(String command, List<Device> devices) {
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

    return '''
BẠN LÀ TRỢ LÝ ĐIỀU KHIỂN NHÀ THÔNG MINH BẰNG GIỌNG NÓI.

DANH SÁCH THIẾT BỊ HIỆN CÓ:
$deviceList

CÂU LỆNH NGƯỜI DÙNG:
"$command"

NHIỆM VỤ:
1. Phân tích câu lệnh tiếng Việt (có thể nói tắt, không chính xác)
2. Tìm thiết bị PHÙ HỢP NHẤT dựa trên ngữ cảnh (không cần khớp 100% tên)
3. Xác định hành động cần thực hiện
4. Trả về JSON theo format chính xác dưới đây

QUAN TRỌNG - SUY LUẬN THÔNG MINH:
- Người dùng có thể nói TẮT hoặc KHÔNG CHÍNH XÁC
- Ví dụ: "Bật đèn" → tìm thiết bị loại "light" gần nhất
- Ví dụ: "Tắt quạt" → tìm thiết bị loại "fan" trong danh sách
- Ví dụ: "Mở cửa" → tìm thiết bị có tên chứa "cua" hoặc loại "servo"
- Ví dụ: "Bật đèn phòng khách" → ưu tiên thiết bị có room="Phòng khách" + loại "light"
- Nếu có NHIỀU thiết bị cùng loại, ưu tiên thiết bị có tên GẦN NHẤT với câu lệnh
- Nếu KHÔNG RÕ RÀNG, chọn thiết bị ĐẦU TIÊN cùng loại

CÁC HÀNH ĐỘNG HỖ TRỢ:
- "turn_on": Bật thiết bị (relay, đèn)
- "turn_off": Tắt thiết bị
- "toggle": Đảo trạng thái
- "set_value": Đặt giá trị cụ thể (độ sáng, góc servo, tốc độ quạt)

FORMAT JSON TRẢ VỀ (BẮT BUỘC):
{
  "success": true,
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

1. RELAY (loại: relay) - Chỉ có ON/OFF:
   - "Bật relay" → turn_on, value = null
   - "Tắt relay" → turn_off, value = null
   - KHÔNG BAO GIỜ dùng set_value cho relay

2. ĐÈN (loại: light) - PHẦN TRĂM 0-100:
   - "Bật đèn" → turn_on
   - "Tắt đèn" → turn_off
   - "Chỉnh đèn X%" → set_value, value = X (0-100)

3. QUẠT (loại: fan) - PHẦN TRĂM 0-100:
   - "Bật quạt" → set_value, value = 67 (mức khá)
   - "Tắt quạt" → set_value, value = 0 (KHÔNG DÙNG turn_off)
   - "Quạt mạnh/nhanh/cao" → set_value, value = 100
   - "Quạt khá/vừa" → set_value, value = 67
   - "Quạt nhẹ/yếu/chậm/thấp" → set_value, value = 33
   - "Quạt X%" → set_value, value = X (0-100)
   - ⚠️ QUAN TRỌNG: Quạt LUÔN dùng set_value, kể cả khi tắt (value=0)

4. SERVO (loại: servo) - Góc 0-180:
   - "Mở cửa/cổng/rèm/cửa sổ" → set_value, value = 180
   - "Đóng cửa/cổng/rèm/cửa sổ" → set_value, value = 0
   - "Mở một nửa/nửa chừng" → set_value, value = 90
   - "Xoay/quay X độ" → set_value, value = X

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

VÍ DỤ CHI TIẾT:

RELAY (chỉ ON/OFF):
Lệnh: "Bật relay phòng khách"
→ {"success": true, "device_key": "relay_phong_khach", "action": "turn_on", "value": null}

ĐÈN (% 0-100):
Lệnh: "Bật đèn"
→ {"success": true, "device_key": "den_phong_khach", "action": "turn_on", "value": null}

Lệnh: "Chỉnh đèn 70%"
→ {"success": true, "device_key": "den", "action": "set_value", "value": 70}

QUẠT (% 0-100, LUÔN dùng set_value):
Lệnh: "Tắt quạt"
→ {"success": true, "device_key": "quat", "action": "set_value", "value": 0}

Lệnh: "Bật quạt"
→ {"success": true, "device_key": "quat", "action": "set_value", "value": 67}

Lệnh: "Quạt nhẹ"
→ {"success": true, "device_key": "quat", "action": "set_value", "value": 33}

Lệnh: "Quạt mạnh"
→ {"success": true, "device_key": "quat", "action": "set_value", "value": 100}

SERVO (Góc 0-180):
Lệnh: "Mở cửa"
→ {"success": true, "device_key": "servo_cua_so", "action": "set_value", "value": 180}

Lệnh: "Đóng cổng"
→ {"success": true, "device_key": "servo_cong", "action": "set_value", "value": 0}

NÓI TẮT (FUZZY):
Lệnh: "Bật đèn ngủ" (có "Đèn phòng ngủ")
→ {"success": true, "device_key": "den_phong_ngu", "action": "turn_on", "value": null}

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

      // Extract data
      final deviceKey = json['device_key'] as String?;
      final action = json['action'] as String?;
      final value = json['value'];

      if (deviceKey == null || action == null) {
        return CommandResult.error(
          'JSON thiếu thông tin device_key hoặc action',
        );
      }

      return CommandResult(
        success: true,
        deviceKeyName: deviceKey,
        action: action,
        value: value,
      );
    } catch (e) {
      print('❌ AI Voice: Parse error - $e');
      print('   Response text: $responseText');
      return CommandResult.error('Lỗi parse JSON: $e');
    }
  }
}

/// 📊 Command Result từ AI
class CommandResult {
  final bool success;
  final String? deviceKeyName; // keyName của device (chuẩn hóa)
  final String? action; // turn_on, turn_off, set_value, toggle
  final dynamic value; // Giá trị (nếu có)
  final String? error; // Error message (nếu thất bại)

  CommandResult({
    required this.success,
    this.deviceKeyName,
    this.action,
    this.value,
    this.error,
  });

  /// Constructor cho error case
  factory CommandResult.error(String errorMessage) {
    return CommandResult(success: false, error: errorMessage);
  }

  @override
  String toString() {
    if (!success) return 'CommandResult(error: $error)';
    return 'CommandResult(device: $deviceKeyName, action: $action, value: $value)';
  }
}
