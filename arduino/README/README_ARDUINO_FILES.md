# 📁 **THƯ MỤC ARDUINO CODE**

## ⚠️ **LƯU Ý QUAN TRỌNG**

Thư mục này chứa **code Arduino (ESP32)**, **KHÔNG PHẢI code Flutter/Dart!**

```
arduino/           ← Thư mục này
├── *.ino          ← Arduino sketch files (C++)
├── *.md           ← Tài liệu hướng dẫn
└── .flutterignore ← File ignore để Flutter bỏ qua
```

---

## 🚫 **FLUTTER SẼ BỎ QUA THƯ MỤC NÀY**

File `.flutterignore` đã được tạo để **Flutter build KHÔNG xử lý** các file `.ino` trong thư mục này.

**Khi build Flutter:**
```bash
flutter build apk
flutter build ios
flutter run
```

→ Flutter sẽ **BỎ QUA** tất cả file `.ino` trong `arduino/`  
→ **KHÔNG CÓ LỖI** compile Arduino code

---

## 📋 **DANH SÁCH FILE ARDUINO**

### **🧪 File Test Chính:**

| File | Mô tả | Thiết bị |
|------|-------|----------|
| **`17_Complete_All_Devices_Test.ino`** | **Test đầy đủ tất cả** | 6 sensors + 10 actuators |
| `16_Full_System_Test.ino` | Test PIR + LED + Servo + Motor | 5 LED + 2 Servo + 2 Motor |
| `13_Complete_Test.ino` | Test PIR + LED + Servo + Motor | Tương tự 16 |

### **📡 File Test Cảm Biến:**

| File | Cảm biến | GPIO |
|------|----------|------|
| `01_DHT22_Test.ino` | DHT22 (Nhiệt độ & độ ẩm) | GPIO4 |
| `02_MQ2_Gas_Test.ino` | MQ-2 (Khí gas) | GPIO34 |
| `03_Rain_Sensor_Test.ino` | Rain Sensor (Mưa) | GPIO35 |
| `04_Soil_Moisture_Test.ino` | Soil Moisture (Độ ẩm đất) | GPIO32 |
| `05_GP2Y_Dust_Test.ino` | GP2Y1010AU0F (Bụi mịn) | GPIO25, 36 |
| `06_PIR_Motion_Test.ino` | PIR (Chuyển động) | GPIO33 |
| `Multi_Sensor_Rotation_Test.ino` | Test nhiều sensor luân phiên | - |

### **⚙️ File Test Actuator:**

| File | Actuator | GPIO |
|------|----------|------|
| `07_Servo_Test.ino` | Servo SG90 | GPIO22, 23 |
| `08_Fan_L298N_Test.ino` | Motor L298N (Fan) | GPIO14, 26, 27 |
| `09_LED_Light_Test.ino` | LED | GPIO5, 18, 19, 21 |
| `10_Relay_Test.ino` | Relay | GPIO26, 27 |
| `14_LED_Test_Simple.ino` | Test LED đơn giản | GPIO5, 18, 19, 21, 13 |
| `15_LED_Always_ON.ino` | LED sáng liên tục | GPIO5, 18, 19, 21, 13 |

### **🎨 File Khác:**

| File | Mô tả |
|------|-------|
| `11_PIR_4LED_Test.ino` | PIR + 4 LED |
| `12_PIR_LED_2Servo_Test.ino` | PIR + 5 LED + 2 Servo |
| `SmartHome_MultiDevice_ESP32.ino` | Multi-device MQTT |

---

## 🔧 **CÁCH SỬ DỤNG ARDUINO CODE**

### **Bước 1: Mở Arduino IDE**

```
1. Tải Arduino IDE: https://www.arduino.cc/en/software
2. Cài board ESP32:
   - File → Preferences
   - Additional Board URLs:
     https://dl.espressif.com/dl/package_esp32_index.json
3. Tools → Board → ESP32 Arduino → ESP32 Dev Module
```

### **Bước 2: Cài thư viện**

```
Tools → Manage Libraries → Tìm và cài:
- ESP32Servo
- DHT sensor library for ESPx
- PubSubClient (cho MQTT)
- ArduinoJson
```

### **Bước 3: Upload code**

```
1. Mở file .ino trong thư mục arduino/
2. Chọn port: Tools → Port → COM_X
3. Click Upload (mũi tên →)
4. Mở Serial Monitor (Ctrl+Shift+M)
5. Chọn baud rate: 115200
```

---

## 📚 **TÀI LIỆU HƯỚNG DẪN**

| File | Nội dung |
|------|----------|
| `VOLTAGE_GUIDE.md` | Hướng dẫn điện áp cho tất cả thiết bị |
| `COMPLETE_SYSTEM_WIRING.md` | Sơ đồ kết nối hệ thống hoàn chỉnh |
| `PIR_LED_WIRING.md` | Kết nối PIR + LED |
| `SENSOR_RELAY_WIRING.md` | Kết nối Sensor + Relay |
| `MULTI_SENSOR_TEST_GUIDE.md` | Hướng dẫn test multi-sensor |
| `RELAY_TEST_GUIDE.md` | Hướng dẫn test relay |
| `LED_TROUBLESHOOTING.md` | Khắc phục lỗi LED |

---

## ⚡ **NGUỒN ĐIỆN YÊU CẦU**

```
Hệ thống 5V:
- ESP32 + Sensors + LED + Servo + Relay
- Dòng: ~1.2A (normal), ~2A (worst)
- Khuyến nghị: Adapter 5V/2A hoặc Nguồn Pi 5 (5V/5A) ✅

Hệ thống 12V:
- 2 Motors L298N
- Dòng: ~1A (normal), ~4A (worst)
- Khuyến nghị: Adapter 12V/2A
```

---

## 🎯 **FILE NÀO NÊN DÙNG?**

### **Cho người mới bắt đầu:**

```
Bước 1: Test từng cảm biến
→ Dùng: 01_DHT22_Test.ino
→ Dùng: 02_MQ2_Gas_Test.ino
→ Dùng: 03_Rain_Sensor_Test.ino
... (từng file riêng)

Bước 2: Test LED đơn giản
→ Dùng: 14_LED_Test_Simple.ino

Bước 3: Test LED sáng liên tục
→ Dùng: 15_LED_Always_ON.ino
```

### **Cho người đã có kinh nghiệm:**

```
Test luôn full hệ thống:
→ Dùng: 17_Complete_All_Devices_Test.ino ⭐
```

---

## 🚀 **TÍCH HỢP VỚI FLUTTER APP**

### **Arduino ESP32 (file này):**
- Đọc sensor
- Điều khiển actuator
- Gửi/nhận MQTT

### **Flutter App (thư mục `lib/`):**
- UI hiển thị
- Gửi/nhận MQTT
- Firestore sync
- Voice control (Gemini AI)

### **Kết nối:**

```
ESP32 ←→ MQTT Broker ←→ Flutter App
(Arduino)   (HiveMQ)    (Dart)
```

---

## ⚠️ **QUAN TRỌNG**

1. **Thư mục này CHỈ cho ESP32**, không build với Flutter!
2. File `.flutterignore` đảm bảo Flutter bỏ qua `*.ino`
3. Upload Arduino code qua **Arduino IDE**, không phải Flutter
4. Flutter app ở thư mục `lib/`, Arduino ở thư mục `arduino/`

---

**📖 Đọc kỹ `VOLTAGE_GUIDE.md` trước khi kết nối phần cứng!**

**🔌 Đảm bảo GND chung giữa tất cả nguồn điện!**

**⚡ An toàn điện = Dự án thành công!** 🚀

