/*
 * ============================================================================
 * TEST DHT22 - Cảm biến Nhiệt độ & Độ ẩm
 * ============================================================================
 * Kết nối:
 * - VCC -> 3.3V
 * - DATA -> GPIO4
 * - GND -> GND
 * ============================================================================
 
#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// WiFi & MQTT Config
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "16257efaa31f4843a11e19f83c34e594.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_user = "zedho";
const char* mqtt_pass = "Hokage2004";

// Device Config
const char* DEVICE_ID = "ESP32_DHT22";
const char* DEVICE_CODE = "DHT22_001";

// Pin Definition
#define DHT_PIN 4

// Objects
DHT dht(DHT_PIN, DHT22);
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Variables
unsigned long lastRead = 0;
const long readInterval = 5000; // 5 giây

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== DHT22 SENSOR TEST ===");
  
  // Khởi tạo DHT22
  dht.begin();
  
  // Kết nối WiFi
  setup_wifi();
  
  // Cấu hình MQTT
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
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("❌ Failed to read DHT22!");
    return;
  }
  
  Serial.println("\n--- DHT22 Reading ---");
  Serial.printf("Temperature: %.1f°C\n", temperature);
  Serial.printf("Humidity: %.1f%%\n", humidity);
  
  // Publish Temperature
  String topicTemp = "smart_home/devices/" + String(DEVICE_CODE) + "/state";
  StaticJsonDocument<128> docTemp;
  docTemp["type"] = "temperature";
  docTemp["value"] = temperature;
  docTemp["timestamp"] = millis();
  
  String msgTemp;
  serializeJson(docTemp, msgTemp);
  client.publish(topicTemp.c_str(), msgTemp.c_str());
  Serial.println("📡 Published: " + msgTemp);
  
  // Publish Humidity
  StaticJsonDocument<128> docHum;
  docHum["type"] = "humidity";
  docHum["value"] = humidity;
  docHum["timestamp"] = millis();
  
  String msgHum;
  serializeJson(docHum, msgHum);
  client.publish(topicTemp.c_str(), msgHum.c_str());
  Serial.println("📡 Published: " + msgHum);
  
  Serial.println("--------------------\n");
}

*/

