# 📋 Cập nhật AI Prompt & MQTT Format Documentation

## ✅ Hoàn thành

### 1. Tạo MQTT Format Documentation (MQTT_FORMAT_DOCUMENTATION.md)
📄 File: `MQTT_FORMAT_DOCUMENTATION.md`

**Nội dung:**
- ✅ So sánh đầy đủ tất cả format MQTT giữa App và Arduino
- ✅ Format gửi từ App → Arduino (4 loại thiết bị)
- ✅ Format nhận từ Arduino → App (sensors + devices)
- ✅ Dual format support explanation
- ✅ Smart publishing strategy
- ✅ GPIO mapping đầy đủ
- ✅ Common issues & solutions
- ✅ Best practices

**Highlights:**
- **LED/Relay**: Hỗ trợ 2 format `{"state": true}` và `{"action": "turn_on"}`
- **Motor/Fan**: Hỗ trợ `{"speed": 0-255}` và alternative `{"action": "turn_on"}` → auto convert
- **Servo**: Format duy nhất `{"angle": 0-180}`
- **PING**: Plain text `"ping"` → response `"1"`

### 2. Cập nhật AI Voice Service Prompt
📄 File: `lib/services/ai_voice_service.dart`

**Thay đổi:**

#### A. Thêm MQTT Format Summary (đầu prompt):
```
═══════════════════════════════════════════════════════════════════
🎯 MQTT FORMAT SUPPORT SUMMARY (Arduino hỗ trợ NHIỀU FORMAT)
═══════════════════════════════════════════════════════════════════
```
- Giải thích luồng: Voice → AI → JSON → App → MQTT → Arduino
- Dual format support overview
- AI output format expectations

#### B. Mở rộng QUY ƯỚC GIÁ TRỊ section:

**RELAY:**
```dart
MQTT Format hỗ trợ:
- turn_on → App gửi: {"state": true} HOẶC {"action": "turn_on"}
- turn_off → App gửi: {"state": false} HOẶC {"action": "turn_off"}

Voice Command:
- "Bật relay" → turn_on, value = null

Arduino nhận: Tự động hỗ trợ CẢ 2 FORMAT (state hoặc action)
```

**ĐÈN:**
```dart
MQTT Format hỗ trợ:
- turn_on → App gửi: {"state": true} HOẶC {"action": "turn_on"}
- turn_off → App gửi: {"state": false} HOẶC {"action": "turn_off"}

Voice Command:
- "Bật đèn" → turn_on, value = null
- "Chỉnh đèn X%" → set_value, value = X (0-100)

Arduino nhận: Tự động hỗ trợ CẢ 2 FORMAT
```

**QUẠT/MOTOR (Chi tiết nhất):**
```dart
MQTT Format hỗ trợ:
- set_value → App gửi: {"speed": X} với X = 0-255 (PWM)
- Alternative → App gửi: {"action": "turn_on"} → Arduino convert thành speed=255
- Alternative → App gửi: {"action": "turn_off"} → Arduino convert thành speed=0

Voice Command (AI trả về % 0-100, App convert sang 0-255):
- "Bật quạt" → set_value, value = 67 (App convert: 67% = 171/255)
- "Tắt quạt" → set_value, value = 0
- "Quạt mạnh/nhanh/cao/full/max" → set_value, value = 100 (→ 255/255)
- "Quạt khá/vừa/medium" → set_value, value = 67 (→ 171/255)
- "Quạt nhẹ/yếu/chậm/thấp/low" → set_value, value = 33 (→ 84/255)
- "Quạt X%" → set_value, value = X (App convert: X% * 255/100)

⚠️ QUAN TRỌNG:
- Quạt LUÔN dùng set_value với value 0-100 (AI output)
- App tự động convert 0-100 → 0-255 trước khi gửi MQTT
- Arduino CHỈ nhận speed 0-255, CHỈ hỗ trợ chiều thuận (forward only)

Arduino Logic (L298N):
- speed > 0: IN1=HIGH, IN2=LOW, PWM=speed (forward)
- speed = 0: IN1=LOW, IN2=LOW, PWM=0 (stop)
- KHÔNG hỗ trợ reverse (tránh lỗi cả 2 LED L298N sáng)
```

**SERVO:**
```dart
MQTT Format:
- set_value → App gửi: {"angle": X} với X = 0-180 degrees

Voice Command:
- "Mở cửa/cổng/rèm/cửa sổ/mái che" → set_value, value = 180
- "Đóng cửa/cổng/rèm/cửa sổ/mái che" → set_value, value = 0
- "Mở một nửa/nửa chừng" → set_value, value = 90

⚠️ QUAN TRỌNG:
- Servo LUÔN dùng set_value với góc cụ thể
- KHÔNG DÙNG turn_on/turn_off cho servo
- Range: 0-180 degrees (chuẩn servo 180°)
```

#### C. Mở rộng VÍ DỤ CHI TIẾT với MQTT flow:

**RELAY Example:**
```dart
Lệnh: "Bật relay phòng khách"
→ AI Output: {"success": true, "device_key": "relay_phong_khach", "action": "turn_on", "value": null}
→ App gửi MQTT: {"state": true} hoặc {"action": "turn_on"}
→ Arduino nhận: Tự động parse CẢ 2 format → digitalWrite(RELAY_PIN, HIGH)
→ Arduino phản hồi: {"state": "ON", "timestamp": 12345678}
```

**QUẠT Example (chi tiết nhất):**
```dart
Lệnh: "Quạt mạnh"
→ AI Output: {"success": true, "device_key": "quat", "action": "set_value", "value": 100}
→ App convert: 100% → 255/255
→ App gửi MQTT: {"speed": 255}
→ Arduino nhận: speed=255 → IN1=HIGH, IN2=LOW, PWM=255 (full speed)
→ Arduino phản hồi: {"speed": 255, "state": true, "timestamp": 12345678}

Lệnh: "Tắt quạt"
→ AI Output: {"success": true, "device_key": "quat", "action": "set_value", "value": 0}
→ App convert: 0% → 0/255
→ App gửi MQTT: {"speed": 0}
→ Arduino nhận: speed=0 → IN1=LOW, IN2=LOW, PWM=0 (stop)
→ Arduino phản hồi: {"speed": 0, "state": false, "timestamp": 12345678}

Alternative format (nếu app dùng action):
Lệnh: "Bật quạt full"
→ App có thể gửi: {"action": "turn_on"}
→ Arduino convert: action="turn_on" → speed=255 (full speed)
```

**SERVO Example:**
```dart
Lệnh: "Mở cửa"
→ AI Output: {"success": true, "device_key": "servo_cua_so", "action": "set_value", "value": 180}
→ App gửi MQTT: {"angle": 180}
→ Arduino nhận: angle=180 → servo.write(180)
→ Arduino phản hồi: {"angle": 180, "state": true, "timestamp": 12345678}
```

#### D. Thêm MQTT Topics & Response Time:
```dart
📌 MQTT TOPICS USED:
- Command (App → Arduino): smart_home/devices/{DEVICE_CODE}/cmd
- State (Arduino → App): smart_home/devices/{DEVICE_CODE}/state
- Ping (Health check): smart_home/devices/{DEVICE_CODE}/ping

📌 RESPONSE TIME:
- Arduino phản hồi state NGAY SAU khi nhận lệnh
- App subscribe topic /state để cập nhật UI real-time
- Ping/pong timeout: 5 seconds (offline detection)
```

---

## 🎯 Lợi ích của cập nhật

### 1. AI hiểu rõ hơn về MQTT flow
- Biết format nào Arduino hỗ trợ
- Hiểu conversion % → PWM (0-100 → 0-255)
- Biết Arduino có dual format support

### 2. Examples chi tiết hơn
- Từ voice command → AI output → MQTT → Arduino logic → Response
- Mỗi bước đều có explain rõ ràng
- Special cases cho Motor/Fan (vì phức tạp nhất)

### 3. Giảm confusion
- Rõ ràng AI chỉ cần output % 0-100
- App lo việc convert format
- Arduino lo việc parse multiple format

### 4. Documentation đầy đủ
- `MQTT_FORMAT_DOCUMENTATION.md` là reference chính
- AI prompt có summary ngắn gọn
- Developer có thể tra cứu chi tiết khi cần

---

## 📊 Format Support Matrix

| Device Type | AI Output | App MQTT Format | Arduino Support |
|------------|-----------|-----------------|-----------------|
| **LED** | turn_on/off | `{"state": true}` | ✅ State format |
|  |  | `{"action": "turn_on"}` | ✅ Action format |
| **Relay** | turn_on/off | `{"state": true}` | ✅ State format |
|  |  | `{"action": "turn_on"}` | ✅ Action format |
| **Motor/Fan** | set_value (0-100%) | `{"speed": 0-255}` | ✅ Speed format |
|  | Alternative | `{"action": "turn_on"}` | ✅ Auto → speed=255 |
| **Servo** | set_value (0-180°) | `{"angle": 0-180}` | ✅ Angle format |

---

## 🔧 Code Changes Summary

### Files Modified:
1. ✅ **MQTT_FORMAT_DOCUMENTATION.md** (NEW)
   - 450+ lines comprehensive documentation
   - All MQTT formats documented
   - GPIO mapping
   - Best practices

2. ✅ **lib/services/ai_voice_service.dart** (UPDATED)
   - Added MQTT Format Summary section
   - Expanded QUY ƯỚC GIÁ TRỊ with MQTT details
   - Enhanced VÍ DỤ CHI TIẾT with full MQTT flow
   - Added topics & response time info

### Lines of Code:
- Documentation: +450 lines
- AI Prompt: +200 lines (expanded)
- Total: ~650 lines of documentation

---

## 🚀 Next Steps

### Testing AI với new prompt:
1. Test voice commands cho từng loại thiết bị
2. Verify AI output format đúng chuẩn
3. Confirm app convert % → PWM correctly
4. Check Arduino handle dual format

### Examples to test:
```
✅ "Bật đèn phòng ngủ"
✅ "Tắt relay"
✅ "Quạt mạnh"
✅ "Quạt nhẹ"
✅ "Tắt quạt"
✅ "Mở cửa"
✅ "Đóng cổng"
✅ "Mở mái che một nửa"
```

---

## 📝 Notes

- AI prompt giờ dài hơn (~800 tokens) nhưng comprehensive hơn rất nhiều
- Gemini 2.0 Flash có 32k context window → không vấn đề
- Trade-off: Token cost tăng nhưng accuracy tăng đáng kể
- Documentation format consistency: Markdown + emojis cho dễ đọc

---

**Last Updated:** 2024-11-01 23:45 UTC+7
**Author:** DoAn4 Team
**Status:** ✅ COMPLETED - Ready for testing
