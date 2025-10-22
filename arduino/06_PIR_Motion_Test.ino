/*
 * ============================================================================
 * TEST HC-SR501 - Cảm biến Chuyển động PIR
 * ============================================================================
 * Kết nối:
 * - VCC -> 5V
 * - OUT -> GPIO27
 * - GND -> GND
 * 
 * Lưu ý:
 * - Điều chỉnh 2 biến trở: Time Delay & Sensitivity
 * - Jumper: H = Retriggerable, L = Non-retriggerable
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
const char* DEVICE_ID = "ESP32_PIR";
const char* DEVICE_CODE = "PIR_MOTION_001";

// Pin Definition
#define PIR_SENSOR_PIN 27

// Objects
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Variables
bool lastMotionState = false;

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== HC-SR501 PIR MOTION SENSOR TEST ===");
  
  pinMode(PIR_SENSOR_PIN, INPUT);
  
  setup_wifi();
  
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  
  Serial.println("Setup completed!");
  Serial.println("Waiting for sensor to stabilize (30s)...");
  delay(30000); // PIR cần thời gian ổn định
  Serial.println("Sensor ready!");
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  
  checkMotion();
  delay(100); // Nhỏ delay để phản ứng nhanh
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
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retry in 5s");
      delay(5000);
    }
  }
}

void checkMotion() {
  bool currentMotion = digitalRead(PIR_SENSOR_PIN) == HIGH;
  
  // Chỉ publish khi có thay đổi
  if (currentMotion != lastMotionState) {
    lastMotionState = currentMotion;
    
    Serial.println("\n🚨 --- Motion State Changed ---");
    Serial.printf("Motion: %s\n", currentMotion ? "DETECTED!" : "Stopped");
    
    String topic = "smart_home/devices/" + String(DEVICE_CODE) + "/state";
    StaticJsonDocument<128> doc;
    doc["type"] = "motion";
    doc["value"] = currentMotion ? 1 : 0;
    doc["timestamp"] = millis();
    
    String message;
    serializeJson(doc, message);
    client.publish(topic.c_str(), message.c_str());
    Serial.println("📡 Published: " + message);
    Serial.println("------------------------------\n");
  }
}

*/

