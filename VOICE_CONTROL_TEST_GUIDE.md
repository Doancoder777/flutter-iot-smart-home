# 🎤 HƯỚNG DẪN TEST VOICE CONTROL

## ✅ ĐÃ HOÀN THÀNH

### 📦 Files đã tạo:
1. ✅ `lib/config/ai_config.dart` - Cấu hình Gemini 2.0 Flash
2. ✅ `lib/services/ai_voice_service.dart` - AI service xử lý commands
3. ✅ `lib/controllers/voice_controller.dart` - Voice recognition controller
4. ✅ `lib/widgets/voice_control_button.dart` - UI button điều khiển bằng giọng nói
5. ✅ `lib/main.dart` - Đã tích hợp VoiceController provider
6. ✅ `lib/screens/home/home_screen.dart` - Đã thêm voice button
7. ✅ `android/app/src/main/AndroidManifest.xml` - Đã thêm permissions

### ⚙️ Permissions đã setup:
- ✅ RECORD_AUDIO - Ghi âm giọng nói
- ✅ MICROPHONE - Truy cập microphone
- ✅ INTERNET - Kết nối Gemini AI

### 🎯 Tính năng:
- ✅ Speech-to-Text (tiếng Việt)
- ✅ AI parsing bằng Gemini 2.0 Flash
- ✅ Auto-match devices từ Firestore
- ✅ Gửi MQTT commands tự động
- ✅ UI animation đẹp

---

## 🧪 CÁCH TEST

### **BƯỚC 1: Build & Chạy App**

```bash
cd C:\Users\sigma\Desktop\DoAn4\flutter-iot-smart-home
flutter clean
flutter pub get
flutter run
```

### **BƯỚC 2: Đăng nhập**

1. Mở app
2. Đăng nhập bằng Google (hasagi35386@gmail.com)
3. Chờ app load danh sách thiết bị từ Firestore

### **BƯỚC 3: Kiểm tra Voice Button**

- Nút voice sẽ xuất hiện ở **giữa bottom** màn hình Home
- Màu xanh = sẵn sàng
- Nếu không thấy → VoiceController chưa initialize

### **BƯỚC 4: Test Voice Commands**

#### **Test 1: Bật thiết bị**
1. Tap nút microphone (xanh)
2. Nói: **"Bật đèn 78"**
3. Đợi processing (nút chuyển cam)
4. Kết quả:
   - ✅ Nút chuyển xanh lá
   - ✅ Hiện "✅ Đã thực hiện: Đèn 78 hasa - Bật"
   - ✅ MQTT gửi lệnh đến broker
   - ✅ ESP32 nhận được lệnh

#### **Test 2: Tắt thiết bị**
1. Tap nút microphone
2. Nói: **"Tắt servo 94"**
3. Kết quả:
   - ✅ Device "Servo 94 hasa" chuyển sang OFF
   - ✅ MQTT publish lệnh tắt

#### **Test 3: Thiết bị không tồn tại**
1. Tap nút microphone
2. Nói: **"Bật quạt phòng bếp"**
3. Kết quả:
   - ❌ Hiện "Không tìm thấy thiết bị"

#### **Test 4: Lệnh không rõ**
1. Tap nút microphone
2. Nói: **"Chào bạn"**
3. Kết quả:
   - ❌ AI trả về error "Không hiểu lệnh"

---

## 📱 MONITORING

### **Check Logs**

```bash
# Theo dõi terminal khi chạy app
# Các log quan trọng:

🎤 Voice Controller: Initializing...
✅ Voice Controller: Initialized successfully
🎤 Voice Controller: Start listening...
✅ Voice Controller: Final result - "Bật đèn 78"
🤖 Voice Controller: Processing command - "Bật đèn 78"
📱 Voice Controller: Available devices - 2
🤖 AI Voice: Processing command: "Bật đèn 78"
🤖 AI Voice: Available devices: 2
🔍 AI Voice: Extracted JSON: {"success": true, "device_key": "den_78_hasa", "action": "turn_on", "value": null}
✅ AI Voice: Success - Device: den_78_hasa, Action: turn_on
📱 Voice Controller: Found device - Đèn 78 hasa (012345)
🎯 Voice Controller: Executing action - turn_on on Đèn 78 hasa
📤 Device MQTT: Published to smart_home/devices/phong78/den_78_hasa: {"action":"turn_on","deviceCode":"012345"}
✅ Voice Controller: Command executed successfully
```

### **Check MQTT (HiveMQ Broker)**

1. Mở MQTT Explorer hoặc HiveMQ Web Client
2. Connect đến broker:
   - `26d1fcc0724b46c495e45a93d79c78d2.s1.eu.hivemq.cloud:8883`
   - Username: `sigma`
   - Password: `35386Doan`
3. Subscribe: `smart_home/devices/#`
4. Nói lệnh → Xem message

---

## 🐛 TROUBLESHOOTING

### **❌ Nút Voice không hiện**

**Nguyên nhân:** VoiceController không initialize

**Fix:**
```dart
// Check trong HomeScreen:
Consumer<VoiceController>(
  builder: (context, voiceController, _) {
    print('Voice initialized: ${voiceController.isInitialized}');
    // ...
  },
)
```

### **❌ Lỗi "Permission denied"**

**Nguyên nhân:** Chưa cấp quyền microphone

**Fix:**
1. Mở Settings → Apps → Smart Home IoT
2. Permissions → Microphone → Allow
3. Restart app

### **❌ Speech recognition không hoạt động**

**Nguyên nhân:** Thiết bị không hỗ trợ hoặc không có internet

**Fix:**
- Kiểm tra kết nối internet
- Test trên thiết bị thật (không phải emulator)
- Check log: `Voice Controller: Initialize failed`

### **❌ AI không hiểu lệnh**

**Nguyên nhân:** 
- Danh sách thiết bị rỗng
- Tên thiết bị không khớp
- Gemini API lỗi

**Fix:**
1. Check devices loaded: `Available devices - 0`
2. Đảm bảo đã đăng nhập và load Firestore
3. Check API key trong `ai_config.dart`

### **❌ MQTT không gửi**

**Nguyên nhân:** DeviceProvider chưa kết nối MQTT

**Fix:**
1. Check MQTT status trong ConnectionStatusBadge
2. Đảm bảo đã connect MQTT broker
3. Check device có mqttConfig không

---

## 📊 TEST CASES

| **Test** | **Voice Command** | **Expected Result** | **MQTT Topic** |
|----------|-------------------|---------------------|----------------|
| ✅ Test 1 | "Bật đèn 78" | Device ON, MQTT sent | `smart_home/devices/phong78/den_78_hasa` |
| ✅ Test 2 | "Tắt đèn 78" | Device OFF, MQTT sent | `smart_home/devices/phong78/den_78_hasa` |
| ✅ Test 3 | "Bật servo 94" | Device ON, MQTT sent | `smart_home/devices/phong_94/sevo_94_hasa` |
| ✅ Test 4 | "Tắt servo 94" | Device OFF, MQTT sent | `smart_home/devices/phong_94/sevo_94_hasa` |
| ❌ Test 5 | "Bật quạt" | Error: Multiple matches | N/A |
| ❌ Test 6 | "Chào bạn" | Error: Không hiểu lệnh | N/A |

---

## 🎯 DANH SÁCH THIẾT BỊ CỦA BẠN

Từ Firestore user `LER44WHITwXBtgbKjV41ZI7jw493`:

1. **Đèn 78 hasa**
   - keyName: `den_78_hasa`
   - deviceCode: `012345`
   - Broker: `26d1fcc0...hivemq.cloud`
   - Voice commands: "Bật đèn 78", "Tắt đèn 78"

2. **Servo 94 hasa**
   - keyName: `sevo_94_hasa`
   - deviceCode: `345678`
   - Broker: `16257efa...hivemq.cloud`
   - Voice commands: "Bật servo 94", "Tắt servo 94"

---

## 🚀 NEXT STEPS

Sau khi test thành công, bạn có thể:

1. **Thêm nhiều commands hơn:**
   - "Đặt độ sáng đèn 50%"
   - "Xoay servo 90 độ"
   - "Bật tất cả đèn"

2. **Improve AI prompt:**
   - Hỗ trợ synonyms (bật = mở = turn on)
   - Group commands
   - Context awareness

3. **Thêm Text-to-Speech:**
   - "Đã bật đèn phòng 78"
   - Voice feedback

4. **Command history:**
   - Hiển thị lịch sử 10 lệnh gần nhất
   - Tap để repeat

---

**🎉 SẴN SÀNG TEST!**

Chạy `flutter run` và thử nói lệnh ngay nhé! 🎤




