/*
 * ============================================================================
 * TEST GP2Y1010AU0F - Cảm biến Bụi PM2.5/PM10
 * ============================================================================
 * Kết nối:
 * - Pin 1 (V-LED) -> GND
 * - Pin 2 (LED) -> GPIO25 (qua điện trở 150Ω)
 * - Pin 3 (LED+) -> 5V
 * - Pin 4 (S-GND) -> GND
 * - Pin 5 (Vo) -> GPIO33 (ADC1_5)
 * - Pin 6 (Vcc) -> 5V
 * 
 * Lưu ý: Cần tụ điện 220µF giữa Pin 3 và Pin 4
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
const char* DEVICE_ID = "ESP32_DUST";
const char* DEVICE_CODE = "DUST_GP2Y_001";

// Pin Definition
#define DUST_LED_PIN 25
#define DUST_SENSOR_PIN 33

// Objects
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Variables
unsigned long lastRead = 0;
const long readInterval = 10000; // 10 giây

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== GP2Y1010AU0F DUST SENSOR TEST ===");
  
  pinMode(DUST_LED_PIN, OUTPUT);
  pinMode(DUST_SENSOR_PIN, INPUT);
  
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
  // Sampling with LED pulse
  digitalWrite(DUST_LED_PIN, LOW);
  delayMicroseconds(280);
  
  int rawValue = analogRead(DUST_SENSOR_PIN);
  
  delayMicroseconds(40);
  digitalWrite(DUST_LED_PIN, HIGH);
  delayMicroseconds(9680);
  
  // Convert to voltage
  float voltage = rawValue * (3.3 / 4095.0);
  
  // Convert to dust density (mg/m³)
  float dustDensity = 0.17 * voltage - 0.1;
  if (dustDensity < 0) dustDensity = 0;
  
  Serial.println("\n--- Dust Sensor Reading ---");
  Serial.printf("Raw ADC: %d\n", rawValue);
  Serial.printf("Voltage: %.3f V\n", voltage);
  Serial.printf("Dust Density: %.2f mg/m³\n", dustDensity);
  
  String quality;
  if (dustDensity < 0.05) quality = "EXCELLENT";
  else if (dustDensity < 0.15) quality = "GOOD";
  else if (dustDensity < 0.25) quality = "MODERATE";
  else quality = "POOR";
  Serial.printf("Air Quality: %s\n", quality.c_str());
  
  String topic = "smart_home/devices/" + String(DEVICE_CODE) + "/state";
  StaticJsonDocument<128> doc;
  doc["type"] = "dust";
  doc["value"] = dustDensity;
  doc["voltage"] = voltage;
  doc["raw"] = rawValue;
  doc["timestamp"] = millis();
  
  String message;
  serializeJson(doc, message);
  client.publish(topic.c_str(), message.c_str());
  Serial.println("📡 Published: " + message);
  Serial.println("--------------------------\n");
}

*/

