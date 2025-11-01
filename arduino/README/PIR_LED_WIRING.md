# 🚶 **HƯỚNG DẪN KẾT NỐI PIR + 4 LED**

## 📋 **TỔNG QUAN**

### **Thiết bị:**
- 🚶 **PIR Motion Sensor HC-SR501** (GPIO33)
- 💡 **4 LED** (GPIO5, GPIO18, GPIO19, GPIO21)
- 📌 **4 điện trở 220Ω** (cho LED)

### **GPIO sử dụng (KHÔNG TRÙNG):**

| GPIO | Thiết bị | Đã dùng trước đó? |
|------|----------|-------------------|
| GPIO33 | PIR Sensor | ✅ Còn trống |
| GPIO5 | LED 1 (Red) | ✅ Còn trống |
| GPIO18 | LED 2 (Yellow) | ✅ Còn trống |
| GPIO19 | LED 3 (Green) | ✅ Còn trống |
| GPIO21 | LED 4 (Blue) | ✅ Còn trống |

---

## 🔌 **SƠ ĐỒ KẾT NỐI**

### **1. PIR Sensor HC-SR501**

```
PIR HC-SR501    ESP32
──────────────────────
VCC         →   5V (hoặc 3.3V)
GND         →   GND
OUT         →   GPIO33
```

**Lưu ý:**
- PIR có thể dùng **3.3V hoặc 5V** (linh hoạt)
- OUT là **digital signal** (HIGH/LOW)
- Có 2 biến trở trên module:
  - **Sx**: Sensitivity (độ nhạy)
  - **Tx**: Time delay (thời gian giữ HIGH)

---

### **2. 4 LED với điện trở**

#### **Sơ đồ từng LED:**

```
      GPIO Pin ─┬─── [R: 220Ω] ─┬─── LED (+) Anode
                │                │
                │               LED (-) Cathode
                │                │
                │               GND
```

#### **Kết nối cụ thể:**

```
LED 1 (Red):
   GPIO5 → [220Ω] → LED (+) → LED (-) → GND

LED 2 (Yellow):
   GPIO18 → [220Ω] → LED (+) → LED (-) → GND

LED 3 (Green):
   GPIO19 → [220Ω] → LED (+) → LED (-) → GND

LED 4 (Blue):
   GPIO21 → [220Ω] → LED (+) → LED (-) → GND
```

---

### **3. Sơ đồ tổng quát**

```
┌──────────────────────────────────────┐
│            ESP32 38-Pin              │
├──────────────────────────────────────┤
│                                      │
│  5V ────────────── PIR VCC           │
│  GND ───┬───────── PIR GND           │
│         │                            │
│  GPIO33 ────────── PIR OUT           │
│         │                            │
│  GPIO5 ─┼─[220Ω]─── LED1 (+)──┐     │
│  GPIO18─┼─[220Ω]─── LED2 (+)──┤     │
│  GPIO19─┼─[220Ω]─── LED3 (+)──┼─GND │
│  GPIO21─┴─[220Ω]─── LED4 (+)──┘     │
│                                      │
└──────────────────────────────────────┘
```

---

## ⚡ **ĐIỆN ÁP & DÒNG ĐIỆN**

### **PIR Sensor:**
```
Điện áp:     3.3V - 5V (khuyến nghị 5V)
Dòng tiêu thụ: ~65mA (khi active)
Output:      3.3V digital (HIGH/LOW)
Range:       3-7 meters
Angle:       120 degrees
```

### **LED:**
```
Mỗi LED:
- Điện áp rơi: ~2V (red), ~3V (blue/white)
- Dòng:        ~15-20mA
- Điện trở:    220Ω (giới hạn dòng)

4 LED tổng:    ~60-80mA
```

### **Tổng tiêu thụ:**
```
PIR:     65mA
4 LED:   80mA
ESP32:   80-240mA
─────────────────
TỔNG:    225-385mA

USB 5V/500mA: ✅ ĐỦ
```

---

## 🎯 **LOGIC HOẠT ĐỘNG**

### **Khi phát hiện chuyển động:**

```
1. PIR OUT → HIGH
2. Đếm số lần phát hiện (+1)
3. Bật TẤT CẢ 4 LED
4. LED 3 & 4 nhấp nháy luân phiên (200ms)
5. Ghi lại thời gian
```

### **Khi KHÔNG có chuyển động (5 giây):**

```
1. Sau 5s:  Tắt LED 4 (Blue)
2. Sau 6s:  Tắt LED 3 (Green)
3. Sau 7s:  Tắt LED 2 (Yellow)
4. Sau 8s:  Tắt LED 1 (Red)
→ Hiệu ứng tắt dần
```

---

## 🔧 **HIỆU CHỈNH PIR SENSOR**

### **2 Biến trở trên PIR:**

```
┌─────────────────┐
│   PIR HC-SR501  │
│                 │
│  [Sx]    [Tx]   │
│   │       │     │
│   │       │     │
│  Sensitivity  │
│        Time Delay
└─────────────────┘
```

### **Sx - Sensitivity (Độ nhạy):**
```
Vặn trái (MIN):  ~3 meters
Vặn phải (MAX):  ~7 meters

Khuyến nghị: Giữa (4-5 meters)
```

### **Tx - Time Delay (Thời gian giữ):**
```
Vặn trái (MIN):  ~0.3 seconds
Vặn phải (MAX):  ~300 seconds

Khuyến nghị: 
- Test: MIN (0.3s) - phản ứng nhanh
- Thực tế: 3-5 seconds
```

### **Jumper (nếu có):**
```
H: Repeatable trigger (khuyến nghị)
   → Trigger liên tục khi có chuyển động

L: Single trigger
   → Trigger 1 lần, phải chờ hết delay
```

---

## 🚀 **CÁCH SỬ DỤNG**

### **Bước 1: Kết nối phần cứng**

1. Nối PIR theo sơ đồ (VCC=5V, GND, OUT=GPIO33)
2. Nối 4 LED với điện trở 220Ω
3. Kiểm tra kỹ trước khi cấp nguồn

### **Bước 2: Upload code**

```
Arduino IDE → Mở 11_PIR_4LED_Test.ino → Upload
```

### **Bước 3: Đợi PIR ổn định**

```
Code sẽ tự động đếm ngược 30 giây
Trong thời gian này:
- PIR tự hiệu chỉnh
- KHÔNG di chuyển trước mặt sensor
```

### **Bước 4: Test**

```
1. Di chuyển trước PIR
2. Quan sát:
   - Serial Monitor hiển thị "MOTION DETECTED"
   - 4 LED sáng lên
   - LED 3 & 4 nhấp nháy
3. Đứng yên 5 giây
4. LED tắt dần
```

---

## 📺 **OUTPUT SERIAL MONITOR**

### **Khởi động:**

```
╔════════════════════════════════════════════════╗
║     ESP32 PIR SENSOR + 4 LED TEST             ║
║     Motion Detection with Visual Feedback     ║
╚════════════════════════════════════════════════╝

✅ Hardware initialized!
📌 PIR Sensor: GPIO33
📌 LED 1 (Red):    GPIO5
📌 LED 2 (Yellow): GPIO18
📌 LED 3 (Green):  GPIO19
📌 LED 4 (Blue):   GPIO21

🔍 Waiting for PIR to stabilize (30 seconds)...
   ⏱️  30 seconds remaining...
   ⏱️  29 seconds remaining...
   ...
   ⏱️  1 seconds remaining...

✅ PIR ready! Start moving to test...
```

### **Phát hiện chuyển động:**

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  🚶 MOTION DETECTED!                 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
   📊 Count: 1
   ⏰ Time: 35240 ms
   💡 Turning ON all LEDs...

┌─────────────────────────────────────┐
│         PIR + LED STATUS            │
├─────────────────────────────────────┤
│  PIR State:       🚶 MOTION         │
│  Motion Count:    1                 │
│  Last Motion:     0                 │
│                   seconds ago       │
├─────────────────────────────────────┤
│  💡 LED 1 (GPIO5):  🔴 ON           │
│  💡 LED 2 (GPIO18): 🟡 ON           │
│  💡 LED 3 (GPIO19): 🟢 ON           │
│  💡 LED 4 (GPIO21): 🔵 ON           │
└─────────────────────────────────────┘
```

### **Không có chuyển động:**

```
┌─────────────────────────────────────┐
│         PIR + LED STATUS            │
├─────────────────────────────────────┤
│  PIR State:       ⚫ NO MOTION      │
│  Motion Count:    5                 │
│  Last Motion:     12                │
│                   seconds ago       │
├─────────────────────────────────────┤
│  💡 LED 1 (GPIO5):  ⚫ OFF          │
│  💡 LED 2 (GPIO18): ⚫ OFF          │
│  💡 LED 3 (GPIO19): ⚫ OFF          │
│  💡 LED 4 (GPIO21): ⚫ OFF          │
└─────────────────────────────────────┘
```

---

## 🐛 **TROUBLESHOOTING**

### **PIR không phát hiện chuyển động:**

| Vấn đề | Giải pháp |
|--------|-----------|
| Chưa đợi 30s | Chờ PIR ổn định |
| Tx quá dài | Vặn Tx về MIN |
| Sx quá thấp | Vặn Sx lên cao hơn |
| Nối sai pin | Kiểm tra VCC, GND, OUT |

### **PIR phát hiện liên tục (false positive):**

| Nguyên nhân | Giải pháp |
|-------------|-----------|
| Sx quá cao | Giảm Sx |
| Gần nguồn nhiệt | Tránh quạt, điều hòa |
| Ánh sáng mặt trời | Che chắn PIR |
| Jumper sai | Đặt jumper ở chế độ H |

### **LED không sáng:**

| Vấn đề | Giải pháp |
|--------|-----------|
| Nối ngược cực | Đảo LED (+/-) |
| Điện trở sai | Dùng 220Ω |
| GPIO sai | Kiểm tra 5, 18, 19, 21 |
| Chạm đất | Kiểm tra short circuit |

---

## 💡 **MẸO SỬ DỤNG**

### **1. Test PIR nhanh:**

```cpp
// Sửa line 19 trong code
const unsigned long MOTION_TIMEOUT = 1000; // 1 giây thay vì 5
```
→ LED tắt nhanh hơn, tiết kiệm thời gian test

### **2. LED pattern khác:**

```cpp
// Trong loop(), thay đổi pattern
digitalWrite(LED1_PIN, motionDetected);
digitalWrite(LED2_PIN, !motionDetected);
// Hiệu ứng đảo ngược
```

### **3. Đếm người qua lại:**

```cpp
// Thêm trong setup()
unsigned long peopleCount = 0;

// Trong loop(), khi phát hiện motion
peopleCount++;
Serial.printf("👥 People passed: %lu\n", peopleCount);
```

---

## 📊 **SO SÁNH PIR vs ULTRASONIC**

| Tính năng | PIR HC-SR501 | Ultrasonic HC-SR04 |
|-----------|-------------|-------------------|
| Phát hiện | Chuyển động | Khoảng cách |
| Range | 3-7m | 2-400cm |
| Góc | 120° | 15° |
| Dòng tiêu thụ | 65mA | 15mA |
| Giá | ~20k VND | ~15k VND |
| Dùng cho | Báo động, đèn tự động | Đo khoảng cách |

---

## 🎯 **ỨNG DỤNG THỰC TẾ**

1. **Đèn hành lang tự động:**
   - Phát hiện người → Bật đèn
   - Không người → Tắt sau 30s

2. **Báo động:**
   - Phát hiện xâm nhập → Kêu buzzer
   - Gửi thông báo qua WiFi

3. **Đếm khách:**
   - Đếm số người qua cửa
   - Lưu vào database

4. **Tiết kiệm năng lượng:**
   - Tắt màn hình khi không người
   - Bật điều hòa khi có người

---

**🎉 Hoàn thành!** 

Giờ bạn có hệ thống phát hiện chuyển động với feedback trực quan qua 4 LED!


