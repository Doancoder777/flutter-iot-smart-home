# 🐛 DEBUG VOICE CONTROL - Khắc phục lỗi "Không tìm thấy thiết bị"

## ❌ VẤN ĐỀ:
Hỏi "Nhiệt độ bao nhiêu?" → AI trả về "Không tìm thấy thiết bị, null"

---

## 🔍 NGUYÊN NHÂN CÓ THỂ:

### 1️⃣ **App cũ chưa có code mới**
- Bạn đã build lại app sau khi code được update chưa?
- APK cũ không có logic xử lý sensor query

### 2️⃣ **Sensor data = 0 (ESP32 chưa gửi)**
- Kiểm tra màn hình Sensors có data không
- Nếu tất cả = 0 → ESP32 chưa kết nối

### 3️⃣ **AI không nhận ra câu hỏi**
- Keywords không match
- Prompt không rõ ràng

---

## ✅ CÁCH FIX:

### BƯỚC 1: Build app mới với code đã update

```powershell
# Chạy script build tự động
.\build_and_install.ps1

# HOẶC manual:
flutter build apk --release
flutter install
```

**⚠️ QUAN TRỌNG:** Phải build lại app vì code đã thay đổi!

---

### BƯỚC 2: Kiểm tra debug logs

Sau khi cài app mới, kết nối phone qua USB và chạy:

```powershell
# Xem logs real-time
flutter logs

# HOẶC filter để dễ nhìn:
flutter logs | Select-String "DEBUG INFO"
```

**Expected output khi bạn test voice control:**

```
═══════════════════════════════════════
🔍 DEBUG INFO:
   Command: "Nhiệt độ bao nhiêu?"
   User ID: abc123
   Devices count: 10
   Sensor data:
      Temperature: 28.5°C         ← ✅ Phải có giá trị thực
      Humidity: 65%               ← ✅ Không phải 0
      Rain: 0
      Gas: 400 ppm
      Dust: 35
═══════════════════════════════════════
🤖 AI Voice: Processing command: "Nhiệt độ bao nhiêu?"
🤖 AI Voice: Available devices: 10
🤖 AI Voice: Sensor data included: true    ← ✅ Phải là true
💰 Token saved: 0
✅ AI Voice: Sensor Query - temperature: 28.5
═══════════════════════════════════════
📥 AI RESULT:
   Success: true                          ← ✅ Phải là true
   Response Type: ResponseType.sensorQuery
   Sensor Type: temperature
   Sensor Value: 28.5
═══════════════════════════════════════
```

---

### BƯỚC 3: Kiểm tra sensor data có từ ESP32 chưa

**Vào màn hình Sensors trong app:**

#### ✅ NẾU CÓ DATA (OK):
```
Temperature: 28.5°C
Humidity: 65%
Gas: 400 ppm
```
→ Sensor data OK, AI sẽ hoạt động

#### ❌ NẾU TẤT CẢ = 0 (LỖI):
```
Temperature: 0.0°C
Humidity: 0.0%
Gas: 0 ppm
```
→ **ESP32 chưa gửi data** → Cần kết nối ESP32 trước!

---

### BƯỚC 4: Test với FAKE DATA (nếu chưa có ESP32)

Nếu bạn chưa có ESP32 để test, tạm thời hardcode fake data:

**File:** `lib/screens/voice_control/voice_control_example_screen.dart`

Sửa dòng 220:

```dart
// OLD: Dùng data thực từ provider
sensorData: sensorProvider.currentData,

// NEW: Dùng fake data để test
sensorData: SensorData(
  temperature: 28.5,
  humidity: 65.0,
  rain: 0,
  light: 500,
  soilMoisture: 45,
  gas: 400,
  dust: 35,
  motionDetected: false,
  timestamp: DateTime.now(),
),
```

Sau đó build lại:
```powershell
flutter build apk --release
flutter install
```

---

## 🧪 TEST CHECKLIST:

Sau khi build app mới, test theo thứ tự:

- [ ] **1. Kiểm tra app đã cài phiên bản mới chưa**
  - Xem version number hoặc timestamp file APK
  
- [ ] **2. Vào màn hình Sensors**
  - Có data thực từ ESP32? (không phải 0)
  
- [ ] **3. Vào Voice Control**
  - Gõ: "Nhiệt độ bao nhiêu?"
  
- [ ] **4. Xem logs trên terminal**
  - `flutter logs | Select-String "DEBUG INFO"`
  - Check sensor data có được gửi đến AI không
  
- [ ] **5. Xem response**
  - Success = true?
  - Response Type = sensorQuery?
  - Có hiển thị nhiệt độ không?

---

## 📊 SO SÁNH KẾT QUẢ:

### ❌ APP CŨ (TRƯỚC KHI SỬA):
```
Input: "Nhiệt độ bao nhiêu?"
→ AI: "Không tìm thấy thiết bị, null"
→ Lý do: Không có logic xử lý sensor query
```

### ✅ APP MỚI (SAU KHI SỬA):
```
Input: "Nhiệt độ bao nhiêu?"
→ AI: { sensor_type: "temperature", value: 28.5 }
→ UI: "🌡️ Nhiệt độ: 28.5°C (Ấm)"
```

---

## 🔧 TROUBLESHOOTING:

### Vấn đề 1: "Sensor data included: false"
```
🤖 AI Voice: Sensor data included: false  ← ❌ SAI!
```

**Nguyên nhân:** Keyword "nhiệt độ" không match trong `_isSensorQuery()`

**Fix:** Kiểm tra file `lib/services/ai_voice_service.dart` line 516:
```dart
final sensorKeywords = [
  'nhiệt độ',  // ← Phải có
  'bao nhiêu',
  // ...
];
```

---

### Vấn đề 2: Sensor data = 0.0
```
🔍 Debug: Sensor data = 0.0°C, 0.0%  ← ❌ KHÔNG CÓ DATA
```

**Giải pháp:**
1. Kiểm tra ESP32 đã connect WiFi chưa
2. Kiểm tra ESP32 đã publish MQTT chưa
3. Dùng FAKE DATA để test tạm (xem Bước 4 ở trên)

---

### Vấn đề 3: AI timeout
```
❌ AI Voice: Error - AI request timeout
```

**Giải pháp:**
1. Kiểm tra internet connection
2. Kiểm tra API key còn hoạt động không
3. Tăng timeout trong `lib/config/ai_config.dart`:
```dart
static const int requestTimeout = 20000; // 20 giây
```

---

## 🚀 QUICK FIX COMMANDS:

```powershell
# 1. Clean build
flutter clean
flutter pub get

# 2. Build mới
flutter build apk --release

# 3. Install
flutter install

# 4. Xem logs
flutter logs | Select-String "DEBUG"
```

---

## 📞 NẾU VẪN KHÔNG WORK:

**Copy và gửi cho tôi:**

1. **Console logs** khi bạn test voice control
   ```
   flutter logs > logs.txt
   ```

2. **Sensor data từ màn hình Sensors**
   - Screenshot hoặc ghi lại giá trị

3. **Thông tin:**
   - ESP32 đã kết nối chưa?
   - App version (xem timestamp APK file)
   - Câu lệnh bạn test

---

## ✅ CHECKLIST CUỐI CÙNG:

Trước khi báo lỗi, đảm bảo:

- [x] Đã build app mới sau khi code update
- [x] Đã cài app mới lên phone
- [x] Đã kiểm tra sensor data có từ ESP32 (không phải 0)
- [x] Đã xem logs khi test voice control
- [x] Đã thử với fake data nếu chưa có ESP32

---

**Bây giờ chạy lệnh này để build app mới:**

```powershell
.\build_and_install.ps1
```

Hoặc:

```powershell
flutter build apk --release
flutter install
```

Rồi test lại và gửi logs cho tôi! 📱
