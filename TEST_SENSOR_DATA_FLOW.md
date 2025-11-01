# 🧪 TEST SENSOR DATA FLOW - Kiểm tra cập nhật UI từ MQTT

## 📊 Flow hiện tại (Đã verified):

```
ESP32 Arduino
    ↓ publish: smart_home/sensors/DHT22_001/state = {"type":"temperature","value":25.5}
    ↓
Global MQTT Service (MqttService)
    ↓ subscribe: smart_home/sensors/# (line 114)
    ↓ _onMessageReceived() callback
    ↓
MqttProvider.setMessageHandler()
    ↓ Forward message to SensorProvider.handleMqttMessage()
    ↓
SensorProvider.handleMqttMessage() (line 133-247)
    ↓ Parse topic: smart_home/sensors/DHT22_001/state
    ↓ Extract device code: DHT22_001
    ↓ Find sensor: _userSensors.firstWhere(s => s.deviceCode == DHT22_001)
    ↓ Parse JSON: {"value": 25.5}
    ↓ Update Firestore: _firestoreService.updateSensorValue()
    ↓
Firestore Real-time Listener (line 74-89)
    ↓ watchUserSensors() emits updated sensor list
    ↓ _sensorsSubscription.listen() receives update
    ↓ _userSensors = sensors; _safeNotify();
    ↓
Flutter UI (sensors_screen.dart)
    ↓ Consumer<SensorProvider> rebuilds
    ↓ sensor.formattedValue shows "25.5°C"
    ↓ sensor.lastUpdateAt shows "Cập nhật: vài giây trước"
```

---

## ✅ ĐIỀU KIỆN ĐỂ UI CẬP NHẬT:

### 1. App phải kết nối MQTT global (Settings)
```dart
// home_screen.dart - Line 36
_autoConnectMqtt() → mqtt.connect()
```

**Check:**
```
📡 Settings → MQTT Status = "Connected"
✅ Broker: 16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud
✅ Port: 8883, SSL: true
```

### 2. Global MQTT phải subscribe sensor topics
```dart
// mqtt_service.dart - Line 114
subscribeToAll() → subscribe('smart_home/sensors/#')
```

**Log expected:**
```
✅ MQTT: Connected callback
📥 MQTT: Subscribed to smart_home/sensors/#
✅ MQTT: Subscribed to all topics (sensors, devices, alerts, status)
```

### 3. Message handler phải được setup
```dart
// auth_wrapper.dart - Line 89, 149
mqttProvider.setMessageHandler(sensorProvider.handleMqttMessage);
```

**Log expected:**
```
🔗 AuthWrapper: Connected MQTT message handler to SensorProvider
```

### 4. Sensor phải tồn tại trong Firestore với deviceCode khớp
```dart
// sensor_provider.dart - Line 163-171
sensor = _userSensors.firstWhere((s) => s.deviceCode == deviceCode && s.isActive)
```

**Firestore structure:**
```
sensors/{userId}/userSensors/{sensorId}
  - displayName: "Nhiệt độ phòng khách"
  - deviceCode: "DHT22_001"  ← MUST MATCH Arduino device code!
  - sensorTypeId: "temperature"
  - mqttTopic: "smart_home/sensors/DHT22_001/state"
  - isActive: true
  - currentValue: 25.5
  - lastUpdateAt: Timestamp
```

### 5. Arduino phải publish đúng format
```cpp
// arduino/FullMQTT_Complete_Test.ino - Line 529
String topic = "smart_home/sensors/" + String(SENSOR_CODE) + "/state";
String payload = "{\"type\":\"temperature\",\"value\":" + String(temp) + "}";
client.publish(topic.c_str(), payload.c_str());
```

---

## 🧪 TEST PLAN:

### TEST 1: Thêm sensor qua UI
1. **Hot restart app** (R trong terminal)
2. **Sensors Screen** → tap "+" button
3. **Add Sensor Screen:**
   ```
   - Tên: "Test DHT22"
   - Device Code: "DHT22_001" ← QUAN TRỌNG!
   - Loại: Temperature (Nhiệt độ)
   - Broker 94 chip
   - Check "Tạo topic tự động" ← Topic = smart_home/sensors/DHT22_001/state
   ```
4. **Lưu sensor**
5. **Check Firestore:**
   ```
   Firebase Console → sensors/{userId}/userSensors/{newSensorId}
   Verify: deviceCode = "DHT22_001"
   ```

### TEST 2: Giả lập MQTT message (KHÔNG cần Arduino!)
**Option A: Dùng MQTTX client (Windows app)**
1. Download MQTTX: https://mqttx.app/
2. Connect to HiveMQ:
   ```
   Host: 16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud
   Port: 8883
   Protocol: mqtts://
   Username: sigma
   Password: 35386Doan
   SSL/TLS: Enable
   ```
3. Publish test message:
   ```
   Topic: smart_home/sensors/DHT22_001/state
   Payload: {"type":"temperature","value":25.5}
   QoS: 1
   ```

**Option B: Dùng PowerShell (mosquitto_pub)**
```powershell
# Install mosquitto client (if not installed)
# choco install mosquitto

mosquitto_pub `
  -h 16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud `
  -p 8883 `
  -u sigma `
  -P 35386Doan `
  --cafile "C:\path\to\cert.pem" `
  -t "smart_home/sensors/DHT22_001/state" `
  -m '{"type":"temperature","value":25.5}' `
  -q 1
```

### TEST 3: Quan sát logs trong VS Code Debug Console
**Expected logs sequence:**
```
📨 handleMqttMessage: topic=smart_home/sensors/DHT22_001/state, message={"type":"temperature","value":25.5}
🔍 Searching sensor by device code: DHT22_001
✅ Found sensor by device code: Test DHT22 (temperature)
📊 Parsed JSON value: 25.5
📊 Final value (double): 25.5
✅ Updated sensor: Test DHT22 = 25.5
📡 Received real-time sensor update: 1 sensors
🐞 DEBUG: Loaded sensor: Test DHT22 (DHT22_001)
```

### TEST 4: Verify UI update
**Sensors Screen should show:**
```
┌──────────────────────┐
│ 🌡️  Test DHT22       │
│                      │
│     25.5°C          │ ← Value updated!
│                      │
│ Cập nhật: vài giây   │ ← Timestamp updated!
│ trước                │
└──────────────────────┘
```

### TEST 5: Publish nhiều giá trị liên tục
```json
// Value 1
{"type":"temperature","value":26.0}

// Value 2 (sau 2 giây)
{"type":"temperature","value":26.5}

// Value 3 (sau 2 giây)
{"type":"temperature","value":27.0}
```

**Expected:** UI cập nhật realtime, mỗi giá trị mới hiển thị ngay!

---

## 🐛 TROUBLESHOOTING:

### ❌ Problem: UI không cập nhật
**Check 1: MQTT connected?**
```
Settings → MQTT → Connection Status = "Connected"?
```
→ Nếu "Disconnected": Tap "Kết nối" button

**Check 2: Subscribed to topics?**
```
Debug Console log:
📥 MQTT: Subscribed to smart_home/sensors/#
```
→ Nếu không có: Disconnect & reconnect MQTT

**Check 3: Message handler setup?**
```
Debug Console log:
🔗 AuthWrapper: Connected MQTT message handler to SensorProvider
```
→ Nếu không có: Hot restart app (R)

**Check 4: Device code khớp?**
```
Firestore: sensor.deviceCode = "DHT22_001"
MQTT topic: smart_home/sensors/DHT22_001/state
                              ^^^^^^^^^ phải khớp!
```
→ Nếu không khớp: Edit sensor, sửa device code

**Check 5: Message đến app?**
```
Debug Console log:
📨 handleMqttMessage: topic=..., message=...
```
→ Nếu không có log: Check MQTT publish thành công chưa?

---

## ✅ SUCCESS CRITERIA:

1. ✅ Publish MQTT message → Log xuất hiện trong Debug Console
2. ✅ SensorProvider.handleMqttMessage() parse thành công
3. ✅ Firestore sensor.currentValue updated
4. ✅ UI shows new value (25.5°C)
5. ✅ UI shows timestamp "Cập nhật: vài giây trước"
6. ✅ Publish giá trị mới → UI update realtime (không cần refresh)

---

## 📝 NOTES:

- **Global MQTT vs SensorMqttService:**
  - Global MQTT (MqttProvider): Dùng để **NHẬN DATA** từ Arduino (subscribe `sensors/#`)
  - SensorMqttService: Dùng để **PING sensor** (mỗi sensor tự kết nối broker riêng)
  
- **Tại sao cần 2 services?**
  - Ping: Sensor có thể ở broker khác nhau (custom config per sensor)
  - Data: App chỉ cần 1 MQTT global để nhận data từ tất cả sensors
  
- **Flow data về app:**
  ```
  Arduino publish → Global MQTT nhận → SensorProvider parse → 
  Update Firestore → Firestore listener → Update UI
  ```

- **Không cần Arduino để test!**
  - Dùng MQTTX hoặc mosquitto_pub để giả lập Arduino publish
  - Test được toàn bộ flow từ MQTT → UI
