// #include <WiFi.h>
// #include <PubSubClient.h>
// #include <ArduinoJson.h>
// #include <WiFiClientSecure.h>

// // ===========================
// // 🔧 WIFI & MQTT Configuration
// // ===========================
// const char* ssid = "VIETTEL NgocThoai";      // Wifi connect
// const char* password = "0934918347";   // Password

// // MQTT Broker (sử dụng HiveMQ Cloud như code mẫu)
// const char* mqtt_server = "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud";
// const int mqtt_port = 8883;
// const char* mqtt_user = "sigma";                     // Từ code mẫu
// const char* mqtt_password = "35386Doan";             // Từ code mẫu
// const char* mqtt_client_id = "ESP32_SmartHome";

// // ===========================
// // 🎯 MQTT Topics (từ Flutter app)
// // ===========================
// const char* CONTROL_TOPIC = "smarthome/control/+";       // Subscribe to all control commands
// const char* SENSOR_TOPIC_BASE = "smart_home/sensors/";   // Publish sensor data
// const char* STATUS_TOPIC = "smart_home/status/esp32";    // Publish ESP32 status

// // ===========================
// // 📱 Device IDs (từ Flutter DeviceProvider) - Linh động hơn
// // ===========================
// const char* DEVICE_FAN = "fan";
// const char* DEVICE_FAN_LIVING = "fan_living";  // Quạt phòng khách với L298N
// const char* DEVICE_PUMP = "pump";
// const char* DEVICE_LED = "led";
// const char* DEVICE_LIGHT_LIVING = "light_living";
// const char* DEVICE_LIGHT_YARD = "light_yard";
// const char* DEVICE_MIST_MAKER = "mist_maker";
// const char* DEVICE_ROOF_SERVO = "roof_servo";
// const char* DEVICE_GATE_SERVO = "gate_servo";

// // ===========================
// // 🔌 Hardware Pin Definitions (theo ESP32 38-pin diagram)
// // ===========================
// // Relay Outputs (Digital Output)
// const int PIN_FAN = 2;           // GPIO2 - Fan relay
// const int PIN_PUMP = 4;          // GPIO4 - Pump relay  
// const int PIN_LED = 5;           // GPIO5 - LED relay
// const int PIN_LIGHT_LIVING = 18; // GPIO18 - Living room light
// const int PIN_LIGHT_YARD = 19;   // GPIO19 - Yard light
// const int PIN_MIST_MAKER = 21;   // GPIO21 - Mist maker

// // L298N Motor Driver - Quạt phòng khách
// const int PIN_FAN_LIVING_PWM = 23;  // GPIO23 - ENA (PWM tốc độ)
// const int PIN_FAN_LIVING_IN1 = 22;  // GPIO22 - IN1 (Direction)
// const int PIN_FAN_LIVING_IN2 = 25;  // GPIO25 - IN2 (Direction)

// // Servo Outputs (PWM Output)
// const int PIN_ROOF_SERVO = 16;   // GPIO16 - Roof servo
// const int PIN_GATE_SERVO = 17;   // GPIO17 - Gate servo

// // Sensor Inputs (Analog/Digital Input)
// const int PIN_TEMP_SENSOR = 36;  // GPIO36 (ADC1_0) - Temperature sensor
// const int PIN_HUMIDITY_SENSOR = 39; // GPIO39 (ADC1_3) - Humidity sensor
// const int PIN_LIGHT_SENSOR = 34;    // GPIO34 (ADC1_6) - Light sensor
// const int PIN_SOIL_SENSOR = 35;     // GPIO35 (ADC1_7) - Soil moisture

// // Built-in LED for status
// const int PIN_STATUS_LED = 2;    // Built-in LED

// // ===========================
// // 🌐 Objects
// // ===========================
// WiFiClientSecure espClient;        // Sử dụng WiFiClientSecure cho SSL
// PubSubClient client(espClient);

// // ===========================
// // 💾 Device State Storage (Linh động hơn)
// // ===========================
// struct DeviceState {
//   String id;
//   String type;  // "relay", "servo", "fan_pwm"
//   bool state;
//   int value;
//   int pin_main;
//   int pin_aux1;  // Cho L298N IN1
//   int pin_aux2;  // Cho L298N IN2
// };

// // Danh sách devices linh động - dễ thêm/bớt
// DeviceState devices[] = {
//   {DEVICE_FAN, "relay", false, 0, PIN_FAN, -1, -1},
//   {DEVICE_PUMP, "relay", false, 0, PIN_PUMP, -1, -1},
//   {DEVICE_LED, "relay", false, 0, PIN_LED, -1, -1},
//   {DEVICE_LIGHT_LIVING, "relay", false, 0, PIN_LIGHT_LIVING, -1, -1},
//   {DEVICE_LIGHT_YARD, "relay", false, 0, PIN_LIGHT_YARD, -1, -1},
//   {DEVICE_MIST_MAKER, "relay", false, 0, PIN_MIST_MAKER, -1, -1},
//   {DEVICE_FAN_LIVING, "fan_pwm", false, 0, PIN_FAN_LIVING_PWM, PIN_FAN_LIVING_IN1, PIN_FAN_LIVING_IN2},
//   {DEVICE_ROOF_SERVO, "servo", false, 0, PIN_ROOF_SERVO, -1, -1},
//   {DEVICE_GATE_SERVO, "servo", false, 0, PIN_GATE_SERVO, -1, -1}
// };

// const int DEVICE_COUNT = sizeof(devices) / sizeof(DeviceState);

// // ===========================
// // 🚀 Setup Function
// // ===========================
// void setup() {
//   Serial.begin(115200);
//   Serial.println("🔥 ESP32 Smart Home Starting...");
  
//   // Initialize pins
//   setupPins();
  
//   // Connect to WiFi
//   setupWiFi();
  
//   // Connect to MQTT
//   setupMQTT();
  
//   Serial.println("✅ ESP32 Smart Home Ready!");
//   Serial.println("📊 Loaded " + String(DEVICE_COUNT) + " devices");
//   publishStatus("online");
// }

// // ===========================
// // 🔄 Main Loop
// // ===========================
// void loop() {
//   // Maintain MQTT connection
//   if (!client.connected()) {
//     reconnectMQTT();
//   }
//   client.loop();
  
//   // Send sensor data every 30 seconds
//   static unsigned long lastSensorUpdate = 0;
//   if (millis() - lastSensorUpdate > 30000) {
//     publishSensorData();
//     lastSensorUpdate = millis();
//   }
  
//   delay(100);
// }

// // ===========================
// // 🔌 Pin Setup - Linh động
// // ===========================
// void setupPins() {
//   Serial.println("🔌 Setting up pins...");
  
//   for (int i = 0; i < DEVICE_COUNT; i++) {
//     DeviceState& device = devices[i];
    
//     if (device.type == "relay") {
//       pinMode(device.pin_main, OUTPUT);
//       digitalWrite(device.pin_main, LOW);
//       Serial.println("📌 " + device.id + " relay pin: " + String(device.pin_main));
      
//     } else if (device.type == "fan_pwm") {
//       pinMode(device.pin_main, OUTPUT);    // PWM
//       pinMode(device.pin_aux1, OUTPUT);    // IN1
//       pinMode(device.pin_aux2, OUTPUT);    // IN2
//       setFanSpeed(i, 0);  // Stop initially
//       Serial.println("📌 " + device.id + " L298N pins: " + String(device.pin_main) + "," + String(device.pin_aux1) + "," + String(device.pin_aux2));
      
//     } else if (device.type == "servo") {
//       pinMode(device.pin_main, OUTPUT);
//       Serial.println("📌 " + device.id + " servo pin: " + String(device.pin_main));
//     }
//   }
  
//   // Setup sensor pins as inputs
//   pinMode(PIN_TEMP_SENSOR, INPUT);
//   pinMode(PIN_HUMIDITY_SENSOR, INPUT);
//   pinMode(PIN_LIGHT_SENSOR, INPUT);
//   pinMode(PIN_SOIL_SENSOR, INPUT);
//   pinMode(PIN_STATUS_LED, OUTPUT);
  
//   Serial.println("✅ All pins configured");
// }

// // ===========================
// // 📶 WiFi Setup
// // ===========================
// void setupWiFi() {
//   delay(10);
//   Serial.println();
//   Serial.print("🔗 Connecting to WiFi: ");
//   Serial.println(ssid);

//   WiFi.begin(ssid, password);

//   while (WiFi.status() != WL_CONNECTED) {
//     delay(500);
//     Serial.print(".");
//   }

//   Serial.println("");
//   Serial.println("✅ WiFi connected!");
//   Serial.print("📍 IP address: ");
//   Serial.println(WiFi.localIP());
// }

// // ===========================
// // 📡 MQTT Setup  
// // ===========================
// void setupMQTT() {
//   // Cấu hình SSL - bỏ qua verify certificate cho HiveMQ Cloud
//   espClient.setInsecure();
  
//   client.setServer(mqtt_server, mqtt_port);
//   client.setCallback(onMqttMessage);
  
//   reconnectMQTT();
// }

// // ===========================
// // 🔄 MQTT Reconnection
// // ===========================
// void reconnectMQTT() {
//   while (!client.connected()) {
//     Serial.print("🔄 Attempting MQTT connection...");
    
//     // Kết nối với username và password cho HiveMQ Cloud
//     if (client.connect(mqtt_client_id, mqtt_user, mqtt_password)) {
//       Serial.println(" ✅ Connected!");
      
//       // Subscribe to control topics
//       client.subscribe(CONTROL_TOPIC);
//       Serial.println("📥 Subscribed to: smarthome/control/+");
      
//       // Publish online status
//       publishStatus("online");
      
//       // Blink status LED to indicate connection
//       blinkStatusLED(3);
      
//     } else {
//       Serial.print(" ❌ Failed, rc=");
//       Serial.print(client.state());
//       Serial.println(" trying again in 5 seconds");
//       delay(5000);
//     }
//   }
// }

// // ===========================
// // 📨 MQTT Message Handler - Linh động hơn
// // ===========================
// void onMqttMessage(char* topic, byte* payload, unsigned int length) {
//   // Convert payload to string
//   String message = "";
//   for (int i = 0; i < length; i++) {
//     message += (char)payload[i];
//   }
  
//   // Parse topic to get device ID
//   String topicStr = String(topic);
//   String deviceId = "";
  
//   if (topicStr.startsWith("smarthome/control/")) {
//     deviceId = topicStr.substring(18); // Remove "smarthome/control/"
//   }
  
//   // Print received command
//   Serial.println("📨 MQTT Received:");
//   Serial.println("  📋 Topic: " + topicStr);
//   Serial.println("  🎯 Device: " + deviceId);
//   Serial.println("  💬 Message: " + message);
  
//   // Kiểm tra xem có phải JSON không
//   if (message.startsWith("{") && message.endsWith("}")) {
//     executeJsonCommand(deviceId, message);
//   } else {
//     executeSimpleCommand(deviceId, message);
//   }
// }

// // ===========================
// // ⚡ Simple Command Execution - Linh động
// // ===========================
// void executeSimpleCommand(String deviceId, String message) {
//   int value = message.toInt();
  
//   // Tìm device trong array
//   for (int i = 0; i < DEVICE_COUNT; i++) {
//     if (devices[i].id == deviceId) {
//       DeviceState& device = devices[i];
      
//       if (device.type == "relay") {
//         bool state = (value == 1);
//         device.state = state;
//         digitalWrite(device.pin_main, state ? HIGH : LOW);
//         Serial.println("🔌 " + device.id + " " + String(state ? "ON" : "OFF"));
        
//       } else if (device.type == "servo") {
//         device.value = constrain(value, 0, 180);
//         setServoAngle(device.pin_main, device.value);
//         Serial.println("🎚️ " + device.id + " angle: " + String(device.value) + "°");
        
//       } else if (device.type == "fan_pwm") {
//         device.value = constrain(value, 0, 255);
//         device.state = (device.value > 0);
//         setFanSpeed(i, device.value);
//         Serial.println("🌀 " + device.id + " speed: " + String(device.value) + " (" + String(((device.value/255.0)*100)) + "%)");
//       }
//       return;
//     }
//   }
  
//   Serial.println("❓ Unknown device: " + deviceId);
// }

// // ===========================
// // 🎛️ JSON Command Execution - Linh động hơn
// // ===========================
// void executeJsonCommand(String deviceId, String jsonMessage) {
//   Serial.println("🔧 Processing JSON command...");
  
//   // Parse JSON
//   StaticJsonDocument<300> doc;
//   DeserializationError error = deserializeJson(doc, jsonMessage);
  
//   if (error) {
//     Serial.println("❌ JSON Parse Error: " + String(error.c_str()));
//     return;
//   }
  
//   // Extract command parameters
//   String command = doc["command"] | "";
//   int speed = doc["speed"] | 0;
//   int value = doc["value"] | 0;
//   bool state = doc["state"] | false;
//   String preset = doc["preset"] | "";
  
//   // Tìm device trong array
//   for (int i = 0; i < DEVICE_COUNT; i++) {
//     if (devices[i].id == deviceId) {
//       DeviceState& device = devices[i];
      
//       if (device.type == "fan_pwm") {
//         if (command == "set_speed") {
//           device.value = constrain(speed, 0, 255);
//           device.state = (device.value > 0);
//           setFanSpeed(i, device.value);
//           Serial.println("🌀 " + device.id + " JSON speed: " + String(device.value));
          
//         } else if (command == "toggle") {
//           device.state = state;
//           if (state && device.value == 0) device.value = 150; // Default medium
//           if (!state) device.value = 0;
//           setFanSpeed(i, device.value);
//           Serial.println("🌀 " + device.id + " JSON toggle: " + String(state ? "ON" : "OFF"));
          
//         } else if (command == "preset") {
//           int presetSpeed = 150; // default medium
//           if (preset == "low") presetSpeed = 80;
//           else if (preset == "medium") presetSpeed = 150;
//           else if (preset == "high") presetSpeed = 255;
          
//           device.value = presetSpeed;
//           device.state = true;
//           setFanSpeed(i, device.value);
//           Serial.println("🌀 " + device.id + " preset " + preset + ": " + String(presetSpeed));
//         }
//       }
//       return;
//     }
//   }
  
//   Serial.println("❓ JSON command not supported for device: " + deviceId);
// }

// // ===========================
// // 🌀 Fan Speed Control - Improved
// // ===========================
// void setFanSpeed(int deviceIndex, int speed) {
//   DeviceState& device = devices[deviceIndex];
//   speed = constrain(speed, 0, 255);
  
//   if (speed == 0) {
//     // Stop motor
//     digitalWrite(device.pin_aux1, LOW);
//     digitalWrite(device.pin_aux2, LOW);
//     analogWrite(device.pin_main, 0);
//     Serial.println("🛑 " + device.id + " STOPPED");
//   } else {
//     // Set direction (IN1=HIGH, IN2=LOW for forward)
//     digitalWrite(device.pin_aux1, HIGH);
//     digitalWrite(device.pin_aux2, LOW);
    
//     // Set speed with PWM
//     analogWrite(device.pin_main, speed);
    
//     int percentage = map(speed, 0, 255, 0, 100);
//     Serial.println("🌀 " + device.id + " running at " + String(percentage) + "% (PWM: " + String(speed) + ")");
//   }
// }

// // ===========================
// // 🎮 Servo Control
// // ===========================
// void setServoAngle(int pin, int angle) {
//   // Constrain angle to 0-180 degrees
//   angle = constrain(angle, 0, 180);
  
//   // Convert angle to PWM signal (500-2400 microseconds)
//   int pulseWidth = map(angle, 0, 180, 500, 2400);
  
//   // Generate PWM signal for servo
//   for (int i = 0; i < 20; i++) {
//     digitalWrite(pin, HIGH);
//     delayMicroseconds(pulseWidth);
//     digitalWrite(pin, LOW);
//     delayMicroseconds(20000 - pulseWidth);
//   }
// }

// // ===========================
// // 📊 Sensor Data Publishing
// // ===========================
// void publishSensorData() {
//   // Read analog sensors (mock values for now)
//   float temperature = readTemperature();
//   float humidity = readHumidity();
//   int lightLevel = readLightLevel();
//   int soilMoisture = readSoilMoisture();
  
//   // Create JSON payload
//   StaticJsonDocument<300> doc;
//   doc["temperature"] = temperature;
//   doc["humidity"] = humidity;
//   doc["light"] = lightLevel;
//   doc["soil_moisture"] = soilMoisture;
//   doc["timestamp"] = millis();
  
//   // Add device states
//   JsonArray deviceStates = doc.createNestedArray("devices");
//   for (int i = 0; i < DEVICE_COUNT; i++) {
//     JsonObject deviceObj = deviceStates.createNestedObject();
//     deviceObj["id"] = devices[i].id;
//     deviceObj["type"] = devices[i].type;
//     deviceObj["state"] = devices[i].state;
//     deviceObj["value"] = devices[i].value;
//   }
  
//   String payload;
//   serializeJson(doc, payload);
  
//   // Publish to MQTT
//   String topic = String(SENSOR_TOPIC_BASE) + "esp32";
//   client.publish(topic.c_str(), payload.c_str());
  
//   Serial.println("📊 Sensor data published:");
//   Serial.println("  🌡️ Temperature: " + String(temperature) + "°C");
//   Serial.println("  💧 Humidity: " + String(humidity) + "%");
//   Serial.println("  ☀️ Light: " + String(lightLevel));
//   Serial.println("  🌱 Soil: " + String(soilMoisture));
// }

// // ===========================
// // 🌡️ Sensor Reading Functions
// // ===========================
// float readTemperature() {
//   int sensorValue = analogRead(PIN_TEMP_SENSOR);
//   float temperature = map(sensorValue, 0, 4095, 20, 40); // 20-40°C range
//   return temperature;
// }

// float readHumidity() {
//   int sensorValue = analogRead(PIN_HUMIDITY_SENSOR);
//   float humidity = map(sensorValue, 0, 4095, 30, 90); // 30-90% range
//   return humidity;
// }

// int readLightLevel() {
//   int lightLevel = analogRead(PIN_LIGHT_SENSOR);
//   return map(lightLevel, 0, 4095, 0, 100); // Convert to 0-100%
// }

// int readSoilMoisture() {
//   int soilValue = analogRead(PIN_SOIL_SENSOR);
//   return map(soilValue, 0, 4095, 0, 100); // Convert to 0-100%
// }

// // ===========================
// // 📡 Status Publishing
// // ===========================
// void publishStatus(String status) {
//   StaticJsonDocument<200> doc;
//   doc["status"] = status;
//   doc["device"] = "ESP32";
//   doc["timestamp"] = millis();
//   doc["device_count"] = DEVICE_COUNT;
//   doc["free_heap"] = ESP.getFreeHeap();
  
//   String payload;
//   serializeJson(doc, payload);
  
//   client.publish(STATUS_TOPIC, payload.c_str());
//   Serial.println("📡 Status published: " + status);
// }

// // ===========================
// // 💡 Status LED Functions
// // ===========================
// void blinkStatusLED(int times) {
//   for (int i = 0; i < times; i++) {
//     digitalWrite(PIN_STATUS_LED, HIGH);
//     delay(200);
//     digitalWrite(PIN_STATUS_LED, LOW);
//     delay(200);
//   }
// }