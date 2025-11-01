# 📡 MQTT Format Documentation - App & Arduino

## 🎯 Tổng quan

Hệ thống hỗ trợ **NHIỀU FORMAT MQTT** để tương thích giữa:
- **Flutter App** (gửi lệnh điều khiển)
- **Arduino ESP32** (nhận lệnh + gửi trạng thái)

---

## 📤 FORMAT GỬI TỪ APP → ARDUINO

### 1. LED Control (5 LEDs)

#### Format 1: State-based (Primary)
```json
{
  "state": true
}
```

#### Format 2: Action-based (Alternative)
```json
{
  "action": "turn_on"
}
```
hoặc
```json
{
  "action": "turn_off"
}
```

**Topics:**
- `smart_home/devices/LED_RED_001/cmd`
- `smart_home/devices/LED_YELLOW_001/cmd`
- `smart_home/devices/LED_GREEN_001/cmd`
- `smart_home/devices/LED_BLUE_001/cmd`
- `smart_home/devices/LED_WHITE_001/cmd`

---

### 2. SERVO Control (2 Servos)

#### Format: Angle-based
```json
{
  "angle": 90
}
```

**Range:** 0-180 degrees

**Topics:**
- `smart_home/devices/SERVO_ROOF_001/cmd` (GPIO13 - Mái che)
- `smart_home/devices/SERVO_DOOR_001/cmd` (GPIO14 - Cổng)

**Examples:**
- Đóng: `{"angle": 0}`
- Mở một nửa: `{"angle": 90}`
- Mở hoàn toàn: `{"angle": 180}`

---

### 3. MOTOR Control (2 Motors L298N)

#### Format 1: Speed-based (Primary)
```json
{
  "speed": 255
}
```

**Range:** 0-255 (PWM)
- `0` = Tắt motor
- `64` = 25% tốc độ
- `128` = 50% tốc độ
- `192` = 75% tốc độ
- `255` = 100% tốc độ

#### Format 2: Action-based (Alternative)
```json
{
  "action": "turn_on"
}
```
→ Arduino tự động chuyển thành `speed = 255`

```json
{
  "action": "turn_off"
}
```
→ Arduino tự động chuyển thành `speed = 0`

**Topics:**
- `smart_home/devices/MOTOR_FAN_A_001/cmd` (GPIO16,17,25)
- `smart_home/devices/MOTOR_FAN_B_001/cmd` (GPIO26,27,12)

**⚠️ LƯU Ý:**
- Arduino CHỈ hỗ trợ **chiều quay THUẬN** (forward only)
- Logic L298N:
  - Forward: `IN1=HIGH, IN2=LOW, PWM=speed`
  - Stop: `IN1=LOW, IN2=LOW, PWM=0`
  - **KHÔNG hỗ trợ chiều ngược** (để tránh lỗi cả 2 LED sáng)

---

### 4. RELAY Control (2 Relays)

#### Format 1: State-based (Primary)
```json
{
  "state": true
}
```

#### Format 2: Action-based (Alternative)
```json
{
  "action": "turn_on"
}
```

**Topics:**
- `smart_home/devices/RELAY_PUMP_001/cmd` (GPIO2)
- `smart_home/devices/RELAY_LIGHT_001/cmd` (GPIO15)

---

### 5. PING/HEALTH CHECK (All Devices)

#### App gửi:
```
ping
```
(text plain, không phải JSON)

#### Arduino phản hồi:
```
1
```
(text plain)

**Topics:**
- Devices: `smart_home/devices/{DEVICE_CODE}/ping`
- Sensors: `smart_home/sensors/{SENSOR_CODE}/ping`

**Example:**
```
App → Topic: smart_home/devices/LED_RED_001/ping
App → Payload: "ping"

Arduino → Topic: smart_home/devices/LED_RED_001/ping
Arduino → Payload: "1"
```

---

## 📥 FORMAT NHẬN TỪ ARDUINO → APP

### 1. SENSOR Data

#### Format:
```json
{
  "type": "temperature",
  "value": 28.5,
  "timestamp": 12345678
}
```

**Topics:**
- `smart_home/sensors/DHT22_001/state` (Temperature)
- `smart_home/sensors/DHT22_002/state` (Humidity)
- `smart_home/sensors/GAS_MQ2_001/state`
- `smart_home/sensors/RAIN_001/state`
- `smart_home/sensors/SOIL_001/state`
- `smart_home/sensors/DUST_GP2Y_001/state`
- `smart_home/sensors/PIR_MOTION_001/state`

**Sensor Types:**
- `temperature` (°C)
- `humidity` (%)
- `gas` (ppm)
- `rain` (%)
- `soil_moisture` (%)
- `dust` (mg/m³)
- `motion` (0 or 1)

---

### 2. DEVICE State (LED, Relay)

#### Format:
```json
{
  "state": "ON",
  "timestamp": 12345678
}
```
hoặc
```json
{
  "state": "OFF",
  "timestamp": 12345678
}
```

**Topics:**
- `smart_home/devices/LED_RED_001/state`
- `smart_home/devices/RELAY_PUMP_001/state`
- (tất cả LED và Relay devices)

---

### 3. DEVICE State (Servo, Motor)

#### Format:
```json
{
  "angle": 90,
  "state": true,
  "timestamp": 12345678
}
```
hoặc
```json
{
  "speed": 128,
  "state": true,
  "timestamp": 12345678
}
```

**Topics:**
- `smart_home/devices/SERVO_ROOF_001/state`
- `smart_home/devices/MOTOR_FAN_A_001/state`

**Fields:**
- `angle` (Servo): 0-180
- `speed` (Motor): 0-255
- `state` (boolean): `true` if value > 0, `false` if value = 0

---

## 🔄 DUAL FORMAT SUPPORT (Arduino)

Arduino **tự động nhận diện và hỗ trợ CẢ 2 FORMAT**:

### Code logic (trong `mqtt_callback`):
```cpp
auto parseState = [&doc]() -> bool {
  // Format 1: {"state": true/false}
  if (doc.containsKey("state")) {
    return doc["state"] | false;
  }
  // Format 2: {"action": "turn_on"/"turn_off"}
  if (doc.containsKey("action")) {
    String action = doc["action"] | "";
    return (action == "turn_on" || action == "on");
  }
  return false;
};
```

### Motor logic:
```cpp
if (doc.containsKey("action")) {
  String action = doc["action"] | "";
  if (action == "turn_on" || action == "on") {
    speed = 255; // Full speed
  } else {
    speed = 0; // Turn off
  }
}
```

---

## 📊 SMART PUBLISHING STRATEGY (Arduino → App)

### 1. First Boot
- Gửi **TẤT CẢ sensors** ngay lập tức khi ESP32 khởi động

### 2. Periodic Publishing
- Gửi **TẤT CẢ sensors** mỗi **1 PHÚT** (60 giây)

### 3. Change Detection
- Kiểm tra thay đổi mỗi **10 giây**
- Nếu có thay đổi **lớn hơn threshold**, gửi ngay:
  - Temperature: ±2°C
  - Humidity: ±5%
  - Gas: ±100 ppm
  - Rain: ±10%
  - Soil: ±10%
  - Dust: ±20 mg/m³

### 4. PIR Special Case
- **CHỈ gửi khi đảo trạng thái** (0→1 hoặc 1→0)
- Không gửi định kỳ nếu không có thay đổi

---

## 🎯 AI VOICE CONTROL FORMAT

### AI Response Format:
```json
{
  "success": true,
  "device_key": "den_phong_ngu",
  "action": "turn_on",
  "value": null
}
```

### Action Mapping:
- `turn_on` → LED/Relay: `{"state": true}` hoặc `{"action": "turn_on"}`
- `turn_off` → LED/Relay: `{"state": false}` hoặc `{"action": "turn_off"}`
- `set_value` → Servo: `{"angle": value}`
- `set_value` → Motor: `{"speed": value}` (value = 0-100% → convert to 0-255)

### Device Type Rules:
| Device Type | Action | MQTT Format |
|------------|--------|-------------|
| LED | turn_on | `{"state": true}` |
| LED | turn_off | `{"state": false}` |
| RELAY | turn_on | `{"state": true}` |
| RELAY | turn_off | `{"state": false}` |
| SERVO | set_value | `{"angle": X}` (0-180) |
| MOTOR/FAN | set_value | `{"speed": X}` (0-255) |

---

## 🔍 TOPIC PATTERNS

### Subscribe Topics (Arduino):
```
smart_home/devices/{DEVICE_CODE}/cmd
smart_home/devices/{DEVICE_CODE}/ping
smart_home/sensors/{SENSOR_CODE}/ping
```

### Publish Topics (Arduino):
```
smart_home/devices/{DEVICE_CODE}/state
smart_home/sensors/{SENSOR_CODE}/state
smart_home/devices/{DEVICE_CODE}/ping (response)
smart_home/sensors/{SENSOR_CODE}/ping (response)
```

### Subscribe Topics (App):
```
smart_home/sensors/#
smart_home/devices/#
smart_home/alerts/#
smart_home/status/#
```

---

## ⚙️ GPIO MAPPING (ESP32 DevKit v1)

### Sensors (7 pins):
- GPIO4: DHT22 (Temperature & Humidity)
- GPIO34: MQ-2 Gas (ADC1_6)
- GPIO35: Rain Sensor (ADC1_7)
- GPIO32: Soil Moisture (ADC1_4)
- GPIO23: GP2Y Dust LED (VSPI_MOSI)
- GPIO36: GP2Y Dust Output (ADC1_0)
- GPIO33: PIR Motion (ADC1_5)

### Actuators (15 pins):
#### LED (5 pins):
- GPIO5: LED_RED_001
- GPIO18: LED_YELLOW_001
- GPIO19: LED_GREEN_001
- GPIO21: LED_BLUE_001
- GPIO22: LED_WHITE_001

#### Servo (2 pins):
- GPIO13: SERVO_ROOF_001 (Mái che)
- GPIO14: SERVO_DOOR_001 (Cổng)

#### Motor A (3 pins):
- GPIO16: ENA (PWM Speed)
- GPIO17: IN1 (Direction 1)
- GPIO25: IN2 (Direction 2)

#### Motor B (3 pins):
- GPIO26: ENB (PWM Speed)
- GPIO27: IN3 (Direction 1)
- GPIO12: IN4 (Direction 2)

#### Relay (2 pins):
- GPIO2: RELAY_PUMP_001
- GPIO15: RELAY_LIGHT_001

---

## 🚨 COMMON ISSUES & SOLUTIONS

### Issue 1: Motor cả 2 LED sáng khi bật
**Nguyên nhân:** IN1 và IN2 cùng HIGH → short circuit/brake
**Giải pháp:** Chỉ support chiều thuận, không hỗ trợ reverse
- Forward: `IN1=HIGH, IN2=LOW`
- Stop: `IN1=LOW, IN2=LOW`

### Issue 2: Servo không quay
**Nguyên nhân:** detach/attach cycles trong code
**Giải pháp:** Đơn giản hóa chỉ dùng `servo.write(angle)`

### Issue 3: MQTT format không khớp
**Nguyên nhân:** App gửi `{"action": "turn_on"}`, Arduino expect `{"state": true}`
**Giải pháp:** Dual format support trong Arduino `parseState()` function

### Issue 4: Sensors gửi liên tục làm MQTT lag
**Nguyên nhân:** Publish mỗi loop() (100ms)
**Giải pháp:** Smart publishing strategy (1 phút + change detection)

---

## 📝 VERSION HISTORY

### v3.0 (Current)
- ✅ Dual format support (state & action)
- ✅ Motor forward only (no reverse)
- ✅ Smart publishing (1 min + change detection)
- ✅ PIR state-change only
- ✅ Servo simplified (no detach/attach)
- ✅ GPIO comments for all device codes

### v2.0
- Split DHT22 into 2 device codes (temp + humidity)
- Fixed continuous sensor publishing bug
- Added MQTT format compatibility

### v1.0
- Initial implementation
- Basic MQTT control for all devices

---

## 🎓 BEST PRACTICES

1. **Always use device codes** - Không dùng tên hiển thị
2. **Handle both formats** - State-based và action-based
3. **Use QoS 1** - `atLeastOnce` cho reliability
4. **Add timestamps** - Để track message age
5. **Use retain flag** - Cho device state persistence
6. **Implement ping/pong** - Health check mechanism
7. **Smart publishing** - Tránh spam MQTT broker
8. **JSON validation** - Parse error handling
9. **GPIO comments** - Document hardware connections
10. **Serial logging** - Debug-friendly với emojis 📡

---

**Last Updated:** 2024-11-01
**Author:** DoAn4 Team
**Project:** Flutter IoT Smart Home
