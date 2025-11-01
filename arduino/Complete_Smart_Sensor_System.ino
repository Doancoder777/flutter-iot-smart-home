// /*
//  * ═══════════════════════════════════════════════════════════════════
//  * 🏠 SMART HOME - COMPLETE SENSOR SYSTEM WITH MQTT
//  * ═══════════════════════════════════════════════════════════════════
//  * 
//  * 📡 MQTT Topics: smart_home/sensors/{CODE}/state
//  * 
//  * 📊 SENSORS MAPPING (App tested):
//  *    ✅ DHT22_001  → Temperature (°C)
//  *    ✅ DHT22_002  → Humidity (%)
//  *    ✅ SOIL_001   → Soil Moisture (%)
//  *    ✅ LDR_001    → Light (lux)
//  *    ✅ MQ2_001    → Gas (ppm)
//  *    ✅ GP2Y_001   → Dust (µg/m³)
//  *    ✅ PIR_001    → Motion (0/1)
//  *    ✅ RAIN_001   → Rain (level)
//  *    ✅ BMP280_001 → Pressure (hPa)
//  *    ✅ SMOKE_001  → Smoke (ppm)
//  * 
//  * 🎯 SMART PUBLISHING STRATEGY:
//  *    - First boot: All sensors send immediately
//  *    - Normal: Every 5 minutes
//  *    - Change detection: Send immediately if change > threshold
//  *    - Motion (PIR): Only send on state change (0→1 or 1→0)
//  * 
//  * ═══════════════════════════════════════════════════════════════════
//  */

// #include <WiFi.h>
// #include <PubSubClient.h>
// #include <DHT.h>
// #include <ArduinoJson.h>

// // ═══════════════════════════════════════════════════════════════════
// // 📡 WIFI & MQTT CONFIGURATION
// // ═══════════════════════════════════════════════════════════════════
// const char* WIFI_SSID = "YOUR_WIFI_SSID";
// const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// const char* MQTT_SERVER = "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud";
// const int MQTT_PORT = 8883;
// const char* MQTT_USER = "doancoder";
// const char* MQTT_PASSWORD = "Abc@123456";

// // ═══════════════════════════════════════════════════════════════════
// // 📌 PIN DEFINITIONS
// // ═══════════════════════════════════════════════════════════════════
// #define DHT_PIN 4           // DHT22 Temperature & Humidity
// #define DHT_TYPE DHT22
// #define SOIL_PIN 34         // Soil Moisture (analog)
// #define LDR_PIN 35          // Light sensor (analog)
// #define MQ2_PIN 32          // Gas sensor (analog)
// #define GP2Y_PIN 33         // Dust sensor (analog)
// #define PIR_PIN 27          // Motion sensor (digital)
// #define RAIN_PIN 36         // Rain sensor (analog)
// // Note: BMP280 uses I2C (SDA=21, SCL=22)

// // ═══════════════════════════════════════════════════════════════════
// // ⏱️ TIMING CONFIGURATION
// // ═══════════════════════════════════════════════════════════════════
// const unsigned long PUBLISH_INTERVAL = 5 * 60 * 1000; // 5 minutes
// unsigned long lastPublishTime = 0;
// bool isFirstBoot = true;

// // ═══════════════════════════════════════════════════════════════════
// // 🎯 CHANGE DETECTION THRESHOLDS
// // ═══════════════════════════════════════════════════════════════════
// struct SensorData {
//   float temperature = 0;
//   float humidity = 0;
//   float soilMoisture = 0;
//   float light = 0;
//   float gas = 0;
//   float dust = 0;
//   int motion = 0;
//   float rain = 0;
//   float pressure = 1013.0;
//   float smoke = 0;
// };

// SensorData currentData;
// SensorData previousData;

// // Change thresholds
// const float TEMP_THRESHOLD = 2.0;      // ±2°C
// const float HUMIDITY_THRESHOLD = 5.0;  // ±5%
// const float SOIL_THRESHOLD = 10.0;     // ±10%
// const float LIGHT_THRESHOLD = 100.0;   // ±100 lux
// const float GAS_THRESHOLD = 50.0;      // ±50 ppm
// const float DUST_THRESHOLD = 20.0;     // ±20 µg/m³
// const float RAIN_THRESHOLD = 100.0;    // ±100 level
// const float PRESSURE_THRESHOLD = 5.0;  // ±5 hPa
// const float SMOKE_THRESHOLD = 50.0;    // ±50 ppm

// // ═══════════════════════════════════════════════════════════════════
// // 🌡️ SENSOR OBJECTS
// // ═══════════════════════════════════════════════════════════════════
// DHT dht(DHT_PIN, DHT_TYPE);
// WiFiClient espClient;
// PubSubClient mqttClient(espClient);

// // ═══════════════════════════════════════════════════════════════════
// // 🔌 SETUP
// // ═══════════════════════════════════════════════════════════════════
// void setup() {
//   Serial.begin(115200);
//   Serial.println("\n\n╔════════════════════════════════════════════╗");
//   Serial.println("║  🏠 SMART HOME SENSOR SYSTEM STARTING...  ║");
//   Serial.println("╚════════════════════════════════════════════╝\n");
  
//   // Initialize sensors
//   dht.begin();
//   pinMode(PIR_PIN, INPUT);
  
//   // Connect WiFi
//   connectWiFi();
  
//   // Connect MQTT
//   mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
//   connectMQTT();
  
//   Serial.println("\n✅ System ready! Starting sensor monitoring...\n");
// }

// // ═══════════════════════════════════════════════════════════════════
// // 🔁 MAIN LOOP
// // ═══════════════════════════════════════════════════════════════════
// void loop() {
//   if (!mqttClient.connected()) {
//     connectMQTT();
//   }
//   mqttClient.loop();
  
//   // Read all sensors
//   readAllSensors();
  
//   // Check if we should publish
//   unsigned long currentTime = millis();
//   bool shouldPublish = false;
  
//   if (isFirstBoot) {
//     // First boot: publish all immediately
//     shouldPublish = true;
//     isFirstBoot = false;
//     Serial.println("📢 FIRST BOOT - Publishing all sensors...");
//   } 
//   else if (currentTime - lastPublishTime >= PUBLISH_INTERVAL) {
//     // 5 minutes passed
//     shouldPublish = true;
//     Serial.println("⏰ 5 MINUTES PASSED - Publishing all sensors...");
//   }
//   else if (hasSignificantChange()) {
//     // Significant change detected
//     shouldPublish = true;
//     Serial.println("🔔 SIGNIFICANT CHANGE DETECTED - Publishing...");
//   }
//   else if (currentData.motion != previousData.motion) {
//     // Motion state changed
//     publishSensor("PIR_001", currentData.motion);
//     previousData.motion = currentData.motion;
//     Serial.println("🚨 MOTION STATE CHANGED - Publishing motion...");
//   }
  
//   if (shouldPublish) {
//     publishAllSensors();
//     previousData = currentData;
//     lastPublishTime = currentTime;
//   }
  
//   delay(1000); // Check every second
// }

// // ═══════════════════════════════════════════════════════════════════
// // 📖 READ ALL SENSORS
// // ═══════════════════════════════════════════════════════════════════
// void readAllSensors() {
//   // Temperature & Humidity (DHT22)
//   currentData.temperature = dht.readTemperature();
//   currentData.humidity = dht.readHumidity();
  
//   if (isnan(currentData.temperature)) currentData.temperature = 25.0;
//   if (isnan(currentData.humidity)) currentData.humidity = 50.0;
  
//   // Soil Moisture (0-100%)
//   int soilRaw = analogRead(SOIL_PIN);
//   currentData.soilMoisture = map(soilRaw, 4095, 0, 0, 100);
//   currentData.soilMoisture = constrain(currentData.soilMoisture, 0, 100);
  
//   // Light (LDR to lux approximation)
//   int ldrRaw = analogRead(LDR_PIN);
//   currentData.light = map(ldrRaw, 0, 4095, 0, 1000);
  
//   // Gas (MQ2 to ppm approximation)
//   int gasRaw = analogRead(MQ2_PIN);
//   currentData.gas = map(gasRaw, 0, 4095, 0, 1000);
  
//   // Dust (GP2Y to µg/m³ approximation)
//   int dustRaw = analogRead(GP2Y_PIN);
//   currentData.dust = map(dustRaw, 0, 4095, 0, 500);
  
//   // Motion (PIR digital)
//   currentData.motion = digitalRead(PIR_PIN);
  
//   // Rain (analog level)
//   int rainRaw = analogRead(RAIN_PIN);
//   currentData.rain = map(rainRaw, 4095, 0, 0, 1000);
  
//   // Pressure (BMP280 - placeholder, requires BMP280 library)
//   // currentData.pressure = bmp.readPressure() / 100.0; // Convert Pa to hPa
//   currentData.pressure = 1013.0 + random(-10, 10); // Simulated for now
  
//   // Smoke (analog)
//   int smokeRaw = analogRead(MQ2_PIN); // Can use same as gas or different pin
//   currentData.smoke = map(smokeRaw, 0, 4095, 0, 500);
// }

// // ═══════════════════════════════════════════════════════════════════
// // 🔍 CHECK SIGNIFICANT CHANGE
// // ═══════════════════════════════════════════════════════════════════
// bool hasSignificantChange() {
//   return (
//     abs(currentData.temperature - previousData.temperature) > TEMP_THRESHOLD ||
//     abs(currentData.humidity - previousData.humidity) > HUMIDITY_THRESHOLD ||
//     abs(currentData.soilMoisture - previousData.soilMoisture) > SOIL_THRESHOLD ||
//     abs(currentData.light - previousData.light) > LIGHT_THRESHOLD ||
//     abs(currentData.gas - previousData.gas) > GAS_THRESHOLD ||
//     abs(currentData.dust - previousData.dust) > DUST_THRESHOLD ||
//     abs(currentData.rain - previousData.rain) > RAIN_THRESHOLD ||
//     abs(currentData.pressure - previousData.pressure) > PRESSURE_THRESHOLD ||
//     abs(currentData.smoke - previousData.smoke) > SMOKE_THRESHOLD
//   );
// }

// // ═══════════════════════════════════════════════════════════════════
// // 📤 PUBLISH ALL SENSORS
// // ═══════════════════════════════════════════════════════════════════
// void publishAllSensors() {
//   publishSensor("DHT22_001", currentData.temperature);
//   publishSensor("DHT22_002", currentData.humidity);
//   publishSensor("SOIL_001", currentData.soilMoisture);
//   publishSensor("LDR_001", currentData.light);
//   publishSensor("MQ2_001", currentData.gas);
//   publishSensor("GP2Y_001", currentData.dust);
//   publishSensor("PIR_001", currentData.motion);
//   publishSensor("RAIN_001", currentData.rain);
//   publishSensor("BMP280_001", currentData.pressure);
//   publishSensor("SMOKE_001", currentData.smoke);
  
//   Serial.println("✅ All sensors published!\n");
// }

// // ═══════════════════════════════════════════════════════════════════
// // 📤 PUBLISH SINGLE SENSOR
// // ═══════════════════════════════════════════════════════════════════
// void publishSensor(const char* deviceCode, float value) {
//   // Create topic
//   String topic = "smart_home/sensors/";
//   topic += deviceCode;
//   topic += "/state";
  
//   // Create JSON
//   StaticJsonDocument<200> doc;
//   doc["value"] = value;
  
//   char jsonBuffer[200];
//   serializeJson(doc, jsonBuffer);
  
//   // Publish
//   if (mqttClient.publish(topic.c_str(), jsonBuffer)) {
//     Serial.printf("📡 %s → %s\n", deviceCode, jsonBuffer);
//   } else {
//     Serial.printf("❌ Failed to publish %s\n", deviceCode);
//   }
// }

// // ═══════════════════════════════════════════════════════════════════
// // 📶 WIFI CONNECTION
// // ═══════════════════════════════════════════════════════════════════
// void connectWiFi() {
//   Serial.print("🔌 Connecting to WiFi");
//   WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
//   while (WiFi.status() != WL_CONNECTED) {
//     delay(500);
//     Serial.print(".");
//   }
  
//   Serial.println(" ✅ Connected!");
//   Serial.print("📡 IP Address: ");
//   Serial.println(WiFi.localIP());
// }

// // ═══════════════════════════════════════════════════════════════════
// // 📡 MQTT CONNECTION
// // ═══════════════════════════════════════════════════════════════════
// void connectMQTT() {
//   while (!mqttClient.connected()) {
//     Serial.print("🔗 Connecting to MQTT broker...");
    
//     String clientId = "ESP32_SmartHome_";
//     clientId += String(random(0xffff), HEX);
    
//     if (mqttClient.connect(clientId.c_str(), MQTT_USER, MQTT_PASSWORD)) {
//       Serial.println(" ✅ Connected!");
//     } else {
//       Serial.print(" ❌ Failed, rc=");
//       Serial.print(mqttClient.state());
//       Serial.println(" Retrying in 5s...");
//       delay(5000);
//     }
//   }
// }
