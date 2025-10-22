/*
 * ============================================================================
 * TEST LED - Đèn chiếu sáng (PWM hoặc Relay)
 * ============================================================================
 * Kết nối:
 * - LED đơn giản: LED -> Điện trở 220Ω -> GPIO26 -> GND
 * - LED Module: VCC -> 5V, Signal -> GPIO26, GND -> GND
 * - Relay: Signal -> GPIO26, VCC -> 5V, GND -> GND
 * 
 * MQTT Commands:
 * Topic: smart_home/devices/LED_LIGHT_001/cmd
 * Payload: {"brightness": 128}  // 0-255 (PWM)
 * Payload: {"action": "turn_on"}
 * Payload: {"action": "turn_off"}
 * Payload: {"command": "on"}
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
const char* DEVICE_ID = "ESP32_LED";
const char* DEVICE_CODE = "LED_LIGHT_001";

// Pin Definition
#define LED_PIN 26

// Objects
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Variables
int currentBrightness = 0;
bool ledState = false;

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== LED LIGHT TEST ===");
  
  pinMode(LED_PIN, OUTPUT);
  analogWrite(LED_PIN, 0);
  
  setup_wifi();
  
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  
  Serial.println("Setup completed!");
  Serial.println("\n📌 Send MQTT command to control:");
  Serial.println("   Topic: smart_home/devices/LED_LIGHT_001/cmd");
  Serial.println("   Payload: {\"brightness\": 128}");
  Serial.println("   Payload: {\"action\": \"turn_on\"}");
  
  // Demo fade
  Serial.println("\n🔄 Running demo fade...");
  for (int i = 0; i <= 255; i += 5) {
    controlLED(i);
    delay(50);
  }
  for (int i = 255; i >= 0; i -= 5) {
    controlLED(i);
    delay(50);
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
  
  String stateTopic = "smart_home/devices/" + String(DEVICE_CODE) + "/state";
  
  if (doc.containsKey("brightness")) {
    int brightness = doc["brightness"];
    controlLED(brightness);
    
    String stateMsg = "{\"brightness\":" + String(brightness) + ",\"state\":" + (brightness > 0 ? "true" : "false") + "}";
    client.publish(stateTopic.c_str(), stateMsg.c_str());
    Serial.println("📡 Published state: " + stateMsg);
  }
  else if (doc.containsKey("action")) {
    String action = doc["action"];
    if (action == "turn_on") {
      controlLED(255);
      client.publish(stateTopic.c_str(), "{\"brightness\":255,\"state\":true}");
      Serial.println("📡 Published state: ON");
    }
    else if (action == "turn_off") {
      controlLED(0);
      client.publish(stateTopic.c_str(), "{\"brightness\":0,\"state\":false}");
      Serial.println("📡 Published state: OFF");
    }
  }
  else if (doc.containsKey("command")) {
    String cmd = doc["command"];
    if (cmd == "on") {
      controlLED(255);
      client.publish(stateTopic.c_str(), "{\"brightness\":255,\"state\":true}");
      Serial.println("📡 Published state: ON");
    }
    else if (cmd == "off") {
      controlLED(0);
      client.publish(stateTopic.c_str(), "{\"brightness\":0,\"state\":false}");
      Serial.println("📡 Published state: OFF");
    }
  }
  
  Serial.println("============================\n");
}

void controlLED(int brightness) {
  brightness = constrain(brightness, 0, 255);
  analogWrite(LED_PIN, brightness);
  currentBrightness = brightness;
  ledState = (brightness > 0);
  
  Serial.printf("💡 LED: %d/255 (%.1f%%) - %s\n", 
                brightness, (brightness/255.0)*100, ledState ? "ON" : "OFF");
}

*/

