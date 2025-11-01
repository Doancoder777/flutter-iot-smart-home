# ⚡ **HƯỚNG DẪN ĐIỆN ÁP - TOÀN BỘ THIẾT BỊ**

## 📋 **TỔNG QUAN ESP32**

### **Điện áp hoạt động:**

```
ESP32 VIN:           5V (từ USB hoặc adapter)
ESP32 3.3V rail:     3.3V (điều hòa nội bộ)
GPIO OUTPUT (HIGH):  3.3V ⚠️ KHÔNG PHẢI 5V!
GPIO INPUT (max):    3.6V (tối đa, an toàn)
GND:                 0V (chung)
```

**⚠️ QUAN TRỌNG:**
- ESP32 GPIO **KHÔNG chịu được 5V trực tiếp!**
- Cảm biến OUT 5V cần **CHIA ÁP** về 3.3V
- GPIO OUTPUT chỉ 3.3V (không đủ trigger một số relay 5V)

---

## 📡 **BẢNG ĐIỆN ÁP CẢM BIẾN**

| Cảm biến | VCC | OUT | ESP32 GPIO | Chia áp? |
|----------|-----|-----|------------|----------|
| **DHT22** | 3.3-5V | 3.3V digital | ✅ Trực tiếp | ❌ Không |
| **MQ-2** | 5V | 0-5V analog | ⚠️ Cần chia áp | ✅ Có |
| **Rain** | 3.3-5V | 0-3.3V analog | ✅ Trực tiếp | ❌ Không |
| **Soil** | 3.3-5V | 0-3.3V analog | ✅ Trực tiếp | ❌ Không |
| **GP2Y Dust** | 5V | 0-5V analog | ⚠️ Cần chia áp | ✅ Có |
| **PIR HC-SR501** | 5V | 3.3V digital | ✅ Trực tiếp | ❌ Không |

---

## 🔌 **CHI TIẾT TỪNG CẢM BIẾN**

### **1. DHT22 (Nhiệt độ & Độ ẩm)**

```
DHT22       ESP32
──────      ─────
VCC   →     3.3V hoặc 5V (cả 2 đều OK)
DATA  →     GPIO4 (3.3V signal)
GND   →     GND
```

**Điện áp:**
- VCC: **3.3V - 5V** (linh hoạt)
- OUT: **3.3V** (pull-up resistor 10kΩ)
- Dòng: **2.5mA** (max)

**Kết nối:**
- ✅ Nối trực tiếp, không cần chia áp
- ✅ Dùng 3.3V hoặc 5V đều được

---

### **2. MQ-2 (Cảm biến khí gas)**

```
MQ-2        Chia áp        ESP32
──────      ───────        ─────
VCC   →     5V
A0    →     [1kΩ] ─┬─→     GPIO34
                   │
                [2kΩ]
                   │
GND   →     GND ───┘───    GND
```

**Điện áp:**
- VCC: **5V** (bắt buộc, cần heat để hoạt động)
- OUT: **0-5V** analog
- Dòng: **~150mA** (warm-up), **~15mA** (stable)

**⚠️ CHIA ÁP:**
```
Signal 5V → [R1: 1kΩ] → GPIO34 → [R2: 2kΩ] → GND
Vout = 5V × (2kΩ / 3kΩ) = 3.33V ✅
```

**Không chia áp:** ❌ Nguy cơ hỏng GPIO!

---

### **3. Rain Sensor (Cảm biến mưa)**

```
Rain        ESP32
──────      ─────
VCC   →     3.3V hoặc 5V
A0    →     GPIO35 (0-3.3V analog)
GND   →     GND
```

**Điện áp:**
- VCC: **3.3V - 5V**
- OUT: **0-3.3V** analog (nếu VCC=3.3V)
- OUT: **0-5V** analog (nếu VCC=5V → cần chia áp)
- Dòng: **~1mA**

**Kết nối:**
- ✅ Dùng VCC=3.3V → Nối trực tiếp
- ⚠️ Dùng VCC=5V → Cần chia áp

---

### **4. Soil Moisture (Độ ẩm đất)**

```
Soil        ESP32
──────      ─────
VCC   →     3.3V hoặc 5V
A0    →     GPIO32 (0-3.3V analog)
GND   →     GND
```

**Điện áp:**
- VCC: **3.3V - 5V**
- OUT: Tương tự Rain Sensor
- Dòng: **~1mA**

**Kết nối:**
- ✅ Dùng VCC=3.3V → An toàn
- ⚠️ Dùng VCC=5V → Cần chia áp

---

### **5. GP2Y1010AU0F (Bụi mịn)**

```
GP2Y        Chia áp        ESP32
──────      ───────        ─────
V-LED →     5V (bắt buộc)
LED   ←     GPIO25 (điều khiển LED)
Vo    →     [1kΩ] ─┬─→     GPIO36
                   │
                [2kΩ]
                   │
GND   →     GND ───┘───    GND
```

**Điện áp:**
- VCC: **5V** (bắt buộc)
- Vo: **0-5V** analog (cần chia áp)
- LED control: **3.3V** OK
- Dòng: **~20mA** (LED sáng), **~10mA** (LED tắt)

**⚠️ CHIA ÁP bắt buộc cho Vo!**

---

### **6. PIR HC-SR501 (Chuyển động)**

```
PIR         ESP32
──────      ─────
VCC   →     5V (khuyến nghị, có thể 3.3V)
OUT   →     GPIO33 (3.3V digital)
GND   →     GND
```

**Điện áp:**
- VCC: **5V** (khuyến nghị), **3.3V** (có thể nhưng kém)
- OUT: **3.3V** (digital, tự động điều chỉnh)
- Dòng: **~65mA** (active)

**Kết nối:**
- ✅ Nối trực tiếp, không cần chia áp
- ✅ OUT tự động 3.3V dù VCC=5V

---

## ⚙️ **BẢNG ĐIỆN ÁP ACTUATORS**

| Actuator | VCC | Signal/Control | Ghi chú |
|----------|-----|----------------|---------|
| **LED** | - | 3.3V (GPIO) | Cần điện trở 220Ω |
| **Servo SG90** | 5V | 3.3V PWM | 5V bắt buộc cho motor |
| **L298N Motor** | 12V | 3.3V logic | 12V cho motor, 3.3V GPIO |
| **Relay** | 5V | 3.3V trigger | 5V cho coil, 3.3V GPIO |

---

## 💡 **CHI TIẾT ACTUATORS**

### **1. LED (5 cái)**

```
ESP32              R            LED
─────              ────         ───
GPIO5  (3.3V) →   [220Ω] →     (+) Anode
                               (-) Cathode → GND
```

**Điện áp:**
- GPIO OUT: **3.3V**
- LED voltage drop: **~2V** (red), **~3V** (blue)
- Dòng qua LED: **(3.3V - 2V) / 220Ω ≈ 6mA** ✅
- Mỗi LED: **6-15mA**

**Tại sao 220Ω?**
```
I = (Vsource - VLED) / R
I = (3.3V - 2V) / 220Ω = 5.9mA ✅ (an toàn)
```

---

### **2. Servo SG90 (2 cái)**

```
Servo       ESP32
──────      ─────
Brown   →   GND
Red     →   5V (bắt buộc, không dùng 3.3V!)
Orange  →   GPIO22/23 (3.3V PWM signal)
```

**Điện áp:**
- VCC: **4.8V - 6V** (5V tối ưu)
- Signal: **3.3V PWM** (OK, servo chấp nhận)
- Dòng: **100-200mA** (khi quay), **10mA** (idle)

**⚠️ LƯU Ý:**
- **Không dùng 3.3V cho VCC** → Servo không đủ lực
- Signal 3.3V OK (servo nhận được)

---

### **3. L298N Motor Driver (2 motors)**

```
L298N       ESP32        Motor       Nguồn
──────      ─────        ─────       ─────
ENA/ENB →   GPIO14/12    -           -
IN1-IN4 →   GPIO26,27,15,16          -
OUT1-4  →   -            Motor 12V   -
+12V    →   -            -           12V (+)
GND     →   GND          -           12V (-)
5V      →   (Không nối)
```

**Điện áp:**
- Motor VCC: **12V** (nguồn riêng)
- Logic IN1-4: **3.3V** (GPIO ESP32) ✅
- ENA/ENB PWM: **3.3V** (GPIO ESP32) ✅
- Dòng motor: **500mA - 2A** (tùy motor)

**⚠️ LƯU Ý:**
- L298N chấp nhận logic 3.3V (threshold ~1.5V)
- **GND phải chung** giữa ESP32 và L298N
- **Không nối 5V pin** của L298N về ESP32

---

### **4. Relay Module (2 cái)**

```
Relay       ESP32        Nguồn
──────      ─────        ─────
VCC   →     5V           5V
IN    →     GPIO2/17     -
GND   →     GND          GND
```

**Điện áp:**
- Coil VCC: **5V**
- Trigger (IN): **3.3V** (GPIO)
- Dòng coil: **~70mA** (khi ON)

**⚠️ LƯU Ý:**
- Module relay **3.3V compatible** (trigger thấp)
- Nếu relay không kích (3.3V không đủ):
  - Dùng transistor NPN (2N2222)
  - Hoặc relay module 3.3V

**Sơ đồ với transistor (nếu cần):**
```
GPIO2 → [1kΩ] → Base (2N2222)
                Collector → Relay IN
                Emitter → GND
```

---

## 🔋 **YÊU CẦU NGUỒN ĐIỆN**

### **Hệ thống 3.3V (ESP32 internal):**

```
ESP32 core:         240mA
GPIO operations:    ~50mA
TỔNG 3.3V:          ~290mA (tự động từ 5V)
```

### **Hệ thống 5V:**

```
ESP32 (5V → 3.3V):  240mA
DHT22:              2.5mA
MQ-2:               150mA (warm-up), 15mA (stable)
Rain:               1mA
Soil:               1mA
GP2Y Dust:          20mA
PIR:                65mA
5 LED:              100mA (20mA × 5)
2 Servo:            400mA (200mA × 2, khi quay)
2 Relay coil:       140mA (70mA × 2)
──────────────────────────────
TỔNG 5V:            ~1.1A (max khi servo quay)
                    ~650mA (servo idle)
```

**→ Adapter 5V/2A (khuyến nghị)**

### **Hệ thống 12V:**

```
2 Motors L298N:     1.5A (tùy motor, khi chạy)
──────────────────────────────
TỔNG 12V:           1.5-2A
```

**→ Adapter 12V/2A**

---

## 🛡️ **CÁCH CHIA ÁP CHO CẢM BIẾN 5V**

### **Sơ đồ:**

```
Sensor OUT (5V)
    ↓
  [R1: 1kΩ]
    ↓
    ├─────→ ESP32 GPIO (3.3V)
    │
  [R2: 2kΩ]
    ↓
   GND
```

### **Công thức:**

```
Vout = Vin × (R2 / (R1 + R2))
Vout = 5V × (2kΩ / (1kΩ + 2kΩ))
Vout = 5V × (2 / 3)
Vout = 3.33V ✅
```

### **Chọn điện trở:**

| Vin | R1 | R2 | Vout | Kết quả |
|-----|----|----|------|---------|
| 5V | 1kΩ | 2kΩ | 3.33V | ✅ OK |
| 5V | 1kΩ | 1kΩ | 2.5V | ⚠️ Thấp |
| 5V | 2.2kΩ | 3.3kΩ | 3.0V | ✅ OK |
| 5V | 10kΩ | 22kΩ | 3.44V | ✅ OK |

**Khuyến nghị:** R1 = 1kΩ, R2 = 2kΩ

---

## 📊 **BẢNG TỔNG HỢP**

| Thiết bị | VCC | OUT/Signal | Nối ESP32 | Chia áp? |
|----------|-----|------------|-----------|----------|
| DHT22 | 3.3-5V | 3.3V | ✅ Trực tiếp | ❌ |
| MQ-2 | 5V | 0-5V | ⚠️ Chia áp | ✅ |
| Rain | 3.3V | 0-3.3V | ✅ Trực tiếp | ❌ |
| Soil | 3.3V | 0-3.3V | ✅ Trực tiếp | ❌ |
| Dust | 5V | 0-5V | ⚠️ Chia áp | ✅ |
| PIR | 5V | 3.3V | ✅ Trực tiếp | ❌ |
| LED | - | 3.3V | ✅ + 220Ω | ❌ |
| Servo | 5V | 3.3V PWM | ✅ Trực tiếp | ❌ |
| Motor | 12V | 3.3V logic | ✅ Trực tiếp | ❌ |
| Relay | 5V | 3.3V trigger | ✅ Trực tiếp | ❌ |

---

## ⚠️ **LƯU Ý AN TOÀN**

### **✅ AN TOÀN:**
1. Nối 3.3V sensor → ESP32 GPIO
2. Chia áp 5V → 3.3V trước khi vào GPIO
3. GND chung tất cả nguồn
4. Nguồn riêng cho motor 12V

### **❌ NGUY HIỂM:**
1. Nối 5V trực tiếp → ESP32 GPIO (hỏng chip!)
2. Không chung GND (nhiễu, reset ESP32)
3. Servo/Motor dùng chung nguồn USB (quá tải)
4. Relay không đủ trigger (3.3V yếu)

---

**🎯 Tóm tắt:**
- ESP32 GPIO = **3.3V**
- Sensor 5V cần **CHIA ÁP**
- Nguồn riêng cho **Servo** và **Motor 12V**
- **GND chung** tất cả!

**⚡ An toàn điện = Dự án thành công!** 🚀

