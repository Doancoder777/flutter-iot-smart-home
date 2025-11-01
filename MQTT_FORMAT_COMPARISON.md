# 🔄 MQTT Format Comparison - App vs Arduino

## 📊 Quick Reference Table

| Device | Voice Command | AI Output | App Sends (MQTT) | Arduino Receives | Arduino Response |
|--------|---------------|-----------|------------------|------------------|------------------|
| **LED** | "Bật đèn" | `{"action":"turn_on"}` | `{"state":true}` ✅<br>`{"action":"turn_on"}` ✅ | Parse both formats | `{"state":"ON"}` |
| **LED** | "Tắt đèn" | `{"action":"turn_off"}` | `{"state":false}` ✅<br>`{"action":"turn_off"}` ✅ | Parse both formats | `{"state":"OFF"}` |
| **Relay** | "Bật relay" | `{"action":"turn_on"}` | `{"state":true}` ✅<br>`{"action":"turn_on"}` ✅ | Parse both formats | `{"state":"ON"}` |
| **Relay** | "Tắt relay" | `{"action":"turn_off"}` | `{"state":false}` ✅<br>`{"action":"turn_off"}` ✅ | Parse both formats | `{"state":"OFF"}` |
| **Motor** | "Bật quạt" | `{"action":"set_value","value":67}` | Convert to `{"speed":171}` | Parse speed | `{"speed":171,"state":true}` |
| **Motor** | "Quạt mạnh" | `{"action":"set_value","value":100}` | Convert to `{"speed":255}` | Parse speed | `{"speed":255,"state":true}` |
| **Motor** | "Quạt nhẹ" | `{"action":"set_value","value":33}` | Convert to `{"speed":84}` | Parse speed | `{"speed":84,"state":true}` |
| **Motor** | "Tắt quạt" | `{"action":"set_value","value":0}` | Convert to `{"speed":0}` | Parse speed | `{"speed":0,"state":false}` |
| **Motor** | "Bật quạt" (alt) | `{"action":"turn_on"}` | `{"action":"turn_on"}` ✅ | Convert to speed=255 | `{"speed":255,"state":true}` |
| **Servo** | "Mở cửa" | `{"action":"set_value","value":180}` | Convert to `{"angle":180}` | Parse angle | `{"angle":180,"state":true}` |
| **Servo** | "Đóng cửa" | `{"action":"set_value","value":0}` | Convert to `{"angle":0}` | Parse angle | `{"angle":0,"state":false}` |

---

## 🔍 Format Conversion Details

### LED / Relay (ON/OFF Devices)

#### App → Arduino
```
Format 1 (State-based):
{"state": true}  → digitalWrite(PIN, HIGH)
{"state": false} → digitalWrite(PIN, LOW)

Format 2 (Action-based):
{"action": "turn_on"}  → digitalWrite(PIN, HIGH)
{"action": "turn_off"} → digitalWrite(PIN, LOW)
```

#### Arduino → App
```
{"state": "ON", "timestamp": 12345678}
{"state": "OFF", "timestamp": 12345678}
```

---

### Motor / Fan (Speed Control)

#### Voice → AI → App → Arduino
```
Voice: "Quạt mạnh"
  ↓
AI: {"action": "set_value", "value": 100}  ← % 0-100
  ↓
App converts: 100% × 255/100 = 255
  ↓
App sends MQTT: {"speed": 255}  ← PWM 0-255
  ↓
Arduino receives: speed = 255
  ↓
Arduino logic:
  IN1 = HIGH
  IN2 = LOW
  analogWrite(ENA, 255)
  ↓
Arduino responds: {"speed": 255, "state": true, "timestamp": 12345678}
```

#### Alternative Flow (action-based)
```
Voice: "Bật quạt"
  ↓
App sends: {"action": "turn_on"}  ← No speed specified
  ↓
Arduino converts: action="turn_on" → speed=255 (full speed)
  ↓
Arduino responds: {"speed": 255, "state": true, "timestamp": 12345678}
```

#### Speed Mapping Table
| Voice | AI Value | App PWM | Arduino Logic | Result |
|-------|----------|---------|---------------|--------|
| "Tắt quạt" | 0 | 0 | IN1=LOW, IN2=LOW, PWM=0 | Stop ⛔ |
| "Quạt nhẹ" | 33 | 84 | IN1=HIGH, IN2=LOW, PWM=84 | 33% 🌬️ |
| "Bật quạt" | 67 | 171 | IN1=HIGH, IN2=LOW, PWM=171 | 67% 💨 |
| "Quạt mạnh" | 100 | 255 | IN1=HIGH, IN2=LOW, PWM=255 | 100% 🌪️ |

---

### Servo (Angle Control)

#### Voice → AI → App → Arduino
```
Voice: "Mở cửa"
  ↓
AI: {"action": "set_value", "value": 180}  ← Degrees 0-180
  ↓
App sends MQTT: {"angle": 180}
  ↓
Arduino receives: angle = 180
  ↓
Arduino logic: servo.write(180)
  ↓
Arduino responds: {"angle": 180, "state": true, "timestamp": 12345678}
```

#### Angle Mapping
| Voice | AI Value | MQTT | Arduino | Servo Position |
|-------|----------|------|---------|----------------|
| "Đóng cửa" | 0 | `{"angle":0}` | servo.write(0) | 0° (Closed) 🚪 |
| "Mở một nửa" | 90 | `{"angle":90}` | servo.write(90) | 90° (Half open) |
| "Mở cửa" | 180 | `{"angle":180}` | servo.write(180) | 180° (Fully open) 🚪✅ |

---

## 🔧 Arduino Code Snippets

### LED/Relay Parser (Dual Format)
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

bool state = parseState();
digitalWrite(LED_PIN, state ? HIGH : LOW);
```

### Motor Parser (Speed + Action)
```cpp
int speed = doc["speed"] | 0;

// Alternative: action → speed conversion
if (doc.containsKey("action")) {
  String action = doc["action"] | "";
  if (action == "turn_on" || action == "on") {
    speed = 255; // Full speed
  } else {
    speed = 0; // Turn off
  }
}

// Constrain and apply
speed = constrain(speed, 0, 255);

if (speed == 0) {
  digitalWrite(MOTOR_IN1, LOW);
  digitalWrite(MOTOR_IN2, LOW);
  analogWrite(MOTOR_ENA, 0);
} else {
  digitalWrite(MOTOR_IN1, HIGH);  // Forward only
  digitalWrite(MOTOR_IN2, LOW);
  analogWrite(MOTOR_ENA, speed);
}
```

### Servo Parser (Simple)
```cpp
int angle = doc["angle"] | 0;
angle = constrain(angle, 0, 180);
servo.write(angle);
```

---

## 📡 MQTT Topics Pattern

### Command Topics (App → Arduino)
```
smart_home/devices/LED_RED_001/cmd
smart_home/devices/LED_YELLOW_001/cmd
smart_home/devices/LED_GREEN_001/cmd
smart_home/devices/LED_BLUE_001/cmd
smart_home/devices/LED_WHITE_001/cmd
smart_home/devices/SERVO_ROOF_001/cmd
smart_home/devices/SERVO_DOOR_001/cmd
smart_home/devices/MOTOR_FAN_A_001/cmd
smart_home/devices/MOTOR_FAN_B_001/cmd
smart_home/devices/RELAY_PUMP_001/cmd
smart_home/devices/RELAY_LIGHT_001/cmd
```

### State Topics (Arduino → App)
```
smart_home/devices/{DEVICE_CODE}/state
```

### Ping Topics (Health Check)
```
smart_home/devices/{DEVICE_CODE}/ping
smart_home/sensors/{SENSOR_CODE}/ping
```

---

## 🎯 Key Takeaways

### For AI (Gemini):
- ✅ Output value in **percentage 0-100** for Motor/Fan
- ✅ Output value in **degrees 0-180** for Servo
- ✅ Use `turn_on`/`turn_off` for LED/Relay
- ✅ Use `set_value` for Motor/Servo
- ❌ NEVER use `turn_on`/`turn_off` for Motor (use `set_value` with value=0)
- ❌ NEVER use `turn_on`/`turn_off` for Servo (use `set_value` with angle)

### For App (Flutter):
- ✅ Convert AI percentage (0-100) → PWM (0-255) for Motor
- ✅ Support both `{"state": true}` and `{"action": "turn_on"}` for LED/Relay
- ✅ Send `{"angle": X}` for Servo
- ✅ Send `{"speed": X}` for Motor (after conversion)
- ✅ Subscribe to `/state` topics for real-time feedback

### For Arduino (ESP32):
- ✅ Parse BOTH formats: `state` and `action`
- ✅ Convert `action="turn_on"` → `speed=255` for Motor
- ✅ Constrain values: speed (0-255), angle (0-180)
- ✅ Publish state immediately after receiving command
- ✅ Support ping/pong for health check
- ❌ NO reverse direction for Motor (forward only)

---

## 🐛 Debugging Checklist

### Motor not working?
- ✅ Check if App converted % → PWM (0-255)
- ✅ Check if Arduino received `{"speed": X}` not `{"action": "turn_on"}`
- ✅ Verify L298N wiring: ENA, IN1, IN2
- ✅ Check power supply (12V for motor, 5V for logic)
- ✅ Ensure IN1=HIGH, IN2=LOW (not both HIGH)

### Servo not moving?
- ✅ Check if App sent `{"angle": X}` not `{"state": true}`
- ✅ Verify servo GPIO: GPIO13 (ROOF), GPIO14 (DOOR)
- ✅ Check external power supply (5A recommended)
- ✅ Ensure angle is 0-180 range

### LED/Relay not responding?
- ✅ Check MQTT topic: `smart_home/devices/{DEVICE_CODE}/cmd`
- ✅ Verify device code matches Arduino (e.g., LED_RED_001)
- ✅ Check if Arduino subscribed to correct topic
- ✅ Test with both formats: `{"state": true}` and `{"action": "turn_on"}`

### AI parsing wrong device?
- ✅ Check if device keyName matches exactly
- ✅ Verify fuzzy matching works (e.g., "đèn ngủ" → "Đèn phòng ngủ")
- ✅ Check if device exists in device list
- ✅ Review AI prompt examples

---

**Last Updated:** 2024-11-01 23:50 UTC+7
**Version:** 3.0
**Status:** ✅ Production Ready
