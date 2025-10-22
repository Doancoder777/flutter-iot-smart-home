/*
 * ============================================================================
 * TEST Soil Moisture - Cảm biến Độ ẩm Đất
 * ============================================================================
 * Kết nối:
 * - VCC -> 3.3V
 * - A0 -> GPIO32 (ADC1_4)
 * - GND -> GND
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
const char* DEVICE_ID = "ESP32_SOIL";
const char* DEVICE_CODE = "SOIL_001";

// Pin Definition
#define SOIL_SENSOR_PIN 32

// Objects
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Variables
unsigned long lastRead = 0;
const long readInterval = 5000;

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== SOIL MOISTURE SENSOR TEST ===");
  
  pinMode(SOIL_SENSOR_PIN, INPUT);
  
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
  int rawValue = analogRead(SOIL_SENSOR_PIN);
  float percentage = ((4095 - rawValue) / 4095.0) * 100.0;
  
  Serial.println("\n--- Soil Moisture Reading ---");
  Serial.printf("Raw ADC: %d\n", rawValue);
  Serial.printf("Moisture: %.1f%%\n", percentage);
  
  String status;
  if (percentage < 30) status = "DRY";
  else if (percentage < 70) status = "MOIST";
  else status = "WET";
  Serial.printf("Status: %s\n", status.c_str());
  
  String topic = "smart_home/devices/" + String(DEVICE_CODE) + "/state";
  StaticJsonDocument<128> doc;
  doc["type"] = "soil_moisture";
  doc["value"] = percentage;
  doc["raw"] = rawValue;
  doc["timestamp"] = millis();
  
  String message;
  serializeJson(doc, message);
  client.publish(topic.c_str(), message.c_str());
  Serial.println("📡 Published: " + message);
  Serial.println("----------------------------\n");
}

*/

