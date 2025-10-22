/*
 * ============================================================================
 * TEST MQ-2 - Cảm biến Khí Gas
 * ============================================================================
 * Kết nối:
 * - VCC -> 5V
 * - A0 -> GPIO34 (ADC1_6)
 * - GND -> GND
 * 
 * Lưu ý: Cần làm nóng cảm biến 24-48h để kết quả chính xác
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
const char* DEVICE_ID = "ESP32_MQ2";
const char* DEVICE_CODE = "GAS_MQ2_001";

// Pin Definition
#define GAS_SENSOR_PIN 34

// Objects
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Variables
unsigned long lastRead = 0;
const long readInterval = 5000;

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== MQ-2 GAS SENSOR TEST ===");
  
  pinMode(GAS_SENSOR_PIN, INPUT);
  
  setup_wifi();
  
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  
  Serial.println("Setup completed!");
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  
  unsigned long currentMillis = millis();
  if (currentMillis - lastRead >= readInterval) {
    lastRead = currentMillis;
    readAndPublish();
  }
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

void readAndPublish() {
  int rawValue = analogRead(GAS_SENSOR_PIN);
  float ppm = (rawValue / 4095.0) * 10000.0; // Simplified conversion
  
  Serial.println("\n--- MQ-2 Reading ---");
  Serial.printf("Raw ADC: %d\n", rawValue);
  Serial.printf("Gas Level: %.1f ppm\n", ppm);
  
  String topic = "smart_home/devices/" + String(DEVICE_CODE) + "/state";
  StaticJsonDocument<128> doc;
  doc["type"] = "gas";
  doc["value"] = ppm;
  doc["raw"] = rawValue;
  doc["timestamp"] = millis();
  
  String message;
  serializeJson(doc, message);
  client.publish(topic.c_str(), message.c_str());
  Serial.println("📡 Published: " + message);
  Serial.println("-------------------\n");
}

*/

