/*
 * ============================================================================
 * ESP32 SMART HOME - MULTI DEVICE CONTROL
 * ============================================================================
 * 
 * Hỗ trợ:
 * - Cảm biến khí gas MQ-2
 * - Cảm biến nhiệt độ/độ ẩm DHT22
 * - Cảm biến mưa
 * - Cảm biến độ ẩm đất
 * - Cảm biến bụi PM2.5/PM10 (GP2Y1010AU0F)
 * - Cảm biến chuyển động PIR (HC-SR501)
 * - Servo motor
 * - Quạt DC với L298N
 * - Đèn LED (relay/PWM)
 * 
 * MQTT Topic Structure:
 * - Subscribe: smart_home/devices/{DEVICE_CODE}/cmd
 * - Publish: smart_home/devices/{DEVICE_CODE}/state
 * 
 * ============================================================================
 
#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>

// ============================================================================
// WIFI & MQTT CONFIG
// ============================================================================
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

const char* mqtt_server = "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_user = "zedho";
const char* mqtt_pass = "Hokage2004";

// Device ID (UNIQUE cho mỗi ESP32)
const char* DEVICE_ID = "ESP32_001";

WiFiClientSecure espClient;
PubSubClient client(espClient);

// ============================================================================
// PIN DEFINITIONS
// ============================================================================
// Cảm biến
#define DHT_PIN         4    // GPIO4  - DHT22
#define GAS_SENSOR_PIN  34   // GPIO34 - MQ-2 (ADC)
#define RAIN_SENSOR_PIN 35   // GPIO35 - Rain sensor (ADC)
#define SOIL_SENSOR_PIN 32   // GPIO32 - Soil moisture (ADC)
#define DUST_LED_PIN    25   // GPIO25 - GP2Y1010AU0F LED
#define DUST_SENSOR_PIN 33   // GPIO33 - GP2Y1010AU0F Output (ADC)
#define PIR_SENSOR_PIN  27   // GPIO27 - PIR Motion Sensor

// Thiết bị điều khiển
#define SERVO_PIN       18   // GPIO18 - Servo signal
#define FAN_ENA_PIN     19   // GPIO19 - L298N Enable A (PWM)
#define FAN_IN1_PIN     21   // GPIO21 - L298N Input 1
#define FAN_IN2_PIN     22   // GPIO22 - L298N Input 2
#define LED_PIN         26   // GPIO26 - LED Control (PWM or Relay)

// ============================================================================
// DEVICE CODES (Khớp với app Flutter)
// ============================================================================
const char* SENSOR_DHT_CODE     = "DHT22_001";
const char* SENSOR_GAS_CODE     = "GAS_MQ2_001";
const char* SENSOR_RAIN_CODE    = "RAIN_001";
const char* SENSOR_SOIL_CODE    = "SOIL_001";
const char* SENSOR_DUST_CODE    = "DUST_GP2Y_001";
const char* SENSOR_PIR_CODE     = "PIR_MOTION_001";
const char* DEVICE_SERVO_CODE   = "SERVO_DOOR_001";
const char* DEVICE_FAN_CODE     = "FAN_L298_001";
const char* DEVICE_LED_CODE     = "LED_LIGHT_001";

// ============================================================================
// SENSOR OBJECTS
// ============================================================================
DHT dht(DHT_PIN, DHT22);
Servo servo;

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================
unsigned long lastSensorRead = 0;
const long sensorInterval = 5000; // Đọc cảm biến mỗi 5 giây

// Servo state
int servoCurrentAngle = 0;

// Fan state
int fanCurrentSpeed = 0; // 0-255

// LED state
int ledBrightness = 0; // 0-255 (PWM) hoặc 0/255 (Relay)
bool ledState = false;

// PIR state
bool lastMotionState = false;

// ============================================================================
// FUNCTION PROTOTYPES
// ============================================================================
void setup_wifi();
void reconnect();
void callback(char* topic, byte* payload, unsigned int length);
void readAndPublishSensors();
void publishSensorData(const char* deviceCode, const char* sensorType, float value);
void controlServo(int angle);
void controlFan(int speed);
void controlLED(int brightness);
float readGasSensor();
float readRainSensor();
float readSoilMoisture();
float readDustSensor();
bool readPIRSensor();
void checkPIRMotion();

// ============================================================================
// SETUP
// ============================================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n");
  Serial.println("====================================");
  Serial.println("ESP32 Smart Home - Multi Device");
  Serial.println("====================================");

  // Khởi tạo cảm biến
  dht.begin();
  pinMode(GAS_SENSOR_PIN, INPUT);
  pinMode(RAIN_SENSOR_PIN, INPUT);
  pinMode(SOIL_SENSOR_PIN, INPUT);
  pinMode(DUST_LED_PIN, OUTPUT);
  pinMode(DUST_SENSOR_PIN, INPUT);
  pinMode(PIR_SENSOR_PIN, INPUT);

  // Khởi tạo thiết bị điều khiển
  servo.attach(SERVO_PIN);
  servo.write(0); // Vị trí ban đầu

  pinMode(FAN_ENA_PIN, OUTPUT);
  pinMode(FAN_IN1_PIN, OUTPUT);
  pinMode(FAN_IN2_PIN, OUTPUT);
  digitalWrite(FAN_IN1_PIN, LOW);
  digitalWrite(FAN_IN2_PIN, LOW);
  analogWrite(FAN_ENA_PIN, 0);

  pinMode(LED_PIN, OUTPUT);
  analogWrite(LED_PIN, 0); // Tắt LED ban đầu

  // Kết nối WiFi
  setup_wifi();

  // Cấu hình MQTT
  espClient.setInsecure(); // Tạm thời bỏ qua SSL certificate validation
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);

  Serial.println("Setup completed!");
}

// ============================================================================
// MAIN LOOP
// ============================================================================
void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Kiểm tra PIR motion (realtime)
  checkPIRMotion();

  // Đọc và publish dữ liệu cảm biến định kỳ
  unsigned long currentMillis = millis();
  if (currentMillis - lastSensorRead >= sensorInterval) {
    lastSensorRead = currentMillis;
    readAndPublishSensors();
  }
}

// ============================================================================
// WIFI SETUP
// ============================================================================
void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

// ============================================================================
// MQTT RECONNECT
// ============================================================================
void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    if (client.connect(DEVICE_ID, mqtt_user, mqtt_pass)) {
      Serial.println("connected!");
      
      // Subscribe to command topics for all devices
      String topic;
      
      topic = "smart_home/devices/" + String(DEVICE_SERVO_CODE) + "/cmd";
      client.subscribe(topic.c_str());
      Serial.println("Subscribed: " + topic);
      
      topic = "smart_home/devices/" + String(DEVICE_FAN_CODE) + "/cmd";
      client.subscribe(topic.c_str());
      Serial.println("Subscribed: " + topic);
      
      topic = "smart_home/devices/" + String(DEVICE_LED_CODE) + "/cmd";
      client.subscribe(topic.c_str());
      Serial.println("Subscribed: " + topic);
      
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

// ============================================================================
// MQTT CALLBACK - Xử lý lệnh từ app
// ============================================================================
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("\n=== MQTT Message Received ===");
  Serial.print("Topic: ");
  Serial.println(topic);
  
  // Parse payload
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';
  Serial.print("Payload: ");
  Serial.println(message);

  // Parse JSON
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.print("JSON parse failed: ");
    Serial.println(error.c_str());
    return;
  }

  const char* deviceName = doc["name"];
  const char* action = doc["action"];
  const char* command = doc["command"];
  
  // ========================================
  // XỬ LÝ SERVO
  // ========================================
  if (String(topic).indexOf(DEVICE_SERVO_CODE) != -1) {
    if (doc.containsKey("angle")) {
      int angle = doc["angle"];
      Serial.print("Servo control: angle = ");
      Serial.println(angle);
      controlServo(angle);
      
      // Publish state
      String stateTopic = "smart_home/devices/" + String(DEVICE_SERVO_CODE) + "/state";
      String stateMsg = "{\"angle\":" + String(angle) + ",\"state\":true}";
      client.publish(stateTopic.c_str(), stateMsg.c_str());
    }
  }
  
  // ========================================
  // XỬ LÝ QUẠT
  // ========================================
  else if (String(topic).indexOf(DEVICE_FAN_CODE) != -1) {
    if (doc.containsKey("speed")) {
      int speed = doc["speed"];
      Serial.print("Fan control: speed = ");
      Serial.println(speed);
      controlFan(speed);
      
      // Publish state
      String stateTopic = "smart_home/devices/" + String(DEVICE_FAN_CODE) + "/state";
      String stateMsg = "{\"speed\":" + String(speed) + ",\"state\":" + (speed > 0 ? "true" : "false") + "}";
      client.publish(stateTopic.c_str(), stateMsg.c_str());
    }
    else if (command && String(command) == "off") {
      Serial.println("Fan: turn off");
      controlFan(0);
      
      String stateTopic = "smart_home/devices/" + String(DEVICE_FAN_CODE) + "/state";
      client.publish(stateTopic.c_str(), "{\"speed\":0,\"state\":false}");
    }
  }
  
  // ========================================
  // XỬ LÝ ĐÈN LED
  // ========================================
  else if (String(topic).indexOf(DEVICE_LED_CODE) != -1) {
    // Kiểm tra brightness (PWM dimming)
    if (doc.containsKey("brightness")) {
      int brightness = doc["brightness"];
      Serial.print("LED control: brightness = ");
      Serial.println(brightness);
      controlLED(brightness);
      
      // Publish state
      String stateTopic = "smart_home/devices/" + String(DEVICE_LED_CODE) + "/state";
      String stateMsg = "{\"brightness\":" + String(brightness) + ",\"state\":" + (brightness > 0 ? "true" : "false") + "}";
      client.publish(stateTopic.c_str(), stateMsg.c_str());
    }
    // Kiểm tra turn_on/turn_off (Relay mode)
    else if (action) {
      if (String(action) == "turn_on") {
        Serial.println("LED: turn on");
        controlLED(255);
        
        String stateTopic = "smart_home/devices/" + String(DEVICE_LED_CODE) + "/state";
        client.publish(stateTopic.c_str(), "{\"brightness\":255,\"state\":true}");
      }
      else if (String(action) == "turn_off") {
        Serial.println("LED: turn off");
        controlLED(0);
        
        String stateTopic = "smart_home/devices/" + String(DEVICE_LED_CODE) + "/state";
        client.publish(stateTopic.c_str(), "{\"brightness\":0,\"state\":false}");
      }
    }
    else if (command) {
      if (String(command) == "on") {
        Serial.println("LED: turn on");
        controlLED(255);
        
        String stateTopic = "smart_home/devices/" + String(DEVICE_LED_CODE) + "/state";
        client.publish(stateTopic.c_str(), "{\"brightness\":255,\"state\":true}");
      }
      else if (String(command) == "off") {
        Serial.println("LED: turn off");
        controlLED(0);
        
        String stateTopic = "smart_home/devices/" + String(DEVICE_LED_CODE) + "/state";
        client.publish(stateTopic.c_str(), "{\"brightness\":0,\"state\":false}");
      }
    }
  }

  Serial.println("=============================\n");
}

// ============================================================================
// ĐỌC VÀ PUBLISH CẢM BIẾN
// ============================================================================
void readAndPublishSensors() {
  Serial.println("\n--- Reading Sensors ---");

  // DHT22 - Nhiệt độ và độ ẩm
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  if (!isnan(temperature) && !isnan(humidity)) {
    publishSensorData(SENSOR_DHT_CODE, "temperature", temperature);
    publishSensorData(SENSOR_DHT_CODE, "humidity", humidity);
    Serial.printf("DHT22: Temp=%.1f°C, Humidity=%.1f%%\n", temperature, humidity);
  } else {
    Serial.println("DHT22: Failed to read");
  }

  // Gas sensor MQ-2
  float gasLevel = readGasSensor();
  publishSensorData(SENSOR_GAS_CODE, "gas", gasLevel);
  Serial.printf("Gas: %.1f ppm\n", gasLevel);

  // Rain sensor
  float rainLevel = readRainSensor();
  publishSensorData(SENSOR_RAIN_CODE, "rain", rainLevel);
  Serial.printf("Rain: %.1f%%\n", rainLevel);

  // Soil moisture
  float soilMoisture = readSoilMoisture();
  publishSensorData(SENSOR_SOIL_CODE, "soil_moisture", soilMoisture);
  Serial.printf("Soil: %.1f%%\n", soilMoisture);

  // Dust sensor GP2Y1010AU0F
  float dustDensity = readDustSensor();
  publishSensorData(SENSOR_DUST_CODE, "dust", dustDensity);
  Serial.printf("Dust: %.2f mg/m³\n", dustDensity);

  // PIR Motion Sensor (đọc state hiện tại)
  bool motionDetected = readPIRSensor();
  publishSensorData(SENSOR_PIR_CODE, "motion", motionDetected ? 1.0 : 0.0);
  Serial.printf("PIR: %s\n", motionDetected ? "Motion Detected" : "No Motion");

  Serial.println("----------------------\n");
}

// ============================================================================
// PUBLISH SENSOR DATA
// ============================================================================
void publishSensorData(const char* deviceCode, const char* sensorType, float value) {
  String topic = "smart_home/devices/" + String(deviceCode) + "/state";
  
  StaticJsonDocument<128> doc;
  doc["type"] = sensorType;
  doc["value"] = value;
  doc["timestamp"] = millis();
  
  String message;
  serializeJson(doc, message);
  
  client.publish(topic.c_str(), message.c_str());
}

// ============================================================================
// ĐỌC CẢM BIẾN KHÍ GAS MQ-2
// ============================================================================
float readGasSensor() {
  int rawValue = analogRead(GAS_SENSOR_PIN);
  // Convert ADC (0-4095) to ppm (simplified)
  float ppm = (rawValue / 4095.0) * 10000.0; // Example conversion
  return ppm;
}

// ============================================================================
// ĐỌC CẢM BIẾN MƯA
// ============================================================================
float readRainSensor() {
  int rawValue = analogRead(RAIN_SENSOR_PIN);
  // Convert to percentage (0% = dry, 100% = wet)
  float percentage = 100.0 - ((rawValue / 4095.0) * 100.0);
  return percentage;
}

// ============================================================================
// ĐỌC ĐỘ ẨM ĐẤT
// ============================================================================
float readSoilMoisture() {
  int rawValue = analogRead(SOIL_SENSOR_PIN);
  // Convert to percentage (0% = dry, 100% = wet)
  float percentage = ((4095 - rawValue) / 4095.0) * 100.0;
  return percentage;
}

// ============================================================================
// ĐỌC CẢM BIẾN BỤI GP2Y1010AU0F
// ============================================================================
float readDustSensor() {
  // Sampling time
  digitalWrite(DUST_LED_PIN, LOW); // Power on LED
  delayMicroseconds(280);
  
  int rawValue = analogRead(DUST_SENSOR_PIN);
  
  delayMicroseconds(40);
  digitalWrite(DUST_LED_PIN, HIGH); // Power off LED
  delayMicroseconds(9680);
  
  // Convert to voltage (ESP32 ADC: 0-4095 = 0-3.3V)
  float voltage = rawValue * (3.3 / 4095.0);
  
  // Convert to dust density (mg/m³)
  // GP2Y1010AU0F: 0V = 0 mg/m³, sensitivity ~0.5V per 0.1mg/m³
  float dustDensity = 0.17 * voltage - 0.1;
  if (dustDensity < 0) dustDensity = 0;
  
  return dustDensity;
}

// ============================================================================
// ĐIỀU KHIỂN SERVO
// ============================================================================
void controlServo(int angle) {
  angle = constrain(angle, 0, 180);
  servo.write(angle);
  servoCurrentAngle = angle;
  Serial.printf("Servo moved to %d°\n", angle);
}

// ============================================================================
// ĐIỀU KHIỂN QUẠT VỚI L298N
// ============================================================================
void controlFan(int speed) {
  speed = constrain(speed, 0, 255);
  
  if (speed == 0) {
    // Tắt quạt
    digitalWrite(FAN_IN1_PIN, LOW);
    digitalWrite(FAN_IN2_PIN, LOW);
    analogWrite(FAN_ENA_PIN, 0);
  } else {
    // Chạy quạt chiều thuận
    digitalWrite(FAN_IN1_PIN, HIGH);
    digitalWrite(FAN_IN2_PIN, LOW);
    analogWrite(FAN_ENA_PIN, speed);
  }
  
  fanCurrentSpeed = speed;
  Serial.printf("Fan speed set to %d/255 (%.1f%%)\n", speed, (speed/255.0)*100);
}

// ============================================================================
// ĐIỀU KHIỂN ĐÈN LED (PWM hoặc RELAY)
// ============================================================================
void controlLED(int brightness) {
  brightness = constrain(brightness, 0, 255);
  
  analogWrite(LED_PIN, brightness);
  ledBrightness = brightness;
  ledState = (brightness > 0);
  
  Serial.printf("LED brightness set to %d/255 (%.1f%%) - State: %s\n", 
                brightness, (brightness/255.0)*100, ledState ? "ON" : "OFF");
}

// ============================================================================
// ĐỌC CẢM BIẾN CHUYỂN ĐỘNG PIR
// ============================================================================
bool readPIRSensor() {
  return digitalRead(PIR_SENSOR_PIN) == HIGH;
}

// ============================================================================
// KIỂM TRA PIR VÀ GỬI THÔNG BÁO KHI CÓ THAY ĐỔI
// ============================================================================
void checkPIRMotion() {
  bool currentMotion = readPIRSensor();
  
  // Chỉ publish khi có thay đổi trạng thái
  if (currentMotion != lastMotionState) {
    lastMotionState = currentMotion;
    
    String topic = "smart_home/devices/" + String(SENSOR_PIR_CODE) + "/state";
    StaticJsonDocument<128> doc;
    doc["type"] = "motion";
    doc["value"] = currentMotion ? 1 : 0;
    doc["timestamp"] = millis();
    
    String message;
    serializeJson(doc, message);
    client.publish(topic.c_str(), message.c_str());
    
    Serial.printf("🚨 PIR Motion: %s\n", currentMotion ? "DETECTED!" : "Stopped");
  }
}

*/

