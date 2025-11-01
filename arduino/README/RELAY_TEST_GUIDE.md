# ⚡ **HƯỚNG DẪN TEST RELAY MODULE**

## 📋 **Mục đích**

Test riêng 2 relay để đảm bảo:
- ✅ Relay hoạt động đúng
- ✅ ESP32 điều khiển được relay
- ✅ Không có lỗi phần cứng
- ✅ LED trên module sáng/tắt đúng

---

## 🔌 **KẾT NỐI PHẦN CỨNG**

### **Relay Module → ESP32:**

```
Relay Module    ESP32
──────────────────────
VCC         →   5V
GND         →   GND
IN1         →   GPIO26
IN2         →   GPIO27
```

### **Lưu ý:**
- ⚠️ **VCC phải là 5V** (không phải 3.3V!)
- ⚠️ **GND chung** với ESP32
- ⚠️ **Chưa nối thiết bị** vào COM/NO/NC (test relay trước)

---

## 🚀 **CÁCH SỬ DỤNG**

### **Bước 1: Upload code**

1. Mở file `10_Relay_Test.ino` trong Arduino IDE
2. Chọn board: **ESP32 Dev Module**
3. Chọn Port (COM)
4. Click **Upload**

### **Bước 2: Mở Serial Monitor**

- Baud rate: **115200**
- Quan sát output

### **Bước 3: Quan sát Relay Module**

Trong quá trình test, bạn sẽ thấy:

1. **LED trên module**:
   - Mỗi relay có 1 LED riêng
   - Sáng = Relay ON
   - Tắt = Relay OFF

2. **Tiếng "click"**:
   - Khi relay bật/tắt, có tiếng cơ học "click"
   - Không có tiếng = relay bị hỏng

3. **Cảm giác rung nhẹ**:
   - Chạm vào relay khi bật/tắt sẽ cảm nhận rung

---

## 📺 **OUTPUT SERIAL MONITOR**

### **Khởi động:**
```
╔════════════════════════════════════════════════╗
║         ESP32 RELAY MODULE TEST                ║
║         2 Channel Relay Control                ║
╚════════════════════════════════════════════════╝

✅ Relay pins initialized!
📌 Relay 1: GPIO26
📌 Relay 2: GPIO27

🔄 Starting test sequence in 3 seconds...
```

### **Test 1 - Relay 1:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  TEST 1: RELAY 1 (GPIO26)            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

⚡ Bật Relay 1...

┌─────────────────────────────────────┐
│         RELAY STATUS                │
├─────────────────────────────────────┤
│  Relay 1 (GPIO26):  🟢 ON           │
│  Relay 2 (GPIO27):  ⚫ OFF          │
└─────────────────────────────────────┘

📌 KIỂM TRA TRÊN MODULE RELAY:
   ✓ LED Relay 1 phải SÁNG
   ✓ Nghe tiếng 'click' khi bật
   ✗ LED Relay 2 phải TẮT

📌 ĐO ĐIỆN ÁP (nếu có multimeter):
   Relay 1: COM-NO có dẫn điện (≈0Ω)
            COM-NC hở mạch (∞Ω)
   Relay 2: COM-NC có dẫn điện (≈0Ω)
            COM-NO hở mạch (∞Ω)

⚡ Tắt Relay 1...
[Tương tự...]
```

### **Test 2 - Relay 2:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  TEST 2: RELAY 2 (GPIO27)            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

⚡ Bật Relay 2...
[...]
```

### **Test 3 - Cả 2 relay:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  TEST 3: CẢ 2 RELAY CÙNG LÚC         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

⚡ Bật cả 2 relay...

┌─────────────────────────────────────┐
│         RELAY STATUS                │
├─────────────────────────────────────┤
│  Relay 1 (GPIO26):  🟢 ON           │
│  Relay 2 (GPIO27):  🟢 ON           │
└─────────────────────────────────────┘
```

### **Test 4 - Blink:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  TEST 4: BẬT LUÂN PHIÊN (BLINK)      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

⚡ Cycle 1/5: Relay 1 ON, Relay 2 OFF
⚡ Cycle 1/5: Relay 1 OFF, Relay 2 ON
⚡ Cycle 2/5: Relay 1 ON, Relay 2 OFF
[...]
```

---

## 🔍 **KIỂM TRA BẰNG MULTIMETER**

### **Công cụ cần:**
- Multimeter (chế độ đo điện trở Ω hoặc continuity)

### **Cách đo:**

#### **Khi Relay OFF:**
```
Đo giữa:
- COM và NC: Điện trở ≈ 0Ω (có dẫn điện) ✅
- COM và NO: Điện trở = ∞Ω (hở mạch) ✅

Nếu khác → Relay bị hỏng!
```

#### **Khi Relay ON:**
```
Đo giữa:
- COM và NO: Điện trở ≈ 0Ω (có dẫn điện) ✅
- COM và NC: Điện trở = ∞Ω (hở mạch) ✅

Nếu khác → Relay bị hỏng!
```

---

## 🎯 **CHECKLIST TEST**

### **✅ Test thành công nếu:**

| Kiểm tra | Kết quả mong đợi |
|----------|------------------|
| LED Relay 1 | Sáng khi ON, tắt khi OFF |
| LED Relay 2 | Sáng khi ON, tắt khi OFF |
| Tiếng "click" | Nghe rõ khi bật/tắt |
| COM-NO (ON) | Dẫn điện (0Ω) |
| COM-NC (OFF) | Dẫn điện (0Ω) |
| Serial Monitor | Hiển thị đúng trạng thái |

### **❌ Lỗi thường gặp:**

| Lỗi | Nguyên nhân | Giải pháp |
|-----|-------------|-----------|
| Relay không "click" | Thiếu nguồn 5V | Kiểm tra VCC = 5V |
| LED không sáng | Nối sai IN1/IN2 | Kiểm tra GPIO26/27 |
| Relay luôn ON | Module active-LOW | Bình thường (một số module) |
| Cả 2 relay cùng bật | Short circuit IN1-IN2 | Kiểm tra kết nối |

---

## 🔧 **GIẢI THÍCH LOGIC**

### **Relay Trigger:**

Có 2 loại module relay:
1. **Active-HIGH**: IN=HIGH → Relay ON
2. **Active-LOW**: IN=HIGH → Relay OFF (phổ biến hơn)

Code này dùng **Active-HIGH** logic:
```cpp
digitalWrite(RELAY1_PIN, HIGH); // Bật relay
digitalWrite(RELAY1_PIN, LOW);  // Tắt relay
```

Nếu module của bạn là **Active-LOW**, đảo ngược:
```cpp
digitalWrite(RELAY1_PIN, LOW);  // Bật relay
digitalWrite(RELAY1_PIN, HIGH); // Tắt relay
```

### **Cách kiểm tra loại module:**

1. Upload code
2. Quan sát relay khi khởi động:
   - Nếu relay **TẮT** → Active-HIGH ✅
   - Nếu relay **BẬT** → Active-LOW (sửa code)

---

## 📊 **SƠ ĐỒ NỐI THIẾT BỊ THẬT (SAU KHI TEST OK)**

### **Ví dụ: Điều khiển đèn 220V AC**

```
         ┌─────────────────┐
         │   Relay Module  │
         └─────────────────┘
                │
        ┌───────┴────────┐
        │                │
  Relay 1               Relay 2
    │                     │
  ┌─┴─┐                 ┌─┴─┐
  │COM├───┐             │COM├───┐
  │NO │   │             │NO │   │
  │NC │   │             │NC │   │
  └───┘   │             └───┘   │
          │                     │
     220V AC                220V AC
     Nguồn điện              Nguồn điện
        │                       │
    ┌───┴───┐               ┌───┴───┐
    │  Đèn  │               │  Quạt │
    └───────┘               └───────┘
```

**⚠️ CẢNH BÁO:**
- Relay chỉ là **công tắc**
- Thiết bị (đèn, quạt) cần **nguồn riêng**
- **NGẮT ĐIỆN** trước khi đấu nối 220V!
- Cẩn thận với điện cao áp!

---

## 🎓 **HIỂU THÊM VỀ RELAY**

### **Relay là gì?**

Relay = **công tắc điều khiển bằng điện**

```
Mạch điều khiển (3.3V-5V)
        ↓
    ⚡ Coil
        ↓
   🧲 Nam châm điện
        ↓
   🔀 Đóng/Mở tiếp điểm
        ↓
  Mạch thiết bị (220V AC / 12V DC)
```

### **Tại sao cần Relay?**

- ESP32 GPIO chỉ **3.3V, 40mA**
- Không đủ để điều khiển đèn 220V, motor 12V
- Relay là **cầu nối** an toàn giữa mạch điều khiển và thiết bị

### **Thông số quan trọng:**

```
Module Relay 2 kênh phổ biến:
- Điện áp Coil: 5V DC
- Dòng Coil: 70mA (35mA/relay)
- Tiếp điểm: 10A 250V AC / 10A 30V DC
- Tuổi thọ: 100,000 lần đóng/mở
```

---

## 💡 **MẸO TEST NHANH**

### **Test không cần multimeter:**

1. **Dùng LED:**
   ```
   Nối LED + điện trở 220Ω vào COM-NO
   - Relay ON → LED sáng
   - Relay OFF → LED tắt
   ```

2. **Dùng buzzer:**
   ```
   Nối buzzer vào COM-NO
   - Relay ON → buzzer kêu
   - Relay OFF → buzzer tắt
   ```

3. **Chỉ quan sát:**
   - LED trên module
   - Tiếng "click"
   - Đủ để xác nhận relay hoạt động!

---

## 🔄 **SAU KHI TEST XONG**

### **Nếu relay hoạt động OK:**

1. ✅ Giữ nguyên kết nối
2. ✅ Nối thêm sensors (Soil, Rain)
3. ✅ Upload code `Multi_Sensor_Rotation_Test.ino`
4. ✅ Test tự động hóa

### **Nếu relay KHÔNG hoạt động:**

1. ❌ Kiểm tra VCC = 5V (không phải 3.3V)
2. ❌ Kiểm tra GND chung
3. ❌ Kiểm tra GPIO26, GPIO27 nối đúng
4. ❌ Thử đảo IN1 ↔ IN2
5. ❌ Thử module relay khác (có thể bị hỏng)

---

**🎉 Chúc test thành công!**

Sau khi relay hoạt động ổn định, bạn có thể yên tâm tích hợp vào hệ thống automation.


