/*
 * ============================================================================
 * TEST FAN với L298N Motor Driver
 * ============================================================================
 * Kết nối L298N -> ESP32:
 * - IN1 -> GPIO21
 * - IN2 -> GPIO22
 * - ENA -> GPIO19 (PWM)
 * - GND -> GND
 * 
 * Kết nối L298N -> Quạt 12V:
 * - OUT1 -> Fan (+)
 * - OUT2 -> Fan (-)
 * - +12V -> Nguồn 12V (+)
 * - GND -> Nguồn 12V (-)
 * 
 * MQTT Commands:
 * Topic: smart_home/devices/FAN_L298_001/cmd
 * Payload: {"speed": 171}  // 0-255
 * Payload: {"command": "off"}
 * ============================================================================
 
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// WiFi & MQTT Config
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_user = "zedho";
const char* mqtt_pass = "Hokage2004";

// Device Config
const char* DEVICE_ID = "ESP32_FAN";
const char* DEVICE_CODE = "FAN_L298_001";

// Pin Definition
#define FAN_ENA_PIN 19
#define FAN_IN1_PIN 21
#define FAN_IN2_PIN 22

// Objects
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Variables
int currentSpeed = 0;

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== L298N FAN MOTOR TEST ===");
  
  pinMode(FAN_ENA_PIN, OUTPUT);
  pinMode(FAN_IN1_PIN, OUTPUT);
  pinMode(FAN_IN2_PIN, OUTPUT);
  
  digitalWrite(FAN_IN1_PIN, LOW);
  digitalWrite(FAN_IN2_PIN, LOW);
  analogWrite(FAN_ENA_PIN, 0);
  
  setup_wifi();
  
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  
  Serial.println("Setup completed!");
  Serial.println("\n📌 Send MQTT command to control:");
  Serial.println("   Topic: smart_home/devices/FAN_L298_001/cmd");
  Serial.println("   Payload: {\"speed\": 171}  // 0-255");
  
  // Demo speeds
  Serial.println("\n🔄 Running demo speeds...");
  int speeds[] = {0, 85, 170, 255, 170, 85, 0};
  for (int speed : speeds) {
    controlFan(speed);
    delay(3000);
  }
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
}

void setup_wifi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("\nWiFi connected!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");
    
    if (client.connect(DEVICE_ID, mqtt_user, mqtt_pass)) {
      Serial.println("connected!");
      
      String topic = "smart_home/devices/" + String(DEVICE_CODE) + "/cmd";
      client.subscribe(topic.c_str());
      Serial.println("Subscribed: " + topic);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retry in 5s");
      delay(5000);
    }
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("\n=== MQTT Command Received ===");
  Serial.print("Topic: ");
  Serial.println(topic);
  
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';
  Serial.print("Payload: ");
  Serial.println(message);
  
  StaticJsonDocument<128> doc;
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.println("❌ JSON parse failed!");
    return;
  }
  
  if (doc.containsKey("speed")) {
    int speed = doc["speed"];
    controlFan(speed);
    
    String stateTopic = "smart_home/devices/" + String(DEVICE_CODE) + "/state";
    String stateMsg = "{\"speed\":" + String(speed) + ",\"state\":" + (speed > 0 ? "true" : "false") + "}";
    client.publish(stateTopic.c_str(), stateMsg.c_str());
    Serial.println("📡 Published state: " + stateMsg);
  }
  else if (doc.containsKey("command")) {
    String cmd = doc["command"];
    if (cmd == "off") {
      controlFan(0);
      
      String stateTopic = "smart_home/devices/" + String(DEVICE_CODE) + "/state";
      client.publish(stateTopic.c_str(), "{\"speed\":0,\"state\":false}");
      Serial.println("📡 Published state: OFF");
    }
  }
  
  Serial.println("============================\n");
}

void controlFan(int speed) {
  speed = constrain(speed, 0, 255);
  
  if (speed == 0) {
    digitalWrite(FAN_IN1_PIN, LOW);
    digitalWrite(FAN_IN2_PIN, LOW);
    analogWrite(FAN_ENA_PIN, 0);
    Serial.println("🌪️ Fan: OFF");
  } else {
    digitalWrite(FAN_IN1_PIN, HIGH);
    digitalWrite(FAN_IN2_PIN, LOW);
    analogWrite(FAN_ENA_PIN, speed);
    Serial.printf("🌪️ Fan speed: %d/255 (%.1f%%)\n", speed, (speed/255.0)*100);
  }
  
  currentSpeed = speed;
}

*/

