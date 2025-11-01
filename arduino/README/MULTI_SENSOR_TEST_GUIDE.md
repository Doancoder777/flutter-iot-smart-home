# 🔄 HƯỚNG DẪN TEST ĐA CẢM BIẾN - ROTATION MODE

## 📋 Tổng quan

Code này tự động **chuyển đổi** giữa 3 cảm biến sau mỗi **2 phút**, lặp vô hạn:

```
Dust Sensor (2 phút) → DHT22 (2 phút) → Soil Moisture (2 phút) → Lặp lại
```

---

## 🔌 Kết nối phần cứng

### **1. Dust Sensor GP2Y1010AU0F**
```
GP2Y1010AU0F       ESP32
─────────────────────────
VCC (1)      →     3.3V
GND (2)      →     GND
LED (3)      →     GPIO25
V0 (5)       →     GPIO34
```

**Tụ điện 220μF**: GND ↔ VCC (gần cảm biến)

---

### **2. DHT22 (Nhiệt độ & Độ ẩm)**
```
DHT22          ESP32
─────────────────────
VCC (+)   →    3.3V
DATA      →    GPIO4
GND (-)   →    GND
```

**Điện trở pull-up 10kΩ**: GPIO4 ↔ 3.3V (nếu module không có sẵn)

---

### **3. Soil Moisture Sensor**
```
Soil Sensor    ESP32
─────────────────────
VCC       →    3.3V
A0        →    GPIO32
GND       →    GND
```

---

## 📥 Cài đặt thư viện

### **Arduino IDE (Khuyến nghị)**

1. Vào **Tools** → **Manage Libraries** (hoặc `Ctrl + Shift + I`)
2. Tìm kiếm: **DHT sensor library for ESPx**
3. Chọn thư viện **"DHT sensor library for ESPx"** by **beegee_tokyo**
4. Click **Install**
5. Đợi cài đặt hoàn tất

### **PlatformIO**

Thêm vào `platformio.ini`:
```ini
lib_deps = 
    beegee-tokyo/DHT sensor library for ESPx@^1.19
```

### **Hoặc cài từ GitHub**

```bash
cd Arduino/libraries/
git clone https://github.com/beegee-tokyo/DHTesp.git
```

---

## 🚀 Sử dụng

### **1. Upload code**

1. Mở file `Multi_Sensor_Rotation_Test.ino` trong Arduino IDE
2. Chọn board: **ESP32 Dev Module**
3. Chọn Port (COM)
4. Click **Upload**

### **2. Mở Serial Monitor**

- Baud rate: **115200**
- Line ending: **Both NL & CR** (hoặc bất kỳ)

---

## 📺 Output mẫu

### **Khởi động:**
```
╔════════════════════════════════════════════════╗
║   MULTI SENSOR ROTATION TEST - ESP32          ║
║   2 minutes per sensor                         ║
╚════════════════════════════════════════════════╝

✅ All sensors initialized!
🔄 Rotation cycle: Dust → DHT22 → Soil → repeat

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  🎯 ACTIVE: DUST SENSOR             ┃
┃  Pin: GPIO25 (LED), GPIO34 (ADC)   ┃
┃  ⏱️  Time remaining: 120 seconds     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### **Dust Sensor (2 phút đầu):**
```
┌─────────────────────────────────────┐
│  💨 DUST SENSOR (GP2Y1010AU0F)     │
├─────────────────────────────────────┤
│  Raw ADC:        1234              │
│  Voltage:        0.992 V           │
│  Dust Density:   0.784 mg/m³       │
│  Air Quality:    VERY POOR         │
└─────────────────────────────────────┘
```

### **DHT22 (2 phút tiếp theo):**
```
┌─────────────────────────────────────┐
│  🌡️ DHT22 SENSOR                    │
├─────────────────────────────────────┤
│  Temperature:    28.5 °C           │
│  Humidity:       65.2 %            │
│  Heat Index:     30.1 °C           │
│  Status:         HUMID             │
└─────────────────────────────────────┘
```

### **Soil Moisture (2 phút cuối):**
```
┌─────────────────────────────────────┐
│  💧 SOIL MOISTURE SENSOR            │
├─────────────────────────────────────┤
│  Raw ADC:        2048              │
│  Moisture:       50.0 %            │
│  Status:         MOIST             │
└─────────────────────────────────────┘
```

### **Chuyển sensor:**
```
═══════════════════════════════════════════════
        🔄 SWITCHING TO NEXT SENSOR
═══════════════════════════════════════════════

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  🎯 ACTIVE: DHT22 SENSOR            ┃
┃  Pin: GPIO4                         ┃
┃  ⏱️  Time remaining: 120 seconds     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## ⚙️ Cấu hình

### **Thay đổi thời gian rotation:**

Sửa dòng 34:
```cpp
const unsigned long SENSOR_INTERVAL = 120000; // 2 phút

// Ví dụ khác:
// 60000  = 1 phút
// 180000 = 3 phút
// 300000 = 5 phút
```

### **Thay đổi tần suất đọc:**

Sửa dòng 37:
```cpp
const unsigned long READ_INTERVAL = 2000; // Đọc mỗi 2 giây

// Ví dụ khác:
// 1000 = 1 giây
// 5000 = 5 giây
```

### **Thay đổi thứ tự sensors:**

Sửa hàm `loop()` - dòng 61:
```cpp
switch (currentSensor) {
  case 0:
    readDHT22();        // Bắt đầu với DHT22
    break;
  case 1:
    readSoilMoisture(); // Tiếp theo Soil
    break;
  case 2:
    readDustSensor();   // Cuối cùng Dust
    break;
}
```

---

## 🎯 Chỉ số đánh giá

### **Dust Sensor (Bụi mịn PM2.5)**

| Mức độ | Giá trị (mg/m³) | Đánh giá |
|--------|----------------|----------|
| EXCELLENT | < 0.05 | Không khí rất sạch |
| GOOD | 0.05 - 0.15 | Không khí tốt |
| MODERATE | 0.15 - 0.25 | Chấp nhận được |
| POOR | 0.25 - 0.35 | Kém |
| VERY POOR | > 0.35 | Rất kém, cần lọc không khí |

### **DHT22 (Độ ẩm)**

| Mức độ | Giá trị (%) | Đánh giá |
|--------|------------|----------|
| DRY | < 30% | Quá khô |
| COMFORTABLE | 30-60% | Thoải mái |
| HUMID | 60-80% | Ẩm |
| VERY HUMID | > 80% | Rất ẩm |

### **Soil Moisture**

| Mức độ | Giá trị (%) | Đánh giá |
|--------|------------|----------|
| DRY | < 30% | Cần tưới nước |
| MOIST | 30-70% | Độ ẩm tốt |
| WET | > 70% | Quá ẩm |

---

## 🐛 Troubleshooting

### **DHT22 báo lỗi "Failed to read"**

✅ **Giải pháp:**
- Kiểm tra kết nối VCC, GND, DATA
- Thêm điện trở pull-up 10kΩ giữa DATA và 3.3V
- Đợi 2 giây sau khi khởi động để DHT22 ổn định

### **Dust sensor luôn cho giá trị 0**

✅ **Giải pháp:**
- Kiểm tra tụ điện 220μF đã gắn đúng chưa
- Kiểm tra LED có sáng không (GPIO25)
- Thử thay đổi pin VO từ GPIO34 sang GPIO36

### **Soil moisture luôn hiển thị 100%**

✅ **Giải pháp:**
- Sensor đang ngập nước hoặc 2 chân chạm nhau
- Raw ADC = 0 → 100%, Raw ADC = 4095 → 0%
- Kiểm tra kết nối A0 → GPIO32

---

## 📊 Timeline mẫu

```
00:00 - 02:00  →  💨 Dust Sensor
02:00 - 04:00  →  🌡️ DHT22
04:00 - 06:00  →  💧 Soil Moisture
06:00 - 08:00  →  💨 Dust Sensor (lặp lại)
08:00 - 10:00  →  🌡️ DHT22
...
```

---

## 💡 Tip

- Code này **KHÔNG có WiFi/MQTT** để tránh conflict với ADC2
- Nếu cần MQTT, sử dụng code riêng cho từng sensor
- Để debug, giảm `SENSOR_INTERVAL` xuống 30000 (30 giây)
- Serial Monitor có thể bị flood - tăng buffer size nếu cần

---

**🎉 Chúc test vui vẻ!**

