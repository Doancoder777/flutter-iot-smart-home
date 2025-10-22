/*
 * ============================================================================
 * TEST SERVO MOTOR (SG90 / MG996R)
 * ============================================================================
 * Kết nối:
 * - VCC (Red) -> 5V
 * - GND (Brown) -> GND
 * - Signal (Orange) -> GPIO18
 * 
 * MQTT Commands:
 * Topic: smart_home/devices/SERVO_DOOR_001/cmd
 * Payload: {"angle": 90}
 * ============================================================================
 
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>

// WiFi & MQTT Config
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_user = "zedho";
const char* mqtt_pass = "Hokage2004";

// Device Config
const char* DEVICE_ID = "ESP32_SERVO";
const char* DEVICE_CODE = "SERVO_DOOR_001";

// Pin Definition
#define SERVO_PIN 18

// Objects
Servo servo;
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Variables
int currentAngle = 0;

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== SERVO MOTOR TEST ===");
  
  servo.attach(SERVO_PIN);
  servo.write(0);
  
  setup_wifi();
  
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  
  Serial.println("Setup completed!");
  Serial.println("\n📌 Send MQTT command to control:");
  Serial.println("   Topic: smart_home/devices/SERVO_DOOR_001/cmd");
  Serial.println("   Payload: {\"angle\": 90}");
  
  // Demo sweep
  Serial.println("\n🔄 Running demo sweep...");
  for (int i = 0; i <= 180; i += 30) {
    controlServo(i);
    delay(1000);
  }
  controlServo(0);
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
  
  if (doc.containsKey("angle")) {
    int angle = doc["angle"];
    controlServo(angle);
    
    // Publish state
    String stateTopic = "smart_home/devices/" + String(DEVICE_CODE) + "/state";
    String stateMsg = "{\"angle\":" + String(angle) + ",\"state\":true}";
    client.publish(stateTopic.c_str(), stateMsg.c_str());
    Serial.println("📡 Published state: " + stateMsg);
  }
  
  Serial.println("============================\n");
}

void controlServo(int angle) {
  angle = constrain(angle, 0, 180);
  servo.write(angle);
  currentAngle = angle;
  Serial.printf("⚙️ Servo moved to %d°\n", angle);
}

*/

