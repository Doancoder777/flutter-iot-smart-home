// /*
//  * ============================================================================
//  * FULL MQTT TEST - TẤT CẢ THIẾT BỊ + MQTT BROKER
//  * ============================================================================
//  * 
//  * Kết hợp:
//  * - 6 Sensors + 10 Actuators (FULL devices từ 17_Complete_All_Devices_Test)
//  * - MQTT Broker (HiveMQ Cloud) để điều khiển từ xa
//  * - GPIO Optimized cho ESP32 DevKit v1 (tránh ADC2 + WiFi conflict)
//  * 
//  * SENSORS (6 loại - 7 chân):
//  * 1. DHT22 (GPIO4)           - Nhiệt độ/Độ ẩm
//  * 2. MQ-2 (GPIO34)           - Khí Gas
//  * 3. Rain (GPIO35)           - Mưa
//  * 4. Soil (GPIO32)           - Độ ẩm đất
//  * 5. GP2Y Dust (GPIO23, 36)  - Bụi PM2.5/PM10
//  * 6. PIR (GPIO33)            - Chuyển động
//  * 
//  * ACTUATORS (4 loại - 15 chân):
//  * 7.  5 LED (GPIO5,18,19,21,22)           - 5 LED
//  * 8.  2 Servo (GPIO13,14)                 - 2 Servo motor
//  * 9.  2 Motor L298N (GPIO16,17,25,26,27,12) - 2 Motor DC
//  * 10. 2 Relay (GPIO2,15)                  - 2 Relay
//  * 
//  * MQTT Topics:
//  * - Subscribe: smart_home/devices/{DEVICE_CODE}/cmd
//  * - Publish:   smart_home/devices/{DEVICE_CODE}/state
//  * 
//  * ============================================================================
//  */

// #include <WiFi.h>
// #include <WiFiClientSecure.h>
// #include <PubSubClient.h>
// #include <ArduinoJson.h>
// #include <ESP32Servo.h>
// #include "DHTesp.h"

// // ============================================================================
// // WIFI & MQTT CONFIG
// // ============================================================================
// // 📶 WiFi - Chọn 1 trong 3 mạng (uncomment dòng cần dùng)
// const char* ssid = "Virus_plus";        // Lựa chọn 1
// const char* password = "tan16108";
// // const char* ssid = "Sigma";          // Lựa chọn 2
// // const char* password = "tan16108";
// // const char* ssid = "VIETTEL NgocThoai";  // Lựa chọn 3
// // const char* password = "0934918347";

// // 🌐 MQTT Broker (HiveMQ Cloud)
// const char* mqtt_server = "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud";
// const int mqtt_port = 8883;              // SSL/TLS port
// const char* mqtt_user = "sigma";
// const char* mqtt_pass = "35386Doan";     // Full password

// // 🆔 Device ID (UNIQUE cho mỗi ESP32)
// const char* DEVICE_ID = "ESP32_FULL_001";

// WiFiClientSecure espClient;
// PubSubClient client(espClient);

// // ============================================================================
// // PIN DEFINITIONS (✅ OPTIMIZED cho ESP32 DevKit v1)
// // ============================================================================
// // SENSORS (7 chân - ADC1 cho analog)
// #define DHT_PIN         4    // GPIO4  - DHT22
// #define MQ2_PIN         34   // GPIO34 - MQ-2 Gas (ADC1_6)
// #define RAIN_PIN        35   // GPIO35 - Rain (ADC1_7)
// #define SOIL_PIN        32   // GPIO32 - Soil (ADC1_4)
// #define DUST_LED_PIN    23   // GPIO23 - Dust LED (VSPI_MOSI)
// #define DUST_VO_PIN     36   // GPIO36 - Dust Output (ADC1_0)
// #define PIR_PIN         33   // GPIO33 - PIR (ADC1_5)

// // ACTUATORS - LED (5 chân)
// #define LED1_PIN        5    // GPIO5  - Red LED
// #define LED2_PIN        18   // GPIO18 - Yellow LED
// #define LED3_PIN        19   // GPIO19 - Green LED
// #define LED4_PIN        21   // GPIO21 - Blue LED
// #define LED5_PIN        22   // GPIO22 - White LED

// // ACTUATORS - Servo (2 chân)
// #define SERVO1_PIN      13   // GPIO13 - Servo 1
// #define SERVO2_PIN      14   // GPIO14 - Servo 2

// // ACTUATORS - Motor A (3 chân)
// #define MOTOR_A_ENA     16   // GPIO16 - Motor A PWM Speed
// #define MOTOR_A_IN1     17   // GPIO17 - Motor A Direction 1
// #define MOTOR_A_IN2     25   // GPIO25 - Motor A Direction 2

// // ACTUATORS - Motor B (3 chân)
// #define MOTOR_B_ENB     26   // GPIO26 - Motor B PWM Speed
// #define MOTOR_B_IN3     27   // GPIO27 - Motor B Direction 1
// #define MOTOR_B_IN4     12   // GPIO12 - Motor B Direction 2

// // ACTUATORS - Relay (2 chân)
// #define RELAY1_PIN      2    // GPIO2  - Relay 1
// #define RELAY2_PIN      15   // GPIO15 - Relay 2

// // ============================================================================
// // DEVICE CODES (Khớp với Flutter app)
// // ============================================================================
// // Sensors
// const char* SENSOR_DHT_CODE     = "DHT22_001";
// const char* SENSOR_GAS_CODE     = "GAS_MQ2_001";
// const char* SENSOR_RAIN_CODE    = "RAIN_001";
// const char* SENSOR_SOIL_CODE    = "SOIL_001";
// const char* SENSOR_DUST_CODE    = "DUST_GP2Y_001";
// const char* SENSOR_PIR_CODE     = "PIR_MOTION_001";

// // Actuators
// const char* DEVICE_LED1_CODE    = "LED_RED_001";
// const char* DEVICE_LED2_CODE    = "LED_YELLOW_001";
// const char* DEVICE_LED3_CODE    = "LED_GREEN_001";
// const char* DEVICE_LED4_CODE    = "LED_BLUE_001";
// const char* DEVICE_LED5_CODE    = "LED_WHITE_001";
// const char* DEVICE_SERVO1_CODE  = "SERVO_DOOR_001";
// const char* DEVICE_SERVO2_CODE  = "SERVO_WINDOW_001";
// const char* DEVICE_MOTOR_A_CODE = "MOTOR_FAN_A_001";
// const char* DEVICE_MOTOR_B_CODE = "MOTOR_FAN_B_001";
// const char* DEVICE_RELAY1_CODE  = "RELAY_PUMP_001";
// const char* DEVICE_RELAY2_CODE  = "RELAY_LIGHT_001";

// // ============================================================================
// // OBJECTS
// // ============================================================================
// DHTesp dht;
// Servo servo1;
// Servo servo2;

// // ============================================================================
// // GLOBAL VARIABLES
// // ============================================================================
// unsigned long lastSensorRead = 0;
// const long sensorInterval = 300000; // Đọc cảm biến mỗi 5 phút (tiết kiệm MQTT)

// // Device states
// int servo1Angle = 0;
// int servo2Angle = 0;
// int motorASpeed = 0;
// int motorBSpeed = 0;
// bool relay1State = false;
// bool relay2State = false;
// bool led1State = false;
// bool led2State = false;
// bool led3State = false;
// bool led4State = false;
// bool led5State = false;

// // ============================================================================
// // FUNCTION PROTOTYPES
// // ============================================================================
// void setup_wifi();
// void reconnect_mqtt();
// void mqtt_callback(char* topic, byte* payload, unsigned int length);
// void publishSensorData(const char* deviceCode, const char* sensorType, float value);
// void publishDeviceState(const char* deviceCode, const char* state);
// void readAndPublishSensors();
// void controlServo1(int angle);
// void controlServo2(int angle);
// void controlMotorA(int speed);
// void controlMotorB(int speed);
// void controlRelay1(bool state);
// void controlRelay2(bool state);
// void controlLED(int ledPin, bool state);

// // ============================================================================
// // SETUP
// // ============================================================================
// void setup() {
//   Serial.begin(115200);
//   delay(1000);
  
//   Serial.println("\n╔════════════════════════════════════════════════╗");
//   Serial.println("║   FULL MQTT TEST - ALL DEVICES + MQTT         ║");
//   Serial.println("║   ESP32 DevKit v1 - Optimized GPIO            ║");
//   Serial.println("╚════════════════════════════════════════════════╝\n");
  
//   // ===== SETUP SENSORS =====
//   dht.setup(DHT_PIN, DHTesp::DHT22);
//   pinMode(MQ2_PIN, INPUT);
//   pinMode(RAIN_PIN, INPUT);
//   pinMode(SOIL_PIN, INPUT);
//   pinMode(DUST_LED_PIN, OUTPUT);
//   pinMode(DUST_VO_PIN, INPUT);
//   pinMode(PIR_PIN, INPUT);
//   digitalWrite(DUST_LED_PIN, LOW);
  
//   // ===== SETUP ACTUATORS =====
//   // LED
//   pinMode(LED1_PIN, OUTPUT);
//   pinMode(LED2_PIN, OUTPUT);
//   pinMode(LED3_PIN, OUTPUT);
//   pinMode(LED4_PIN, OUTPUT);
//   pinMode(LED5_PIN, OUTPUT);
  
//   // Servo
//   servo1.attach(SERVO1_PIN);
//   servo2.attach(SERVO2_PIN);
//   servo1.write(0);
//   servo2.write(0);
  
//   // Motor A
//   pinMode(MOTOR_A_ENA, OUTPUT);
//   pinMode(MOTOR_A_IN1, OUTPUT);
//   pinMode(MOTOR_A_IN2, OUTPUT);
  
//   // Motor B
//   pinMode(MOTOR_B_ENB, OUTPUT);
//   pinMode(MOTOR_B_IN3, OUTPUT);
//   pinMode(MOTOR_B_IN4, OUTPUT);
  
//   // Relay
//   pinMode(RELAY1_PIN, OUTPUT);
//   pinMode(RELAY2_PIN, OUTPUT);
//   digitalWrite(RELAY1_PIN, LOW);
//   digitalWrite(RELAY2_PIN, LOW);
  
//   Serial.println("✅ Hardware initialized!");
//   Serial.println("\n📌 GPIO MAPPING:");
//   Serial.println("   Sensors: GPIO4,34,35,32,23,36,33");
//   Serial.println("   LED:     GPIO5,18,19,21,22");
//   Serial.println("   Servo:   GPIO13,14");
//   Serial.println("   Motor A: GPIO16,17,25");
//   Serial.println("   Motor B: GPIO26,27,12");
//   Serial.println("   Relay:   GPIO2,15");
  
//   // ===== SETUP WiFi =====
//   setup_wifi();
  
//   // ===== SETUP MQTT =====
//   espClient.setInsecure(); // Bỏ qua SSL certificate validation (dev mode)
//   client.setServer(mqtt_server, mqtt_port);
//   client.setCallback(mqtt_callback);
  
//   Serial.println("\n🚀 System ready!\n");
//   Serial.println("═══════════════════════════════════════════════\n");
// }

// // ============================================================================
// // MAIN LOOP
// // ============================================================================
// void loop() {
//   // MQTT connection
//   if (!client.connected()) {
//     reconnect_mqtt();
//   }
//   client.loop();
  
//   // Publish sensor data định kỳ
//   unsigned long currentMillis = millis();
//   if (currentMillis - lastSensorRead >= sensorInterval) {
//     lastSensorRead = currentMillis;
//     readAndPublishSensors();
//   }
  
//   delay(100);
// }

// // ============================================================================
// // WIFI SETUP
// // ============================================================================
// void setup_wifi() {
//   delay(10);
//   Serial.println("\n🔗 Connecting to WiFi...");
//   Serial.print("   SSID: ");
//   Serial.println(ssid);
  
//   WiFi.begin(ssid, password);
  
//   int attempts = 0;
//   while (WiFi.status() != WL_CONNECTED && attempts < 20) {
//     delay(500);
//     Serial.print(".");
//     attempts++;
//   }
  
//   if (WiFi.status() == WL_CONNECTED) {
//     Serial.println("\n✅ WiFi connected!");
//     Serial.print("   IP: ");
//     Serial.println(WiFi.localIP());
//   } else {
//     Serial.println("\n❌ WiFi connection failed!");
//   }
// }

// // ============================================================================
// // MQTT RECONNECT
// // ============================================================================
// void reconnect_mqtt() {
//   while (!client.connected()) {
//     Serial.print("🔄 Attempting MQTT connection...");
    
//     if (client.connect(DEVICE_ID, mqtt_user, mqtt_pass)) {
//       Serial.println(" connected!");
      
//       // Subscribe to command topics for all devices
//       Serial.println("\n📥 Subscribing to topics:");
      
//       // LED topics
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED1_CODE) + "/cmd").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED2_CODE) + "/cmd").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED3_CODE) + "/cmd").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED4_CODE) + "/cmd").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED5_CODE) + "/cmd").c_str());
//       Serial.println("   ✓ 5 LED topics");
      
//       // Servo topics
//       client.subscribe(("smart_home/devices/" + String(DEVICE_SERVO1_CODE) + "/cmd").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_SERVO2_CODE) + "/cmd").c_str());
//       Serial.println("   ✓ 2 Servo topics");
      
//       // Motor topics
//       client.subscribe(("smart_home/devices/" + String(DEVICE_MOTOR_A_CODE) + "/cmd").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_MOTOR_B_CODE) + "/cmd").c_str());
//       Serial.println("   ✓ 2 Motor topics");
      
//       // Relay topics
//       client.subscribe(("smart_home/devices/" + String(DEVICE_RELAY1_CODE) + "/cmd").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_RELAY2_CODE) + "/cmd").c_str());
//       Serial.println("   ✓ 2 Relay topics");
      
//       // Device ping topics (for AUTO-PING feature)
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED1_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED2_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED3_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED4_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_LED5_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_SERVO1_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_SERVO2_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_MOTOR_A_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_MOTOR_B_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_RELAY1_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/devices/" + String(DEVICE_RELAY2_CODE) + "/ping").c_str());
//       Serial.println("   ✓ 11 Device ping topics");
      
//       // Sensor ping topics (for checking sensor connection)
//       client.subscribe(("smart_home/sensors/" + String(SENSOR_DHT_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/sensors/" + String(SENSOR_GAS_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/sensors/" + String(SENSOR_RAIN_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/sensors/" + String(SENSOR_SOIL_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/sensors/" + String(SENSOR_DUST_CODE) + "/ping").c_str());
//       client.subscribe(("smart_home/sensors/" + String(SENSOR_PIR_CODE) + "/ping").c_str());
//       Serial.println("   ✓ 6 Sensor ping topics");
      
//       Serial.println("\n✅ Subscribed to all topics!");
      
//     } else {
//       Serial.print(" failed, rc=");
//       Serial.print(client.state());
//       Serial.println(" - retrying in 5 seconds");
//       delay(5000);
//     }
//   }
// }

// // ============================================================================
// // MQTT CALLBACK - Xử lý lệnh từ app
// // ============================================================================
// void mqtt_callback(char* topic, byte* payload, unsigned int length) {
//   Serial.println("\n📨 MQTT Message Received:");
//   Serial.print("   Topic: ");
//   Serial.println(topic);
  
//   // Parse payload
//   char message[length + 1];
//   memcpy(message, payload, length);
//   message[length] = '\0';
//   Serial.print("   Payload: ");
//   Serial.println(message);
  
//   String topicStr = String(topic);
  
//   // ========================================
//   // XỬ LÝ PING - Phản hồi AUTO-PING từ app (DEVICES và SENSORS)
//   // ========================================
//   if (topicStr.indexOf("/ping") != -1) {
//     // CHỈ xử lý nếu payload là "ping" (từ app), BỎ QUA "1" (response của chính mình)
//     if (String(message) == "ping") {
//       String deviceCode = "";
//       String pingTopic = "";
      
//       // Check if it's a DEVICE or SENSOR ping
//       if (topicStr.indexOf("devices/") != -1) {
//         // Topic format: smart_home/devices/{DEVICE_CODE}/ping
//         int startIdx = topicStr.indexOf("devices/") + 8;
//         int endIdx = topicStr.indexOf("/ping");
//         deviceCode = topicStr.substring(startIdx, endIdx);
//         pingTopic = "smart_home/devices/" + deviceCode + "/ping";
//         Serial.print("   🏓 DEVICE PING response sent for: ");
//       } else if (topicStr.indexOf("sensors/") != -1) {
//         // Topic format: smart_home/sensors/{SENSOR_CODE}/ping
//         int startIdx = topicStr.indexOf("sensors/") + 8;
//         int endIdx = topicStr.indexOf("/ping");
//         deviceCode = topicStr.substring(startIdx, endIdx);
//         pingTopic = "smart_home/sensors/" + deviceCode + "/ping";
//         Serial.print("   🏓 SENSOR PING response sent for: ");
//       }
      
//       // Publish phản hồi "1" về cùng topic
//       if (pingTopic.length() > 0) {
//         client.publish(pingTopic.c_str(), "1");
//         Serial.println(deviceCode);
//       }
//     }
//     // Bỏ qua nếu payload là "1" (response của ESP32)
//     return; // Không xử lý thêm các lệnh điều khiển
//   }
  
//   // Parse JSON cho các lệnh điều khiển
//   StaticJsonDocument<256> doc;
//   DeserializationError error = deserializeJson(doc, message);
  
//   if (error) {
//     Serial.print("❌ JSON parse error: ");
//     Serial.println(error.c_str());
//     return;
//   }
  
//   // ========================================
//   // XỬ LÝ LED (5 chiếc)
//   // ========================================
//   if (topicStr.indexOf(DEVICE_LED1_CODE) != -1) {
//     bool state = doc["state"] | false;
//     controlLED(LED1_PIN, state);
//     publishDeviceState(DEVICE_LED1_CODE, state ? "ON" : "OFF");
//   }
//   else if (topicStr.indexOf(DEVICE_LED2_CODE) != -1) {
//     bool state = doc["state"] | false;
//     controlLED(LED2_PIN, state);
//     publishDeviceState(DEVICE_LED2_CODE, state ? "ON" : "OFF");
//   }
//   else if (topicStr.indexOf(DEVICE_LED3_CODE) != -1) {
//     bool state = doc["state"] | false;
//     controlLED(LED3_PIN, state);
//     publishDeviceState(DEVICE_LED3_CODE, state ? "ON" : "OFF");
//   }
//   else if (topicStr.indexOf(DEVICE_LED4_CODE) != -1) {
//     bool state = doc["state"] | false;
//     controlLED(LED4_PIN, state);
//     publishDeviceState(DEVICE_LED4_CODE, state ? "ON" : "OFF");
//   }
//   else if (topicStr.indexOf(DEVICE_LED5_CODE) != -1) {
//     bool state = doc["state"] | false;
//     controlLED(LED5_PIN, state);
//     publishDeviceState(DEVICE_LED5_CODE, state ? "ON" : "OFF");
//   }
  
//   // ========================================
//   // XỬ LÝ SERVO (2 chiếc)
//   // ========================================
//   else if (topicStr.indexOf(DEVICE_SERVO1_CODE) != -1) {
//     int angle = doc["angle"] | 0;
//     controlServo1(angle);
//     publishDeviceState(DEVICE_SERVO1_CODE, String(angle).c_str());
//   }
//   else if (topicStr.indexOf(DEVICE_SERVO2_CODE) != -1) {
//     int angle = doc["angle"] | 0;
//     controlServo2(angle);
//     publishDeviceState(DEVICE_SERVO2_CODE, String(angle).c_str());
//   }
  
//   // ========================================
//   // XỬ LÝ MOTOR (2 chiếc)
//   // ========================================
//   else if (topicStr.indexOf(DEVICE_MOTOR_A_CODE) != -1) {
//     int speed = doc["speed"] | 0;
//     controlMotorA(speed);
//     publishDeviceState(DEVICE_MOTOR_A_CODE, String(speed).c_str());
//   }
//   else if (topicStr.indexOf(DEVICE_MOTOR_B_CODE) != -1) {
//     int speed = doc["speed"] | 0;
//     controlMotorB(speed);
//     publishDeviceState(DEVICE_MOTOR_B_CODE, String(speed).c_str());
//   }
  
//   // ========================================
//   // XỬ LÝ RELAY (2 chiếc)
//   // ========================================
//   else if (topicStr.indexOf(DEVICE_RELAY1_CODE) != -1) {
//     bool state = doc["state"] | false;
//     controlRelay1(state);
//     publishDeviceState(DEVICE_RELAY1_CODE, state ? "ON" : "OFF");
//   }
//   else if (topicStr.indexOf(DEVICE_RELAY2_CODE) != -1) {
//     bool state = doc["state"] | false;
//     controlRelay2(state);
//     publishDeviceState(DEVICE_RELAY2_CODE, state ? "ON" : "OFF");
//   }
  
//   Serial.println("✅ Command executed!\n");
// }

// // ============================================================================
// // ĐỌC VÀ PUBLISH SENSOR DATA
// // ============================================================================
// void readAndPublishSensors() {
//   Serial.println("📊 Reading sensors...");
  
//   // DHT22 - Temperature & Humidity
//   TempAndHumidity data = dht.getTempAndHumidity();
//   if (dht.getStatus() == 0) {
//     publishSensorData(SENSOR_DHT_CODE, "temperature", data.temperature);
//     publishSensorData(SENSOR_DHT_CODE, "humidity", data.humidity);
//     Serial.printf("   DHT22: %.1f°C, %.1f%%\n", data.temperature, data.humidity);
//   }
  
//   // MQ-2 Gas
//   int gasRaw = analogRead(MQ2_PIN);
//   float gasPPM = (gasRaw / 4095.0) * 10000.0;
//   publishSensorData(SENSOR_GAS_CODE, "gas", gasPPM);
//   Serial.printf("   Gas: %.0f ppm\n", gasPPM);
  
//   // Rain Sensor
//   int rainRaw = analogRead(RAIN_PIN);
//   int rainPercent = map(rainRaw, 4095, 0, 0, 100);
//   publishSensorData(SENSOR_RAIN_CODE, "rain", rainPercent);
//   Serial.printf("   Rain: %d%%\n", rainPercent);
  
//   // Soil Moisture
//   int soilRaw = analogRead(SOIL_PIN);
//   int soilPercent = map(soilRaw, 4095, 0, 0, 100);
//   publishSensorData(SENSOR_SOIL_CODE, "soil_moisture", soilPercent);
//   Serial.printf("   Soil: %d%%\n", soilPercent);
  
//   // Dust Sensor
//   digitalWrite(DUST_LED_PIN, LOW);
//   delayMicroseconds(280);
//   int dustRaw = analogRead(DUST_VO_PIN);
//   delayMicroseconds(40);
//   digitalWrite(DUST_LED_PIN, HIGH);
//   delayMicroseconds(9680);
  
//   float dustVoltage = (dustRaw / 4095.0) * 3.3;
//   float dustDensity = (dustVoltage - 0.6) * 200.0;
//   if (dustDensity < 0) dustDensity = 0;
//   publishSensorData(SENSOR_DUST_CODE, "dust", dustDensity);
//   Serial.printf("   Dust: %.2f mg/m³\n", dustDensity);
  
//   // PIR Motion
//   bool motionDetected = digitalRead(PIR_PIN) == HIGH;
//   publishSensorData(SENSOR_PIR_CODE, "motion", motionDetected ? 1.0 : 0.0);
//   Serial.printf("   PIR: %s\n", motionDetected ? "MOTION" : "NO MOTION");
  
//   Serial.println("✅ Sensors published!\n");
// }

// // ============================================================================
// // PUBLISH SENSOR DATA
// // ============================================================================
// void publishSensorData(const char* deviceCode, const char* sensorType, float value) {
//   String topic = "smart_home/sensors/" + String(deviceCode) + "/state";
  
//   StaticJsonDocument<128> doc;
//   doc["type"] = sensorType;
//   doc["value"] = value;
//   doc["timestamp"] = millis();
  
//   String message;
//   serializeJson(doc, message);
  
//   client.publish(topic.c_str(), message.c_str());
// }

// // ============================================================================
// // PUBLISH DEVICE STATE
// // ============================================================================
// void publishDeviceState(const char* deviceCode, const char* state) {
//   String topic = "smart_home/devices/" + String(deviceCode) + "/state";
  
//   StaticJsonDocument<128> doc;
//   doc["state"] = state;
//   doc["timestamp"] = millis();
  
//   String message;
//   serializeJson(doc, message);
  
//   client.publish(topic.c_str(), message.c_str());
// }

// // ============================================================================
// // CONTROL FUNCTIONS
// // ============================================================================

// void controlLED(int ledPin, bool state) {
//   digitalWrite(ledPin, state ? HIGH : LOW);
//   Serial.printf("💡 LED GPIO%d: %s\n", ledPin, state ? "ON" : "OFF");
// }

// void controlServo1(int angle) {
//   angle = constrain(angle, 0, 180);
//   servo1.write(angle);
//   servo1Angle = angle;
//   Serial.printf("🔄 Servo 1: %d°\n", angle);
// }

// void controlServo2(int angle) {
//   angle = constrain(angle, 0, 180);
//   servo2.write(angle);
//   servo2Angle = angle;
//   Serial.printf("🔄 Servo 2: %d°\n", angle);
// }

// void controlMotorA(int speed) {
//   speed = constrain(speed, -255, 255);
  
//   if (speed == 0) {
//     digitalWrite(MOTOR_A_IN1, LOW);
//     digitalWrite(MOTOR_A_IN2, LOW);
//     analogWrite(MOTOR_A_ENA, 0);
//   } else if (speed > 0) {
//     digitalWrite(MOTOR_A_IN1, HIGH);
//     digitalWrite(MOTOR_A_IN2, LOW);
//     analogWrite(MOTOR_A_ENA, speed);
//   } else {
//     digitalWrite(MOTOR_A_IN1, LOW);
//     digitalWrite(MOTOR_A_IN2, HIGH);
//     analogWrite(MOTOR_A_ENA, abs(speed));
//   }
  
//   motorASpeed = speed;
//   Serial.printf("⚙️  Motor A: %d\n", speed);
// }

// void controlMotorB(int speed) {
//   speed = constrain(speed, -255, 255);
  
//   if (speed == 0) {
//     digitalWrite(MOTOR_B_IN3, LOW);
//     digitalWrite(MOTOR_B_IN4, LOW);
//     analogWrite(MOTOR_B_ENB, 0);
//   } else if (speed > 0) {
//     digitalWrite(MOTOR_B_IN3, HIGH);
//     digitalWrite(MOTOR_B_IN4, LOW);
//     analogWrite(MOTOR_B_ENB, speed);
//   } else {
//     digitalWrite(MOTOR_B_IN3, LOW);
//     digitalWrite(MOTOR_B_IN4, HIGH);
//     analogWrite(MOTOR_B_ENB, abs(speed));
//   }
  
//   motorBSpeed = speed;
//   Serial.printf("⚙️  Motor B: %d\n", speed);
// }

// void controlRelay1(bool state) {
//   digitalWrite(RELAY1_PIN, state ? HIGH : LOW);
//   relay1State = state;
//   Serial.printf("🔌 Relay 1: %s\n", state ? "ON" : "OFF");
// }

// void controlRelay2(bool state) {
//   digitalWrite(RELAY2_PIN, state ? HIGH : LOW);
//   relay2State = state;
//   Serial.printf("🔌 Relay 2: %s\n", state ? "ON" : "OFF");
// }
