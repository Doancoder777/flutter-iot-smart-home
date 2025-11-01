# ⚙️ **HƯỚNG DẪN HỆ THỐNG HOÀN CHỈNH**

## 📋 **TỔNG QUAN**

### **Thiết bị đầy đủ:**
- 🚶 **PIR Motion Sensor** (GPIO33)
- 💡 **5 LED** (GPIO5, 13, 18, 19, 21)
- 🔄 **2 Servo SG90** (GPIO22, 23)
- ⚙️ **2 Motor L298N** (GPIO14, 15, 25, 26, 27, 32)

### **Tổng cộng: 14 GPIO đã sử dụng!**

---

## 🔌 **BẢNG PINOUT HOÀN CHỈNH**

| GPIO | Thiết bị | Chức năng | Loại |
|------|----------|-----------|------|
| **GPIO33** | PIR Sensor OUT | Phát hiện chuyển động | Input |
| **GPIO5** | LED 1 (Red) | Đèn báo 1 | Output |
| **GPIO18** | LED 2 (Yellow) | Đèn báo 2 | Output |
| **GPIO19** | LED 3 (Green) | Đèn báo 3 | Output |
| **GPIO21** | LED 4 (Blue) | Đèn báo 4 | Output |
| **GPIO13** | LED 5 (White) | Đèn báo 5 | Output |
| **GPIO22** | Servo 1 Signal | Servo góc 1 | PWM |
| **GPIO23** | Servo 2 Signal | Servo góc 2 | PWM |
| **GPIO14** | Motor A - ENA | PWM tốc độ Motor A | PWM |
| **GPIO25** | Motor A - IN1 | Chiều quay A (1) | Output |
| **GPIO26** | Motor A - IN2 | Chiều quay A (2) | Output |
| **GPIO27** | Motor B - ENB | PWM tốc độ Motor B | PWM |
| **GPIO32** | Motor B - IN3 | Chiều quay B (3) | Output |
| **GPIO15** | Motor B - IN4 | Chiều quay B (4) | Output |

### **GPIO còn trống:**
- GPIO16, 17 (nếu cần mở rộng)

---

## 🔌 **SƠ ĐỒ KẾT NỐI CHI TIẾT**

### **1. PIR Sensor HC-SR501**

```
PIR HC-SR501    ESP32
──────────────────────
VCC         →   5V
GND         →   GND
OUT         →   GPIO33
```

---

### **2. 5 LED (mỗi LED + điện trở 220Ω)**

```
GPIO5  → [220Ω] → LED1 (+) Red    → (-) GND
GPIO18 → [220Ω] → LED2 (+) Yellow → (-) GND
GPIO19 → [220Ω] → LED3 (+) Green  → (-) GND
GPIO21 → [220Ω] → LED4 (+) Blue   → (-) GND
GPIO13 → [220Ω] → LED5 (+) White  → (-) GND
```

---

### **3. 2 Servo SG90**

```
Servo 1:
  Brown  (GND)    → GND
  Red    (VCC)    → 5V
  Orange (Signal) → GPIO22

Servo 2:
  Brown  (GND)    → GND
  Red    (VCC)    → 5V
  Orange (Signal) → GPIO23
```

---

### **4. Motor A - L298N (Quạt/Fan)**

```
L298N Module      ESP32        Motor/Nguồn
────────────────────────────────────────────
ENA           →   GPIO14       (PWM Speed)
IN1           →   GPIO25       (Direction 1)
IN2           →   GPIO26       (Direction 2)
OUT1, OUT2    →   (Motor A)    Fan 12V
+12V          →   12V Power Supply
GND           →   GND (Common)
5V            →   (Không nối)
```

**⚠️ LƯU Ý:**
- **Jumper ENA**: **BỎ** jumper (để ESP32 điều khiển PWM)
- **Motor A**: Quạt 12V DC hoặc motor tương tự

---

### **5. Motor B - L298N (Bơm/Pump)**

```
L298N Module      ESP32        Motor/Nguồn
────────────────────────────────────────────
ENB           →   GPIO27       (PWM Speed)
IN3           →   GPIO32       (Direction 3)
IN4           →   GPIO15       (Direction 4)
OUT3, OUT4    →   (Motor B)    Pump 12V
+12V          →   12V Power Supply
GND           →   GND (Common)
5V            →   (Không nối)
```

**⚠️ LƯU Ý:**
- **Jumper ENB**: **BỎ** jumper (để ESP32 điều khiển PWM)
- **Motor B**: Bơm nước 12V hoặc motor khác

---

## 🔋 **NGUỒN ĐIỆN**

### **Yêu cầu nguồn:**

```
┌─────────────────────────────────────┐
│  THIẾT BỊ              ĐIỆN ÁP  DÒNG│
├─────────────────────────────────────┤
│  ESP32                 5V      240mA│
│  PIR Sensor            5V       65mA│
│  5 LED                 5V      100mA│
│  2 Servo SG90          5V      400mA│
│  Motor A (L298N)       12V    500mA │
│  Motor B (L298N)       12V    500mA │
├─────────────────────────────────────┤
│  TỔNG 5V:                     805mA │
│  TỔNG 12V:                   1000mA │
└─────────────────────────────────────┘
```

### **Giải pháp nguồn:**

#### **Cách 1: 2 nguồn riêng biệt (KHUYẾN NGHỊ)**

```
┌──────────────────────────────────────┐
│  Adapter 5V/2A:                      │
│    (+) → ESP32 VIN                   │
│    (+) → PIR VCC                     │
│    (+) → 2 Servo VCC                 │
│    (-) → GND chung                   │
│                                      │
│  Adapter 12V/2A:                     │
│    (+) → L298N #1 (+12V)             │
│    (+) → L298N #2 (+12V) (nếu 2 module)│
│    (-) → GND chung                   │
└──────────────────────────────────────┘
```

**✅ Ưu điểm:**
- Nguồn 5V và 12V độc lập → ổn định
- Không quá tải
- An toàn nhất

#### **Cách 2: 1 nguồn 12V + Buck Converter**

```
Adapter 12V/3A
    ↓
    ├─→ L298N Module (+12V)
    │
    └─→ Buck Converter (12V → 5V)
           ↓
           ESP32 + PIR + Servo (5V)
```

**⚠️ Lưu ý:**
- Buck converter cần ít nhất **5V/2A** output
- Đảm bảo GND chung

---

## ⚡ **LOGIC HOẠT ĐỘNG**

### **Khi phát hiện chuyển động:**

```
🚶 PIR OUT = HIGH
    ↓
┌───────────────────────────────┐
│  💡 Bật TẤT CẢ 5 LED          │
│  🔄 Servo 1: 0° → 180°        │
│  🔄 Servo 2: 0° → 180°        │
│  ⚙️  Motor A: FORWARD (70%)   │
│  ⚙️  Motor B: REVERSE (78%)   │
│  📊 Đếm số lần +1             │
└───────────────────────────────┘
```

### **Khi KHÔNG có chuyển động (5 giây):**

```
⚫ PIR OUT = LOW (timeout)
    ↓
┌───────────────────────────────┐
│  💡 Tắt TẤT CẢ 5 LED          │
│  🔄 Servo 1: 180° → 0°        │
│  🔄 Servo 2: 180° → 0°        │
│  ⚙️  Motor A: STOP             │
│  ⚙️  Motor B: STOP             │
└───────────────────────────────┘
```

---

## 🎮 **ĐIỀU KHIỂN MOTOR L298N**

### **Bảng chân lý Motor A:**

| IN1 | IN2 | ENA (PWM) | Hành động |
|-----|-----|-----------|-----------|
| LOW | LOW | 0-255 | ⚫ STOP (phanh) |
| HIGH | LOW | 0-255 | ⚙️ Quay XUÔI (speed) |
| LOW | HIGH | 0-255 | ⚙️ Quay NGƯỢC (speed) |
| HIGH | HIGH | 0-255 | ⚫ STOP (phanh) |

### **Bảng chân lý Motor B:**

| IN3 | IN4 | ENB (PWM) | Hành động |
|-----|-----|-----------|-----------|
| LOW | LOW | 0-255 | ⚫ STOP (phanh) |
| HIGH | LOW | 0-255 | ⚙️ Quay XUÔI (speed) |
| LOW | HIGH | 0-255 | ⚙️ Quay NGƯỢC (speed) |
| HIGH | HIGH | 0-255 | ⚫ STOP (phanh) |

### **Code ví dụ điều khiển:**

```cpp
// Motor A: Quay xuôi 180/255 (70%)
digitalWrite(MOTOR_A_IN1, HIGH);
digitalWrite(MOTOR_A_IN2, LOW);
analogWrite(MOTOR_A_ENA, 180);

// Motor B: Quay ngược 200/255 (78%)
digitalWrite(MOTOR_B_IN3, LOW);
digitalWrite(MOTOR_B_IN4, HIGH);
analogWrite(MOTOR_B_ENB, 200);

// Dừng cả 2 motor
digitalWrite(MOTOR_A_IN1, LOW);
digitalWrite(MOTOR_A_IN2, LOW);
analogWrite(MOTOR_A_ENA, 0);

digitalWrite(MOTOR_B_IN3, LOW);
digitalWrite(MOTOR_B_IN4, LOW);
analogWrite(MOTOR_B_ENB, 0);
```

---

## 📺 **OUTPUT SERIAL MONITOR**

### **Khởi động:**

```
╔════════════════════════════════════════════════╗
║  COMPLETE TEST: PIR + LED + SERVO + MOTOR     ║
║  Full Motion Detection System                  ║
╚════════════════════════════════════════════════╝

✅ Hardware initialized!

📌 PINOUT:
   PIR Sensor:     GPIO33
   LED 1 (Red):    GPIO5
   LED 2 (Yellow): GPIO18
   LED 3 (Green):  GPIO19
   LED 4 (Blue):   GPIO21
   LED 5 (White):  GPIO13
   Servo 1:        GPIO22
   Servo 2:        GPIO23
   Motor A (ENA):  GPIO14
   Motor A (IN1):  GPIO25
   Motor A (IN2):  GPIO26
   Motor B (ENB):  GPIO27
   Motor B (IN3):  GPIO32
   Motor B (IN4):  GPIO15

🔍 Waiting for PIR to stabilize (30s)...

✅ PIR ready! Start moving to test...
```

### **Phát hiện chuyển động:**

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  🚶 MOTION DETECTED!                 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
   📊 Count: 1
   💡 LEDs: ALL ON
   🔄 Servos: Moving to 180°
   ⚙️  Motor A: FORWARD at 180/255 (70.6%)
   ⚙️  Motor B: REVERSE at 200/255 (78.4%)

┌──────────────────────────────────────────┐
│    COMPLETE SYSTEM STATUS                │
├──────────────────────────────────────────┤
│  PIR:             🚶 MOTION              │
│  Motion Count:    1                      │
│  Last Motion:     0 seconds ago          │
├──────────────────────────────────────────┤
│  💡 LED STATUS:                          │
│    LED 1 (Red):   🔴 ON                  │
│    LED 2 (Yellow):🟡 ON                  │
│    LED 3 (Green): 🟢 ON                  │
│    LED 4 (Blue):  🔵 ON                  │
│    LED 5 (White): ⚪ ON                  │
├──────────────────────────────────────────┤
│  🔄 SERVO STATUS:                        │
│    Servo 1:        90° → 180°            │
│    Servo 2:        85° → 180°            │
├──────────────────────────────────────────┤
│  ⚙️  MOTOR STATUS:                       │
│    Motor A:       ⚙️  FORWARD (71%)      │
│    Motor B:       ⚙️  REVERSE (78%)      │
└──────────────────────────────────────────┘
```

---

## 🐛 **TROUBLESHOOTING**

### **Motor không quay:**

| Vấn đề | Giải pháp |
|--------|-----------|
| Không đủ nguồn 12V | Kiểm tra adapter 12V/2A |
| Jumper ENA/ENB còn cắm | BỎ jumper ra |
| Nối sai chân | Kiểm tra IN1, IN2, ENA |
| Motor hỏng | Test motor trực tiếp 12V |

### **Servo giật cục:**

| Nguyên nhân | Giải pháp |
|-------------|-----------|
| Nguồn 5V yếu | Dùng adapter 5V/2A |
| Nhiều thiết bị cùng lúc | Nguồn riêng cho servo |
| Capacitor | Thêm 1000µF/16V vào nguồn servo |

### **ESP32 reset liên tục:**

| Nguyên nhân | Giải pháp |
|-------------|-----------|
| Quá tải nguồn | Tăng nguồn 5V lên 2A |
| Nhiễu từ motor | Thêm diode chống nhiễu |
| GND không chung | Nối GND tất cả nguồn lại |

---

## 🎯 **TỐI ƯU HÓA**

### **1. Giảm tiêu thụ điện:**

```cpp
// Thay đổi tốc độ motor thấp hơn
const int MOTOR_A_SPEED = 120; // 47% thay vì 70%
const int MOTOR_B_SPEED = 150; // 59% thay vì 78%
```

### **2. Thêm delay tắt LED (hiệu ứng):**

```cpp
// Tắt dần LED (thêm vào sau line 280)
if (!motionDetected && (currentMillis - lastMotionTime > MOTION_TIMEOUT)) {
  delay(500);
  digitalWrite(LED5_PIN, LOW);
  delay(500);
  digitalWrite(LED4_PIN, LOW);
  delay(500);
  digitalWrite(LED3_PIN, LOW);
  delay(500);
  digitalWrite(LED2_PIN, LOW);
  delay(500);
  digitalWrite(LED1_PIN, LOW);
}
```

### **3. Điều chỉnh tốc độ servo:**

```cpp
// Servo quay nhanh hơn
const int SERVO_STEP = 10;  // Bước lớn hơn
const int SERVO_DELAY = 10; // Delay ngắn hơn
```

---

## 📊 **SO SÁNH CÁC BẢN TEST**

| File | PIR | LED | Servo | Motor | Relay |
|------|-----|-----|-------|-------|-------|
| `10_Relay_Test.ino` | ❌ | ❌ | ❌ | ❌ | ✅ 2 |
| `11_PIR_4LED_Test.ino` | ✅ | ✅ 4 | ❌ | ❌ | ❌ |
| `12_PIR_LED_2Servo_Test.ino` | ✅ | ✅ 5 | ✅ 2 | ❌ | ❌ |
| **`13_Complete_Test.ino`** | **✅** | **✅ 5** | **✅ 2** | **✅ 2** | **❌** |

---

## 🎨 **ỨNG DỤNG THỰC TẾ**

### **1. Hệ thống an ninh:**
- PIR phát hiện → LED cảnh báo
- Servo điều hướng camera
- Motor mở khóa cửa

### **2. Tưới cây tự động:**
- PIR phát hiện người → Tắt tưới
- Servo điều chỉnh vòi
- Motor bơm nước

### **3. Robot giám sát:**
- PIR phát hiện → LED báo
- Servo xoay camera/cảm biến
- Motor di chuyển robot

### **4. Quạt + đèn tự động:**
- Có người → Bật quạt + đèn
- Không người → Tắt tất cả

---

**🎉 HỆ THỐNG HOÀN CHỈNH!**

**14 GPIO đã sử dụng - Hệ thống đa chức năng mạnh mẽ!** 🚀⚙️


