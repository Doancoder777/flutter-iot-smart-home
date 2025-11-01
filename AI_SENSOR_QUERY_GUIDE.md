# 🤖 AI Voice Service - Sensor Query Support

## ✅ Cập nhật hoàn thành

### 🎯 Tính năng mới: SENSOR QUERY

AI Voice Service giờ hỗ trợ **2 loại command**:

1. **Device Control** (cũ) - Điều khiển thiết bị
2. **Sensor Query** (MỚI) - Trả lời về dữ liệu cảm biến

---

## 📊 Sensor Query Examples

### Câu hỏi về Nhiệt độ:
```
❓ "Nhiệt độ bao nhiêu?"
✅ AI: "Nhiệt độ hiện tại 28°C, hơi nóng."

❓ "Nhà tôi có nóng không?"
✅ AI: "Hơi nóng, 29°C. Có thể bật quạt cho mát."

❓ "Mấy độ?"
✅ AI: "24°C, mát mẻ rất dễ chịu."
```

### Câu hỏi về Độ ẩm:
```
❓ "Độ ẩm thế nào?"
✅ AI: "Độ ẩm 65%, mức bình thường."

❓ "Có ẩm không?"
✅ AI: "Hơi ẩm, 72%. Có thể bật quạt."
```

### Câu hỏi về Mưa:
```
❓ "Có mưa không?"
✅ AI: "Không mưa, trời đẹp."

❓ "Trời có mưa không?"
✅ AI: "Đang mưa. Nên đóng cửa sổ."
```

### Câu hỏi về Bụi:
```
❓ "Chất lượng không khí thế nào?"
✅ AI: "Bụi PM2.5: 45 µg/m³, mức tốt."

❓ "Có bụi nhiều không?"
✅ AI: "Bụi 120 µg/m³, mức xấu. Nên đóng cửa."
```

### Câu hỏi về Chuyển động:
```
❓ "Có người trong nhà không?"
✅ AI: "Có chuyển động phát hiện lúc 14:30."

❓ "Có ai ở nhà không?"
✅ AI: "Không phát hiện chuyển động."
```

### Câu hỏi về Đất:
```
❓ "Cây có cần tưới không?"
✅ AI: "Độ ẩm đất 25%, khô cần tưới ngay."

❓ "Độ ẩm đất thế nào?"
✅ AI: "60%, ổn không cần tưới."
```

### Câu hỏi tổng hợp:
```
❓ "Thời tiết thế nào?"
✅ AI: "Nhiệt độ 26°C mát mẻ, độ ẩm 55% bình thường, không mưa."

❓ "Nhà tôi ra sao?"
✅ AI: "Nhiệt độ 24°C, độ ẩm 60%, ánh sáng 350 lux, không có người."
```

---

## 🔧 API Changes

### Before (Device Control Only):
```dart
final result = await aiService.processVoiceCommand(
  userId: userId,
  voiceCommand: 'Bật đèn phòng ngủ',
  devices: devices,
);

if (result?.success == true) {
  // Điều khiển thiết bị
  controlDevice(result!.deviceKeyName, result.action, result.value);
}
```

### After (Device Control + Sensor Query):
```dart
final result = await aiService.processVoiceCommand(
  userId: userId,
  voiceCommand: command,
  devices: devices,
  sensorData: sensorProvider.currentData, // ⬅️ MỚI: Pass sensor data
);

if (result?.success == true) {
  if (result!.responseType == ResponseType.deviceControl) {
    // Điều khiển thiết bị
    controlDevice(result.deviceKeyName!, result.action!, result.value);
  } else if (result.responseType == ResponseType.sensorQuery) {
    // Hiển thị câu trả lời về sensor
    showResponse(result.textResponse!);
  }
}
```

---

## 📝 JSON Response Formats

### Device Control Response:
```json
{
  "success": true,
  "response_type": "device_control",
  "device_key": "den_phong_ngu",
  "action": "turn_on",
  "value": null
}
```

### Sensor Query Response:
```json
{
  "success": true,
  "response_type": "sensor_query",
  "text_response": "Nhiệt độ hiện tại 28°C, hơi nóng. Độ ẩm 65%, mức bình thường."
}
```

### Error Response:
```json
{
  "success": false,
  "error": "Không tìm thấy thiết bị trong câu lệnh"
}
```

---

## 🧠 AI Logic - Phân loại câu lệnh

### Sensor Query Keywords:
- "bao nhiêu" → Hỏi giá trị cụ thể
- "thế nào" → Hỏi trạng thái
- "có ... không" → Hỏi yes/no
- "mấy độ" → Hỏi nhiệt độ
- "nóng", "lạnh", "mát" → Hỏi cảm giác nhiệt độ
- "ẩm", "khô" → Hỏi độ ẩm
- "mưa" → Hỏi trời mưa
- "bụi" → Hỏi chất lượng không khí

### Device Control Keywords:
- "bật", "tắt" → ON/OFF
- "mở", "đóng" → Servo/Door
- "chỉnh", "điều chỉnh" → Set value
- "tăng", "giảm" → Adjust value

---

## 📊 Sensor Value Interpretation

### Nhiệt độ (°C):
```
< 20°C  → "Lạnh"
20-26°C → "Mát"
26-30°C → "Ấm"
> 30°C  → "Nóng"
```

### Độ ẩm (%):
```
< 30%   → "Khô"
30-60%  → "Bình thường"
> 60%   → "Ẩm"
```

### Gas (ppm):
```
< 1000  → "An toàn"
> 1500  → "Nguy hiểm"
```

### Bụi PM2.5 (µg/m³):
```
< 50    → "Tốt"
50-100  → "Trung bình"
> 100   → "Xấu"
```

### Ánh sáng (lux):
```
< 100   → "Tối"
100-500 → "Mờ"
> 500   → "Sáng"
```

### Độ ẩm đất (%):
```
< 30%   → "Khô cần tưới"
30-70%  → "Ổn"
> 70%   → "Ướt"
```

---

## 🔄 Integration Example (Full Flow)

### 1. User speaks: "Nhiệt độ bao nhiêu?"

### 2. App calls AI:
```dart
final result = await aiService.processVoiceCommand(
  userId: currentUser.uid,
  voiceCommand: "Nhiệt độ bao nhiêu?",
  devices: deviceProvider.devices,
  sensorData: sensorProvider.currentData, // Temperature: 28°C
);
```

### 3. AI processes:
```
Input: "Nhiệt độ bao nhiêu?"
Sensor Data: temperature = 28.0°C
AI detects: SENSOR_QUERY (keyword: "bao nhiêu")
AI generates: "Nhiệt độ hiện tại 28°C, hơi nóng."
```

### 4. AI returns JSON:
```json
{
  "success": true,
  "response_type": "sensor_query",
  "text_response": "Nhiệt độ hiện tại 28°C, hơi nóng."
}
```

### 5. App displays:
```dart
if (result.responseType == ResponseType.sensorQuery) {
  // Hiển thị trong chat hoặc TTS
  showMessage(result.textResponse!);
  // Hoặc text-to-speech
  tts.speak(result.textResponse!);
}
```

---

## 🎨 UI Suggestions

### Chat-style display:
```
┌─────────────────────────────────────┐
│ 👤 User: Nhiệt độ bao nhiêu?        │
│                                     │
│ 🤖 AI: Nhiệt độ hiện tại 28°C,     │
│     hơi nóng. Có thể bật quạt       │
│     cho mát.                        │
└─────────────────────────────────────┘
```

### Card display:
```
╔═══════════════════════════════════╗
║  📊 Thông tin cảm biến            ║
╠═══════════════════════════════════╣
║                                   ║
║  🌡️ Nhiệt độ: 28°C (Hơi nóng)    ║
║  💧 Độ ẩm: 65% (Bình thường)     ║
║  ☁️ Gas: 800 ppm (An toàn)       ║
║  🌫️ Bụi: 45 µg/m³ (Tốt)          ║
║                                   ║
║  ⏰ Cập nhật: 2 phút trước        ║
╚═══════════════════════════════════╝
```

---

## 🚀 Next Steps for Integration

### 1. Update Voice Control Screen:
```dart
// screens/voice_control/voice_control_screen.dart

Future<void> _processVoiceCommand(String command) async {
  setState(() => _isProcessing = true);

  final result = await _aiService.processVoiceCommand(
    userId: _currentUser!.uid,
    voiceCommand: command,
    devices: _deviceProvider.devices,
    sensorData: _sensorProvider.currentData, // ⬅️ ADD THIS
  );

  if (result?.success == true) {
    if (result!.responseType == ResponseType.deviceControl) {
      // Execute device control
      await _executeDeviceControl(result);
    } else if (result.responseType == ResponseType.sensorQuery) {
      // Show sensor query response
      setState(() {
        _responseText = result.textResponse!;
      });
      // Optional: Text-to-speech
      await _tts.speak(result.textResponse!);
    }
  }

  setState(() => _isProcessing = false);
}
```

### 2. Add Response Display Widget:
```dart
Widget _buildResponse() {
  if (_responseText == null) return SizedBox.shrink();

  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.smart_toy, size: 40),
          SizedBox(height: 8),
          Text(
            _responseText!,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
```

### 3. Test Voice Commands:
```dart
// Test cases
final testCases = [
  // Sensor queries
  'Nhiệt độ bao nhiêu?',
  'Nhà tôi có nóng không?',
  'Độ ẩm thế nào?',
  'Có mưa không?',
  'Chất lượng không khí ra sao?',
  
  // Device control
  'Bật đèn phòng khách',
  'Tắt quạt',
  'Mở cửa',
];
```

---

## 📊 Prompt Changes Summary

### Added to Prompt:
1. ✅ Sensor data section with current values
2. ✅ Response type classification (device_control vs sensor_query)
3. ✅ Sensor query keywords list
4. ✅ Value interpretation guide (temperature ranges, etc.)
5. ✅ Natural language response examples
6. ✅ Two output JSON formats

### Prompt Size:
- Before: ~800 tokens
- After: ~1200 tokens
- Still within Gemini 2.0 Flash 32k context window ✅

---

## 🎯 Benefits

### 1. Natural Conversation:
```
User: "Nhà tôi có nóng không?"
AI: "Hơi nóng, 29°C. Có thể bật quạt cho mát."
→ User can then say: "Bật quạt đi"
```

### 2. Contextual Responses:
```
User: "Có cần tưới cây không?"
AI: "Độ ẩm đất 25%, khô cần tưới ngay."
→ Suggest action based on sensor data
```

### 3. Multi-sensor Queries:
```
User: "Thời tiết thế nào?"
AI: "Nhiệt độ 26°C mát mẻ, độ ẩm 55% bình thường, không mưa."
→ Combined sensor response
```

### 4. Smart Home Feel:
- User can ask questions, not just give commands
- AI provides context and suggestions
- More natural interaction

---

## 🐛 Error Handling

### No sensor data available:
```dart
if (sensorData == null) {
  return "Chưa có dữ liệu cảm biến. Vui lòng thử lại sau.";
}
```

### Sensor outdated (> 5 minutes):
```dart
final age = DateTime.now().difference(sensorData.timestamp);
if (age.inMinutes > 5) {
  return "Dữ liệu cảm biến đã cũ (${age.inMinutes} phút trước). "
         "Có thể không chính xác.";
}
```

### Sensor value abnormal:
```dart
if (temperature < -10 || temperature > 60) {
  return "Cảm biến nhiệt độ có thể bị lỗi ($temperature°C).";
}
```

---

## 📝 Code Files Changed

1. ✅ `lib/services/ai_voice_service.dart`
   - Added `SensorData` import
   - Added `sensorData` parameter to `processVoiceCommand()`
   - Updated `_buildPrompt()` to include sensor data
   - Updated `_parseAiResponse()` to handle sensor_query type
   - Added `ResponseType` enum
   - Updated `CommandResult` class with new fields
   - Added factory constructors: `CommandResult.deviceControl()`, `CommandResult.sensorQuery()`
   - Added `_formatTime()` helper method

2. 📄 `AI_SENSOR_QUERY_GUIDE.md` (This file)
   - Documentation for new feature
   - Examples and use cases
   - Integration guide

---

## 🎉 Ready to Test!

### Test Sequence:
1. ✅ Update voice control screen to pass `sensorData`
2. ✅ Test device control (should still work)
3. ✅ Test sensor queries with examples above
4. ✅ Check AI response parsing
5. ✅ Verify UI displays text response
6. ✅ Test TTS with sensor responses

---

**Last Updated:** 2024-11-01 23:55 UTC+7
**Feature Status:** ✅ Code Complete - Ready for Integration Testing
**Next:** Update Voice Control Screen UI
