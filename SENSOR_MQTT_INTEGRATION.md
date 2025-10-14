# 📡 Sensor MQTT Integration - Implementation Progress

## ✅ Step 1: Update UserSensor Model (COMPLETED)

### Fields Added:
```dart
// 📡 MQTT Configuration
final String? sensorId;        // ESP32 MAC-based ID (giống deviceId)
final String? mqttBroker;      // ví dụ: broker.hivemq.cloud
final int? mqttPort;           // ví dụ: 8883 (SSL) hoặc 1883
final String? mqttUsername;    // MQTT username
final String? mqttPassword;    // MQTT password
final bool mqttUseSsl;         // true = SSL/TLS, false = plain
```

### Methods Updated:
- ✅ `fromJson()` - Parse MQTT config từ JSON
- ✅ `toJson()` - Serialize MQTT config to JSON  
- ✅ `copyWith()` - Copy sensor với MQTT config mới

---

## 📋 Next Steps:

### Step 2: Update Add Sensor UI ⏳
**File**: `lib/screens/sensors/add_sensor_screen.dart`

Cần thêm:
```dart
// Form controllers
TextEditingController _sensorIdController
TextEditingController _mqttBrokerController
TextEditingController _mqttPortController
TextEditingController _mqttUsernameController
TextEditingController _mqttPasswordController
bool _mqttUseSsl

// UI Section: MQTT Configuration
- Sensor ID (ESP32 MAC)
- Broker address
- Port (default: 8883 cho SSL, 1883 cho non-SSL)
- Username
- Password (obscure text)
- SSL toggle

// Test Connection button
- Similar to device test connection
- Subscribe to sensor topic
- Publish ping
- Wait for response
```

### Step 3: SensorProvider - Auto Ping ⏳
**File**: `lib/providers/sensor_provider.dart`

Cần thêm:
```dart
// Track sensor online status
Map<String, bool> _sensorOnlineStatus = {};

// Methods
Future<void> pingSensor(UserSensor sensor)
Future<void> pingAllSensors()
void startAutoPing()  // Every 5 minutes
void stopAutoPing()
bool isSensorOnline(String sensorId)
int get onlineSensorsCount
```

**Logic**:
```
For each sensor:
  Subscribe: smart_home/sensors/{sensorId}/{sensorName}/state
  Publish: smart_home/sensors/{sensorId}/{sensorName}/ping → "ping"
  Wait for response: "1" | "online" | "pong"
  Update _sensorOnlineStatus
```

### Step 4: Update Sensor UI - Show Status ⏳
**Files**:
- `lib/screens/sensors/sensors_screen.dart`
- `lib/widgets/sensor_card.dart`

Hiển thị:
```dart
// Header
Text('$onlineCount/$totalCount cảm biến online')

// Sensor Card
Row(
  children: [
    Icon(
      Icons.circle,
      color: isOnline ? Colors.green : Colors.red,
      size: 12,
    ),
    Text(sensor.displayName),
  ],
)
```

### Step 5: ESP32 Implementation ⏳
**Sensor Code**:
```cpp
String SENSOR_ID = "ESP32_" + WiFi.macAddress();
String pingTopic = "smart_home/sensors/" + SENSOR_ID + "/" + SENSOR_NAME + "/ping";
String stateTopic = "smart_home/sensors/" + SENSOR_ID + "/" + SENSOR_NAME + "/state";
String dataTopic = "smart_home/sensors/" + SENSOR_ID + "/" + SENSOR_NAME + "/data";

void setup() {
  // Subscribe to ping
  mqttClient.subscribe(pingTopic.c_str());
}

void onMessage(String topic, String message) {
  if (topic == pingTopic && message == "ping") {
    // Respond with pong
    mqttClient.publish(stateTopic.c_str(), "pong");
  }
}

void loop() {
  // Đọc sensor data
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  // Publish sensor data
  String payload = String(temp) + "," + String(humidity);
  mqttClient.publish(dataTopic.c_str(), payload.c_str());
  
  delay(5000); // 5 giây publish 1 lần
}
```

---

## 📊 Topic Structure

### Sensors (Similar to Devices):

| Purpose | Topic Pattern | Example |
|---------|--------------|---------|
| Data | `smart_home/sensors/{sensorId}/{name}/data` | `smart_home/sensors/ESP32_AA:BB:CC/DHT22/data` |
| Ping | `smart_home/sensors/{sensorId}/{name}/ping` | `smart_home/sensors/ESP32_AA:BB:CC/DHT22/ping` |
| State | `smart_home/sensors/{sensorId}/{name}/state` | `smart_home/sensors/ESP32_AA:BB:CC/DHT22/state` |

### Payload Examples:

**Data Topic**:
```json
{
  "temperature": 25.5,
  "humidity": 60.2,
  "timestamp": 1697270400
}
```
Hoặc CSV format:
```
25.5,60.2
```

**Ping/Pong**:
```
ping  → pong
```

---

## 🔄 Comparison: Device vs Sensor

| Feature | Device | Sensor |
|---------|--------|--------|
| **Purpose** | Control (relay, servo, fan) | Monitor (temp, humidity, light) |
| **Direction** | App → ESP32 (command) | ESP32 → App (data) |
| **Topics** | `/cmd`, `/state`, `/ping` | `/data`, `/state`, `/ping` |
| **Auto-Ping** | ✅ Every 5 min | ✅ Every 5 min |
| **MQTT Config** | ✅ Per device | ✅ Per sensor |
| **ID Field** | `deviceId` | `sensorId` |
| **Online Status** | 🟢/🔴 | 🟢/🔴 |

---

## ✅ Current Status:

- [x] Step 1: UserSensor model updated with MQTT config
- [ ] Step 2: Add Sensor UI - MQTT form
- [ ] Step 3: SensorProvider auto-ping
- [ ] Step 4: Sensor UI - online/offline indicator
- [ ] Step 5: ESP32 sensor code

---

## 🎯 Next Immediate Action:

**Update Add Sensor Screen** để thêm form MQTT config giống Add Device Screen!

Bạn muốn tiếp tục Step 2 không? 🚀
