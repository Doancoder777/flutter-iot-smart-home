/*
 * ============================================================================
 * FULL MQTT TEST - TẤT CẢ THIẾT BỊ + MQTT BROKER + SMART PUBLISHING - FIXED
 * ============================================================================
 * 
 * ✅ ĐÃ SỬA:
 * 1. Device codes khớp với app: MQ2_001, GP2Y_001, PIR_001 (bỏ prefix)
 * 2. DHT22 LUÔN LUÔN publish (bỏ error check để đảm bảo có data)
 * 3. Added debug logging cho DHT22 status
 * 
 * Kết hợp:
 * - 6 Sensors + 10 Actuators (FULL devices từ 17_Complete_All_Devices_Test)
 * - MQTT Broker (HiveMQ Cloud) để điều khiển từ xa
 * - GPIO Optimized cho ESP32 DevKit v1 (tránh ADC2 + WiFi conflict)
 * - 🎯 SMART PUBLISHING: First boot → 1 minute → Change detection → PIR state-only
 * 
 * SENSORS (6 loại - 7 chân):
 * 1. DHT22 (GPIO4)           - Nhiệt độ/Độ ẩm
 * 2. MQ-2 (GPIO34)           - Khí Gas
 * 3. Rain (GPIO35)           - Mưa
 * 4. Soil (GPIO32)           - Độ ẩm đất
 * 5. GP2Y Dust (GPIO23, 36)  - Bụi PM2.5/PM10
 * 6. PIR (GPIO33)            - Chuyển động
 * 
 * ACTUATORS (4 loại - 15 chân):
 * 7.  5 LED (GPIO5,18,19,21,22)           - 5 LED
 * 8.  2 Servo (GPIO13,14)                 - 2 Servo motor
 * 9.  2 Motor L298N (GPIO16,17,25,26,27,12) - 2 Motor DC
 * 10. 2 Relay (GPIO2,15)                  - 2 Relay
 * 
 * MQTT Topics:
 * - Subscribe: smart_home/devices/{DEVICE_CODE}/cmd
 * - Publish:   smart_home/devices/{DEVICE_CODE}/state
 * - Sensors:   smart_home/sensors/{SENSOR_CODE}/state
 * 
 * ============================================================================
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>
#include "DHTesp.h"

// ============================================================================
// WIFI & MQTT CONFIG
// ============================================================================
// 📶 WiFi - Chọn 1 trong 3 mạng (uncomment dòng cần dùng)
const char* ssid = "Virus_plus";        // Lựa chọn 1
const char* password = "tan16108";
// const char* ssid = "Sigma";          // Lựa chọn 2
// const char* password = "tan16108";
// const char* ssid = "VIETTEL NgocThoai";  // Lựa chọn 3
// const char* password = "0934918347";

// 🌐 MQTT Broker (HiveMQ Cloud)
const char* mqtt_server = "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;              // SSL/TLS port
const char* mqtt_user = "sigma";
const char* mqtt_pass = "35386Doan";     // Full password

// 🆔 Device ID (UNIQUE cho mỗi ESP32)
const char* DEVICE_ID = "ESP32_FULL_001";

WiFiClientSecure espClient;
PubSubClient client(espClient);

// ============================================================================
// PIN DEFINITIONS (✅ OPTIMIZED cho ESP32 DevKit v1)
// ============================================================================
// SENSORS (7 chân - ADC1 cho analog)
#define DHT_PIN         4    // GPIO4  - DHT22
#define MQ2_PIN         34   // GPIO34 - MQ-2 Gas (ADC1_6)
#define RAIN_PIN        35   // GPIO35 - Rain (ADC1_7)
#define SOIL_PIN        32   // GPIO32 - Soil (ADC1_4)
#define DUST_LED_PIN    23   // GPIO23 - Dust LED (VSPI_MOSI)
#define DUST_VO_PIN     36   // GPIO36 - Dust Output (ADC1_0)
#define PIR_PIN         33   // GPIO33 - PIR (ADC1_5)

// ACTUATORS - LED (5 chân)
#define LED1_PIN        5    // GPIO5  - Red LED
#define LED2_PIN        18   // GPIO18 - Yellow LED
#define LED3_PIN        19   // GPIO19 - Green LED
#define LED4_PIN        21   // GPIO21 - Blue LED
#define LED5_PIN        22   // GPIO22 - White LED

// ACTUATORS - Servo (2 chân)
#define SERVO1_PIN      13   // GPIO13 - Servo Mái Che (đóng/mở khi mưa)
#define SERVO2_PIN      14   // GPIO14 - Servo Cổng

// ACTUATORS - Motor A (3 chân)
#define MOTOR_A_ENA     16   // GPIO16 - Motor A PWM Speed
#define MOTOR_A_IN1     17   // GPIO17 - Motor A Direction 1
#define MOTOR_A_IN2     25   // GPIO25 - Motor A Direction 2

// ACTUATORS - Motor B (3 chân)
#define MOTOR_B_ENB     26   // GPIO26 - Motor B PWM Speed
#define MOTOR_B_IN3     27   // GPIO27 - Motor B Direction 1
#define MOTOR_B_IN4     12   // GPIO12 - Motor B Direction 2

// ACTUATORS - Relay (2 chân)
#define RELAY1_PIN      2    // GPIO2  - Relay 1
#define RELAY2_PIN      15   // GPIO15 - Relay 2

// ============================================================================
// DEVICE CODES - ✅ FIXED: Khớp với Flutter app (BỎ PREFIX để match)
// ============================================================================
// Sensors
const char* SENSOR_TEMP_CODE    = "DHT22_001";        // 🌡️ Temperature (GPIO4)
const char* SENSOR_HUMID_CODE   = "DHT22_002";        // 💧 Humidity (GPIO4)
const char* SENSOR_GAS_CODE     = "MQ2_001";          // ✅ FIXED: MQ2_001 (bỏ GAS_)
const char* SENSOR_RAIN_CODE    = "RAIN_001";         // 🌧️ Rain Sensor (GPIO35)
const char* SENSOR_SOIL_CODE    = "SOIL_001";         // 🌱 Soil Moisture (GPIO32)
const char* SENSOR_DUST_CODE    = "GP2Y_001";         // ✅ FIXED: GP2Y_001 (bỏ DUST_)
const char* SENSOR_PIR_CODE     = "PIR_001";          // ✅ FIXED: PIR_001 (bỏ _MOTION)

// Actuators
const char* DEVICE_LED1_CODE    = "LED_RED_001";      // 🔴 Red LED (GPIO5)
const char* DEVICE_LED2_CODE    = "LED_YELLOW_001";   // 🟡 Yellow LED (GPIO18)
const char* DEVICE_LED3_CODE    = "LED_GREEN_001";    // 🟢 Green LED (GPIO19)
const char* DEVICE_LED4_CODE    = "LED_BLUE_001";     // 🔵 Blue LED (GPIO21)
const char* DEVICE_LED5_CODE    = "LED_WHITE_001";    // ⚪ White LED (GPIO22)
const char* DEVICE_SERVO1_CODE  = "SERVO_ROOF_001";   // 🏠 Mái che - GPIO13
const char* DEVICE_SERVO2_CODE  = "SERVO_DOOR_001";   // 🚪 Cổng - GPIO14
const char* DEVICE_MOTOR_A_CODE = "MOTOR_FAN_A_001";  // 🌀 Motor A (GPIO16,17,25)
const char* DEVICE_MOTOR_B_CODE = "MOTOR_FAN_B_001";  // 🌀 Motor B (GPIO26,27,12)
const char* DEVICE_RELAY1_CODE  = "RELAY_PUMP_001";   // 💧 Relay Pump (GPIO2)
const char* DEVICE_RELAY2_CODE  = "RELAY_LIGHT_001";  // 💡 Relay Light (GPIO15)

// ============================================================================
// OBJECTS
// ============================================================================
DHTesp dht;
Servo servo1;
Servo servo2;

// ============================================================================
// GLOBAL VARIABLES - DEVICE STATES
// ============================================================================
int servo1Angle = 0;
int servo2Angle = 0;
int motorASpeed = 0;
int motorBSpeed = 0;
bool relay1State = false;
bool relay2State = false;
bool led1State = false;
bool led2State = false;
bool led3State = false;
bool led4State = false;
bool led5State = false;

// ============================================================================
// 🎯 SMART PUBLISHING - SENSOR STATE TRACKING
// ============================================================================
bool firstBoot = true;  // First boot flag - gửi ngay khi có dữ liệu lần đầu
unsigned long lastSensorPublish = 0;
const long publishInterval = 60000; // 🔥 1 PHÚT = 60000ms

// Previous sensor values for change detection
float lastTemp = -999.0;
float lastHumidity = -999.0;
float lastGasPPM = -999.0;
int lastRainPercent = -999;
int lastSoilPercent = -999;
float lastDustDensity = -999.0;
bool lastMotionState = false;  // PIR - chỉ gửi khi đảo trạng thái

// ⏱️ CHECK INTERVAL - Kiểm tra thay đổi mỗi 10 giây (tránh spam)
unsigned long lastCheckTime = 0;
const long checkInterval = 10000; // 10 giây

// Change detection thresholds (ngưỡng phát hiện thay đổi lớn)
const float TEMP_THRESHOLD = 2.0;        // ±2°C
const float HUMIDITY_THRESHOLD = 5.0;    // ±5%
const float GAS_THRESHOLD = 100.0;       // ±100 ppm
const int RAIN_THRESHOLD = 10;           // ±10%
const int SOIL_THRESHOLD = 10;           // ±10%
const float DUST_THRESHOLD = 20.0;       // ±20 mg/m³

// ============================================================================
// FUNCTION PROTOTYPES
// ============================================================================
void setup_wifi();
void reconnect_mqtt();
void mqtt_callback(char* topic, byte* payload, unsigned int length);
void publishSensorData(const char* deviceCode, const char* sensorType, float value);
void publishDeviceState(const char* deviceCode, const char* state);
void publishDeviceState(const char* deviceCode, int value, const char* valueKey);
void readAndPublishSensors();
bool shouldPublishSensors();
void controlServo1(int angle);
void controlServo2(int angle);
void controlMotorA(int speed);
void controlMotorB(int speed);
void controlRelay1(bool state);
void controlRelay2(bool state);
void controlLED(int ledPin, bool state);

// ============================================================================
// SETUP
// ============================================================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n╔════════════════════════════════════════════════╗");
  Serial.println("║   FULL MQTT TEST - ALL DEVICES + MQTT FIXED   ║");
  Serial.println("║   ESP32 DevKit v1 - Optimized GPIO            ║");
  Serial.println("║   ✅ Device codes fixed to match app          ║");
  Serial.println("║   ✅ DHT22 always publish (no error check)    ║");
  Serial.println("╚════════════════════════════════════════════════╝\n");
  
  // ===== SETUP SENSORS =====
  dht.setup(DHT_PIN, DHTesp::DHT22);
  pinMode(MQ2_PIN, INPUT);
  pinMode(RAIN_PIN, INPUT);
  pinMode(SOIL_PIN, INPUT);
  pinMode(DUST_LED_PIN, OUTPUT);
  pinMode(DUST_VO_PIN, INPUT);
  pinMode(PIR_PIN, INPUT);
  digitalWrite(DUST_LED_PIN, LOW);
  
  // ===== SETUP ACTUATORS =====
  // LED
  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);
  pinMode(LED3_PIN, OUTPUT);
  pinMode(LED4_PIN, OUTPUT);
  pinMode(LED5_PIN, OUTPUT);
  
  // Servo
  servo1.attach(SERVO1_PIN);
  servo2.attach(SERVO2_PIN);
  servo1.write(0);
  servo2.write(0);
  
  // Motor A
  pinMode(MOTOR_A_ENA, OUTPUT);
  pinMode(MOTOR_A_IN1, OUTPUT);
  pinMode(MOTOR_A_IN2, OUTPUT);
  
  // Motor B
  pinMode(MOTOR_B_ENB, OUTPUT);
  pinMode(MOTOR_B_IN3, OUTPUT);
  pinMode(MOTOR_B_IN4, OUTPUT);
  
  // Relay
  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  digitalWrite(RELAY1_PIN, LOW);
  digitalWrite(RELAY2_PIN, LOW);
  
  Serial.println("✅ Hardware initialized!");
  Serial.println("\n📌 GPIO MAPPING:");
  Serial.println("   Sensors: GPIO4,34,35,32,23,36,33");
  Serial.println("   LED:     GPIO5,18,19,21,22");
  Serial.println("   Servo:   GPIO13,14");
  Serial.println("   Motor A: GPIO16,17,25");
  Serial.println("   Motor B: GPIO26,27,12");
  Serial.println("   Relay:   GPIO2,15");
  
  Serial.println("\n✅ FIXED DEVICE CODES:");
  Serial.println("   OLD -> NEW");
  Serial.println("   GAS_MQ2_001      -> MQ2_001");
  Serial.println("   DUST_GP2Y_001    -> GP2Y_001");
  Serial.println("   PIR_MOTION_001   -> PIR_001");
  
  // ===== SETUP WiFi =====
  setup_wifi();
  
  // ===== SETUP MQTT =====
  espClient.setInsecure(); // Bỏ qua SSL certificate validation (dev mode)
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(mqtt_callback);
  
  Serial.println("\n🚀 System ready!\n");
  Serial.println("🎯 SMART PUBLISHING:");
  Serial.println("   - First boot: Publish ALL sensors immediately");
  Serial.println("   - Normal: Every 1 MINUTE");
  Serial.println("   - Change check: Every 10 seconds");
  Serial.println("   - Publish if change > threshold");
  Serial.println("   - PIR: Only publish on state change (0→1 or 1→0)");
  Serial.println("   - DHT22: ✅ ALWAYS publish (no error check)");
  Serial.println("═══════════════════════════════════════════════\n");
}

// ============================================================================
// MAIN LOOP
// ============================================================================
void loop() {
  // MQTT connection
  if (!client.connected()) {
    reconnect_mqtt();
  }
  client.loop();
  
  // Smart sensor publishing
  if (shouldPublishSensors()) {
    readAndPublishSensors();
  }
  
  delay(100);
}

// ============================================================================
// 🎯 SMART PUBLISHING LOGIC - Kiểm tra xem có nên publish sensors không
// ============================================================================
bool shouldPublishSensors() {
  unsigned long currentMillis = millis();
  
  // 1️⃣ FIRST BOOT: Gửi ngay lần đầu
  if (firstBoot) {
    Serial.println("\n📢 FIRST BOOT - Publishing all sensors immediately...");
    firstBoot = false;
    lastSensorPublish = currentMillis;
    lastCheckTime = currentMillis;
    return true;
  }
  
  // 2️⃣ PERIODIC: Gửi mỗi 1 PHÚT
  if (currentMillis - lastSensorPublish >= publishInterval) {
    Serial.println("\n⏰ 1 MINUTE PASSED - Publishing all sensors...");
    lastSensorPublish = currentMillis;
    lastCheckTime = currentMillis;
    return true;
  }
  
  // 3️⃣ CHANGE DETECTION: CHỈ CHECK MỖI 10 GIÂY (tránh spam)
  if (currentMillis - lastCheckTime < checkInterval) {
    return false; // 🚫 Chưa đến lúc check, bỏ qua
  }
  
  lastCheckTime = currentMillis;
  
  // Bây giờ mới đọc sensors để kiểm tra thay đổi
  TempAndHumidity data = dht.getTempAndHumidity();
  // ✅ FIXED: Luôn lấy giá trị, không check error
  float currentTemp = data.temperature;
  float currentHumidity = data.humidity;
  
  int gasRaw = analogRead(MQ2_PIN);
  float currentGasPPM = (gasRaw / 4095.0) * 10000.0;
  
  int rainRaw = analogRead(RAIN_PIN);
  int currentRainPercent = map(rainRaw, 4095, 0, 0, 100);
  
  int soilRaw = analogRead(SOIL_PIN);
  int currentSoilPercent = map(soilRaw, 4095, 0, 0, 100);
  
  digitalWrite(DUST_LED_PIN, LOW);
  delayMicroseconds(280);
  int dustRaw = analogRead(DUST_VO_PIN);
  delayMicroseconds(40);
  digitalWrite(DUST_LED_PIN, HIGH);
  delayMicroseconds(9680);
  float dustVoltage = (dustRaw / 4095.0) * 3.3;
  float currentDustDensity = (dustVoltage - 0.6) * 200.0;
  if (currentDustDensity < 0) currentDustDensity = 0;
  
  bool currentMotionState = (digitalRead(PIR_PIN) == HIGH);
  
  // Kiểm tra thay đổi lớn
  bool hasSignificantChange = false;
  
  if (abs(currentTemp - lastTemp) > TEMP_THRESHOLD) {
    Serial.println("🔔 Temperature changed significantly!");
    hasSignificantChange = true;
  }
  if (abs(currentHumidity - lastHumidity) > HUMIDITY_THRESHOLD) {
    Serial.println("🔔 Humidity changed significantly!");
    hasSignificantChange = true;
  }
  if (abs(currentGasPPM - lastGasPPM) > GAS_THRESHOLD) {
    Serial.println("🔔 Gas level changed significantly!");
    hasSignificantChange = true;
  }
  if (abs(currentRainPercent - lastRainPercent) > RAIN_THRESHOLD) {
    Serial.println("🔔 Rain level changed significantly!");
    hasSignificantChange = true;
  }
  if (abs(currentSoilPercent - lastSoilPercent) > SOIL_THRESHOLD) {
    Serial.println("🔔 Soil moisture changed significantly!");
    hasSignificantChange = true;
  }
  if (abs(currentDustDensity - lastDustDensity) > DUST_THRESHOLD) {
    Serial.println("🔔 Dust density changed significantly!");
    hasSignificantChange = true;
  }
  
  // 4️⃣ PIR SPECIAL CASE: Chỉ gửi khi đảo trạng thái
  if (currentMotionState != lastMotionState) {
    Serial.println("🚨 PIR MOTION STATE CHANGED - Publishing motion only...");
    publishSensorData(SENSOR_PIR_CODE, "motion", currentMotionState ? 1.0 : 0.0);
    lastMotionState = currentMotionState;
  }
  
  // Nếu có thay đổi lớn, publish ALL sensors
  if (hasSignificantChange) {
    Serial.println("📤 SIGNIFICANT CHANGE DETECTED - Publishing all sensors...");
    lastSensorPublish = currentMillis;
    return true;
  }
  
  return false;
}

// ============================================================================
// ĐỌC VÀ PUBLISH SENSOR DATA
// ============================================================================
void readAndPublishSensors() {
  Serial.println("📊 Reading sensors...");
  
  // DHT22 - Temperature & Humidity (TÁCH RIÊNG 2 DEVICE CODES)
  // ✅ FIXED: LUÔN LUÔN publish, không check error
  TempAndHumidity data = dht.getTempAndHumidity();
  int status = dht.getStatus();
  
  Serial.printf("🔍 DHT22 Status Code: %d\n", status);
  
  // LUÔN LUÔN publish, dù có lỗi hay không
  lastTemp = data.temperature;
  lastHumidity = data.humidity;
  
  // 🌡️ Publish Temperature → DHT22_001
  publishSensorData(SENSOR_TEMP_CODE, "temperature", data.temperature);
  delay(100);
  
  // 💧 Publish Humidity → DHT22_002
  publishSensorData(SENSOR_HUMID_CODE, "humidity", data.humidity);
  delay(100);
  
  Serial.printf("   DHT22: %.1f°C, %.1f%% (Status: %d)\n", 
                data.temperature, data.humidity, status);
  
  // MQ-2 Gas
  int gasRaw = analogRead(MQ2_PIN);
  lastGasPPM = (gasRaw / 4095.0) * 10000.0;
  publishSensorData(SENSOR_GAS_CODE, "gas", lastGasPPM);
  Serial.printf("   Gas: %.0f ppm\n", lastGasPPM);
  delay(100);
  
  // Rain Sensor
  int rainRaw = analogRead(RAIN_PIN);
  lastRainPercent = map(rainRaw, 4095, 0, 0, 100);
  publishSensorData(SENSOR_RAIN_CODE, "rain", lastRainPercent);
  Serial.printf("   Rain: %d%%\n", lastRainPercent);
  delay(100);
  
  // Soil Moisture
  int soilRaw = analogRead(SOIL_PIN);
  lastSoilPercent = map(soilRaw, 4095, 0, 0, 100);
  publishSensorData(SENSOR_SOIL_CODE, "soil_moisture", lastSoilPercent);
  Serial.printf("   Soil: %d%%\n", lastSoilPercent);
  delay(100);
  
  // Dust Sensor
  digitalWrite(DUST_LED_PIN, LOW);
  delayMicroseconds(280);
  int dustRaw = analogRead(DUST_VO_PIN);
  delayMicroseconds(40);
  digitalWrite(DUST_LED_PIN, HIGH);
  delayMicroseconds(9680);
  
  float dustVoltage = (dustRaw / 4095.0) * 3.3;
  lastDustDensity = (dustVoltage - 0.6) * 200.0;
  if (lastDustDensity < 0) lastDustDensity = 0;
  publishSensorData(SENSOR_DUST_CODE, "dust", lastDustDensity);
  Serial.printf("   Dust: %.2f mg/m³\n", lastDustDensity);
  delay(100);
  
  // PIR Motion (cập nhật state hiện tại)
  lastMotionState = (digitalRead(PIR_PIN) == HIGH);
  publishSensorData(SENSOR_PIR_CODE, "motion", lastMotionState ? 1.0 : 0.0);
  Serial.printf("   PIR: %s\n", lastMotionState ? "MOTION" : "NO MOTION");
  
  Serial.println("✅ Sensors published!\n");
}

// ============================================================================
// WIFI SETUP
// ============================================================================
void setup_wifi() {
  delay(10);
  Serial.println("\n🔗 Connecting to WiFi...");
  Serial.print("   SSID: ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected!");
    Serial.print("   IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi connection failed!");
  }
}

// ============================================================================
// MQTT RECONNECT
// ============================================================================
void reconnect_mqtt() {
  while (!client.connected()) {
    Serial.print("🔄 Attempting MQTT connection...");
    
    if (client.connect(DEVICE_ID, mqtt_user, mqtt_pass)) {
      Serial.println(" connected!");
      
      // Subscribe to command topics for all devices
      Serial.println("\n📥 Subscribing to topics:");
      
      // LED topics
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED1_CODE) + "/cmd").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED2_CODE) + "/cmd").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED3_CODE) + "/cmd").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED4_CODE) + "/cmd").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED5_CODE) + "/cmd").c_str());
      Serial.println("   ✓ 5 LED topics");
      
      // Servo topics
      client.subscribe(("smart_home/devices/" + String(DEVICE_SERVO1_CODE) + "/cmd").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_SERVO2_CODE) + "/cmd").c_str());
      Serial.println("   ✓ 2 Servo topics");
      
      // Motor topics
      client.subscribe(("smart_home/devices/" + String(DEVICE_MOTOR_A_CODE) + "/cmd").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_MOTOR_B_CODE) + "/cmd").c_str());
      Serial.println("   ✓ 2 Motor topics");
      
      // Relay topics
      client.subscribe(("smart_home/devices/" + String(DEVICE_RELAY1_CODE) + "/cmd").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_RELAY2_CODE) + "/cmd").c_str());
      Serial.println("   ✓ 2 Relay topics");
      
      // Device ping topics (for AUTO-PING feature)
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED1_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED2_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED3_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED4_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_LED5_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_SERVO1_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_SERVO2_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_MOTOR_A_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_MOTOR_B_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_RELAY1_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/devices/" + String(DEVICE_RELAY2_CODE) + "/ping").c_str());
      Serial.println("   ✓ 11 Device ping topics");
      
      // Sensor ping topics (for checking sensor connection)
      client.subscribe(("smart_home/sensors/" + String(SENSOR_TEMP_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/sensors/" + String(SENSOR_HUMID_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/sensors/" + String(SENSOR_GAS_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/sensors/" + String(SENSOR_RAIN_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/sensors/" + String(SENSOR_SOIL_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/sensors/" + String(SENSOR_DUST_CODE) + "/ping").c_str());
      client.subscribe(("smart_home/sensors/" + String(SENSOR_PIR_CODE) + "/ping").c_str());
      Serial.println("   ✓ 7 Sensor ping topics");
      
      Serial.println("\n✅ Subscribed to all topics!");
      
    } else {
      Serial.print(" failed, rc=");
      Serial.print(client.state());
      Serial.println(" - retrying in 5 seconds");
      delay(5000);
    }
  }
}

// ============================================================================
// MQTT CALLBACK - Xử lý lệnh từ app
// ============================================================================
void mqtt_callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("\n📨 MQTT Message Received:");
  Serial.print("   Topic: ");
  Serial.println(topic);
  
  // Parse payload
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';
  Serial.print("   Payload: ");
  Serial.println(message);
  
  String topicStr = String(topic);
  
  // ========================================
  // XỬ LÝ PING - Phản hồi AUTO-PING từ app (DEVICES và SENSORS)
  // ========================================
  if (topicStr.indexOf("/ping") != -1) {
    // CHỈ xử lý nếu payload là "ping" (từ app), BỎ QUA "1" (response của chính mình)
    if (String(message) == "ping") {
      String deviceCode = "";
      String pingTopic = "";
      
      // Check if it's a DEVICE or SENSOR ping
      if (topicStr.indexOf("devices/") != -1) {
        // Topic format: smart_home/devices/{DEVICE_CODE}/ping
        int startIdx = topicStr.indexOf("devices/") + 8;
        int endIdx = topicStr.indexOf("/ping");
        deviceCode = topicStr.substring(startIdx, endIdx);
        pingTopic = "smart_home/devices/" + deviceCode + "/ping";
        Serial.print("   🏓 DEVICE PING response sent for: ");
      } else if (topicStr.indexOf("sensors/") != -1) {
        // Topic format: smart_home/sensors/{SENSOR_CODE}/ping
        int startIdx = topicStr.indexOf("sensors/") + 8;
        int endIdx = topicStr.indexOf("/ping");
        deviceCode = topicStr.substring(startIdx, endIdx);
        pingTopic = "smart_home/sensors/" + deviceCode + "/ping";
        Serial.print("   🏓 SENSOR PING response sent for: ");
      }
      
      // Publish phản hồi "1" về cùng topic
      if (pingTopic.length() > 0) {
        client.publish(pingTopic.c_str(), "1");
        Serial.println(deviceCode);
      }
    }
    // Bỏ qua nếu payload là "1" (response của ESP32)
    return; // Không xử lý thêm các lệnh điều khiển
  }
  
  // Parse JSON cho các lệnh điều khiển
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.print("❌ JSON parse error: ");
    Serial.println(error.c_str());
    return;
  }
  
  // ========================================
  // XỬ LÝ LED (5 chiếc) - HỖ TRỢ 2 FORMAT
  // ========================================
  // Helper function để parse state từ 2 format khác nhau
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
  
  if (topicStr.indexOf(DEVICE_LED1_CODE) != -1) {
    bool state = parseState();
    controlLED(LED1_PIN, state);
    publishDeviceState(DEVICE_LED1_CODE, state ? "ON" : "OFF");
  }
  else if (topicStr.indexOf(DEVICE_LED2_CODE) != -1) {
    bool state = parseState();
    controlLED(LED2_PIN, state);
    publishDeviceState(DEVICE_LED2_CODE, state ? "ON" : "OFF");
  }
  else if (topicStr.indexOf(DEVICE_LED3_CODE) != -1) {
    bool state = parseState();
    controlLED(LED3_PIN, state);
    publishDeviceState(DEVICE_LED3_CODE, state ? "ON" : "OFF");
  }
  else if (topicStr.indexOf(DEVICE_LED4_CODE) != -1) {
    bool state = parseState();
    controlLED(LED4_PIN, state);
    publishDeviceState(DEVICE_LED4_CODE, state ? "ON" : "OFF");
  }
  else if (topicStr.indexOf(DEVICE_LED5_CODE) != -1) {
    bool state = parseState();
    controlLED(LED5_PIN, state);
    publishDeviceState(DEVICE_LED5_CODE, state ? "ON" : "OFF");
  }
  
  // ========================================
  // XỬ LÝ SERVO (2 chiếc)
  // ========================================
  else if (topicStr.indexOf(DEVICE_SERVO1_CODE) != -1) {
    int angle = doc["angle"] | 0;
    controlServo1(angle);
    publishDeviceState(DEVICE_SERVO1_CODE, angle, "angle");
  }
  else if (topicStr.indexOf(DEVICE_SERVO2_CODE) != -1) {
    int angle = doc["angle"] | 0;
    controlServo2(angle);
    publishDeviceState(DEVICE_SERVO2_CODE, angle, "angle");
  }
  
  // ========================================
  // XỬ LÝ MOTOR (2 chiếc)
  // ========================================
  else if (topicStr.indexOf(DEVICE_MOTOR_A_CODE) != -1) {
    int speed = doc["speed"] | 0;
    // Nếu có action thay vì speed, chuyển đổi
    if (doc.containsKey("action")) {
      String action = doc["action"] | "";
      if (action == "turn_on" || action == "on") {
        speed = 255;
      } else {
        speed = 0;
      }
    }
    controlMotorA(speed);
    publishDeviceState(DEVICE_MOTOR_A_CODE, speed, "speed");
  }
  else if (topicStr.indexOf(DEVICE_MOTOR_B_CODE) != -1) {
    int speed = doc["speed"] | 0;
    // Nếu có action thay vì speed, chuyển đổi
    if (doc.containsKey("action")) {
      String action = doc["action"] | "";
      if (action == "turn_on" || action == "on") {
        speed = 255;
      } else {
        speed = 0;
      }
    }
    controlMotorB(speed);
    publishDeviceState(DEVICE_MOTOR_B_CODE, speed, "speed");
  }
  
  // ========================================
  // XỬ LÝ RELAY (2 chiếc)
  // ========================================
  else if (topicStr.indexOf(DEVICE_RELAY1_CODE) != -1) {
    bool state = parseState();
    controlRelay1(state);
    publishDeviceState(DEVICE_RELAY1_CODE, state ? "ON" : "OFF");
  }
  else if (topicStr.indexOf(DEVICE_RELAY2_CODE) != -1) {
    bool state = parseState();
    controlRelay2(state);
    publishDeviceState(DEVICE_RELAY2_CODE, state ? "ON" : "OFF");
  }
  
  Serial.println("✅ Command executed!\n");
}

// ============================================================================
// PUBLISH SENSOR DATA
// ============================================================================
void publishSensorData(const char* deviceCode, const char* sensorType, float value) {
  String topic = "smart_home/sensors/" + String(deviceCode) + "/state";
  
  StaticJsonDocument<128> doc;
  doc["type"] = sensorType;
  doc["value"] = value;
  doc["timestamp"] = millis();
  
  String message;
  serializeJson(doc, message);
  
  client.publish(topic.c_str(), message.c_str());
}

// ============================================================================
// PUBLISH DEVICE STATE
// ============================================================================
// Overload 1: Publish ON/OFF state (LED, Relay)
void publishDeviceState(const char* deviceCode, const char* state) {
  String topic = "smart_home/devices/" + String(deviceCode) + "/state";
  
  StaticJsonDocument<128> doc;
  doc["state"] = state;
  doc["timestamp"] = millis();
  
  String message;
  serializeJson(doc, message);
  
  client.publish(topic.c_str(), message.c_str());
}

// Overload 2: Publish numeric value (Servo angle, Motor speed)
void publishDeviceState(const char* deviceCode, int value, const char* valueKey) {
  String topic = "smart_home/devices/" + String(deviceCode) + "/state";
  
  StaticJsonDocument<128> doc;
  doc[valueKey] = value;
  doc["state"] = (value > 0);
  doc["timestamp"] = millis();
  
  String message;
  serializeJson(doc, message);
  
  client.publish(topic.c_str(), message.c_str());
}

// ============================================================================
// CONTROL FUNCTIONS
// ============================================================================

void controlLED(int ledPin, bool state) {
  digitalWrite(ledPin, state ? HIGH : LOW);
  Serial.printf("💡 LED GPIO%d: %s\n", ledPin, state ? "ON" : "OFF");
}

void controlServo1(int angle) {
  angle = constrain(angle, 0, 180);
  servo1.write(angle);
  servo1Angle = angle;
  Serial.printf("🔄 Servo 1: %d° (GPIO%d)\n", angle, SERVO1_PIN);
}

void controlServo2(int angle) {
  angle = constrain(angle, 0, 180);
  servo2.write(angle);
  servo2Angle = angle;
  Serial.printf("🔄 Servo 2: %d° (GPIO%d)\n", angle, SERVO2_PIN);
}

void controlMotorA(int speed) {
  speed = constrain(speed, 0, 255);
  
  if (speed == 0) {
    digitalWrite(MOTOR_A_IN1, LOW);
    digitalWrite(MOTOR_A_IN2, LOW);
    analogWrite(MOTOR_A_ENA, 0);
    Serial.println("⚙️  Motor A: OFF | IN1=LOW, IN2=LOW, PWM=0");
  } else {
    digitalWrite(MOTOR_A_IN1, HIGH);
    digitalWrite(MOTOR_A_IN2, LOW);
    analogWrite(MOTOR_A_ENA, speed);
    Serial.printf("⚙️  Motor A: SPEED %d/255 | IN1=HIGH, IN2=LOW, PWM=%d\n", speed, speed);
  }
  
  motorASpeed = speed;
}

void controlMotorB(int speed) {
  speed = constrain(speed, 0, 255);
  
  if (speed == 0) {
    digitalWrite(MOTOR_B_IN3, LOW);
    digitalWrite(MOTOR_B_IN4, LOW);
    analogWrite(MOTOR_B_ENB, 0);
    Serial.println("⚙️  Motor B: OFF | IN3=LOW, IN4=LOW, PWM=0");
  } else {
    digitalWrite(MOTOR_B_IN3, HIGH);
    digitalWrite(MOTOR_B_IN4, LOW);
    analogWrite(MOTOR_B_ENB, speed);
    Serial.printf("⚙️  Motor B: SPEED %d/255 | IN3=HIGH, IN4=LOW, PWM=%d\n", speed, speed);
  }
  
  motorBSpeed = speed;
}

void controlRelay1(bool state) {
  digitalWrite(RELAY1_PIN, state ? HIGH : LOW);
  relay1State = state;
  Serial.printf("🔌 Relay 1: %s\n", state ? "ON" : "OFF");
}

void controlRelay2(bool state) {
  digitalWrite(RELAY2_PIN, state ? HIGH : LOW);
  relay2State = state;
  Serial.printf("🔌 Relay 2: %s\n", state ? "ON" : "OFF");
}
