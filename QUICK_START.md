# 🚀 HƯỚNG DẪN CHẠY ỨNG DỤNG NHANH

## ⚡ Bước 1: Kiểm tra môi trường

```bash
flutter doctor
```

Đảm bảo tất cả check marks ✓ cho:
- Flutter (Channel stable)
- Android toolchain
- VS Code / Android Studio

---

## 📦 Bước 2: Cài đặt dependencies

```bash
cd C:\Users\sigma\Desktop\DoAn_Flutter_IOT\version3
flutter pub get
```

---

## 🔧 Bước 3: Fix possible issues (Nếu có lỗi)

### Nếu thiếu package:
```bash
flutter pub add provider
flutter pub add mqtt_client
flutter pub add shared_preferences
flutter pub add flutter_local_notifications
flutter pub add intl
flutter pub add shimmer
```

### Nếu có lỗi build:
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

---

## 📱 Bước 4: Chạy app

### Chạy trên emulator:
```bash
flutter run
```

### Chạy trên device thật (USB debugging):
```bash
# Kết nối điện thoại qua USB
# Bật USB Debugging trong Developer Options
flutter devices  # Kiểm tra device
flutter run
```

### Build APK:
```bash
flutter build apk --release
# APK sẽ ở: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔌 Bước 5: Kết nối ESP32

### 5.1. Upload code Arduino lên ESP32
1. Mở Arduino IDE
2. Mở file `version2/version2.ino` hoặc code ESP32 của bạn
3. Chọn Board: "ESP32 Dev Module"
4. Chọn Port: COM port của ESP32
5. Click Upload

### 5.2. Kiểm tra ESP32 kết nối WiFi
- Mở Serial Monitor (115200 baud)
- Xem log: "Connected to WiFi" và "MQTT Connected"

### 5.3. Kiểm tra Flutter app
- Mở app
- Vào Settings → MQTT Settings
- Xem status: "Đã kết nối" (màu xanh)

---

## 📊 Bước 6: Test các chức năng

### Test Sensors:
1. Mở tab "Cảm biến"
2. Xem data real-time từ ESP32:
   - Nhiệt độ (°C)
   - Độ ẩm (%)
   - Ánh sáng (lux)
   - Độ ẩm đất (%)
   - Khí gas (ppm)
   - Bụi (µg/m³)
   - Mưa (Yes/No)
   - Chuyển động (Detected/Clear)

### Test Devices:
1. Mở tab "Thiết bị"
2. Toggle switches:
   - Máy bơm (ON/OFF)
   - Đèn phòng khách (ON/OFF)
   - Đèn sân (ON/OFF)
   - Máy phát ion (ON/OFF)
3. Slide servos:
   - Cửa trần (0°-180°)
   - Cửa cổng (0°-180°)
4. Xem ESP32 thực hiện lệnh (check relay/servo)

### Test Automation:
1. Mở tab "Tự động"
2. Tạo rule mới:
   - Condition: "Nếu nhiệt độ > 30°C"
   - Action: "Bật quạt"
3. Enable rule
4. Xem rule tự động chạy khi điều kiện đúng

---

## 🎨 Bước 7: Tùy chỉnh giao diện

### Đổi theme:
1. Settings → Giao diện
2. Chọn "Chế độ sáng" hoặc "Chế độ tối"

### Cấu hình notifications:
1. Settings → Cài đặt thông báo
2. Bật/tắt các loại thông báo:
   - Cảnh báo khí gas
   - Cảnh báo bụi
   - Cảnh báo mưa
   - Cảnh báo chuyển động

---

## 🐛 Troubleshooting

### App không kết nối MQTT:
```
❌ Lỗi: "MQTT Connection Failed"
✅ Fix:
1. Kiểm tra WiFi điện thoại có internet
2. Kiểm tra broker: 16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud
3. Port: 8883 (SSL/TLS)
4. Username: sigma
5. Password: 35386Doan
```

### Sensors không update:
```
❌ Lỗi: Giá trị cảm biến không đổi
✅ Fix:
1. Kiểm tra ESP32 đang publish: Serial Monitor shows "Published"
2. Kiểm tra topic đúng: smart_home/sensors/*
3. Restart app và ESP32
```

### Devices không phản hồi:
```
❌ Lỗi: Bật/tắt device không hoạt động
✅ Fix:
1. Kiểm tra ESP32 subscribe đúng topic: smart_home/controls/*
2. Kiểm tra wiring GPIO (relay/servo)
3. Check payload format: "1" = ON, "0" = OFF, "90" = servo angle
```

### Build APK failed:
```
❌ Lỗi: Gradle build failed
✅ Fix:
1. flutter clean
2. flutter pub get
3. flutter build apk --release --no-tree-shake-icons
```

---

## 📝 Các lệnh hữu ích

### Kiểm tra lỗi:
```bash
flutter analyze
```

### Hot reload (khi đang chạy):
```
Press 'r' in terminal
```

### Hot restart:
```
Press 'R' in terminal
```

### Xem logs:
```bash
flutter logs
```

### Kiểm tra devices:
```bash
flutter devices
```

### Update Flutter:
```bash
flutter upgrade
```

---

## 🎯 Kiểm tra hoàn tất

- [ ] Flutter doctor: Tất cả ✓
- [ ] Dependencies installed: `flutter pub get` thành công
- [ ] App chạy được: `flutter run` không lỗi
- [ ] ESP32 kết nối WiFi: Serial Monitor hiển thị "MQTT Connected"
- [ ] MQTT connection: App hiển thị "Đã kết nối"
- [ ] Sensors hiển thị data: Giá trị thay đổi theo thực tế
- [ ] Devices hoạt động: Relay bật/tắt, Servo quay
- [ ] Automation rules work: Rules tự động trigger
- [ ] Theme switching: Dark/Light mode đổi được
- [ ] Notifications: Alerts hiển thị khi có warning

---

## 🎉 Hoàn thành!

App đã sẵn sàng! Bạn có thể:
1. ✅ Monitor sensors real-time
2. ✅ Control devices remotely
3. ✅ Setup automation rules
4. ✅ Customize settings
5. ✅ Build APK để cài trên điện thoại

**Chúc may mắn với đồ án! 🚀**

---

## 📞 Support

Nếu gặp vấn đề:
1. Kiểm tra `PROJECT_DOCUMENTATION.md` để hiểu chi tiết architecture
2. Xem code comments trong các file providers/services
3. Check HiveMQ Cloud console để debug MQTT messages
4. Review ESP32 Serial Monitor để xem hardware logs

**Version**: 3.0.0  
**Ready to deploy**: ✅
