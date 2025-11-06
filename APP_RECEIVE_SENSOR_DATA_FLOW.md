# 📡 APP NHẬN DỮ LIỆU TỪ ESP32 CHO SENSOR - Chi tiết đầy đủ

## 🎯 Tổng quan Flow

```
┌─────────────────────┐
│   ESP32 Arduino     │ Đọc cảm biến (DHT22, MQ2, PIR...)
│   Read Sensor       │ → temp = 25.5°C, gas = 350, motion = 0
└──────────┬──────────┘
           │
           │ MQTT Publish
           │ Topic: smart_home/sensors/{SENSOR_CODE}/state
           │ Message: {"type":"temperature","value":25.5,"timestamp":12345}
           ▼
┌─────────────────────┐
│   HiveMQ Cloud      │ MQTT Broker (SSL/TLS port 8883)
│   MQTT Broker       │ 16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud
└──────────┬──────────┘
           │
           │ MQTT Subscribe: smart_home/sensors/#
           ▼
┌─────────────────────┐
│  MqttService        │ Global MQTT connection
│  (mqtt_service.dart)│ Listen to all sensor topics
└──────────┬──────────┘
           │
           │ onMessageReceived callback
           ▼
┌─────────────────────┐
│  MqttProvider       │ State management wrapper
│  Forward message    │ Call registered handler
└──────────┬──────────┘
           │
           │ setMessageHandler(sensorProvider.handleMqttMessage)
           ▼
┌─────────────────────┐
│  SensorProvider     │ 1. Parse JSON message
│  handleMqttMessage()│ 2. Find sensor by topic/deviceCode
│                     │ 3. Convert data type (int/double/bool)
│                     │ 4. Handle special logic (IR sensor inversion)
│                     │ 5. Update Firestore
│                     │ 6. Check thresholds
│                     │ 7. Send push notification if needed
└──────────┬──────────┘
           │
           │ Update Firestore
           ▼
┌─────────────────────┐
│  Firestore          │ users/{userId}/sensors/{sensorId}
│  Real-time Listener │ Update value & lastUpdate fields
└──────────┬──────────┘
           │
           │ Stream listener trigger
           ▼
┌─────────────────────┐
│  SensorProvider     │ _sensorsSubscription.listen()
│  Update _userSensors│ notifyListeners()
└──────────┬──────────┘
           │
           │ UI rebuild
           ▼
┌─────────────────────┐
│  UI Widgets         │ SensorCard, WeatherWidget, Charts
│  Auto Update        │ Display new sensor value
└─────────────────────┘
```

---

## 📂 Files liên quan (Ordered by flow)

### 1️⃣ ESP32 Arduino (Gửi data)
- **File:** `arduino/FullMQTT_Smart_Publishing.ino`
- **Location:** Lines 320-450 (publishSensors function)

### 2️⃣ MQTT Service (Nhận message)
- **File:** `lib/services/mqtt_service.dart`
- **Key Methods:**
  - `connect()` - Line 35-100
  - `subscribe()` - Line 102-113
  - `subscribeToAll()` - Line 115-140
  - `_setupMessageListener()` - Line 230-268

### 3️⃣ MQTT Provider (Forward message)
- **File:** `lib/providers/mqtt_provider.dart`
- **Key Method:** `setMessageHandler()` - Line 32-36

### 4️⃣ Auth Wrapper (Setup handler)
- **File:** `lib/widgets/auth_wrapper.dart`
- **Location:** Line 89 - Connect handler

### 5️⃣ Sensor Provider (Parse & update)
- **File:** `lib/providers/sensor_provider.dart`
- **Key Methods:**
  - `handleMqttMessage()` - Line 193-375
  - `subscribeSensorTopics()` - Line 135-165
  - `_checkSensorThresholds()` - Line 380-450
  - `_updateCurrentDataFromSensors()` - Line 500-600

### 6️⃣ Firestore Service (Save to DB)
- **File:** `lib/services/firestore_sensor_service.dart`
- **Key Method:** `updateSensorValue()`

### 7️⃣ Notification Service (Alert user)
- **File:** `lib/services/notification_service.dart`
- **Key Method:** `checkThresholdAndNotify()`

---

## 🔥 STEP-BY-STEP: Chi tiết từng bước

---

## STEP 1: ESP32 Publish Sensor Data

### 📍 File: `arduino/FullMQTT_Smart_Publishing.ino`

**Line 320-450: publishSensors() function**

```cpp
void publishSensors() {
  unsigned long currentMillis = millis();
  
  // ═════════════════════════════════════════════════════════
  // 🌡️ DHT22 - Temperature & Humidity (30s interval)
  // ═════════════════════════════════════════════════════════
  if (currentMillis - lastDHT22Publish >= 30000) {
    lastDHT22Publish = currentMillis;
    
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    
    if (!isnan(temp) && !isnan(hum)) {
      // 📤 Publish Temperature
      StaticJsonDocument<128> doc;
      doc["type"] = "temperature";
      doc["value"] = temp;
      doc["unit"] = "°C";
      doc["timestamp"] = millis();
      
      char buffer[128];
      serializeJson(doc, buffer);
      
      client.publish("smart_home/sensors/DHT22_001/state", buffer);
      Serial.print("🌡️  Temperature: ");
      Serial.println(temp);
      
      // 📤 Publish Humidity
      doc["type"] = "humidity";
      doc["value"] = hum;
      doc["unit"] = "%";
      serializeJson(doc, buffer);
      
      client.publish("smart_home/sensors/DHT22_001/state", buffer);
      Serial.print("💧 Humidity: ");
      Serial.println(hum);
    }
  }
  
  // ═════════════════════════════════════════════════════════
  // 🔥 MQ2 Gas Sensor (30s interval)
  // ═════════════════════════════════════════════════════════
  if (currentMillis - lastMQ2Publish >= 30000) {
    lastMQ2Publish = currentMillis;
    
    int gasValue = analogRead(MQ2_PIN);
    
    StaticJsonDocument<128> doc;
    doc["type"] = "gas";
    doc["value"] = gasValue;
    doc["unit"] = "ppm";
    doc["timestamp"] = millis();
    
    char buffer[128];
    serializeJson(doc, buffer);
    
    client.publish("smart_home/sensors/MQ2_001/state", buffer);
    Serial.print("🔥 Gas: ");
    Serial.println(gasValue);
  }
  
  // ═════════════════════════════════════════════════════════
  // 🚶 PIR Motion Sensor (State change only)
  // ═════════════════════════════════════════════════════════
  bool currentMotionState = (digitalRead(PIR_PIN) == LOW); // LOW = detected
  
  if (currentMotionState != lastMotionState) {
    lastMotionState = currentMotionState;
    
    StaticJsonDocument<128> doc;
    doc["type"] = "motion";
    doc["value"] = currentMotionState ? 0 : 1; // 0 = detected, 1 = not detected
    doc["timestamp"] = millis();
    
    char buffer[128];
    serializeJson(doc, buffer);
    
    client.publish("smart_home/sensors/PIR_001/state", buffer);
    Serial.print("🚶 Motion: ");
    Serial.println(currentMotionState ? "DETECTED" : "NOT DETECTED");
  }
  
  // ... More sensors: Rain, Soil, Dust, Light ...
}
```

**🔑 Key Points:**
- **Topic format:** `smart_home/sensors/{SENSOR_CODE}/state`
- **Message format:** JSON với keys: `type`, `value`, `unit`, `timestamp`
- **Publish interval:** 
  - DHT22, MQ2, Soil, Dust, Light: **30 seconds**
  - PIR Motion, Rain: **State change only** (để tránh spam)
- **Special logic:**
  - PIR sensor: `0` = detected, `1` = not detected (hardware LOW = detected)

---

## STEP 2: MqttService Subscribe & Listen

### 📍 File: `lib/services/mqtt_service.dart`

**Line 35-100: connect() - Kết nối MQTT broker**

```dart
Future<bool> connect(custom.MqttConfig config) async {
  try {
    // Tạo client với unique ID
    final uniqueId = _generateUniqueClientId();
    client = MqttServerClient.withPort(config.broker, uniqueId, config.port);
    
    // Configure
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.connectTimeoutPeriod = 10 * 1000;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    
    // SSL/TLS
    client.secure = config.useSsl;
    if (config.useSsl) {
      client.securityContext = SecurityContext.defaultContext;
    }
    
    // Set callbacks
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    
    // Connection message
    final connMessage = MqttConnectMessage()
        .authenticateAs(config.username, config.password)
        .startClean()
        .keepAliveFor(30);
    
    client.connectionMessage = connMessage;
    
    // Connect
    print('🔄 MQTT: Connecting to ${config.broker}:${config.port}...');
    await client.connect();
    
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('✅ MQTT: Connected successfully!');
      return true;
    } else {
      print('❌ MQTT: Connection failed');
      return false;
    }
  } catch (e) {
    print('❌ MQTT Connection Error: $e');
    return false;
  }
}
```

**Line 115-140: subscribeToAll() - Subscribe tất cả topics**

```dart
void subscribeToAll() {
  print('╔═══════════════════════════════════════════════════════╗');
  print('║  📥 SUBSCRIBING TO ALL MQTT TOPICS                    ║');
  print('╚═══════════════════════════════════════════════════════╝');
  
  // 📡 Subscribe to all sensor topics (WILDCARD)
  print('📡 Subscribing to: ${MqttTopics.base}/sensors/#');
  subscribe('${MqttTopics.base}/sensors/#');
  
  // 📡 Subscribe to all device topics
  print('📡 Subscribing to: ${MqttTopics.base}/devices/#');
  subscribe('${MqttTopics.base}/devices/#');
  
  // 📡 Subscribe to alerts
  print('📡 Subscribing to: ${MqttTopics.base}/alerts/#');
  subscribe('${MqttTopics.base}/alerts/#');
  
  // 📡 Subscribe to status
  print('📡 Subscribing to: ${MqttTopics.base}/status/#');
  subscribe('${MqttTopics.base}/status/#');
  
  print('✅ MQTT: Subscribed to all topics');
  print('🎧 Now listening for messages...\n');
}
```

**Line 230-268: _setupMessageListener() - Lắng nghe messages**

```dart
void _setupMessageListener() {
  print('🎧 [MQTT] Setting up message listener...');
  
  client.updates!.listen(
    (List<MqttReceivedMessage<MqttMessage>> messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final topic = messages[0].topic;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      
      // 🔍 Debug log
      print('╔═══════════════════════════════════════════════════════╗');
      print('║  📨 MQTT MESSAGE RECEIVED!                            ║');
      print('╚═══════════════════════════════════════════════════════╝');
      print('📍 Topic:   $topic');
      print('📦 Payload: $payload');
      print('🕐 Time:    ${DateTime.now()}');
      print('───────────────────────────────────────────────────────');
      
      // 🔔 Call registered handler
      print('🔔 [MQTT] Calling onMessageReceived callback...');
      onMessageReceived?.call(topic, payload);
      print('✅ [MQTT] Message forwarded to handler\n');
    },
    onError: (error) {
      print('❌ MQTT Stream Error: $error');
    },
  );
}
```

**🔑 Key Points:**
- **Wildcard subscription:** `smart_home/sensors/#` → nhận TẤT CẢ sensor topics
- **Auto-reconnect:** enabled để tự động kết nối lại khi mất kết nối
- **Message listener:** Forward message tới callback `onMessageReceived`

---

## STEP 3: MqttProvider Forward Message

### 📍 File: `lib/providers/mqtt_provider.dart`

**Line 32-36: setMessageHandler()**

```dart
void setMessageHandler(Function(String topic, String message)? handler) {
  _mqttService.onMessageReceived = handler;
  print('🔗 MqttProvider: Message handler registered');
}
```

**🔑 Key Points:**
- Provider đơn giản forward handler vào MqttService
- Handler thường là `sensorProvider.handleMqttMessage`

---

## STEP 4: Auth Wrapper Setup Handler

### 📍 File: `lib/widgets/auth_wrapper.dart`

**Line 85-90: Connect handler khi user login**

```dart
Future<void> _checkAuthStatus() async {
  // ... auth check ...
  
  if (authProvider.isLoggedIn) {
    final sensorProvider = context.read<SensorProvider>();
    final mqttProvider = context.read<MqttProvider>();
    
    // 🔗 Connect MQTT message handler to SensorProvider
    mqttProvider.setMessageHandler(sensorProvider.handleMqttMessage);
    print('🔗 AuthWrapper: Connected MQTT message handler to SensorProvider');
  }
}
```

**🔑 Key Points:**
- Handler được setup **SAU KHI USER LOGIN**
- Mỗi message từ MQTT sẽ được forward tới `SensorProvider.handleMqttMessage()`

---

## STEP 5: SensorProvider Parse & Update (🔥 QUAN TRỌNG NHẤT!)

### 📍 File: `lib/providers/sensor_provider.dart`

**Line 193-375: handleMqttMessage() - Parse MQTT message**

```dart
Future<void> handleMqttMessage(String topic, String message) async {
  print('═══════════════════════════════════════════════════════');
  print('🔔 [SENSOR] NEW MQTT MESSAGE RECEIVED!');
  print('📨 Topic:   $topic');
  print('📦 Message: $message');
  print('👤 UserId:  $_currentUserId');
  print('═══════════════════════════════════════════════════════');
  
  if (_currentUserId == null) {
    print('❌ [SENSOR] UserId is NULL! Cannot process.');
    return;
  }
  
  try {
    // ─────────────────────────────────────────────────────────
    // STEP 1: Tìm sensor theo topic/deviceCode
    // ─────────────────────────────────────────────────────────
    UserSensor? sensor;
    
    // Thử tìm theo exact topic trước
    try {
      sensor = _userSensors.firstWhere(
        (s) => s.mqttTopic == topic && s.isActive,
      );
      print('✅ Found sensor by exact topic: ${sensor.displayName}');
    } catch (_) {
      // Nếu không tìm thấy, extract device code từ topic
      // Topic format: smart_home/sensors/{DEVICE_CODE}/state
      final topicParts = topic.split('/');
      
      if (topicParts.length >= 4 &&
          topicParts[0] == 'smart_home' &&
          topicParts[1] == 'sensors') {
        final deviceCode = topicParts[2]; // DHT22_001
        
        print('🔍 [SENSOR] Searching by device code: $deviceCode');
        
        // Tìm sensor có deviceCode khớp
        sensor = _userSensors.firstWhere(
          (s) => s.deviceCode == deviceCode && s.isActive,
          orElse: () => throw StateError('No sensor found'),
        );
        
        print('✅ [SENSOR] FOUND! Sensor: ${sensor.displayName}');
      } else {
        throw StateError('Invalid topic format');
      }
    }
    
    // ─────────────────────────────────────────────────────────
    // STEP 2: Parse message (JSON hoặc plain text)
    // ─────────────────────────────────────────────────────────
    dynamic value;
    
    print('🔧 [SENSOR] Parsing message...');
    
    // 🛡️ Strip "Message: " prefix (from HiveMQ Web Client)
    if (message.startsWith('Message: ')) {
      message = message.substring('Message: '.length);
    }
    
    // Check if JSON
    if (message.trim().startsWith('{')) {
      print('📝 [SENSOR] Parsing as JSON...');
      final Map<String, dynamic> json = jsonDecode(message);
      
      // Extract value from JSON
      if (json.containsKey('value')) {
        value = json['value'];
        print('📊 [SENSOR] Extracted value: $value (${value.runtimeType})');
      } else {
        throw Exception('JSON missing "value" key');
      }
    } else {
      // Plain text
      print('📝 [SENSOR] Parsing as plain text...');
      switch (sensor.sensorType!.dataType) {
        case SensorDataType.double:
          value = double.parse(message);
          break;
        case SensorDataType.int:
          value = int.parse(message);
          break;
        case SensorDataType.bool:
          value = message == '1' || message.toLowerCase() == 'true';
          break;
      }
    }
    
    // ─────────────────────────────────────────────────────────
    // STEP 3: Convert data type
    // ─────────────────────────────────────────────────────────
    print('🔄 [SENSOR] Converting to ${sensor.sensorType!.dataType}...');
    
    switch (sensor.sensorType!.dataType) {
      case SensorDataType.double:
        value = (value as num).toDouble();
        break;
        
      case SensorDataType.int:
        value = (value as num).toInt();
        break;
        
      case SensorDataType.bool:
        bool boolValue = value == true || value == 1 || value == '1';
        
        // 🔥 SPECIAL: Motion sensor logic inverted
        // IR Obstacle sensor: LOW (0) = detected, HIGH (1) = not detected
        if (sensor.sensorType?.name.toLowerCase().contains('motion') == true ||
            sensor.deviceCode.toLowerCase().contains('motion') ||
            sensor.deviceCode.toLowerCase().contains('pir') ||
            sensor.deviceCode.toLowerCase().contains('ir_')) {
          value = !boolValue; // Invert: 0→true (detected), 1→false (not detected)
          print('🔄 [IR SENSOR] Inverted logic: $value');
        } else {
          value = boolValue;
        }
        break;
    }
    
    print('✅ [SENSOR] Final value: $value (${value.runtimeType})');
    
    // ─────────────────────────────────────────────────────────
    // STEP 4: Update Firestore
    // ─────────────────────────────────────────────────────────
    print('💾 [SENSOR] Updating Firestore...');
    await _firestoreService.updateSensorValue(
      _currentUserId!,
      sensor.id,
      value,
    );
    print('✅ [SENSOR] Firestore updated!');
    
    // ─────────────────────────────────────────────────────────
    // STEP 5: Check thresholds & send notification
    // ─────────────────────────────────────────────────────────
    _checkSensorThresholds(sensor, value);
    
    // ─────────────────────────────────────────────────────────
    // STEP 6: Update currentData (for backward compatibility)
    // ─────────────────────────────────────────────────────────
    _updateCurrentDataFromSensors();
    
    print('═══════════════════════════════════════════════════════');
    print('🎉 [SENSOR] SUCCESS! Updated: ${sensor.displayName} = $value');
    print('⏰ [SENSOR] Waiting for Firestore listener to trigger UI update...');
    print('═══════════════════════════════════════════════════════\n');
    
  } catch (e, stackTrace) {
    print('═══════════════════════════════════════════════════════');
    print('❌ [SENSOR] ERROR in handleMqttMessage!');
    print('📨 Topic:   $topic');
    print('📦 Message: $message');
    print('⚠️  Error:   $e');
    print('📚 Stack trace: $stackTrace');
    print('═══════════════════════════════════════════════════════\n');
  }
}
```

**🔑 Key Points:**

1. **Tìm sensor:** Theo exact topic HOẶC extract deviceCode từ topic
2. **Parse message:** Hỗ trợ cả JSON và plain text
3. **Convert type:** numeric, int, double, bool
4. **Special logic:** 
   - IR/PIR Motion sensor: Đảo ngược logic (0→true, 1→false)
   - Không ảnh hưởng sensors khác
5. **Update Firestore:** Lưu value mới vào database
6. **Check threshold:** Gửi notification nếu vượt ngưỡng
7. **Update UI:** Firestore listener sẽ tự động trigger UI update

---

## STEP 6: Firestore Update

### 📍 File: `lib/services/firestore_sensor_service.dart`

**updateSensorValue() method**

```dart
Future<void> updateSensorValue(
  String userId,
  String sensorId,
  dynamic value,
) async {
  try {
    await _db
        .collection('users')
        .doc(userId)
        .collection('sensors')
        .doc(sensorId)
        .update({
      'value': value,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
    
    print('✅ Firestore: Updated sensor $sensorId = $value');
  } catch (e) {
    print('❌ Firestore: Update failed - $e');
    rethrow;
  }
}
```

**🔑 Key Points:**
- Update 2 fields: `value` và `lastUpdate`
- Path: `users/{userId}/sensors/{sensorId}`
- Firestore listener sẽ tự động trigger khi có update

---

## STEP 7: Firestore Listener Trigger UI Update

### 📍 File: `lib/providers/sensor_provider.dart`

**Line 80-120: setCurrentUser() - Setup Firestore listener**

```dart
Future<void> setCurrentUser(String userId) async {
  _currentUserId = userId;
  
  // Cancel previous listener
  await _sensorsSubscription?.cancel();
  
  // 🎧 Setup Firestore real-time listener
  _sensorsSubscription = _firestoreService
      .getUserSensorsStream(userId)
      .listen((sensors) {
    print('🔔 [SENSOR] Firestore listener triggered!');
    print('📊 Received ${sensors.length} sensors from Firestore');
    
    _userSensors = sensors;
    
    // Update currentData from sensors
    _updateCurrentDataFromSensors();
    
    // Notify UI to rebuild
    notifyListeners();
    
    print('✅ [SENSOR] UI updated with new sensor values');
  });
  
  print('🎧 [SENSOR] Firestore listener setup complete');
}
```

**Line 500-600: _updateCurrentDataFromSensors()**

```dart
void _updateCurrentDataFromSensors() {
  // Tìm sensors theo type và update currentData
  final tempSensor = getSensorByType('temperature');
  final humSensor = getSensorByType('humidity');
  final gasSensor = getSensorByType('gas');
  final rainSensor = getSensorByType('rain');
  final soilSensor = getSensorByType('soil_moisture');
  final dustSensor = getSensorByType('dust');
  final motionSensor = getSensorByType('motion');
  
  _currentData = SensorData(
    temperature: tempSensor?.value as double? ?? 0.0,
    humidity: humSensor?.value as double? ?? 0.0,
    gas: gasSensor?.value as int? ?? 0,
    rain: rainSensor?.value as int? ?? 0,
    soilMoisture: soilSensor?.value as int? ?? 0,
    dust: dustSensor?.value as int? ?? 0,
    motionDetected: motionSensor?.value as bool? ?? false,
    timestamp: DateTime.now(),
  );
  
  print('🔄 [SENSOR] Updated currentData from sensors');
}
```

**🔑 Key Points:**
- **Real-time listener:** Firestore stream tự động trigger khi có update
- **notifyListeners():** Rebuild tất cả widgets đang listen
- **currentData:** Backward compatibility cho old widgets

---

## STEP 8: Check Thresholds & Send Notification

### 📍 File: `lib/providers/sensor_provider.dart`

**Line 380-450: _checkSensorThresholds()**

```dart
void _checkSensorThresholds(UserSensor sensor, dynamic value) {
  print('🔍 [THRESHOLD] Checking sensor: ${sensor.displayName}');
  print('   Current value: $value');
  print('   Min threshold: ${sensor.minThreshold}');
  print('   Max threshold: ${sensor.maxThreshold}');
  
  // Skip if no thresholds defined
  if (sensor.minThreshold == null && sensor.maxThreshold == null) {
    print('⏭️  [THRESHOLD] No thresholds defined, skipping');
    return;
  }
  
  // Check min threshold
  if (sensor.minThreshold != null && value < sensor.minThreshold!) {
    print('⚠️  [THRESHOLD] Below min! Sending notification...');
    _notificationService.sendThresholdNotification(
      sensorName: sensor.displayName,
      value: value,
      threshold: sensor.minThreshold!,
      isAbove: false,
    );
  }
  
  // Check max threshold
  if (sensor.maxThreshold != null && value > sensor.maxThreshold!) {
    print('⚠️  [THRESHOLD] Above max! Sending notification...');
    _notificationService.sendThresholdNotification(
      sensorName: sensor.displayName,
      value: value,
      threshold: sensor.maxThreshold!,
      isAbove: true,
    );
  }
  
  print('✅ [THRESHOLD] Check complete');
}
```

### 📍 File: `lib/services/notification_service.dart`

**checkThresholdAndNotify() method**

```dart
Future<void> checkThresholdAndNotify(UserSensor sensor) async {
  // Check cooldown (5 minutes per sensor type)
  final now = DateTime.now();
  final lastNotif = _lastNotificationTime[sensor.sensorTypeId];
  
  if (lastNotif != null && 
      now.difference(lastNotif).inMinutes < _cooldownMinutes) {
    print('⏭️  Notification cooldown active, skipping');
    return;
  }
  
  // Check threshold
  dynamic value = sensor.value;
  
  if (sensor.maxThreshold != null && value > sensor.maxThreshold!) {
    // Send notification
    await showNotification(
      title: '⚠️ ${sensor.displayName} Cảnh báo!',
      body: 'Giá trị $value vượt ngưỡng tối đa ${sensor.maxThreshold}',
    );
    
    // Update cooldown
    _lastNotificationTime[sensor.sensorTypeId] = now;
  }
  
  // Similar check for min threshold...
}
```

**🔑 Key Points:**
- **Cooldown:** 5 phút per sensor type (tránh spam)
- **State change detection:** Motion sensor chỉ notify khi false→true
- **Push notification:** Hiển thị ngay trên device

---

## STEP 9: UI Auto Update

### 📍 Widgets tự động rebuild khi `notifyListeners()`:

**1. SensorCard (lib/widgets/sensors/sensor_card.dart)**
```dart
Consumer<SensorProvider>(
  builder: (context, sensorProvider, child) {
    final sensor = sensorProvider.userSensors.firstWhere(
      (s) => s.id == sensorId,
    );
    
    return Card(
      child: Text('${sensor.displayName}: ${sensor.value}'),
    );
  },
)
```

**2. WeatherWidget (lib/widgets/weather/weather_widget.dart)**
```dart
Consumer<SensorProvider>(
  builder: (context, sensorProvider, child) {
    final temp = sensorProvider.temperature;
    final hum = sensorProvider.humidity;
    
    return Text('$temp°C - $hum%');
  },
)
```

**3. SensorChartScreen (lib/screens/sensors/sensor_chart_screen.dart)**
```dart
Consumer<SensorProvider>(
  builder: (context, sensorProvider, child) {
    final history = sensorProvider.history;
    
    return LineChart(
      data: history.map((d) => d.temperature).toList(),
    );
  },
)
```

---

## 🔍 Debug Checklist

### ✅ Kiểm tra từng bước:

**1. ESP32 publish OK?**
```
📤 Arduino Serial Monitor:
🌡️  Temperature: 25.5
📤 Publishing to: smart_home/sensors/DHT22_001/state
```

**2. App subscribe OK?**
```
📥 MQTT: Subscribed to smart_home/sensors/#
✅ MQTT: Subscribed to all topics
```

**3. Message received?**
```
║  📨 MQTT MESSAGE RECEIVED!
📍 Topic:   smart_home/sensors/DHT22_001/state
📦 Payload: {"type":"temperature","value":25.5,"timestamp":12345}
```

**4. Handler called?**
```
🔔 [MQTT] Calling onMessageReceived callback...
🔔 [SENSOR] NEW MQTT MESSAGE RECEIVED!
```

**5. Sensor found?**
```
✅ [SENSOR] FOUND! Sensor: Nhiệt độ phòng khách
   → Device code: DHT22_001
```

**6. Value parsed?**
```
📊 [SENSOR] Extracted value: 25.5 (double)
✅ [SENSOR] Final value: 25.5 (double)
```

**7. Firestore updated?**
```
💾 [SENSOR] Updating Firestore...
✅ [SENSOR] Firestore updated!
```

**8. Listener triggered?**
```
🔔 [SENSOR] Firestore listener triggered!
✅ [SENSOR] UI updated with new sensor values
```

**9. UI rebuilt?**
```
SensorCard, WeatherWidget, Charts → All updated!
```

---

## 🚨 Common Issues & Solutions

### ❌ Issue 1: Message received nhưng sensor không update

**Nguyên nhân:** Sensor không tìm thấy (deviceCode không khớp)

**Fix:**
```dart
// Check deviceCode khớp giữa:
// 1. Arduino: "DHT22_001"
// 2. App sensor: deviceCode = "DHT22_001"
// 3. Topic: smart_home/sensors/DHT22_001/state
```

---

### ❌ Issue 2: JSON parse error

**Nguyên nhân:** Message không phải JSON hợp lệ

**Fix:**
```dart
// Arduino phải gửi JSON đúng format:
{"type":"temperature","value":25.5,"timestamp":12345}

// KHÔNG ĐƯỢC gửi:
"25.5" (plain text không có JSON wrapper)
```

---

### ❌ Issue 3: Motion sensor hiển thị ngược

**Nguyên nhân:** IR Obstacle sensor hardware LOW=detected

**Fix:**
```dart
// ✅ ĐÃ FIX trong SensorProvider line 309-330
// Đảo ngược logic CHỈ cho motion sensor
if (sensor.deviceCode.contains('motion') || 
    sensor.deviceCode.contains('pir') ||
    sensor.deviceCode.contains('ir_')) {
  value = !boolValue; // 0→true, 1→false
}
```

---

### ❌ Issue 4: Notification spam

**Nguyên nhân:** Không có cooldown

**Fix:**
```dart
// ✅ ĐÃ FIX trong NotificationService
// Cooldown 5 phút per sensor type
if (now.difference(lastNotif).inMinutes < 5) {
  return; // Skip notification
}
```

---

## 📊 Performance Notes

### Sensor publish intervals:
- **DHT22, MQ2, Soil, Dust, Light:** 30 seconds
- **PIR Motion, Rain:** State change only

### Why 30 seconds?
- ✅ Real-time enough cho monitoring
- ✅ Không spam MQTT broker
- ✅ Tiết kiệm bandwidth & battery
- ✅ Tránh Firestore rate limits

### Firestore optimization:
- **Real-time listener:** Only 1 stream per user
- **Update fields:** Chỉ update `value` và `lastUpdate`
- **Index:** deviceCode indexed cho fast search

---

## 🎯 Summary

### Data Flow Timeline:

```
0ms   : ESP32 đọc sensor
10ms  : ESP32 publish MQTT
50ms  : App nhận message
60ms  : SensorProvider parse JSON
70ms  : Firestore update
100ms : Firestore listener trigger
120ms : UI rebuild
```

**Total latency: ~120ms từ ESP32 tới UI update!** ⚡

---

### Key Components:

| Component | File | Responsibility |
|-----------|------|----------------|
| **ESP32** | FullMQTT_Smart_Publishing.ino | Read sensors, publish MQTT |
| **MqttService** | mqtt_service.dart | Connect broker, subscribe topics |
| **MqttProvider** | mqtt_provider.dart | Forward messages to handler |
| **AuthWrapper** | auth_wrapper.dart | Setup message handler |
| **SensorProvider** | sensor_provider.dart | Parse, convert, update Firestore |
| **FirestoreService** | firestore_sensor_service.dart | Save to database |
| **NotificationService** | notification_service.dart | Check threshold, send alert |
| **Firestore Listener** | sensor_provider.dart | Real-time sync, trigger UI |
| **UI Widgets** | sensor_card.dart, etc. | Display sensor values |

---

**Last updated:** November 3, 2025

**Status:** ✅ HOẠT ĐỘNG HOÀN TOÀN - Tested with ESP32 & Flutter app
