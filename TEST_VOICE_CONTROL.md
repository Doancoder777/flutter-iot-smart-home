# 🧪 TEST VOICE CONTROL - Hướng dẫn kiểm tra

## 📱 Cách test trên app:

### Bước 1: Vào màn hình Voice Control
1. Mở app
2. Vào menu → "Voice Control Example"

### Bước 2: Kiểm tra sensor data
- Xem console log khi gõ câu hỏi
- Tìm dòng: `🔍 Debug: Sensor data = XX°C, XX%`
- Nếu thấy `0.0°C, 0.0%` → **CHƯA CÓ DATA TỪ ESP32**

### Bước 3: Test từng loại câu hỏi

#### ✅ Test 1: Hỏi nhiệt độ
**Input:** "Nhiệt độ bao nhiêu?"

**Expected console log:**
```
🔍 Debug: Sensor data = 28.5°C, 65%
🔍 Debug: Devices = 10
🔍 Debug: Command = "Nhiệt độ bao nhiêu?"
🤖 AI Voice: Processing command: "Nhiệt độ bao nhiêu?"
🤖 AI Voice: Sensor data included: true
✅ AI Voice: Sensor Query - temperature: 28.5
```

**Expected UI:**
```
🌡️ Nhiệt độ: 28.5°C (Ấm)
```

---

#### ✅ Test 2: Hỏi có nóng không
**Input:** "Giờ nhà tôi có nóng không?"

**Expected response:**
```
🌡️ Nhiệt độ: 28.5°C (Ấm)
```

---

#### ✅ Test 3: Hỏi mưa
**Input:** "Trời có mưa không?"

**Expected response:**
```
🌤️ Không mưa
```
HOẶC
```
🌧️ Đang mưa
```

---

#### ✅ Test 4: Bật đèn (Device control)
**Input:** "Bật đèn phòng ngủ"

**Expected response:**
```
✅ Đã bật Đèn phòng ngủ
```

---

## 🐛 Các lỗi thường gặp:

### ❌ Lỗi 1: "Không tìm thấy thiết bị" khi hỏi sensor
**Nguyên nhân:** AI không nhận ra là sensor query

**Console log sẽ thấy:**
```
🤖 AI Voice: Sensor data included: false  ← ❌ SAI! Phải là true
```

**Giải pháp:**
- Kiểm tra keywords trong `_isSensorQuery()` có match không
- Debug: Print ra `needsSensorData` value

---

### ❌ Lỗi 2: Sensor data = 0.0°C, 0.0%
**Nguyên nhân:** ESP32 chưa kết nối hoặc chưa gửi data

**Giải pháp:**
1. Kiểm tra ESP32 đã connect WiFi chưa
2. Kiểm tra ESP32 đã publish MQTT sensor data chưa
3. Vào màn hình Sensors xem có data không

---

### ❌ Lỗi 3: AI timeout
**Console log:**
```
❌ AI Voice: Error - AI request timeout
```

**Giải pháp:**
- Kiểm tra internet connection
- Kiểm tra Gemini API key còn hoạt động không
- Tăng timeout trong `ai_config.dart`:
  ```dart
  static const int requestTimeout = 20000; // Tăng lên 20 giây
  ```

---

### ❌ Lỗi 4: API key invalid
**Console log:**
```
❌ AI Voice: Error - API key not valid
```

**Giải pháp:**
1. Vào https://aistudio.google.com/app/apikey
2. Tạo API key mới
3. Update trong `lib/config/ai_config.dart`

---

## 🧪 Test với fake data (nếu chưa có ESP32):

Tạm thời hardcode fake sensor data để test:

```dart
// Trong voice_control_example_screen.dart
final result = await _aiService.processVoiceCommand(
  userId: authProvider.currentUser!.id,
  voiceCommand: command,
  devices: deviceProvider.devices,
  sensorData: SensorData(
    temperature: 28.5,
    humidity: 65.0,
    rain: 0,
    light: 500,
    soilMoisture: 45,
    gas: 400,
    dust: 35.0,
    motionDetected: false,
    timestamp: DateTime.now(),
  ), // ⬅️ FAKE DATA
);
```

---

## 📊 Test Results Checklist:

- [ ] Sensor data được load từ ESP32
- [ ] Hỏi nhiệt độ → Trả về nhiệt độ + đánh giá
- [ ] Hỏi độ ẩm → Trả về độ ẩm + đánh giá
- [ ] Hỏi mưa → Trả về có/không
- [ ] Bật/tắt thiết bị → Execute thành công
- [ ] Console log đầy đủ
- [ ] Không có error timeout
- [ ] API key hoạt động

---

## 🔍 Debug Command:

Thêm vào đầu `_processCommand()`:

```dart
print('═══════════════════════════════════════');
print('🧪 TEST COMMAND: "$command"');
print('🔍 Sensor Data:');
print('   Temperature: ${sensorData.temperature}°C');
print('   Humidity: ${sensorData.humidity}%');
print('   Rain: ${sensorData.rain}');
print('🔍 Devices: ${deviceProvider.devices.length}');
print('═══════════════════════════════════════');
```

---

## 📞 Nếu vẫn không work:

1. **Copy toàn bộ console log** và gửi cho tôi
2. **Screenshot** màn hình khi test
3. **Cho biết:**
   - ESP32 đã connect chưa?
   - Màn hình Sensors có hiển thị data không?
   - API key có hoạt động không? (test tại https://aistudio.google.com/)
