# 📡 MQTT Components Reference - Tổng hợp tất cả phần liên quan MQTT

## 📋 Mục lục

1. [MQTT Services](#mqtt-services)
2. [MQTT Providers](#mqtt-providers)
3. [MQTT Models](#mqtt-models)
4. [MQTT Screens](#mqtt-screens)
5. [MQTT Utils](#mqtt-utils)
6. [Device Control với MQTT](#device-control)
7. [Sensor Data với MQTT](#sensor-data)
8. [Arduino MQTT Code](#arduino-mqtt)
9. [MQTT Topics Structure](#mqtt-topics)
10. [MQTT Message Formats](#mqtt-formats)

---

## 1. MQTT Services

### 🔹 `lib/services/mqtt_service.dart`
**Mục đích:** Service chính để kết nối MQTT broker (HiveMQ Cloud)

**Chức năng:**
- Kết nối/ngắt kết nối MQTT broker
- Subscribe/unsubscribe topics
- Publish messages
- Handle reconnection
- SSL/TLS connection

**Key Methods:**
```dart
Future<void> connect()
Future<void> disconnect()
void subscribe(String topic)
void unsubscribe(String topic)
void publish(String topic, String message)
bool get isConnected
MqttConnectionState get connectionState
```

**Sử dụng:**
```dart
final mqttService = MqttService();
await mqttService.connect();
mqttService.subscribe('smart_home/devices/#');
mqttService.publish('smart_home/devices/LED_001/cmd', '{"action":"turn_on"}');
```

---

### 🔹 `lib/services/device_mqtt_service.dart`
**Mục đích:** MQTT service riêng cho TỪNG DEVICE (mỗi device tự kết nối broker)

**Chức năng:**
- Ping device để check connectivity
- Mỗi device có thể config broker riêng (IP/Port/Username/Password)
- Publish lệnh điều khiển tới device
- Subscribe device state feedback

**Key Methods:**
```dart
Future<void> connectToCustomBroker(Device device)
Future<void> publishToCustomTopic(Device device, String topic, String message)
Future<void> subscribeToCustomTopic(Device device, String topic)
void setDeviceCallback(String deviceId, Function(String, String) callback)
void removeDeviceCallback(String deviceId)
void dispose()
```

**Sử dụng:**
```dart
// Device ping test
await _deviceMqttService.connectToCustomBroker(device);
await _deviceMqttService.publishToCustomTopic(
  device,
  'smart_home/devices/${device.deviceCode}/ping',
  '{"action":"ping"}',
);
```

---

### 🔹 `lib/services/sensor_mqtt_service.dart`
**Mục đích:** MQTT service riêng cho SENSOR (tương tự device_mqtt_service)

**Chức năng:**
- Ping sensor để check connectivity
- Mỗi sensor có thể config broker riêng
- Subscribe sensor data topic
- Handle sensor data updates

**Key Methods:**
```dart
Future<void> connectToCustomBroker(Sensor sensor)
Future<void> publishToCustomTopic(Sensor sensor, String topic, String message)
Future<void> subscribeToCustomTopic(Sensor sensor, String topic)
void setSensorCallback(String sensorId, Function(String, String) callback)
void removeSensorCallback(String sensorId)
void dispose()
```

---

### 🔹 `lib/services/mqtt_config_service.dart`
**Mục đích:** Lưu/load MQTT configuration từ shared preferences

**Chức năng:**
- Save/load MQTT broker config (broker, port, username, password, SSL)
- Validate MQTT config
- Manage default config

**Key Methods:**
```dart
Future<MqttConfig?> loadConfig()
Future<void> saveConfig(MqttConfig config)
Future<void> clearConfig()
MqttConfig getDefaultConfig()
```

---

## 2. MQTT Providers

### 🔹 `lib/providers/mqtt_provider.dart`
**Mục đích:** Provider quản lý MQTT state và connect với UI

**Chức năng:**
- Wrap MqttService để expose state cho UI
- Handle MQTT connection state
- Forward MQTT messages tới SensorProvider/DeviceProvider
- Auto-reconnect logic

**Key Properties:**
```dart
bool isConnected
MqttConnectionState connectionState
MqttService mqttService
```

**Key Methods:**
```dart
Future<void> connect()
Future<void> disconnect()
void setMessageHandler(Function(String topic, String message) handler)
```

**Sử dụng trong main.dart:**
```dart
final mqttService = MqttService();
ChangeNotifierProvider(create: (_) => MqttProvider(mqttService))
```

---

### 🔹 `lib/providers/device_provider.dart`
**Mục đích:** Quản lý devices và gửi MQTT commands

**Chức năng:**
- Load/save devices từ Firestore
- Gửi MQTT commands để điều khiển device
- Nhận MQTT feedback từ device (qua MqttProvider)
- Ping device để check connectivity

**MQTT Related Methods:**
```dart
// Điều khiển device
Future<void> updateDeviceState(String id, bool state)
Future<void> toggleDevice(String id)
Future<void> updateServoValue(String id, int value)

// Ping device
Future<bool> checkDeviceMqttConnection(Device device)

// Lắng nghe MQTT feedback
void handleDeviceState(String topic, String message)
```

**MQTT Message Flow:**
```
1. User tap button → toggleDevice(id)
2. DeviceProvider.toggleDevice() → publish MQTT
   Topic: smart_home/devices/{deviceCode}/cmd
   Message: {"action":"turn_on"} hoặc {"state":true}
3. Arduino nhận → điều khiển hardware → publish feedback
   Topic: smart_home/devices/{deviceCode}/state
   Message: {"state":"ON","timestamp":12345}
4. MqttProvider nhận → forward tới DeviceProvider.handleDeviceState()
5. DeviceProvider parse → update UI
```

**Code example từ device_provider.dart:**
```dart
// Line ~500: Toggle device via MQTT
Future<void> toggleDevice(String id) async {
  final device = _devices.firstWhere((d) => d.id == id);
  final newState = !device.state;
  
  // Publish MQTT command
  final topic = '${MqttTopics.base}/devices/${device.deviceCode}/cmd';
  final message = jsonEncode({'action': newState ? 'turn_on' : 'turn_off'});
  _mqttProvider?.mqttService.publish(topic, message);
  
  // Update local state
  device.state = newState;
  notifyListeners();
}
```

---

### 🔹 `lib/providers/sensor_provider.dart`
**Mục đích:** Nhận sensor data từ MQTT và update UI

**Chức năng:**
- Subscribe sensor topics qua SensorMqttService
- Parse MQTT messages từ Arduino
- Update sensor values trong real-time
- Trigger push notifications khi sensor vượt ngưỡng
- Ping sensor để check connectivity

**MQTT Related Methods:**
```dart
// Nhận MQTT sensor data
Future<void> handleMqttMessage(String topic, String message)

// Subscribe sensor topic
Future<void> subscribeSensorTopic(Sensor sensor)

// Ping sensor
Future<bool> checkSensorMqttConnection(Sensor sensor)
```

**MQTT Message Flow:**
```
1. Arduino đọc sensor → publish lên MQTT
   Topic: smart_home/sensors/{sensorCode}/state
   Message: {"type":"temperature","value":25.5,"timestamp":12345}
   
2. Global MQTT (MqttProvider) subscribe smart_home/sensors/#
   → Nhận message → forward tới SensorProvider.handleMqttMessage()
   
3. SensorProvider parse message:
   - Tìm sensor theo topic
   - Extract value (temperature, humidity, gas, etc.)
   - Convert data type (bool, numeric, string)
   - Update sensor.value
   - notifyListeners() → UI tự động update
   
4. Kiểm tra threshold:
   - Nếu value vượt ngưỡng → gọi NotificationService
   - Gửi push notification cho user
```

**Code example từ sensor_provider.dart:**
```dart
// Line 193-371: Handle MQTT message
Future<void> handleMqttMessage(String topic, String message) async {
  print('🔔 [SENSOR] NEW MQTT MESSAGE RECEIVED!');
  print('   Topic: $topic');
  print('   Message: $message');
  
  try {
    final data = jsonDecode(message);
    
    // Tìm sensor theo topic
    final sensor = _sensors.firstWhere(
      (s) => s.mqttTopic == topic && s.isActive,
      orElse: () => throw Exception('Sensor not found'),
    );
    
    // Parse value dựa vào data type
    dynamic value = data['value'];
    
    switch (sensor.dataType) {
      case SensorDataType.numeric:
        value = (value is num) ? value.toDouble() : double.tryParse(value.toString());
        break;
        
      case SensorDataType.bool:
        bool boolValue = value == true || value == 1 || value == '1';
        // 🔥 SPECIAL: Motion sensor logic inverted (0=detected, 1=not detected)
        if (sensor.deviceCode.toLowerCase().contains('motion') ||
            sensor.deviceCode.toLowerCase().contains('pir') ||
            sensor.deviceCode.toLowerCase().contains('ir_')) {
          value = !boolValue; // Invert logic
        } else {
          value = boolValue;
        }
        break;
        
      case SensorDataType.string:
        value = value.toString();
        break;
    }
    
    // Update sensor value
    sensor.value = value;
    sensor.lastUpdate = DateTime.now();
    notifyListeners();
    
    // Check threshold và gửi notification
    await _notificationService.checkThresholdAndNotify(sensor);
    
  } catch (e) {
    print('❌ [SENSOR] ERROR in handleMqttMessage: $e');
  }
}
```

---

## 3. MQTT Models

### 🔹 `lib/models/mqtt_config.dart`
**Mục đích:** Model chứa cấu hình MQTT broker

**Fields:**
```dart
String broker;          // Broker address (e.g., "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud")
int port;               // Port (8883 for SSL/TLS)
String? username;       // MQTT username
String? password;       // MQTT password
bool useSsl;            // Enable SSL/TLS
String? clientId;       // MQTT client ID
```

**Methods:**
```dart
factory MqttConfig.fromJson(Map<String, dynamic> json)
Map<String, dynamic> toJson()
MqttConfig copyWith({...})
```

---

### 🔹 `lib/models/device_mqtt_config.dart`
**Mục đích:** MQTT config riêng cho TỪNG DEVICE (extends MqttConfig)

**Additional Fields:**
```dart
String? customTopic;    // Custom MQTT topic cho device này
```

**Sử dụng:**
```dart
final config = DeviceMqttConfig(
  broker: '192.168.1.100',
  port: 1883,
  username: 'device_user',
  password: 'pass123',
  useSsl: false,
  customTopic: 'smart_home/devices/RELAY_001/cmd',
);
```

---

## 4. MQTT Screens

### 🔹 `lib/screens/settings/mqtt_settings_screen.dart`
**Mục đích:** UI để config MQTT broker chính (global)

**Features:**
- Input broker address, port, username, password
- Toggle SSL/TLS
- Test connection button
- Save/load config
- Show connection status

---

### 🔹 `lib/screens/devices/device_mqtt_config_screen.dart`
**Mục đích:** UI để config MQTT broker riêng cho TỪNG DEVICE

**Features:**
- Override global MQTT config
- Custom broker per device
- Custom topic per device
- Ping test button

---

## 5. MQTT Utils

### 🔹 `lib/utils/mqtt_topics.dart`
**Mục đích:** Helper class để generate MQTT topics

**Constants:**
```dart
static const String base = 'smart_home';
static const String devices = 'devices';
static const String sensors = 'sensors';
static const String alerts = 'alerts';
static const String status = 'status';
```

**Methods:**
```dart
static String deviceCommand(String deviceCode)
  → 'smart_home/devices/{deviceCode}/cmd'
  
static String deviceState(String deviceCode)
  → 'smart_home/devices/{deviceCode}/state'
  
static String sensorState(String sensorCode)
  → 'smart_home/sensors/{sensorCode}/state'
  
static String devicePing(String deviceCode)
  → 'smart_home/devices/{deviceCode}/ping'
```

**Sử dụng:**
```dart
import '../../utils/mqtt_topics.dart';

final topic = MqttTopics.deviceCommand('RELAY_001');
// → "smart_home/devices/RELAY_001/cmd"
```

---

## 6. Device Control với MQTT

### Flow điều khiển device:

```
┌──────────────┐
│     USER     │ Tap button "Bật đèn"
└──────┬───────┘
       │
       ▼
┌──────────────────────────┐
│  DeviceProvider          │
│  toggleDevice(id)        │
│  → Build MQTT message    │
└──────┬───────────────────┘
       │
       ▼ Publish
┌──────────────────────────┐
│  MqttService             │
│  publish(topic, message) │
└──────┬───────────────────┘
       │
       ▼ Via HiveMQ Cloud
┌──────────────────────────┐
│  ESP32 Arduino           │
│  mqtt_callback()         │
│  → digitalWrite(LED, HIGH)│
└──────┬───────────────────┘
       │
       ▼ Publish feedback
┌──────────────────────────┐
│  MqttService             │
│  onMessage callback      │
└──────┬───────────────────┘
       │
       ▼ Forward
┌──────────────────────────┐
│  DeviceProvider          │
│  handleDeviceState()     │
│  → Update device.state   │
│  → notifyListeners()     │
└──────┬───────────────────┘
       │
       ▼
┌──────────────┐
│  UI UPDATE   │ Icon đổi màu
└──────────────┘
```

### Code example:

**1. User tap button trong device_card.dart:**
```dart
IconButton(
  icon: Icon(device.state ? Icons.lightbulb : Icons.lightbulb_outline),
  onPressed: () {
    deviceProvider.toggleDevice(device.id);
  },
)
```

**2. DeviceProvider gửi MQTT:**
```dart
// device_provider.dart
Future<void> toggleDevice(String id) async {
  final device = _devices.firstWhere((d) => d.id == id);
  final newState = !device.state;
  
  // Build MQTT topic
  final topic = MqttTopics.deviceCommand(device.deviceCode);
  // → "smart_home/devices/RELAY_001/cmd"
  
  // Build MQTT message (Arduino hỗ trợ nhiều format)
  final message = jsonEncode({
    'action': newState ? 'turn_on' : 'turn_off',
    'deviceCode': device.deviceCode,
  });
  
  // Publish via MqttProvider
  _mqttProvider?.mqttService.publish(topic, message);
  
  // Update local state (optimistic update)
  device.state = newState;
  notifyListeners();
}
```

**3. Arduino nhận và điều khiển:**
```cpp
// FullMQTT_Smart_Publishing.ino - Line 567
void mqtt_callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  // Parse JSON
  DynamicJsonDocument doc(256);
  deserializeJson(doc, message);
  
  // Check topic
  if (String(topic).indexOf("/RELAY_001/") >= 0) {
    // Parse command (hỗ trợ nhiều format)
    bool state = false;
    
    if (doc.containsKey("action")) {
      String action = doc["action"];
      state = (action == "turn_on");
    } else if (doc.containsKey("state")) {
      state = doc["state"];
    }
    
    // Control hardware
    digitalWrite(RELAY_PIN, state ? HIGH : LOW);
    
    // Publish feedback
    StaticJsonDocument<128> response;
    response["state"] = state ? "ON" : "OFF";
    response["timestamp"] = millis();
    
    char buffer[128];
    serializeJson(response, buffer);
    client.publish("smart_home/devices/RELAY_001/state", buffer);
  }
}
```

**4. App nhận feedback:**
```dart
// device_provider.dart
void handleDeviceState(String topic, String message) {
  try {
    final data = jsonDecode(message);
    
    // Extract deviceCode from topic
    // "smart_home/devices/RELAY_001/state" → "RELAY_001"
    final deviceCode = topic.split('/')[2];
    
    // Find device
    final device = _devices.firstWhere(
      (d) => d.deviceCode == deviceCode,
      orElse: () => throw Exception('Device not found'),
    );
    
    // Update state
    if (data.containsKey('state')) {
      device.state = (data['state'] == 'ON' || data['state'] == true);
      notifyListeners();
    }
  } catch (e) {
    print('❌ Error handling device state: $e');
  }
}
```

---

## 7. Sensor Data với MQTT

### Flow nhận sensor data:

```
┌──────────────────────────┐
│  ESP32 Arduino           │
│  Read DHT22 sensor       │
│  temp = 25.5°C           │
└──────┬───────────────────┘
       │
       ▼ Publish (every 30s)
┌──────────────────────────┐
│  MQTT Broker (HiveMQ)    │
│  Topic: smart_home/      │
│    sensors/DHT22_001/    │
│    state                 │
└──────┬───────────────────┘
       │
       ▼ Subscribe smart_home/sensors/#
┌──────────────────────────┐
│  Global MqttService      │
│  onMessage callback      │
└──────┬───────────────────┘
       │
       ▼ Forward via MqttProvider
┌──────────────────────────┐
│  SensorProvider          │
│  handleMqttMessage()     │
│  → Parse JSON            │
│  → Find sensor by topic  │
│  → Update sensor.value   │
│  → Check threshold       │
│  → Send notification     │
│  → notifyListeners()     │
└──────┬───────────────────┘
       │
       ▼
┌──────────────┐
│  UI UPDATE   │ Chart + Card update
└──────────────┘
```

### Code example:

**1. Arduino gửi sensor data:**
```cpp
// FullMQTT_Smart_Publishing.ino - Line 320-340
void publishSensors() {
  // Read DHT22
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  
  if (!isnan(temp)) {
    // Publish temperature
    StaticJsonDocument<128> doc;
    doc["type"] = "temperature";
    doc["value"] = temp;
    doc["unit"] = "°C";
    doc["timestamp"] = millis();
    
    char buffer[128];
    serializeJson(doc, buffer);
    
    client.publish("smart_home/sensors/DHT22_001/state", buffer);
    
    // Publish humidity
    doc["type"] = "humidity";
    doc["value"] = hum;
    doc["unit"] = "%";
    serializeJson(doc, buffer);
    
    client.publish("smart_home/sensors/DHT22_001/state", buffer);
  }
}
```

**2. App setup MQTT subscription:**
```dart
// mqtt_service.dart - Line 114-120
Future<void> connect() async {
  // ... connect logic ...
  
  // Subscribe to all sensor topics
  subscribe('${MqttTopics.base}/sensors/#');
  subscribe('${MqttTopics.base}/devices/#');
  subscribe('${MqttTopics.base}/alerts/#');
  
  print('✅ MQTT: Subscribed to all topics');
}
```

**3. Forward messages tới SensorProvider:**
```dart
// auth_wrapper.dart - Line 50-60
// Setup MQTT message handler
final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
final sensorProvider = Provider.of<SensorProvider>(context, listen: false);

mqttProvider.setMessageHandler((topic, message) {
  if (topic.contains('/sensors/')) {
    sensorProvider.handleMqttMessage(topic, message);
  } else if (topic.contains('/devices/')) {
    deviceProvider.handleDeviceState(topic, message);
  }
});
```

**4. SensorProvider parse và update:**
```dart
// sensor_provider.dart - Line 193-371
Future<void> handleMqttMessage(String topic, String message) async {
  print('🔔 [SENSOR] NEW MQTT MESSAGE!');
  print('   Topic: $topic');
  print('   Message: $message');
  
  try {
    final data = jsonDecode(message);
    
    // Find sensor by topic
    final sensor = _sensors.firstWhere(
      (s) => s.mqttTopic == topic && s.isActive,
      orElse: () => throw Exception('Sensor not found for topic: $topic'),
    );
    
    print('✅ Found sensor: ${sensor.displayName}');
    
    // Extract value
    dynamic value = data['value'];
    
    // Convert based on data type
    switch (sensor.dataType) {
      case SensorDataType.numeric:
        value = (value is num) 
            ? value.toDouble() 
            : double.tryParse(value.toString()) ?? 0.0;
        break;
        
      case SensorDataType.bool:
        bool boolValue = value == true || value == 1 || value == '1';
        
        // 🔥 Special case: IR/PIR motion sensor (inverted logic)
        if (sensor.deviceCode.toLowerCase().contains('motion') ||
            sensor.deviceCode.toLowerCase().contains('pir') ||
            sensor.deviceCode.toLowerCase().contains('ir_')) {
          value = !boolValue; // Invert: 0 → true (detected), 1 → false (not detected)
          print('🔄 [IR SENSOR] Inverted logic: $value');
        } else {
          value = boolValue;
        }
        break;
        
      case SensorDataType.string:
        value = value.toString();
        break;
    }
    
    // Update sensor
    sensor.value = value;
    sensor.lastUpdate = DateTime.now();
    notifyListeners();
    
    print('✅ Updated sensor value: $value');
    
    // Check threshold và gửi notification
    await _notificationService.checkThresholdAndNotify(sensor);
    
  } catch (e) {
    print('❌ [SENSOR] ERROR: $e');
  }
}
```

---

## 8. Arduino MQTT Code

### Main Arduino file: `arduino/FullMQTT_Smart_Publishing.ino`

**Key sections:**

**1. WiFi & MQTT Config (Line 42-60):**
```cpp
// WiFi
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT Broker (HiveMQ Cloud)
const char* mqtt_server = "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;              // SSL/TLS port
const char* mqtt_user = "sigma";
const char* mqtt_pass = "35386Doan";
```

**2. MQTT Setup (Line 260-263):**
```cpp
void setup() {
  // ...
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(mqtt_callback);
  
  // ...
}
```

**3. MQTT Reconnect (Line 496-564):**
```cpp
void reconnect_mqtt() {
  while (!client.connected()) {
    Serial.print("🔄 Attempting MQTT connection...");
    
    if (client.connect(DEVICE_ID, mqtt_user, mqtt_pass)) {
      Serial.println("✅ CONNECTED!");
      
      // Subscribe to command topics
      client.subscribe("smart_home/devices/RELAY_PUMP_001/cmd");
      client.subscribe("smart_home/devices/RELAY_LIGHT_001/cmd");
      client.subscribe("smart_home/devices/LED_WHITE_001/cmd");
      client.subscribe("smart_home/devices/SERVO_DOOR_001/cmd");
      client.subscribe("smart_home/devices/SERVO_ROOF_001/cmd");
      client.subscribe("smart_home/devices/MOTOR_FAN_A_001/cmd");
      client.subscribe("smart_home/devices/MOTOR_FAN_B_001/cmd");
      
      Serial.println("📥 Subscribed to all device command topics");
    } else {
      Serial.print("❌ FAILED, rc=");
      Serial.println(client.state());
      delay(5000);
    }
  }
}
```

**4. MQTT Callback (Line 567-750):**
```cpp
void mqtt_callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("\n📨 MQTT Message Received:");
  Serial.print("   Topic: ");
  Serial.println(topic);
  
  // Convert payload to string
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.print("   Message: ");
  Serial.println(message);
  
  // Parse JSON
  DynamicJsonDocument doc(256);
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.print("❌ JSON parse failed: ");
    Serial.println(error.c_str());
    return;
  }
  
  // Route to appropriate handler based on topic
  String topicStr = String(topic);
  
  if (topicStr.indexOf("/RELAY_PUMP_001/") >= 0) {
    handleRelayCommand(doc, RELAY_PUMP_PIN, "RELAY_PUMP_001");
  }
  else if (topicStr.indexOf("/RELAY_LIGHT_001/") >= 0) {
    handleRelayCommand(doc, RELAY_LIGHT_PIN, "RELAY_LIGHT_001");
  }
  else if (topicStr.indexOf("/LED_WHITE_001/") >= 0) {
    handleLedCommand(doc, LED_WHITE_PIN, "LED_WHITE_001");
  }
  else if (topicStr.indexOf("/SERVO_DOOR_001/") >= 0) {
    handleServoCommand(doc, &servo1, "SERVO_DOOR_001");
  }
  else if (topicStr.indexOf("/MOTOR_FAN_A_001/") >= 0) {
    handleMotorCommand(doc, MOTOR_A_IN1, MOTOR_A_IN2, MOTOR_A_ENA, "MOTOR_FAN_A_001");
  }
  // ... more handlers ...
}

void handleRelayCommand(JsonDocument& doc, int pin, const char* deviceCode) {
  bool state = false;
  
  // Parse command (supports multiple formats)
  if (doc.containsKey("action")) {
    String action = doc["action"];
    state = (action == "turn_on");
  } else if (doc.containsKey("state")) {
    state = doc["state"];
  }
  
  // Control hardware
  digitalWrite(pin, state ? HIGH : LOW);
  
  Serial.print("✅ ");
  Serial.print(deviceCode);
  Serial.print(" → ");
  Serial.println(state ? "ON" : "OFF");
  
  // Publish feedback
  publishDeviceState(deviceCode, state ? "ON" : "OFF");
}
```

**5. Publish Sensor Data (Line 320-450):**
```cpp
void publishSensors() {
  unsigned long currentMillis = millis();
  
  // DHT22 - Temperature & Humidity (30s interval)
  if (currentMillis - lastDHT22Publish >= 30000) {
    lastDHT22Publish = currentMillis;
    
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    
    if (!isnan(temp) && !isnan(hum)) {
      // Publish temperature
      publishSensorValue("DHT22_001", "temperature", temp, "°C");
      
      // Publish humidity
      publishSensorValue("DHT22_001", "humidity", hum, "%");
    }
  }
  
  // MQ2 Gas Sensor (30s interval)
  if (currentMillis - lastMQ2Publish >= 30000) {
    lastMQ2Publish = currentMillis;
    
    int gasValue = analogRead(MQ2_PIN);
    publishSensorValue("MQ2_001", "gas", gasValue, "ppm");
  }
  
  // PIR Motion Sensor (state change only)
  bool currentMotionState = (digitalRead(PIR_PIN) == LOW); // LOW = detected
  
  if (currentMotionState != lastMotionState) {
    lastMotionState = currentMotionState;
    
    // Publish motion state (0 = detected, 1 = not detected)
    publishSensorValue("PIR_001", "motion", currentMotionState ? 0 : 1, "");
    
    Serial.print("🚶 Motion: ");
    Serial.println(currentMotionState ? "DETECTED" : "NOT DETECTED");
  }
  
  // ... more sensors ...
}

void publishSensorValue(const char* deviceCode, const char* type, 
                       float value, const char* unit) {
  StaticJsonDocument<128> doc;
  doc["type"] = type;
  doc["value"] = value;
  if (strlen(unit) > 0) {
    doc["unit"] = unit;
  }
  doc["timestamp"] = millis();
  
  char buffer[128];
  serializeJson(doc, buffer);
  
  char topic[64];
  snprintf(topic, sizeof(topic), "smart_home/sensors/%s/state", deviceCode);
  
  client.publish(topic, buffer);
}
```

---

## 9. MQTT Topics Structure

### Standard Topics:

```
smart_home/
├── devices/
│   ├── {DEVICE_CODE}/
│   │   ├── cmd        ← App gửi lệnh điều khiển
│   │   ├── state      ← Arduino gửi trạng thái feedback
│   │   └── ping       ← App gửi ping test
│   │
│   ├── RELAY_PUMP_001/
│   │   ├── cmd
│   │   ├── state
│   │   └── ping
│   │
│   ├── LED_WHITE_001/
│   │   ├── cmd
│   │   ├── state
│   │   └── ping
│   │
│   └── MOTOR_FAN_A_001/
│       ├── cmd
│       ├── state
│       └── ping
│
├── sensors/
│   ├── {SENSOR_CODE}/
│   │   ├── state      ← Arduino gửi sensor data
│   │   └── ping       ← App gửi ping test
│   │
│   ├── DHT22_001/
│   │   ├── state
│   │   └── ping
│   │
│   └── MQ2_001/
│       ├── state
│       └── ping
│
├── alerts/
│   └── system         ← Alerts & warnings
│
└── status/
    └── heartbeat      ← System heartbeat
```

### Subscription Patterns:

**App subscriptions:**
```dart
// Subscribe all sensor data
subscribe('smart_home/sensors/#');

// Subscribe all device states
subscribe('smart_home/devices/#');

// Subscribe specific device
subscribe('smart_home/devices/RELAY_001/state');
```

**Arduino subscriptions:**
```cpp
// Subscribe all device commands
client.subscribe("smart_home/devices/+/cmd");

// Subscribe specific device
client.subscribe("smart_home/devices/RELAY_PUMP_001/cmd");
```

---

## 10. MQTT Message Formats

### Device Commands (App → Arduino):

**Format 1: Action-based (recommended)**
```json
{
  "action": "turn_on",
  "deviceCode": "RELAY_001"
}
```

**Format 2: State-based**
```json
{
  "state": true
}
```

**Format 3: Value-based (for servo/motor)**
```json
{
  "action": "set_value",
  "value": 180
}
```

**Motor/Fan formats:**
```json
// Tắt
{"speed": 0}

// Bật (speed 0-255)
{"speed": 171}

// Alternative
{"action": "turn_on"}
{"action": "turn_off"}
```

**Servo formats:**
```json
// Set angle
{"angle": 180}

// Alternative
{"action": "set_value", "value": 180}
```

---

### Device States (Arduino → App):

**Relay/LED feedback:**
```json
{
  "state": "ON",
  "timestamp": 12345678
}
```

**Motor feedback:**
```json
{
  "speed": 171,
  "state": true,
  "timestamp": 12345678
}
```

**Servo feedback:**
```json
{
  "angle": 180,
  "state": true,
  "timestamp": 12345678
}
```

---

### Sensor Data (Arduino → App):

**Temperature:**
```json
{
  "type": "temperature",
  "value": 25.5,
  "unit": "°C",
  "timestamp": 12345678
}
```

**Humidity:**
```json
{
  "type": "humidity",
  "value": 65.2,
  "unit": "%",
  "timestamp": 12345678
}
```

**Gas:**
```json
{
  "type": "gas",
  "value": 350,
  "unit": "ppm",
  "timestamp": 12345678
}
```

**Motion (boolean):**
```json
{
  "type": "motion",
  "value": 0,
  "timestamp": 12345678
}
```
Note: Motion sensor logic:
- Arduino gửi: `0` = detected, `1` = not detected (hardware LOW = detected)
- App đảo ngược: `0` → `true`, `1` → `false` (chỉ cho motion sensor)

**Rain (boolean):**
```json
{
  "type": "rain",
  "value": 1,
  "timestamp": 12345678
}
```
Note: `0` = có mưa, `1` = không mưa

**Soil Moisture:**
```json
{
  "type": "soil_moisture",
  "value": 450,
  "unit": "raw",
  "timestamp": 12345678
}
```

---

### Ping Messages:

**App → Device/Sensor:**
```json
{
  "action": "ping",
  "timestamp": 1699000000
}
```

**Arduino → App:**
```json
{
  "pong": true,
  "timestamp": 12345678
}
```

---

## 🔍 Quick Reference

### Khi cần gửi lệnh điều khiển device:

```dart
// 1. Get topic
final topic = MqttTopics.deviceCommand(device.deviceCode);

// 2. Build message
final message = jsonEncode({'action': 'turn_on'});

// 3. Publish
mqttProvider.mqttService.publish(topic, message);
```

### Khi cần nhận sensor data:

```dart
// 1. Subscribe trong mqtt_service.dart
subscribe('smart_home/sensors/#');

// 2. Forward trong auth_wrapper.dart
mqttProvider.setMessageHandler((topic, message) {
  if (topic.contains('/sensors/')) {
    sensorProvider.handleMqttMessage(topic, message);
  }
});

// 3. Parse trong sensor_provider.dart
Future<void> handleMqttMessage(String topic, String message) {
  final data = jsonDecode(message);
  final sensor = _sensors.firstWhere((s) => s.mqttTopic == topic);
  sensor.value = data['value'];
  notifyListeners();
}
```

### Khi cần ping test device:

```dart
// device_provider.dart
Future<bool> checkDeviceMqttConnection(Device device) async {
  await _deviceMqttService.connectToCustomBroker(device);
  
  final topic = '${device.customMqttTopic}/ping';
  await _deviceMqttService.publishToCustomTopic(
    device, 
    topic, 
    '{"action":"ping"}'
  );
  
  // Wait for pong...
}
```

---

## 📚 Related Documentation

- **MQTT_FORMAT_DOCUMENTATION.md** - Chi tiết tất cả format MQTT
- **MQTT_FORMAT_COMPARISON.md** - So sánh format App vs Arduino
- **AI_PROMPT_UPDATE_SUMMARY.md** - MQTT format trong AI voice control
- **DEVICE_KEYS_FOR_AI.md** - Device codes và MQTT topics
- **TEST_SENSOR_DATA_FLOW.md** - Test flow nhận sensor data
- **SENSOR_REALTIME_UPDATE_TEST.md** - Debug real-time sensor updates

---

## ✅ Checklist MQTT Integration

### Backend (Arduino):
- [x] WiFi connection
- [x] MQTT SSL/TLS connection to HiveMQ
- [x] Subscribe device command topics
- [x] Parse multiple JSON formats
- [x] Control hardware (relay, LED, servo, motor)
- [x] Publish device state feedback
- [x] Publish sensor data (temperature, humidity, gas, motion, rain, etc.)
- [x] Smart publishing (avoid spam)
- [x] Reconnect logic

### App (Flutter):
- [x] Global MQTT service (MqttService)
- [x] Device-specific MQTT service (DeviceMqttService)
- [x] Sensor-specific MQTT service (SensorMqttService)
- [x] MQTT Provider (state management)
- [x] Device control via MQTT
- [x] Sensor data subscription
- [x] Real-time UI updates
- [x] MQTT config screens
- [x] Connection status indicators
- [x] Ping test functionality
- [x] Error handling & reconnection
- [x] Push notifications on threshold violations

---

**Last updated:** November 3, 2025
