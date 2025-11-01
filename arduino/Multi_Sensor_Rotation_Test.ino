// /*
// /*
//  * ============================================================================
//  * MULTI SENSOR ROTATION TEST - ESP32 Optimized
//  * ============================================================================
//  * Test tự động chuyển đổi giữa các cảm biến sau mỗi 2 phút:
//  * 1. Dust Sensor (GP2Y1010AU0F) - GPIO25, GPIO34
//  * 2. DHT22 (Nhiệt độ & Độ ẩm) - GPIO4
//  * 3. Soil Moisture - GPIO32
//  * 4. Rain Sensor - GPIO35
//  * 
//  * Relay điều khiển:
//  * - Relay 1: GPIO26 (bật/tắt theo mưa)
//  * - Relay 2: GPIO27 (bật/tắt theo độ ẩm đất)
//  * 
//  * Chu kỳ: 2 phút/sensor → 8 phút/vòng lặp
//  * 
//  * Thư viện cần cài:
//  * - DHT sensor library for ESPx by beegee_tokyo
//  *   Arduino IDE: Tools → Manage Libraries → Tìm "DHTesp"
//  * ============================================================================
//  */

// #include "DHTesp.h"

// // ========================================
// // PIN DEFINITIONS
// // ========================================
// // Dust Sensor GP2Y1010AU0F
// #define DUST_LED_PIN    25   // GPIO25 - LED hồng ngoại
// #define DUST_VO_PIN     34   // GPIO34 - ADC1_6 (analog input)

// // DHT22 Temperature & Humidity
// #define DHT_PIN         4    // GPIO4

// // Soil Moisture Sensor
// #define SOIL_PIN        32   // GPIO32 - ADC1_4 (analog input)

// // Rain Sensor
// #define RAIN_PIN        35   // GPIO35 - ADC1_7 (analog input)

// // Relay Control
// #define RELAY1_PIN      26   // GPIO26 - Relay 1 (điều khiển theo mưa)
// #define RELAY2_PIN      27   // GPIO27 - Relay 2 (điều khiển theo độ ẩm đất)

// // ========================================
// // OBJECTS
// // ========================================
// DHTesp dht;

// // ========================================
// // TIMING VARIABLES
// // ========================================
// unsigned long lastSensorSwitch = 0;
// const unsigned long SENSOR_INTERVAL = 120000; // 2 phút = 120,000 ms
// int currentSensor = 0; // 0=Dust, 1=DHT22, 2=Soil, 3=Rain

// unsigned long lastReading = 0;
// const unsigned long READ_INTERVAL = 2000; // Đọc mỗi 2 giây

// // ========================================
// // RELAY STATE
// // ========================================
// bool relay1State = false; // Relay 1 (mưa)
// bool relay2State = false; // Relay 2 (độ ẩm đất)

// // ========================================
// // SETUP
// // ========================================
// void setup() {
//   Serial.begin(115200);
//   delay(1000);
  
//   Serial.println("\n╔════════════════════════════════════════════════╗");
//   Serial.println("║   MULTI SENSOR ROTATION TEST - ESP32          ║");
//   Serial.println("║   2 minutes per sensor                         ║");
//   Serial.println("╚════════════════════════════════════════════════╝\n");
  
//   // Setup Dust Sensor
//   pinMode(DUST_LED_PIN, OUTPUT);
//   pinMode(DUST_VO_PIN, INPUT);
//   digitalWrite(DUST_LED_PIN, HIGH); // LED tắt (active LOW)
  
//   // Setup DHT22
//   dht.setup(DHT_PIN, DHTesp::DHT22);
  
//   // Setup Soil Moisture
//   pinMode(SOIL_PIN, INPUT);
  
//   // Setup Rain Sensor
//   pinMode(RAIN_PIN, INPUT);
  
//   // Setup Relay
//   pinMode(RELAY1_PIN, OUTPUT);
//   pinMode(RELAY2_PIN, OUTPUT);
//   digitalWrite(RELAY1_PIN, LOW); // Relay tắt ban đầu
//   digitalWrite(RELAY2_PIN, LOW);
  
//   Serial.println("✅ All sensors initialized!");
//   Serial.println("⚡ Relay 1 (GPIO26): Rain control");
//   Serial.println("⚡ Relay 2 (GPIO27): Soil moisture control");
//   Serial.println("🔄 Rotation cycle: Dust → DHT22 → Soil → Rain → repeat\n");
  
//   // Hiển thị sensor đầu tiên
//   printCurrentSensor();
// }

// // ========================================
// // LOOP
// // ========================================
// void loop() {
//   unsigned long currentMillis = millis();
  
//   // Kiểm tra chuyển sensor (2 phút)
//   if (currentMillis - lastSensorSwitch >= SENSOR_INTERVAL) {
//     lastSensorSwitch = currentMillis;
//     currentSensor = (currentSensor + 1) % 4; // 0→1→2→3→0
    
//     Serial.println("\n\n");
//     Serial.println("═══════════════════════════════════════════════");
//     Serial.println("        🔄 SWITCHING TO NEXT SENSOR");
//     Serial.println("═══════════════════════════════════════════════");
//     printCurrentSensor();
//   }
  
//   // Đọc sensor hiện tại mỗi 2 giây
//   if (currentMillis - lastReading >= READ_INTERVAL) {
//     lastReading = currentMillis;
    
//     switch (currentSensor) {
//       case 0:
//         readDustSensor();
//         break;
//       case 1:
//         readDHT22();
//         break;
//       case 2:
//         readSoilMoisture();
//         break;
//       case 3:
//         readRainSensor();
//         break;
//     }
//   }
// }

// // ========================================
// // SENSOR READING FUNCTIONS
// // ========================================

// void readDustSensor() {
//   // Bật LED IR
//   digitalWrite(DUST_LED_PIN, LOW);
//   delayMicroseconds(280);
  
//   // Đọc ADC
//   int rawADC = analogRead(DUST_VO_PIN);
//   delayMicroseconds(40);
  
//   // Tắt LED IR
//   digitalWrite(DUST_LED_PIN, HIGH);
//   delayMicroseconds(9680);
  
//   // Tính toán
//   float voltage = rawADC * (3.3 / 4095.0);
//   float dustDensity = (voltage - 0.6) / 0.5;
//   if (dustDensity < 0) dustDensity = 0;
  
//   // Hiển thị
//   Serial.println("┌─────────────────────────────────────┐");
//   Serial.println("│  💨 DUST SENSOR (GP2Y1010AU0F)     │");
//   Serial.println("├─────────────────────────────────────┤");
//   Serial.printf("│  Raw ADC:        %4d              │\n", rawADC);
//   Serial.printf("│  Voltage:        %.3f V           │\n", voltage);
//   Serial.printf("│  Dust Density:   %.3f mg/m³       │\n", dustDensity);
  
//   // Đánh giá chất lượng không khí
//   String quality;
//   if (dustDensity < 0.05) quality = "EXCELLENT";
//   else if (dustDensity < 0.15) quality = "GOOD";
//   else if (dustDensity < 0.25) quality = "MODERATE";
//   else if (dustDensity < 0.35) quality = "POOR";
//   else quality = "VERY POOR";
  
//   Serial.printf("│  Air Quality:    %-17s│\n", quality.c_str());
//   Serial.println("└─────────────────────────────────────┘\n");
// }

// void readDHT22() {
//   // Đợi DHT sẵn sàng (tối thiểu 2s giữa các lần đọc)
//   delay(dht.getMinimumSamplingPeriod());
  
//   // Đọc DHT22
//   TempAndHumidity data = dht.getTempAndHumidity();
  
//   // Kiểm tra lỗi
//   if (dht.getStatus() != 0) {
//     Serial.println("┌─────────────────────────────────────┐");
//     Serial.println("│  🌡️ DHT22 SENSOR                    │");
//     Serial.println("├─────────────────────────────────────┤");
//     Serial.print("│  ❌ ERROR: ");
//     Serial.print(dht.getStatusString());
//     Serial.println("  │");
//     Serial.println("└─────────────────────────────────────┘\n");
//     return;
//   }
  
//   float temperature = data.temperature;
//   float humidity = data.humidity;
  
//   // Tính Heat Index
//   float heatIndex = dht.computeHeatIndex(temperature, humidity, false);
  
//   // Hiển thị
//   Serial.println("┌─────────────────────────────────────┐");
//   Serial.println("│  🌡️ DHT22 SENSOR                    │");
//   Serial.println("├─────────────────────────────────────┤");
//   Serial.printf("│  Temperature:    %.1f °C           │\n", temperature);
//   Serial.printf("│  Humidity:       %.1f %%            │\n", humidity);
//   Serial.printf("│  Heat Index:     %.1f °C           │\n", heatIndex);
  
//   // Đánh giá độ ẩm
//   String humidStatus;
//   if (humidity < 30) humidStatus = "DRY";
//   else if (humidity < 60) humidStatus = "COMFORTABLE";
//   else if (humidity < 80) humidStatus = "HUMID";
//   else humidStatus = "VERY HUMID";
  
//   Serial.printf("│  Status:         %-17s│\n", humidStatus.c_str());
//   Serial.println("└─────────────────────────────────────┘\n");
// }

// void readSoilMoisture() {
//   // Đọc ADC
//   int rawValue = analogRead(SOIL_PIN);
  
//   // ⚠️ NẾU DÙNG CHIA ÁP (5V → 3.3V): Uncomment dòng dưới
//   // rawValue = (rawValue * 5.3) / 3.3; // Điều chỉnh cho voltage divider
  
//   // Tính phần trăm độ ẩm (đảo ngược: 4095=0%, 0=100%)
//   float percentage = ((4095 - rawValue) / 4095.0) * 100.0;
  
//   // Đánh giá trạng thái
//   String status;
//   if (percentage < 30) status = "DRY";
//   else if (percentage < 70) status = "MOIST";
//   else status = "WET";
  
//   // Điều khiển Relay 2 (tự động tưới nước khi đất khô)
//   if (percentage < 30 && !relay2State) {
//     relay2State = true;
//     digitalWrite(RELAY2_PIN, HIGH);
//     Serial.println("⚡ RELAY 2: ON (Soil too dry → watering)");
//   } else if (percentage > 60 && relay2State) {
//     relay2State = false;
//     digitalWrite(RELAY2_PIN, LOW);
//     Serial.println("⚡ RELAY 2: OFF (Soil moist enough)");
//   }
  
//   // Hiển thị
//   Serial.println("┌─────────────────────────────────────┐");
//   Serial.println("│  💧 SOIL MOISTURE SENSOR            │");
//   Serial.println("├─────────────────────────────────────┤");
//   Serial.printf("│  Raw ADC:        %4d              │\n", rawValue);
//   Serial.printf("│  Moisture:       %.1f %%            │\n", percentage);
//   Serial.printf("│  Status:         %-17s│\n", status.c_str());
//   Serial.printf("│  Relay 2:        %-17s│\n", relay2State ? "ON" : "OFF");
//   Serial.println("└─────────────────────────────────────┘\n");
// }

// void readRainSensor() {
//   // Đọc ADC
//   int rawValue = analogRead(RAIN_PIN);
  
//   // Tính phần trăm (4095 = khô, 0 = ướt)
//   float percentage = ((4095 - rawValue) / 4095.0) * 100.0;
  
//   // Đánh giá trạng thái mưa
//   String status;
//   String intensity;
//   if (percentage < 20) {
//     status = "NO RAIN";
//     intensity = "☀️ SUNNY";
//   } else if (percentage < 40) {
//     status = "LIGHT RAIN";
//     intensity = "🌦️ DRIZZLE";
//   } else if (percentage < 70) {
//     status = "MODERATE RAIN";
//     intensity = "🌧️ RAIN";
//   } else {
//     status = "HEAVY RAIN";
//     intensity = "⛈️ STORM";
//   }
  
//   // Điều khiển Relay 1 (tắt phun nước khi mưa)
//   if (percentage > 40 && !relay1State) {
//     relay1State = true;
//     digitalWrite(RELAY1_PIN, HIGH);
//     Serial.println("⚡ RELAY 1: ON (Rain detected → sprinkler OFF)");
//   } else if (percentage < 20 && relay1State) {
//     relay1State = false;
//     digitalWrite(RELAY1_PIN, LOW);
//     Serial.println("⚡ RELAY 1: OFF (No rain → sprinkler can run)");
//   }
  
//   // Hiển thị
//   Serial.println("┌─────────────────────────────────────┐");
//   Serial.println("│  🌧️ RAIN SENSOR                     │");
//   Serial.println("├─────────────────────────────────────┤");
//   Serial.printf("│  Raw ADC:        %4d              │\n", rawValue);
//   Serial.printf("│  Rain Level:     %.1f %%            │\n", percentage);
//   Serial.printf("│  Status:         %-17s│\n", status.c_str());
//   Serial.printf("│  Intensity:      %-17s│\n", intensity.c_str());
//   Serial.printf("│  Relay 1:        %-17s│\n", relay1State ? "ON" : "OFF");
//   Serial.println("└─────────────────────────────────────┘\n");
// }

// // ========================================
// // HELPER FUNCTIONS
// // ========================================

// void printCurrentSensor() {
//   unsigned long remainingTime = (SENSOR_INTERVAL - (millis() - lastSensorSwitch)) / 1000;
  
//   Serial.println("\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
  
//   switch (currentSensor) {
//     case 0:
//       Serial.println("┃  🎯 ACTIVE: DUST SENSOR             ┃");
//       Serial.println("┃  Pin: GPIO25 (LED), GPIO34 (ADC)   ┃");
//       break;
//     case 1:
//       Serial.println("┃  🎯 ACTIVE: DHT22 SENSOR            ┃");
//       Serial.println("┃  Pin: GPIO4                         ┃");
//       break;
//     case 2:
//       Serial.println("┃  🎯 ACTIVE: SOIL MOISTURE           ┃");
//       Serial.println("┃  Pin: GPIO32 (ADC)                  ┃");
//       break;
//   }
  
//   Serial.printf("┃  ⏱️  Time remaining: %lu seconds     ┃\n", remainingTime);
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
// }


// */