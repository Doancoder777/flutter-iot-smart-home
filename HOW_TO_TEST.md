# 🧪 HƯỚNG DẪN CHẠY TEST AI VOICE

## 📝 Có 2 script test:

### 1️⃣ **Simple Test** (Dễ nhìn hơn)
```powershell
dart run test/simple_ai_test.dart
```

**Output mẫu:**
```
🧪 AI VOICE SERVICE - SIMPLE TEST
═══════════════════════════════════════════════════════════

📝 TEST 1: Nhiệt độ bao nhiêu?
───────────────────────────────────────────────────────────
🤖 AI Voice: Processing command: "Nhiệt độ bao nhiêu?"
🤖 AI Voice: Available devices: 2
🤖 AI Voice: Sensor data included: true
✅ AI Voice: Sensor Query - temperature: 28.5
📊 RESULT:
   Success: true
   Response Type: ResponseType.sensorQuery
   ├─ Sensor Type: temperature
   └─ Sensor Value: 28.5
   💬 Display: 🌡️ Nhiệt độ: 28.5°C (Ấm)


📝 TEST 2: Giờ nhà tôi có nóng không?
───────────────────────────────────────────────────────────
...
```

---

### 2️⃣ **Flutter Test** (Có assertions)
```powershell
flutter test test/ai_voice_service_test.dart
```

**Output mẫu:**
```
00:01 +0: AI Voice Service Tests Test 1: Sensor Query - Nhiệt độ bao nhiêu?
🧪 TEST 1: Hỏi nhiệt độ
═══════════════════════════════════════
🤖 AI Voice: Processing command: "Nhiệt độ bao nhiêu?"
✅ AI Voice: Sensor Query - temperature: 28.5

📊 RESULT:
Success: true
Response Type: ResponseType.sensorQuery
Sensor Type: temperature
Sensor Value: 28.5

00:02 +1: AI Voice Service Tests Test 2: Sensor Query - Có nóng không?
...
```

---

## 🎯 Test Cases:

✅ **Test 1:** Nhiệt độ bao nhiêu?  
✅ **Test 2:** Giờ nhà tôi có nóng không?  
✅ **Test 3:** Trời có mưa không?  
✅ **Test 4:** Bật đèn phòng ngủ  
✅ **Test 5:** Tắt quạt phòng khách  
✅ **Test 6:** Câu lệnh không hợp lệ  

---

## ⚠️ LƯU Ý:

### Trước khi chạy test:

1. **Kiểm tra API key** trong `lib/config/ai_config.dart`
2. **Có kết nối internet** (để gọi Gemini API)
3. **Đảm bảo pubspec.yaml** đã có dependencies

---

## 🐛 Nếu gặp lỗi:

### ❌ Error: "Target of URI doesn't exist"
**Fix:** Chạy `flutter pub get` trước

### ❌ Error: "API key not valid"
**Fix:** 
1. Vào https://aistudio.google.com/app/apikey
2. Tạo API key mới
3. Update vào `lib/config/ai_config.dart`

### ❌ Error: "Timeout"
**Fix:** Kiểm tra kết nối internet hoặc tăng timeout:
```dart
// lib/config/ai_config.dart
static const int requestTimeout = 20000; // Tăng lên 20s
```

---

## 📊 Kết quả mong đợi:

### ✅ Test PASS khi:
- Sensor Query → trả về `ResponseType.sensorQuery` + `sensorType` + `sensorValue`
- Device Control → trả về `ResponseType.deviceControl` + `deviceKeyName` + `action`
- Format đúng theo JSON schema
- Không có exception

### ❌ Test FAIL khi:
- Result = null
- Success = false
- Có exception
- Response type sai
- Format sai

---

## 🔍 Debug:

Nếu muốn xem chi tiết request/response của AI:

```dart
// Thêm vào ai_voice_service.dart trước khi call API:
print('📤 PROMPT SENT TO AI:');
print(prompt);
print('═══════════════════════════════════════');

// Sau khi nhận response:
print('📥 RAW RESPONSE FROM AI:');
print(response.text);
print('═══════════════════════════════════════');
```

---

## 🚀 Chạy ngay:

```powershell
# Quick test
dart run test/simple_ai_test.dart

# Full test với assertions
flutter test test/ai_voice_service_test.dart

# Chạy tất cả tests
flutter test
```

---

## 💡 TIP:

Nếu muốn test với data khác, sửa ở đầu file:

```dart
// test/simple_ai_test.dart
final sensorData = SensorData(
  temperature: 35.0,  // ⬅️ Thay đổi giá trị ở đây
  humidity: 80.0,
  rain: 1,            // 1 = có mưa
  // ...
);
```

Rồi chạy lại test!
