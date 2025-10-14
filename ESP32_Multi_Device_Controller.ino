/*
 * ====================================================================
 * ESP32 Smart Home Multi-Device Controller
 * ====================================================================
 * 
 * Topic Structure: smart_home/devices/{DEVICE_ID}/{device_name}/{function}
 * 
 * Ví dụ:
 * - smart_home/devices/ESP32_A4CF12/den_phong_khach/cmd
 * - smart_home/devices/ESP32_A4CF12/den_phong_khach/state
 * - smart_home/devices/ESP32_A4CF12/quat_tran/cmd
 * - smart_home/devices/ESP32_A4CF12/servo_cua/cmd
 * 
 * Features:
 * ✅ Tự động generate Device ID từ MAC address
 * ✅ 1 ESP32 điều khiển nhiều thiết bị
 * ✅ Hỗ trợ Relay, PWM (Fan), Servo
 * ✅ Ping-pong test connection
 * ✅ State feedback
 * ====================================================================
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>

// ===========================
// 🔧 WIFI Configuration
// ===========================
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// ===========================
// 📡 MQTT Configuration
// ===========================
const char* MQTT_SERVER = "broker.hivemq.com";  // Hoặc HiveMQ Cloud broker
const int MQTT_PORT = 1883;                     // 8883 nếu dùng SSL
const char* MQTT_USERNAME = "";                 // Để trống nếu public broker
const char* MQTT_PASSWORD = "";

// ===========================
// 🔑 Device ID (Auto-generated từ MAC)
// ===========================
String DEVICE_ID;  // Sẽ được tạo trong setup()

// ===========================
// 🔌 Hardware Pin Definitions
// ===========================
// Relay devices
const int PIN_LED_LIVING = 2;      // Đèn phòng khách
const int PIN_LED_BEDROOM = 4;     // Đèn phòng ngủ

// PWM devices (Fan control)
const int PIN_FAN = 5;             // Quạt trần
const int PWM_CHANNEL = 0;
const int PWM_FREQ = 5000;
const int PWM_RESOLUTION = 8;      // 0-255

// Servo devices
const int PIN_SERVO_DOOR = 18;     // Servo cửa
const int PIN_SERVO_WINDOW = 19;   // Servo cửa sổ
Servo servoDoor;
Servo servoWindow;

// ===========================
// 📱 Device Names (phải khớp với Flutter app)
// ===========================
const char* DEV_LED_LIVING = "den_phong_khach";
const char* DEV_LED_BEDROOM = "den_phong_ngu";
const char* DEV_FAN = "quat_tran";
const char* DEV_SERVO_DOOR = "servo_cua";
const char* DEV_SERVO_WINDOW = "servo_cua_so";

// ===========================
// 🌐 MQTT Client
// ===========================
WiFiClient espClient;
PubSubClient mqttClient(espClient);

// ===========================
// ⚙️ Helper Functions
// ===========================

// Tạo Device ID từ MAC address
void generateDeviceId() {
  uint8_t mac[6];
  WiFi.macAddress(mac);
  
  DEVICE_ID = "ESP32_";
  for (int i = 0; i < 6; i++) {
    char buf[3];
    sprintf(buf, "%02X", mac[i]);
    DEVICE_ID += String(buf);
  }
}

// Kết nối WiFi
void connectWiFi() {
  Serial.print("🌐 Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.println("✅ WiFi Connected!");
  Serial.print("📍 IP Address: ");
  Serial.println(WiFi.localIP());
}

// Kết nối MQTT
void connectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("📡 Connecting to MQTT...");
    
    bool connected;
    if (strlen(MQTT_USERNAME) > 0) {
      connected = mqttClient.connect(DEVICE_ID.c_str(), MQTT_USERNAME, MQTT_PASSWORD);
    } else {
      connected = mqttClient.connect(DEVICE_ID.c_str());
    }
    
    if (connected) {
      Serial.println(" ✅ Connected!");
      
      // Subscribe to all command topics
      String baseTopic = "smart_home/devices/" + DEVICE_ID + "/";
      
      // Subscribe từng device
      mqttClient.subscribe((baseTopic + String(DEV_LED_LIVING) + "/cmd").c_str());
      mqttClient.subscribe((baseTopic + String(DEV_LED_BEDROOM) + "/cmd").c_str());
      mqttClient.subscribe((baseTopic + String(DEV_FAN) + "/cmd").c_str());
      mqttClient.subscribe((baseTopic + String(DEV_SERVO_DOOR) + "/cmd").c_str());
      mqttClient.subscribe((baseTopic + String(DEV_SERVO_WINDOW) + "/cmd").c_str());
      
      // Subscribe ping với wildcard
      mqttClient.subscribe((baseTopic + "+/ping").c_str());
      
      Serial.println("📩 Subscribed to topics:");
      Serial.println("   " + baseTopic + "*/cmd");
      Serial.println("   " + baseTopic + "*/ping");
      
      // Gửi online message
      publishState("system", "online");
      
    } else {
      Serial.print(" ❌ Failed, rc=");
      Serial.print(mqttClient.state());
      Serial.println(" | Retrying in 5 seconds...");
      delay(5000);
    }
  }
}

// Publish state feedback
void publishState(const char* deviceName, const char* state) {
  String topic = "smart_home/devices/" + DEVICE_ID + "/" + String(deviceName) + "/state";
  mqttClient.publish(topic.c_str(), state);
  Serial.println("📤 " + topic + " = " + String(state));
}

// Extract device name from topic
String extractDeviceName(String topic) {
  // Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/ping
  // Return: den_phong_khach
  int lastSlash = topic.lastIndexOf('/');
  int secondLastSlash = topic.lastIndexOf('/', lastSlash - 1);
  return topic.substring(secondLastSlash + 1, lastSlash);
}

// MQTT Callback
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String topicStr = String(topic);
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.println("📩 Received: " + topicStr + " = " + message);
  
  String baseTopic = "smart_home/devices/" + DEVICE_ID + "/";
  
  // ===== XỬ LÝ PING =====
  if (topicStr.endsWith("/ping")) {
    String deviceName = extractDeviceName(topicStr);
    publishState(deviceName.c_str(), "online");
    Serial.println("🏓 Pong: " + deviceName);
    return;
  }
  
  // ===== ĐÈN PHÒNG KHÁCH =====
  if (topicStr == baseTopic + String(DEV_LED_LIVING) + "/cmd") {
    bool state = (message == "1" || message.equalsIgnoreCase("ON"));
    digitalWrite(PIN_LED_LIVING, state ? HIGH : LOW);
    publishState(DEV_LED_LIVING, state ? "1" : "0");
    Serial.println(state ? "💡 Đèn phòng khách BẬT" : "💡 Đèn phòng khách TẮT");
  }
  
  // ===== ĐÈN PHÒNG NGỦ =====
  else if (topicStr == baseTopic + String(DEV_LED_BEDROOM) + "/cmd") {
    bool state = (message == "1" || message.equalsIgnoreCase("ON"));
    digitalWrite(PIN_LED_BEDROOM, state ? HIGH : LOW);
    publishState(DEV_LED_BEDROOM, state ? "1" : "0");
    Serial.println(state ? "💡 Đèn phòng ngủ BẬT" : "💡 Đèn phòng ngủ TẮT");
  }
  
  // ===== QUẠT TRẦN (PWM) =====
  else if (topicStr == baseTopic + String(DEV_FAN) + "/cmd") {
    int speed = message.toInt();  // 0-255
    ledcWrite(PWM_CHANNEL, speed);
    publishState(DEV_FAN, String(speed).c_str());
    Serial.println("🌀 Quạt tốc độ: " + String(speed));
  }
  
  // ===== SERVO CỬA =====
  else if (topicStr == baseTopic + String(DEV_SERVO_DOOR) + "/cmd") {
    int angle = message.toInt();  // 0-180
    servoDoor.write(angle);
    publishState(DEV_SERVO_DOOR, String(angle).c_str());
    Serial.println("🚪 Servo cửa: " + String(angle) + "°");
  }
  
  // ===== SERVO CỬA SỔ =====
  else if (topicStr == baseTopic + String(DEV_SERVO_WINDOW) + "/cmd") {
    int angle = message.toInt();
    servoWindow.write(angle);
    publishState(DEV_SERVO_WINDOW, String(angle).c_str());
    Serial.println("🪟 Servo cửa sổ: " + String(angle) + "°");
  }
}

// ===========================
// 🚀 Setup
// ===========================
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  // Generate Device ID
  generateDeviceId();
  
  // Print Device Info
  Serial.println();
  Serial.println("╔════════════════════════════════════════╗");
  Serial.println("║   ESP32 SMART HOME CONTROLLER         ║");
  Serial.println("╠════════════════════════════════════════╣");
  Serial.print  ("║ Device ID: ");
  Serial.print(DEVICE_ID);
  Serial.println("       ║");
  Serial.println("╠════════════════════════════════════════╣");
  Serial.println("║ Devices:                               ║");
  Serial.println("║   - Đèn phòng khách (GPIO 2)           ║");
  Serial.println("║   - Đèn phòng ngủ (GPIO 4)             ║");
  Serial.println("║   - Quạt trần PWM (GPIO 5)             ║");
  Serial.println("║   - Servo cửa (GPIO 18)                ║");
  Serial.println("║   - Servo cửa sổ (GPIO 19)             ║");
  Serial.println("╚════════════════════════════════════════╝");
  Serial.println();
  
  // Setup GPIO
  pinMode(PIN_LED_LIVING, OUTPUT);
  pinMode(PIN_LED_BEDROOM, OUTPUT);
  digitalWrite(PIN_LED_LIVING, LOW);
  digitalWrite(PIN_LED_BEDROOM, LOW);
  
  // Setup PWM for fan
  ledcSetup(PWM_CHANNEL, PWM_FREQ, PWM_RESOLUTION);
  ledcAttachPin(PIN_FAN, PWM_CHANNEL);
  ledcWrite(PWM_CHANNEL, 0);
  
  // Setup Servos
  servoDoor.attach(PIN_SERVO_DOOR);
  servoWindow.attach(PIN_SERVO_WINDOW);
  servoDoor.write(0);
  servoWindow.write(0);
  
  // Connect WiFi
  connectWiFi();
  
  // Setup MQTT
  mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
  connectMQTT();
  
  Serial.println("✅ Setup complete! Ready to receive commands.");
}

// ===========================
// 🔄 Loop
// ===========================
void loop() {
  // Reconnect if disconnected
  if (!mqttClient.connected()) {
    connectMQTT();
  }
  
  mqttClient.loop();
  
  // Heartbeat mỗi 30 giây
  static unsigned long lastHeartbeat = 0;
  if (millis() - lastHeartbeat >= 30000) {
    publishState("system", "alive");
    lastHeartbeat = millis();
  }
}
