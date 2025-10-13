# 🌀 Quạt Phòng Khách với L298N Motor Driver

## 📋 **Tóm tắt tính năng:**

✅ **Thêm thành công:**
- Device ID: `fan_living` 
- Hardware: L298N Motor Driver
- Control: JSON commands + PWM speed
- UI: Slider + Preset buttons (Chậm/Vừa/Nhanh)

## 🔌 **Kết nối phần cứng ESP32 với L298N:**

```
ESP32 Pin    →    L298N Pin    →    Chức năng
GPIO23       →    ENA          →    PWM Speed Control (0-255)
GPIO22       →    IN1          →    Direction Control
GPIO25       →    IN2          →    Direction Control
VIN (5V)     →    VCC          →    Power Supply
GND          →    GND          →    Ground

Motor        →    OUT1, OUT2   →    DC Fan Motor
```

## 📡 **MQTT Commands:**

### 1. **JSON Speed Control:**
```json
Topic: smarthome/control/fan_living
Message: {"command": "set_speed", "speed": 180}
```

### 2. **JSON Toggle On/Off:**
```json
Topic: smarthome/control/fan_living  
Message: {"command": "toggle", "state": true}
```

### 3. **JSON Preset Speeds:**
```json
// Chậm (31%)
{"command": "preset", "preset": "low"}

// Vừa (59%) 
{"command": "preset", "preset": "medium"}

// Nhanh (100%)
{"command": "preset", "preset": "high"}
```

### 4. **Simple Speed Control (backward compatible):**
```
Topic: smarthome/control/fan_living
Message: 200  // PWM value 0-255
```

## 🎮 **Flutter App UI:**

- **Switch**: Bật/tắt quạt
- **Slider**: Điều chỉnh tốc độ 0-100%
- **Preset Buttons**: Chậm/Vừa/Nhanh
- **Status Display**: Hiển thị % tốc độ và PWM value

## 🔧 **ESP32 Code Logic:**

```cpp
void setFanLivingSpeed(int speed) {
  speed = constrain(speed, 0, 255);
  
  if (speed == 0) {
    // Stop motor
    digitalWrite(PIN_FAN_LIVING_IN1, LOW);
    digitalWrite(PIN_FAN_LIVING_IN2, LOW);
    analogWrite(PIN_FAN_LIVING_PWM, 0);
  } else {
    // Forward direction
    digitalWrite(PIN_FAN_LIVING_IN1, HIGH);
    digitalWrite(PIN_FAN_LIVING_IN2, LOW);
    // Set PWM speed
    analogWrite(PIN_FAN_LIVING_PWM, speed);
  }
}
```

## 🚀 **Cách sử dụng:**

1. **Upload code lên ESP32**
2. **Kết nối L298N theo sơ đồ trên**
3. **Mở Flutter app**
4. **Tìm "Quạt phòng khách" trong danh sách device**
5. **Sử dụng slider hoặc preset buttons để điều khiển**

## 🎯 **Ưu điểm của JSON approach:**

✅ **Linh hoạt**: Có thể thêm nhiều chế độ (timer, auto, scene)  
✅ **Mở rộng**: Dễ thêm tính năng mới  
✅ **Metadata**: Có thể log commands, user tracking  
✅ **Backward Compatible**: Vẫn nhận simple numbers

## 📊 **Test Commands:**

Bạn có thể test bằng MQTT client:
```bash
# Bật quạt tốc độ trung bình
mosquitto_pub -h 16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud -p 8883 -u sigma -P 35386Doan --cafile cert.pem -t "smarthome/control/fan_living" -m '{"command":"preset","preset":"medium"}'

# Điều chỉnh tốc độ custom
mosquitto_pub -h 16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud -p 8883 -u sigma -P 35386Doan --cafile cert.pem -t "smarthome/control/fan_living" -m '{"command":"set_speed","speed":200}'
```

Ready để test! 🎉