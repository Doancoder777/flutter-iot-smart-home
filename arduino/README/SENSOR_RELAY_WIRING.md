# 🔌 **SƠ ĐỒ KẾT NỐI - 4 SENSORS + 2 RELAY**

## 📋 **TỔNG QUAN**

### **Sensors:**
1. 💨 **GP2Y1010AU0F** (Dust Sensor) - GPIO25, GPIO34
2. 🌡️ **DHT22** (Temperature & Humidity) - GPIO4
3. 💧 **Soil Moisture** - GPIO32
4. 🌧️ **Rain Sensor** - GPIO35

### **Actuators:**
1. ⚡ **Relay 1** - GPIO26 (điều khiển theo mưa)
2. ⚡ **Relay 2** - GPIO27 (điều khiển theo độ ẩm đất)

---

## 🔌 **SƠ ĐỒ KẾT NỐI CHI TIẾT**

```
┌──────────────────────────────────────────────────────┐
│                   USB 5V (500mA+)                     │
└────────────┬─────────────────────────────────────────┘
             │
        ┌────┴────┐
        │  ESP32  │
        │  38-Pin │
        ├─────────┤
        │         │
 VIN ───┤ 5V ─────┼──┬────── GP2Y VCC (bụi mịn)
        │         │  │
        │ 3.3V ───┼──┼──┬─── DHT22 VCC
        │         │  │  │
        │         │  │  ├─── Soil Sensor VCC
        │         │  │  │
        │         │  │  └─── Rain Sensor VCC
        │         │  │
        │         │  │
        │ GPIO4 ──┼──┘  (DHT22 DATA)
        │         │
        │ GPIO25 ─┼────────  GP2Y LED
        │ GPIO34 ─┼────────  GP2Y V0 (analog)
        │         │
        │ GPIO32 ─┼────────  Soil A0 (analog)
        │ GPIO35 ─┼────────  Rain A0 (analog)
        │         │
        │ GPIO26 ─┼────────  Relay 1 IN
        │ GPIO27 ─┼────────  Relay 2 IN
        │         │
        │ GND ────┼──┬──────  Common GND
        │         │  │
        │ 5V ─────┼──┴──┬───  Relay Module VCC
        │         │     │
        │         │     └───  Relay Module VCC
        │         │
        └─────────┘
```

---

## 📍 **KẾT NỐI TỪNG THIẾT BỊ**

### **1. GP2Y1010AU0F (Dust Sensor)**

```
GP2Y1010AU0F    ESP32      Tụ 220μF
─────────────────────────────────────
VCC (pin 1)  →  5V         + (gần VCC)
GND (pin 2)  →  GND        - (gần GND)
LED (pin 3)  →  GPIO25
V0  (pin 5)  →  GPIO34
```

**Lưu ý:**
- Tụ 220μF **BẮT BUỘC** giữa VCC và GND (gần cảm biến)
- VCC dùng 5V để độ nhạy tối đa

---

### **2. DHT22 (Temperature & Humidity)**

```
DHT22         ESP32       Điện trở
────────────────────────────────────
VCC (+)   →   3.3V
DATA      →   GPIO4       10kΩ pull-up (DATA ↔ 3.3V)
NC        →   (không nối)
GND (-)   →   GND
```

**Lưu ý:**
- Module DHT22 thường có sẵn điện trở pull-up
- Nếu dùng sensor rời, cần thêm điện trở 4.7kΩ - 10kΩ

---

### **3. Soil Moisture Sensor**

```
Soil Sensor    ESP32
─────────────────────
VCC       →    3.3V  ⚠️ BẮT BUỘC 3.3V!
A0        →    GPIO32
GND       →    GND
```

**⚠️ QUAN TRỌNG:**
- **CHỈ DÙNG 3.3V** cho VCC
- Nếu dùng 5V → Output 5V → **HƯ HỎNG ESP32!**

---

### **4. Rain Sensor**

```
Rain Sensor    ESP32
─────────────────────
VCC       →    3.3V  ⚠️ BẮT BUỘC 3.3V!
A0        →    GPIO35
GND       →    GND
```

**⚠️ QUAN TRỌNG:**
- Giống Soil Sensor, **CHỈ DÙNG 3.3V**
- GPIO35 là **Input Only** (ADC1_7)

---

### **5. Relay Module (2 channels)**

```
Relay Module    ESP32       Thiết bị điều khiển
──────────────────────────────────────────────────
VCC         →   5V
GND         →   GND
IN1         →   GPIO26      Relay 1 (mưa)
IN2         →   GPIO27      Relay 2 (độ ẩm đất)

COM1        →   Nguồn điện thiết bị 1
NO1         →   Thiết bị 1 (thường hở)
NC1         →   (không dùng)

COM2        →   Nguồn điện thiết bị 2
NO2         →   Thiết bị 2 (thường hở)
NC2         →   (không dùng)
```

**Lưu ý:**
- **VCC Relay = 5V** (không phải 3.3V!)
- Relay module có optocoupler → an toàn
- NO = Normally Open (thường hở)
- NC = Normally Closed (thường đóng)

---

## ⚡ **LOGIC ĐIỀU KHIỂN RELAY**

### **Relay 1 (GPIO26) - Điều khiển theo mưa:**

```
┌──────────────────┬────────────┬─────────────────┐
│  Tình trạng      │  Rain %    │  Relay 1        │
├──────────────────┼────────────┼─────────────────┤
│  ☀️ Nắng         │  < 20%     │  OFF (phun nước)│
│  🌦️ Mưa phùn     │  20-40%    │  OFF            │
│  🌧️ Mưa vừa      │  40-70%    │  ON (tắt phun)  │
│  ⛈️ Mưa to        │  > 70%     │  ON (tắt phun)  │
└──────────────────┴────────────┴─────────────────┘

Logic: Khi mưa > 40% → BẬT relay → TẮT hệ thống phun nước
```

### **Relay 2 (GPIO27) - Điều khiển theo độ ẩm đất:**

```
┌──────────────────┬────────────┬─────────────────┐
│  Tình trạng      │  Soil %    │  Relay 2        │
├──────────────────┼────────────┼─────────────────┤
│  🏜️ Khô           │  < 30%     │  ON (tưới nước) │
│  🌱 Ẩm vừa        │  30-60%    │  Giữ nguyên     │
│  💧 Ẩm            │  > 60%     │  OFF (ngừng)    │
└──────────────────┴────────────┴─────────────────┘

Logic: 
- Đất khô < 30% → BẬT relay → TƯỚI NƯỚC
- Đất ẩm > 60% → TẮT relay → NGỪNG TƯỚI
```

---

## 🎯 **PINOUT SUMMARY**

| Pin | Chức năng | Loại | Thiết bị |
|-----|-----------|------|----------|
| **GPIO4** | Digital I/O | I/O | DHT22 DATA |
| **GPIO25** | Digital Output | Output | GP2Y LED |
| **GPIO26** | Digital Output | Output | Relay 1 |
| **GPIO27** | Digital Output | Output | Relay 2 |
| **GPIO32** | Analog Input | ADC1_4 | Soil Moisture |
| **GPIO34** | Analog Input | ADC1_6 (Input only) | GP2Y V0 |
| **GPIO35** | Analog Input | ADC1_7 (Input only) | Rain Sensor |

---

## 🔋 **NGUỒN ĐIỆN**

### **Tổng dòng tiêu thụ:**

| Thiết bị | Điện áp | Dòng (mA) |
|----------|---------|-----------|
| ESP32 | 3.3V | 80-240 |
| GP2Y1010AU0F | 5V | 20 |
| DHT22 | 3.3V | 1.5 |
| Soil Sensor | 3.3V | 35 |
| Rain Sensor | 3.3V | 5 |
| Relay Module | 5V | 70 (2 relay) |
| **TỔNG** | - | **~212-372 mA** |

### **Nguồn cấp:**
- **USB 5V/500mA**: ✅ Đủ cho test
- **Adapter 5V/1A**: ✅ Khuyến nghị cho vận hành lâu dài
- **Battery 3.7V**: ⚠️ Cần boost converter lên 5V

---

## 🛠️ **CÁCH KẾT NỐI TRÊN BREADBOARD**

```
       3.3V Rail ──┬─── DHT22 VCC
                   │
                   ├─── Soil VCC
                   │
                   └─── Rain VCC

       5V Rail ────┬─── GP2Y VCC
                   │
                   └─── Relay VCC

       GND Rail ───┴─── Tất cả GND (common ground)
```

**Bước thực hiện:**
1. Cắm ESP32 vào breadboard
2. Nối 3.3V rail với ESP32 3.3V pin
3. Nối 5V rail với ESP32 5V pin
4. Nối GND rail với ESP32 GND pin
5. Cắm từng sensor theo sơ đồ trên
6. Nối relay module
7. Kiểm tra kỹ trước khi cấp nguồn!

---

## ⚠️ **CẢNH BÁO AN TOÀN**

1. ❌ **KHÔNG NỐI 5V VÀO ADC ESP32**
   - GPIO32, GPIO34, GPIO35 chỉ chịu **MAX 3.3V**
   - Soil & Rain sensor **BẮT BUỘC dùng VCC = 3.3V**

2. ❌ **KHÔNG ĐẢO CỰC TỤ ĐIỆN**
   - Tụ 220μF có cực (+) và (-)
   - Đảo cực → nổ tụ!

3. ⚠️ **RELAY MODULE CÓ JUMPER**
   - Một số module có jumper chọn High/Low trigger
   - Kiểm tra datasheet

4. ⚠️ **THIẾT BỊ ĐIỀU KHIỂN BỞI RELAY**
   - Relay chỉ là công tắc
   - Thiết bị điều khiển cần nguồn riêng (220V AC hoặc 12V DC)

---

## 📺 **OUTPUT MẪU TRÊN SERIAL MONITOR**

```
╔════════════════════════════════════════════════╗
║   MULTI SENSOR ROTATION TEST - ESP32          ║
║   2 minutes per sensor                         ║
╚════════════════════════════════════════════════╝

✅ All sensors initialized!
⚡ Relay 1 (GPIO26): Rain control
⚡ Relay 2 (GPIO27): Soil moisture control
🔄 Rotation cycle: Dust → DHT22 → Soil → Rain → repeat

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  🎯 ACTIVE: RAIN SENSOR             ┃
┃  Pin: GPIO35 (ADC)                  ┃
┃  ⏱️  Time remaining: 120 seconds     ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃  ⚡ Relay 1 (GPIO26): ON            ┃
┃  ⚡ Relay 2 (GPIO27): OFF           ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

┌─────────────────────────────────────┐
│  🌧️ RAIN SENSOR                     │
├─────────────────────────────────────┤
│  Raw ADC:        1234              │
│  Rain Level:     69.8 %            │
│  Status:         MODERATE RAIN     │
│  Intensity:      🌧️ RAIN            │
│  Relay 1:        ON                │
└─────────────────────────────────────┘

⚡ RELAY 2: ON (Soil too dry → watering)
```

---

**🎉 Hoàn thành setup!** Giờ bạn có hệ thống tự động hóa thông minh:
- 🌧️ Tắt phun nước khi trời mưa
- 💧 Tự động tưới khi đất khô
- 📊 Giám sát 4 loại cảm biến môi trường


