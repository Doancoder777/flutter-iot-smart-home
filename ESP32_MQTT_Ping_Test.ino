/*

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <WiFiClientSecure.h>

// ===========================
// 🔧 WIFI & MQTT Configuration
// ===========================
const char* ssid = "VIETTEL NgocThoai";      // Wifi connect
const char* password = "0934918347";         // Password

// MQTT Broker (thay đổi theo broker của bạn)
const char* mqtt_server = "26d1fcc0724b46c495e45a93d79c78d2.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_user = "sigma";
const char* mqtt_password = "35386Doan";
const char* mqtt_client_id = "ESP32_VWXYZ0";

// Device Code (thay đổi theo thiết bị của bạn)
const char* device_code = "VWXYZ0";
const char* device_name = "test78";

// ===========================
// 🎯 MQTT Topics
// ===========================
// PING Topic - Riêng biệt cho health check
char PING_TOPIC[100];  // smart_home/devices/VWXYZ0/ping

// CMD Topic - Riêng biệt cho JSON commands
char CMD_TOPIC[100];   // smart_home/devices/VWXYZ0/cmd

// ===========================
// 🔌 Hardware Pin Definitions
// ===========================
const int PIN_LED = 2;           // GPIO2 - Built-in LED (for testing)
const int PIN_RELAY_1 = 4;       // GPIO4 - Relay 1
const int PIN_RELAY_2 = 5;       // GPIO5 - Relay 2

// ===========================
// 🌐 Objects
// ===========================
WiFiClientSecure espClient;
PubSubClient client(espClient);

// ===========================
// 🚀 Setup Function
// ===========================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n🔥 ESP32 MQTT Ping Test Starting...");
  
  // Initialize pins
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_RELAY_1, OUTPUT);
  pinMode(PIN_RELAY_2, OUTPUT);
  digitalWrite(PIN_LED, LOW);
  digitalWrite(PIN_RELAY_1, LOW);
  digitalWrite(PIN_RELAY_2, LOW);
  
  // Build MQTT Topics
  snprintf(PING_TOPIC, sizeof(PING_TOPIC), "smart_home/devices/%s/ping", device_code);
  snprintf(CMD_TOPIC, sizeof(CMD_TOPIC), "smart_home/devices/%s/cmd", device_code);
  
  Serial.printf("📍 Device Code: %s\n", device_code);
  Serial.printf("📍 Device Name: %s\n", device_name);
  Serial.printf("📍 PING Topic: %s\n", PING_TOPIC);
  Serial.printf("📍 CMD Topic: %s\n", CMD_TOPIC);
  
  // Connect to WiFi
  setupWiFi();
  
  // Connect to MQTT
  setupMQTT();
  
  Serial.println("✅ ESP32 Ready!");
}

// ===========================
// 🔁 Loop Function
// ===========================
void loop() {
  if (!client.connected()) {
    reconnectMQTT();
  }
  client.loop();
}

// ===========================
// 📡 WiFi Setup
// ===========================
void setupWiFi() {
  Serial.printf("📡 Connecting to WiFi: %s\n", ssid);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
    Serial.printf("📶 IP Address: %s\n", WiFi.localIP().toString().c_str());
    Serial.printf("📶 Signal Strength: %d dBm\n", WiFi.RSSI());
  } else {
    Serial.println("\n❌ WiFi Connection Failed!");
  }
}

// ===========================
// 🔌 MQTT Setup
// ===========================
void setupMQTT() {
  // Set MQTT server
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(mqttCallback);
  
  // Configure SSL/TLS
  espClient.setInsecure(); // Skip certificate verification (for testing)
  
  Serial.printf("🔌 MQTT Server: %s:%d\n", mqtt_server, mqtt_port);
}

// ===========================
// 🔄 MQTT Reconnect
// ===========================
void reconnectMQTT() {
  while (!client.connected()) {
    Serial.println("🔄 Attempting MQTT connection...");
    
    if (client.connect(mqtt_client_id, mqtt_user, mqtt_password)) {
      Serial.println("✅ MQTT Connected!");
      
      // Subscribe to PING topic
      client.subscribe(PING_TOPIC);
      Serial.printf("📥 Subscribed to PING: %s\n", PING_TOPIC);
      
      // Subscribe to CMD topic
      client.subscribe(CMD_TOPIC);
      Serial.printf("📥 Subscribed to CMD: %s\n", CMD_TOPIC);
      
      // Blink LED 3 times to indicate connection
      for (int i = 0; i < 3; i++) {
        digitalWrite(PIN_LED, HIGH);
        delay(100);
        digitalWrite(PIN_LED, LOW);
        delay(100);
      }
      
    } else {
      Serial.printf("❌ MQTT Connection Failed, rc=%d\n", client.state());
      Serial.println("   Retrying in 5 seconds...");
      delay(5000);
    }
  }
}

// ===========================
// 📨 MQTT Callback (Receive Messages)
// ===========================
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  // Convert payload to string
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.printf("\n📨 Message received on [%s]: %s\n", topic, message.c_str());
  
  // Check if it's PING topic
  if (strcmp(topic, PING_TOPIC) == 0) {
    handlePing(message);
  }
  // Check if it's CMD topic
  else if (strcmp(topic, CMD_TOPIC) == 0) {
    handleCommand(message);
  }
}

// ===========================
// 🏓 Handle PING (Separate Topic)
// ===========================
void handlePing(String message) {
  Serial.printf("🏓 PING message received: '%s'\n", message.c_str());
  
  // CHỈ phản hồi nếu message là "ping", KHÔNG phản hồi nếu nhận "1"
  if (message == "ping") {
    Serial.println("✅ Valid PING request - sending response");
    
    // Blink LED once to indicate ping
    digitalWrite(PIN_LED, HIGH);
    delay(50);
    digitalWrite(PIN_LED, LOW);
    
    // Respond with "1" to the same PING topic - CHỈ 1 LẦN
    client.publish(PING_TOPIC, "1");
    Serial.printf("📤 Sent response '1' to: %s\n", PING_TOPIC);
  } else {
    Serial.printf("⚠️ Ignoring non-ping message: '%s'\n", message.c_str());
  }
}

// ===========================
// ⚡ Handle CMD (JSON Commands)
// ===========================
void handleCommand(String message) {
  Serial.println("⚡ Command received on /cmd topic");
  
  // Parse JSON command
  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.printf("❌ JSON parse error: %s\n", error.c_str());
    return;
  }
  
  String name = doc["name"];
  String action = doc["action"];
  
  Serial.printf("🎯 Command - Name: %s, Action: %s\n", name.c_str(), action.c_str());
  
  // Execute commands
  if (action == "turn_on") {
    digitalWrite(PIN_LED, HIGH);
    digitalWrite(PIN_RELAY_1, HIGH);
    Serial.println("💡 Device turned ON");
    
  } else if (action == "turn_off") {
    digitalWrite(PIN_LED, LOW);
    digitalWrite(PIN_RELAY_1, LOW);
    Serial.println("💡 Device turned OFF");
    
  } else if (action == "set_angle") {
    int angle = doc["angle"];
    Serial.printf("🔄 Servo set to angle: %d°\n", angle);
    // Add servo control code here
    
  } else if (action == "set_speed") {
    int speed = doc["speed"];
    Serial.printf("🌀 Fan set to speed: %d%%\n", speed);
    // Add fan control code here
    
  } else {
    Serial.printf("❓ Unknown action: %s\n", action.c_str());
  }
}

// ===========================
// 📊 Helper: Print MQTT State
// ===========================
String getMqttStateString(int state) {
  switch (state) {
    case -4: return "MQTT_CONNECTION_TIMEOUT";
    case -3: return "MQTT_CONNECTION_LOST";
    case -2: return "MQTT_CONNECT_FAILED";
    case -1: return "MQTT_DISCONNECTED";
    case 0: return "MQTT_CONNECTED";
    case 1: return "MQTT_CONNECT_BAD_PROTOCOL";
    case 2: return "MQTT_CONNECT_BAD_CLIENT_ID";
    case 3: return "MQTT_CONNECT_UNAVAILABLE";
    case 4: return "MQTT_CONNECT_BAD_CREDENTIALS";
    case 5: return "MQTT_CONNECT_UNAUTHORIZED";
    default: return "UNKNOWN";
  }
}

*/