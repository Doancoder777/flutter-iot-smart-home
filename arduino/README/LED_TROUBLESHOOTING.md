# 💡 **HƯỚNG DẪN KHẮC PHỤC LED KHÔNG SÁNG**

## 🔍 **CHECKLIST KIỂM TRA NHANH**

### **1. Kiểm tra kết nối cơ bản:**

```
☐ LED có nối ĐÚNG cực (+/-) không?
   - Chân dài (+) Anode → GPIO (qua điện trở)
   - Chân ngắn (-) Cathode → GND

☐ Có điện trở 220Ω chưa?
   - GPIO → [220Ω] → LED (+)

☐ GND có nối chung với ESP32 không?

☐ Nguồn 5V có đủ không?
   - USB: 5V/500mA (đủ cho 5 LED)
   - Adapter: 5V/1A (khuyến nghị)
```

---

## 🧪 **CÁCH TEST**

### **Bước 1: Upload code test đơn giản**

```
File: 14_LED_Test_Simple.ino
→ Upload vào ESP32
→ Mở Serial Monitor (115200 baud)
```

### **Bước 2: Quan sát từng LED**

Code sẽ test:
1. **Bật từng LED** 1 giây (lần lượt)
2. **Bật tất cả** 2 giây
3. **Tắt tất cả** 2 giây
4. **Nhấp nháy** 5 lần
5. **Lặp lại**

### **Bước 3: Ghi nhận kết quả**

| LED | GPIO | Có sáng? | Ghi chú |
|-----|------|----------|---------|
| LED 1 | GPIO5 | ☐ Có ☐ Không | |
| LED 2 | GPIO18 | ☐ Có ☐ Không | |
| LED 3 | GPIO19 | ☐ Có ☐ Không | |
| LED 4 | GPIO21 | ☐ Có ☐ Không | |
| LED 5 | GPIO13 | ☐ Có ☐ Không | |

---

## 🐛 **CÁC LỖI THƯỜNG GẶP**

### **LỖI 1: TẤT CẢ LED KHÔNG SÁNG**

#### **Nguyên nhân:**

| Vấn đề | Cách kiểm tra | Giải pháp |
|--------|---------------|-----------|
| **GND không nối** | Dùng đồng hồ đo | Nối GND LED → GND ESP32 |
| **Nguồn không đủ** | Đo điện áp 5V | Dùng adapter 5V/1A |
| **Code chưa upload** | Check Serial Monitor | Upload lại code |
| **GPIO conflict** | Kiểm tra code khác | Dùng GPIO mới |

#### **Test nhanh:**

```cpp
// Test đơn giản nhất - chỉ 1 LED
void setup() {
  pinMode(5, OUTPUT);
}

void loop() {
  digitalWrite(5, HIGH);
  delay(1000);
  digitalWrite(5, LOW);
  delay(1000);
}
```

→ Nếu LED 1 (GPIO5) vẫn không sáng → **Kiểm tra phần cứng!**

---

### **LỖI 2: MỘT VÀI LED KHÔNG SÁNG**

#### **Nguyên nhân:**

| LED hỏng | Cách test | Giải pháp |
|----------|-----------|-----------|
| **LED chết** | Đổi LED khác | Thay LED mới |
| **Nối ngược cực** | Đảo (+/-) | Nối đúng cực |
| **Điện trở sai** | Đo Ω | Dùng 220Ω |
| **GPIO hỏng** | Test GPIO khác | Đổi GPIO |

#### **Test từng LED bằng pin:**

```
Pin 3V (CR2032) → LED (+) → LED (-) → GND
```

→ LED sáng → LED tốt  
→ LED không sáng → LED hỏng

---

### **LỖI 3: LED SÁNG YẾU/MỜ**

#### **Nguyên nhân:**

| Vấn đề | Giải pháp |
|--------|-----------|
| **Điện trở quá lớn** | Dùng 220Ω (không phải 1kΩ) |
| **Nguồn yếu** | Dùng adapter 5V/1A |
| **Dây nối dài** | Rút ngắn dây |
| **PWM thấp** | Kiểm tra code (phải HIGH) |

---

### **LỖI 4: LED NHẤP NHÁY LOẠN**

#### **Nguyên nhân:**

| Vấn đề | Giải pháp |
|--------|-----------|
| **Nhiễu điện** | Thêm capacitor 100nF |
| **Code conflict** | Xóa code cũ |
| **ESP32 reset** | Kiểm tra nguồn ổn định |

---

## 🔧 **SƠ ĐỒ KẾT NỐI ĐÚNG**

### **LED đơn:**

```
     ESP32              Điện trở           LED
     ─────              ────────           ────
     
GPIO5 ───┬─── [220Ω] ───┬─── (+) Anode (chân dài)
         │               │
         │               └─── (-) Cathode (chân ngắn)
         │                     │
         │                    GND
         │
        GND ─────────────────────┘
```

### **5 LED song song:**

```
ESP32                    LED          GND
─────                    ───          ───

GPIO5  → [220Ω] → LED1 (+) → LED1 (-) ┐
GPIO18 → [220Ω] → LED2 (+) → LED2 (-) ├─→ GND chung
GPIO19 → [220Ω] → LED3 (+) → LED3 (-) │
GPIO21 → [220Ω] → LED4 (+) → LED4 (-) │
GPIO13 → [220Ω] → LED5 (+) → LED5 (-) ┘
```

**⚠️ QUAN TRỌNG:**
- MỖI LED cần 1 điện trở riêng
- KHÔNG dùng chung 1 điện trở cho nhiều LED
- GND có thể nối chung

---

## 🎨 **NHẬN BIẾT CỰC LED**

### **LED thông thường (5mm/3mm):**

```
        ┌─────────┐
        │    ●    │  ← Đầu tròn (dome)
        │         │
        │         │
        ├─────────┤  ← Phần phẳng (flat edge)
        │         │
        │    │    │  ← Chân dài: (+) Anode
        │    │    │
        │   │     │  ← Chân ngắn: (-) Cathode
        └───┴─────┘
```

**Cách nhớ:**
- **Chân DÀI** = **+** (Anode) → Nối GPIO
- **Chân NGẮN** = **-** (Cathode) → Nối GND
- **Cạnh PHẲNG** bên chân ngắn (-)

### **LED SMD:**

```
┌──────────┐
│  ┌─┐ ┌─┐ │
│  │A│ │K│ │  ← A = Anode (+), K = Kathode (-)
│  └─┘ └─┘ │
└──────────┘
```

**Hoặc có dấu:**
- **Góc cắt xéo** → Bên đó là Cathode (-)
- **Dấu + in trên PCB** → Anode (+)

---

## 🧰 **CÔNG CỤ CẦN THIẾT**

### **1. Đồng hồ vạn năng (Multimeter):**

```
Test LED:
1. Chọn chế độ "Diode Test" (⏵|)
2. Que đỏ (+) → LED Anode
3. Que đen (-) → LED Cathode
4. LED sáng yếu → LED tốt
5. Không sáng → LED hỏng hoặc ngược cực
```

### **2. Test nhanh bằng pin 3V:**

```
Pin CR2032 (3V):
  (+) → LED Anode
  (-) → LED Cathode

→ LED sáng mạnh → LED tốt
```

### **3. Test GPIO ESP32:**

```cpp
void setup() {
  pinMode(5, OUTPUT);
}
void loop() {
  digitalWrite(5, HIGH);
  delay(1000);
  digitalWrite(5, LOW);
  delay(1000);
}
```

→ Đo điện áp GPIO5:
- HIGH: ~3.3V
- LOW: ~0V

---

## ⚡ **KIỂM TRA NGUỒN ĐIỆN**

### **Dòng tiêu thụ:**

```
Mỗi LED:  ~15-20mA
5 LED:    ~75-100mA

USB 5V:       500mA  ✅ ĐỦ
Adapter 5V/1A: 1000mA ✅ DƯ THỪA
```

### **Test nguồn:**

```
1. Đo điện áp ESP32:
   - 5V pin: 4.5-5.5V (OK)
   - 3.3V pin: 3.2-3.4V (OK)

2. Đo GND:
   - Tất cả GND phải = 0V

3. Test tải:
   - Bật tất cả LED
   - Đo lại 5V → Không giảm quá 0.5V
```

---

## 🔬 **TEST TỪNG BƯỚC**

### **Test 1: LED đơn với code tối giản**

```cpp
void setup() {
  pinMode(5, OUTPUT);
  digitalWrite(5, HIGH); // Bật luôn
}
void loop() {}
```

→ Upload → LED1 sáng → GPIO5 OK  
→ Không sáng → Kiểm tra LED/kết nối

### **Test 2: Thêm Serial debug**

```cpp
void setup() {
  Serial.begin(115200);
  pinMode(5, OUTPUT);
}
void loop() {
  Serial.println("LED ON");
  digitalWrite(5, HIGH);
  delay(1000);
  
  Serial.println("LED OFF");
  digitalWrite(5, LOW);
  delay(1000);
}
```

→ Kiểm tra Serial có in ra không

### **Test 3: Test 5 GPIO**

```cpp
int leds[] = {5, 18, 19, 21, 13};

void setup() {
  Serial.begin(115200);
  for (int i = 0; i < 5; i++) {
    pinMode(leds[i], OUTPUT);
  }
}

void loop() {
  for (int i = 0; i < 5; i++) {
    Serial.printf("Testing GPIO%d\n", leds[i]);
    digitalWrite(leds[i], HIGH);
    delay(500);
    digitalWrite(leds[i], LOW);
    delay(500);
  }
}
```

→ Ghi nhận GPIO nào sáng, GPIO nào không

---

## 📸 **HÌNH ẢNH THAM KHẢO**

### **Kết nối đúng:**

```
┌───────────────────────────────────────┐
│  [ESP32]                              │
│                                       │
│  GPIO5 ─── [R1: 220Ω] ─── LED1 ─── GND│
│  GPIO18 ── [R2: 220Ω] ─── LED2 ─── GND│
│  GPIO19 ── [R3: 220Ω] ─── LED3 ─── GND│
│  GPIO21 ── [R4: 220Ω] ─── LED4 ─── GND│
│  GPIO13 ── [R5: 220Ω] ─── LED5 ─── GND│
│                                       │
└───────────────────────────────────────┘
```

### **Lỗi thường gặp:**

```
❌ SAI:
GPIO5 ─── LED (+) ─── (-) ─── (Không nối GND)

❌ SAI:
GPIO5 ─── LED (-) ─── (+) ─── GND (Ngược cực)

❌ SAI:
GPIO5 ─── LED (+) ─── (-) ─── GND (Thiếu điện trở)

✅ ĐÚNG:
GPIO5 ─── [220Ω] ─── LED (+) ─── (-) ─── GND
```

---

## 📋 **CHECKLIST CUỐI CÙNG**

```
☐ 1. Code đã upload thành công?
☐ 2. Serial Monitor có hiển thị?
☐ 3. GPIO đúng với code? (5, 18, 19, 21, 13)
☐ 4. LED nối đúng cực? (Chân dài = +)
☐ 5. Có điện trở 220Ω?
☐ 6. GND nối chung ESP32?
☐ 7. Nguồn 5V đủ? (Test bằng đồng hồ)
☐ 8. LED test riêng bằng pin 3V?
☐ 9. GPIO test bằng code đơn giản?
☐ 10. Đã thử đổi LED khác?
```

---

## 🆘 **NẾU VẪN KHÔNG ĐƯỢC**

### **Thử các GPIO khác:**

```cpp
// Thay đổi GPIO trong code
#define LED1_PIN  2   // Thay vì GPIO5
#define LED2_PIN  4   // Thay vì GPIO18
#define LED3_PIN  16  // Thay vì GPIO19
#define LED4_PIN  17  // Thay vì GPIO21
#define LED5_PIN  25  // Thay vì GPIO13
```

### **Hoặc test với LED built-in:**

```cpp
void setup() {
  pinMode(LED_BUILTIN, OUTPUT); // LED trên board
}
void loop() {
  digitalWrite(LED_BUILTIN, HIGH);
  delay(1000);
  digitalWrite(LED_BUILTIN, LOW);
  delay(1000);
}
```

→ LED built-in nhấp nháy → ESP32 OK → Vấn đề ở LED ngoài

---

**🎯 KẾT LUẬN:**

1. **Upload code `14_LED_Test_Simple.ino`** trước
2. **Kiểm tra từng LED** theo Serial Monitor
3. **Ghi nhận LED nào không sáng**
4. **Test LED đó riêng** bằng pin 3V
5. **Kiểm tra kết nối** theo checklist

**💡 90% lỗi do:**
- Nối ngược cực LED (+/-)
- Thiếu điện trở
- GND không chung
- LED hỏng

**Hãy test theo hướng dẫn này và báo lại kết quả!** 🔧


