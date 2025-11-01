# 📌 ESP32 38-PIN GPIO PINOUT GUIDE

## 🎯 MỤC ĐÍCH
Hướng dẫn chọn chân GPIO **AN TOÀN** cho ESP32 38-pin khi dùng WiFi/Bluetooth.

---

## ⚠️ QUY TẮC VÀNG KHI CHỌN CHÂN

### 1. **TRÁNH ADC2 KHI DÙNG WiFi**
```
❌ ADC2 pins: GPIO 0, 2, 4, 12, 13, 14, 15, 25, 26, 27
✅ ADC1 pins: GPIO 32, 33, 34, 35, 36, 39 (AN TOÀN)
```

**Lý do:** WiFi driver sử dụng ADC2, không thể đọc ADC2 khi WiFi bật.

### 2. **CHÂN INPUT ONLY (Chỉ đọc, không xuất)**
```
✅ GPIO 34, 35, 36, 39 - Chỉ INPUT (không có pull-up/pull-down)
```

**Dùng cho:** Cảm biến analog (MQ-2, rain, soil moisture, dust)

### 3. **CHÂN CÓ PULL-UP NỘI BỘ**
```
❌ GPIO 0, 2, 15 - Có pull-up khi boot
⚠️ KHÔNG dùng cho cảm biến quan trọng
```

### 4. **CHÂN BOOT/FLASH (Tránh nếu có thể)**
```
❌ GPIO 0  - BOOT button (pull-up)
❌ GPIO 2  - Built-in LED (có thể dùng LED)
❌ GPIO 15 - HSPI_CS (pull-up khi boot)
⚠️ GPIO 1, 3 - UART TX/RX (dùng cho Serial)
```

### 5. **CHÂN AN TOÀN NHẤT**
```
✅ GPIO 4, 5, 12, 13, 14, 16, 17, 18, 19, 21, 22, 23, 27, 32, 33
```

---

## 📊 BẢNG PHÂN LOẠI CHÂN

### **INPUT ONLY (ADC1 - An toàn với WiFi)**
| GPIO | ADC | Tên khác | Ghi chú |
|------|-----|----------|---------|
| 36 | ADC1_0 | SENSOR_VP | ✅ Input only, ADC |
| 39 | ADC1_3 | SENSOR_VN | ✅ Input only, ADC |
| 34 | ADC1_6 | - | ✅ Input only, ADC |
| 35 | ADC1_7 | - | ✅ Input only, ADC |
| 32 | ADC1_4 | TOUCH_9 | ✅ Input/Output, ADC |
| 33 | ADC1_5 | TOUCH_8 | ✅ Input/Output, ADC |

### **I/O AN TOÀN (Digital)**
| GPIO | Chức năng | Ghi chú |
|------|-----------|---------|
| 4 | ADC2_0, TOUCH_0 | ✅ OK nhưng là ADC2 |
| 5 | VSPI_CS | ✅ An toàn |
| 12 | ADC2_5, TOUCH_5 | ⚠️ ADC2, có pull-down khi boot |
| 13 | ADC2_4, TOUCH_4 | ⚠️ ADC2 |
| 14 | ADC2_6, TOUCH_6 | ⚠️ ADC2 |
| 16 | - | ✅ An toàn |
| 17 | - | ✅ An toàn |
| 18 | VSPI_CLK | ✅ An toàn |
| 19 | VSPI_MISO | ✅ An toàn |
| 21 | I2C_SDA | ✅ An toàn |
| 22 | I2C_SCL | ✅ An toàn |
| 23 | VSPI_MOSI | ✅ An toàn |
| 27 | ADC2_7, TOUCH_7 | ⚠️ ADC2 |

### **CHÂN ĐẶC BIỆT**
| GPIO | Chức năng | Ghi chú |
|------|-----------|---------|
| 0 | BOOT | ❌ Pull-up khi boot, dùng cho boot mode |
| 1 | TX0 | ⚠️ UART TX (dùng cho Serial) |
| 2 | LED_BUILTIN | ⚠️ Built-in LED, pull-down khi boot |
| 3 | RX0 | ⚠️ UART RX (dùng cho Serial) |
| 15 | HSPI_CS | ❌ Pull-up khi boot |
| 25 | ADC2_8, DAC_1 | ❌ ADC2 + DAC, conflict với WiFi |
| 26 | ADC2_9, DAC_2 | ❌ ADC2 + DAC, conflict với WiFi |

---

## 🔧 PROJECT SMART HOME - PINOUT MAPPING

### **CẢNH BÁO CŨ (TRƯỚC KHI SỬA)**
```cpp
❌ #define DUST_LED_PIN    25   // GPIO25 - ADC2_8 (CONFLICT!)
❌ #define LED_PIN         26   // GPIO26 - ADC2_9 (CONFLICT!)
```

### **✅ PINOUT MỚI (ĐÃ SỬA)**

#### **Cảm biến (Sensors)**
| Cảm biến | GPIO | Loại | Lý do chọn |
|----------|------|------|------------|
| DHT22 (Temp/Humidity) | 4 | Digital | ✅ OK với digital read |
| MQ-2 (Gas) | 34 | ADC1_6 | ✅ Input only, ADC1 |
| Rain Sensor | 35 | ADC1_7 | ✅ Input only, ADC1 |
| Soil Moisture | 32 | ADC1_4 | ✅ ADC1, có I/O |
| GP2Y Dust LED | 23 | Digital | ✅ VSPI_MOSI, an toàn |
| GP2Y Dust Output | 33 | ADC1_5 | ✅ ADC1, có I/O |
| PIR Motion | 27 | Digital | ✅ OK với digital read |

#### **Thiết bị điều khiển (Actuators)**
| Thiết bị | GPIO | Loại | Lý do chọn |
|----------|------|------|------------|
| Servo Signal | 18 | PWM | ✅ VSPI_CLK, hỗ trợ PWM |
| Fan L298N ENA (PWM) | 19 | PWM | ✅ VSPI_MISO, hỗ trợ PWM |
| Fan L298N IN1 | 21 | Digital | ✅ I2C_SDA, an toàn |
| Fan L298N IN2 | 22 | Digital | ✅ I2C_SCL, an toàn |
| LED Control | 2 | PWM | ✅ Built-in LED, hỗ trợ PWM |

---

## 📐 SƠ ĐỒ KẾT NỐI

### **1. Cảm biến DHT22 (Nhiệt độ/Độ ẩm)**
```
DHT22 VCC  → 3.3V
DHT22 GND  → GND
DHT22 DATA → GPIO4 (+ pull-up 10kΩ lên 3.3V)
```

### **2. Cảm biến MQ-2 (Khí Gas)**
```
MQ-2 VCC → 5V
MQ-2 GND → GND
MQ-2 A0  → GPIO34 (ADC1_6)
```

### **3. Cảm biến Rain (Mưa)**
```
Rain VCC → 3.3V
Rain GND → GND
Rain A0  → GPIO35 (ADC1_7)
```

### **4. Cảm biến Soil Moisture (Độ ẩm đất)**
```
Soil VCC → 3.3V
Soil GND → GND
Soil A0  → GPIO32 (ADC1_4)
```

### **5. Cảm biến GP2Y1010AU0F (Bụi PM2.5/PM10)**
```
GP2Y Pin 1 (V-LED) → GPIO23 (DUST_LED_PIN)
GP2Y Pin 2 (LED-GND) → GND
GP2Y Pin 3 (LED) → 150Ω → 5V
GP2Y Pin 4 (S-GND) → GND
GP2Y Pin 5 (Vo) → 220μF capacitor → GPIO33 (ADC1_5)
GP2Y Pin 6 (Vcc) → 5V
```

### **6. Cảm biến PIR HC-SR501 (Chuyển động)**
```
PIR VCC → 5V
PIR GND → GND
PIR OUT → GPIO27
```

### **7. Servo Motor SG90/MG90S**
```
Servo Brown  → GND
Servo Red    → 5V (từ nguồn ngoài)
Servo Orange → GPIO18 (PWM)
```

### **8. Quạt DC với L298N**
```
L298N ENA  → GPIO19 (PWM control)
L298N IN1  → GPIO21 (Direction 1)
L298N IN2  → GPIO22 (Direction 2)
L298N OUT1 → Fan Motor +
L298N OUT2 → Fan Motor -
L298N VCC  → 12V (từ nguồn ngoài)
L298N GND  → GND chung
L298N 5V   → 5V hoặc không nối (nếu dùng jumper)
```

### **9. LED/Relay**
```
LED Anode (+) → GPIO2 → 220Ω resistor
LED Cathode (-) → GND
```

---

## ⚡ NGUỒN ĐIỆN

### **ESP32**
- VIN: 5V (từ USB hoặc adapter)
- 3V3: 3.3V output (max 500mA)
- GND: Ground

### **LƯU Ý:**
1. **Servo + L298N:** Dùng nguồn ngoài 5V/12V riêng (không lấy từ ESP32)
2. **Chung GND:** Tất cả GND phải nối chung
3. **Cảm biến 5V:** Dùng điện trở phân áp nếu output > 3.3V
4. **MQ-2:** Dùng 5V, output 0-5V → dùng điện trở phân áp xuống 0-3.3V

---

## 🐛 TROUBLESHOOTING

### **Vấn đề 1: Đọc ADC sai giá trị**
- ✅ Kiểm tra dùng ADC1 (GPIO 32-39)
- ❌ Tránh ADC2 khi WiFi bật

### **Vấn đề 2: Servo giật, không ổn định**
- ✅ Dùng nguồn ngoài 5V cho servo (không lấy từ ESP32)
- ✅ Nối GND chung
- ✅ Thêm capacitor 100μF gần servo

### **Vấn đề 3: ESP32 reset liên tục**
- ✅ Kiểm tra nguồn đủ ampere (min 500mA)
- ✅ Tránh GPIO 0, 15 khi boot
- ✅ Thêm capacitor 100μF gần VIN

### **Vấn đề 4: WiFi không kết nối**
- ✅ Kiểm tra không dùng GPIO 1, 3 (UART)
- ✅ Tránh nhiễu từ servo/motor gần antenna

---

## 📚 TÀI LIỆU THAM KHẢO

1. **ESP32 Datasheet:** https://www.espressif.com/sites/default/files/documentation/esp32_datasheet_en.pdf
2. **ESP32 Pinout Reference:** https://randomnerdtutorials.com/esp32-pinout-reference-gpios/
3. **ADC2 + WiFi Issue:** https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/peripherals/adc.html

---

## ✅ CHECKLIST TRƯỚC KHI CHẠY

- [ ] Kiểm tra tất cả cảm biến analog dùng ADC1 (GPIO 32-39)
- [ ] Tránh ADC2 (GPIO 0, 2, 4, 12-15, 25-27) cho cảm biến
- [ ] Nguồn ngoài cho servo/motor (không lấy từ ESP32)
- [ ] GND nối chung tất cả devices
- [ ] Pull-up resistor cho DHT22 (10kΩ)
- [ ] Điện trở phân áp cho cảm biến 5V → 3.3V
- [ ] Test từng cảm biến riêng lẻ trước khi ghép tất cả

---

**Cập nhật:** October 30, 2025  
**Phiên bản:** 1.0  
**Tác giả:** Smart Home IoT Team
