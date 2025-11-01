// /*
//  * ============================================================================
//  * COMPLETE TEST - TẤT CẢ THIẾT BỊ + CÁC CẢM BIẾN
//  * ============================================================================
//  * Test đầy đủ:
//  * 
//  * SENSORS (6 loại):
//  * 1. DHT22 Temp/Humidity (GPIO4)         - VCC: 3.3-5V, OUT: 3.3V digital
//  * 2. MQ-2 Gas (GPIO34)                   - VCC: 5V, OUT: 0-5V analog (chia áp)
//  * 3. Rain Sensor (GPIO35)                - VCC: 3.3-5V, OUT: 0-3.3V analog
//  * 4. Soil Moisture (GPIO32)              - VCC: 3.3-5V, OUT: 0-3.3V analog
//  * 5. GP2Y1010AU0F Dust (GPIO25,36)       - VCC: 5V, OUT: 0-5V analog (chia áp)
//  * 6. PIR Motion (GPIO33)                 - VCC: 5V, OUT: 3.3V digital
//  * 
//  * ACTUATORS (4 loại - 10 thiết bị):
//  * 7. 5 LED (GPIO5,18,19,21,13)           - OUT: 3.3V → [220Ω] → LED → GND
//  * 8. 2 Servo SG90 (GPIO22,23)            - VCC: 5V, Signal: 3.3V PWM
//  * 9. 2 Motor L298N (GPIO14,26,27,12,15,16) - Motor: 12V, Logic: 3.3V
//  * 10. 2 Relay (GPIO2,17)                 - Coil: 5V, Trigger: 3.3V
//  * 
//  * ⚡ NGUỒN ĐIỆN YÊU CẦU:
//  * - ESP32: 5V/2A (USB hoặc adapter)
//  * - Sensors: Dùng chung 5V từ ESP32 (hoặc nguồn riêng 5V/1A)
//  * - Servo: 5V/1A (khuyến nghị nguồn riêng)
//  * - Motor: 12V/2A (nguồn riêng bắt buộc)
//  * - Relay: 5V (dùng chung ESP32 hoặc riêng)
//  * 
//  * ⚠️ LƯU Ý ĐIỆN ÁP:
//  * - ESP32 GPIO OUTPUT: 3.3V (KHÔNG PHẢI 5V!)
//  * - ESP32 GPIO INPUT: Chịu được tối đa 3.6V
//  * - Cảm biến 5V (MQ-2, Dust) cần CHIA ÁP về 3.3V cho GPIO input
//  * - Sơ đồ chia áp: Signal 5V → [R1: 1kΩ] → GPIO → [R2: 2kΩ] → GND
//  *   → Vout = 5V × (2kΩ / (1kΩ + 2kΩ)) = 3.3V ✅
//  * 
//  * Chu kỳ test:
//  * - 30s: DHT22
//  * - 30s: MQ-2 Gas
//  * - 30s: Rain Sensor
//  * - 30s: Soil Moisture
//  * - 30s: Dust Sensor
//  * - 30s: PIR + BẬT TẤT CẢ ACTUATORS
//  * - 10s: Test LED
//  * - 10s: Test Servo
//  * - 10s: Test Motor
//  * - 10s: Test Relay
//  * ============================================================================
//  */

// #include <ESP32Servo.h>
// #include "DHTesp.h"

// // ========================================
// // PIN DEFINITIONS - SENSORS (✅ OPTIMIZED cho ESP32 DevKit v1)
// // ========================================
// // DHT22: VCC = 3.3-5V, OUT = 3.3V signal
// #define DHT_PIN         4    // GPIO4  - DHT22 ✅ OK (Digital, ADC2 nhưng dùng digital read)

// // MQ-2: VCC = 5V (cần 5V để hoạt động đúng)
// #define MQ2_PIN         34   // GPIO34 - MQ-2 Gas ✅ OK (ADC1_6, Input only)

// // Rain Sensor: VCC = 3.3-5V
// #define RAIN_PIN        35   // GPIO35 - Rain Sensor ✅ OK (ADC1_7, Input only)

// // Soil Moisture: VCC = 3.3-5V
// #define SOIL_PIN        32   // GPIO32 - Soil Moisture ✅ OK (ADC1_4)

// // GP2Y1010AU0F Dust: VCC = 5V (bắt buộc 5V)
// #define DUST_LED_PIN    23   // GPIO23 - Dust LED ✅ SỬA: 25→23 (VSPI_MOSI, tránh ADC2)
// #define DUST_VO_PIN     36   // GPIO36 - Dust V0 ✅ OK (ADC1_0, Input only)

// // PIR HC-SR501: VCC = 5V (khuyến nghị, có thể 3.3V)
// #define PIR_PIN         33   // GPIO33 - PIR Motion ✅ OK (ADC1_5)

// // ========================================
// // PIN DEFINITIONS - ACTUATORS (✅ TRÁNH ADC2 KHI DÙNG WiFi)
// // ========================================
// // 5 LED: Mỗi LED cần điện trở 220Ω, VCC ESP32 = 3.3V
// #define LED1_PIN        5    // GPIO5  - Red ✅ OK (VSPI_CS)
// #define LED2_PIN        18   // GPIO18 - Yellow ✅ OK (VSPI_CLK)
// #define LED3_PIN        19   // GPIO19 - Green ✅ OK (VSPI_MISO)
// #define LED4_PIN        21   // GPIO21 - Blue ✅ OK (I2C_SDA)
// #define LED5_PIN        22   // GPIO22 - White ✅ SỬA: 13→22 (I2C_SCL, tránh ADC2)

// // 2 Servo SG90: VCC = 5V, Signal = 3.3V PWM
// #define SERVO1_PIN      13   // GPIO13 - Servo 1 ✅ SỬA: 22→13 (swap với LED5)
// #define SERVO2_PIN      14   // GPIO14 - Servo 2 ✅ SỬA: 23→14 (ADC2 nhưng OK cho servo)

// // Motor A (L298N): VCC = 12V (motor), Logic = 3.3V (ESP32)
// #define MOTOR_A_ENA     16   // GPIO16 - PWM Speed ✅ SỬA: 14→16 (RX2, tránh ADC2)
// #define MOTOR_A_IN1     17   // GPIO17 - Direction ✅ SỬA: 26→17 (TX2, tránh ADC2)
// #define MOTOR_A_IN2     25   // GPIO25 - Direction ✅ SỬA: 27→25 (ADC2 nhưng chấp nhận)

// // Motor B (L298N): VCC = 12V (motor), Logic = 3.3V (ESP32)
// #define MOTOR_B_ENB     26   // GPIO26 - PWM Speed ✅ SỬA: 12→26 (ADC2 nhưng chấp nhận)
// #define MOTOR_B_IN3     27   // GPIO27 - Direction ✅ GIỮ: 27 (ADC2 nhưng chấp nhận)
// #define MOTOR_B_IN4     12   // GPIO12 - Direction ✅ SỬA: 16→12 (swap)

// // 2 Relay: Coil VCC = 5V, Trigger = 3.3V (ESP32)
// #define RELAY1_PIN      2    // GPIO2  - Relay 1 ✅ OK (Built-in LED, chấp nhận)
// #define RELAY2_PIN      15   // GPIO15 - Relay 2 ✅ SỬA: 17→15 (Strapping, chấp nhận)

// // ========================================
// // OBJECTS
// // ========================================
// DHTesp dht;
// Servo servo1;
// Servo servo2;

// // ========================================
// // VARIABLES
// // ========================================
// unsigned long currentTest = 0;
// const unsigned long SENSOR_TEST_DURATION = 30000; // 30 giây
// const unsigned long ACTUATOR_TEST_DURATION = 10000; // 10 giây

// // ========================================
// // SETUP
// // ========================================
// void setup() {
//   Serial.begin(115200);
//   delay(1000);
  
//   Serial.println("\n╔════════════════════════════════════════════════╗");
//   Serial.println("║   COMPLETE TEST - ALL DEVICES + SENSORS        ║");
//   Serial.println("║   6 Sensors + 4 Actuators (10 loại thiết bị)   ║");
//   Serial.println("╚════════════════════════════════════════════════╝\n");
  
//   // ===== SETUP SENSORS =====
//   dht.setup(DHT_PIN, DHTesp::DHT22);
//   pinMode(MQ2_PIN, INPUT);
//   pinMode(RAIN_PIN, INPUT);
//   pinMode(SOIL_PIN, INPUT);
//   pinMode(DUST_LED_PIN, OUTPUT);
//   pinMode(DUST_VO_PIN, INPUT);
//   pinMode(PIR_PIN, INPUT);
//   digitalWrite(DUST_LED_PIN, LOW);
  
//   // ===== SETUP ACTUATORS =====
//   // LED
//   pinMode(LED1_PIN, OUTPUT);
//   pinMode(LED2_PIN, OUTPUT);
//   pinMode(LED3_PIN, OUTPUT);
//   pinMode(LED4_PIN, OUTPUT);
//   pinMode(LED5_PIN, OUTPUT);
  
//   // Servo
//   servo1.attach(SERVO1_PIN);
//   servo2.attach(SERVO2_PIN);
//   servo1.write(0);
//   servo2.write(0);
  
//   // Motor A
//   pinMode(MOTOR_A_ENA, OUTPUT);
//   pinMode(MOTOR_A_IN1, OUTPUT);
//   pinMode(MOTOR_A_IN2, OUTPUT);
  
//   // Motor B
//   pinMode(MOTOR_B_ENB, OUTPUT);
//   pinMode(MOTOR_B_IN3, OUTPUT);
//   pinMode(MOTOR_B_IN4, OUTPUT);
  
//   // Relay
//   pinMode(RELAY1_PIN, OUTPUT);
//   pinMode(RELAY2_PIN, OUTPUT);
  
//   // Tắt tất cả actuators
//   allActuatorsOff();
  
//   Serial.println("✅ Hardware initialized!");
//   Serial.println("\n📌 SENSORS (Optimized - Tránh ADC2):");
//   Serial.println("   1. DHT22:          GPIO4  ✅");
//   Serial.println("   2. MQ-2 Gas:       GPIO34 ✅ (ADC1)");
//   Serial.println("   3. Rain:           GPIO35 ✅ (ADC1)");
//   Serial.println("   4. Soil Moisture:  GPIO32 ✅ (ADC1)");
//   Serial.println("   5. Dust GP2Y:      GPIO23 (LED) ✅, GPIO36 (V0) ✅");
//   Serial.println("   6. PIR Motion:     GPIO33 ✅ (ADC1)");
  
//   Serial.println("\n📌 ACTUATORS (Optimized cho ESP32 DevKit v1):");
//   Serial.println("   7. 5 LED:          GPIO5, 18, 19, 21, 22 ✅");
//   Serial.println("   8. 2 Servo:        GPIO13, 14 ✅");
//   Serial.println("   9. Motor A:        GPIO16 (ENA), 17 (IN1), 25 (IN2) ✅");
//   Serial.println("      Motor B:        GPIO26 (ENB), 27 (IN3), 12 (IN4) ⚠️");
//   Serial.println("  10. 2 Relay:        GPIO2, 15 ✅");
  
//   Serial.println("\n🔄 Starting test cycle...\n");
//   Serial.println("═══════════════════════════════════════════════\n");
//   delay(3000);
// }

// // ========================================
// // LOOP
// // ========================================
// void loop() {
//   // ===== SENSOR TESTS (30 giây mỗi loại) =====
//   testDHT22();
//   testMQ2();
//   testRain();
//   testSoilMoisture();
//   testDust();
//   testPIRWithActuators();
  
//   // ===== ACTUATOR TESTS (10 giây mỗi loại) =====
//   testLED();
//   testServo();
//   testMotors();
//   testRelays();
  
//   Serial.println("\n⏸️  ═══ CHU KỲ HOÀN TẤT - NGHỈ 5 GIÂY ═══\n");
//   delay(5000);
// }

// // ========================================
// // SENSOR TEST FUNCTIONS
// // ========================================

// void testDHT22() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 1: DHT22 (30 giây)           ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   unsigned long start = millis();
//   int count = 0;
  
//   while (millis() - start < SENSOR_TEST_DURATION) {
//     TempAndHumidity data = dht.getTempAndHumidity();
    
//     if (dht.getStatus() == 0) {
//       Serial.printf("   [%2d] Temp: %.1f°C | Humidity: %.1f%%\n", 
//                     ++count, data.temperature, data.humidity);
//     } else {
//       Serial.printf("   [%2d] ❌ DHT22 Error: %s\n", 
//                     ++count, dht.getStatusString());
//     }
    
//     delay(3000); // Đọc mỗi 3 giây
//   }
  
//   Serial.println("\n✅ DHT22 test completed!\n");
// }

// void testMQ2() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 2: MQ-2 GAS (30 giây)        ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   unsigned long start = millis();
//   int count = 0;
  
//   while (millis() - start < SENSOR_TEST_DURATION) {
//     int rawValue = analogRead(MQ2_PIN);
//     float voltage = (rawValue / 4095.0) * 3.3;
//     int percentage = map(rawValue, 0, 4095, 0, 100);
    
//     Serial.printf("   [%2d] Gas: %d%% | Raw: %d | V: %.2fV\n", 
//                   ++count, percentage, rawValue, voltage);
    
//     if (percentage > 50) {
//       Serial.println("        ⚠️  GAS DETECTED!");
//     }
    
//     delay(3000);
//   }
  
//   Serial.println("\n✅ MQ-2 test completed!\n");
// }

// void testRain() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 3: RAIN SENSOR (30 giây)     ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   unsigned long start = millis();
//   int count = 0;
  
//   while (millis() - start < SENSOR_TEST_DURATION) {
//     int rawValue = analogRead(RAIN_PIN);
//     int percentage = map(rawValue, 4095, 0, 0, 100); // Đảo ngược
    
//     String status;
//     if (percentage < 20) status = "☀️  DRY";
//     else if (percentage < 50) status = "🌤️  LIGHT RAIN";
//     else if (percentage < 80) status = "🌧️  RAINING";
//     else status = "⛈️  HEAVY RAIN";
    
//     Serial.printf("   [%2d] Rain: %d%% | Raw: %d | %s\n", 
//                   ++count, percentage, rawValue, status.c_str());
    
//     delay(3000);
//   }
  
//   Serial.println("\n✅ Rain test completed!\n");
// }

// void testSoilMoisture() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 4: SOIL MOISTURE (30 giây)   ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   unsigned long start = millis();
//   int count = 0;
  
//   while (millis() - start < SENSOR_TEST_DURATION) {
//     int rawValue = analogRead(SOIL_PIN);
//     int percentage = map(rawValue, 4095, 0, 0, 100); // Khô = 0%, Ướt = 100%
    
//     String status;
//     if (percentage < 30) status = "🟤 DRY";
//     else if (percentage < 60) status = "🟡 MOIST";
//     else status = "💧 WET";
    
//     Serial.printf("   [%2d] Soil: %d%% | Raw: %d | %s\n", 
//                   ++count, percentage, rawValue, status.c_str());
    
//     delay(3000);
//   }
  
//   Serial.println("\n✅ Soil Moisture test completed!\n");
// }

// void testDust() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 5: DUST GP2Y (30 giây)       ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   unsigned long start = millis();
//   int count = 0;
  
//   while (millis() - start < SENSOR_TEST_DURATION) {
//     // Bật LED
//     digitalWrite(DUST_LED_PIN, LOW);
//     delayMicroseconds(280);
    
//     // Đọc giá trị
//     int rawValue = analogRead(DUST_VO_PIN);
    
//     delayMicroseconds(40);
//     digitalWrite(DUST_LED_PIN, HIGH);
//     delayMicroseconds(9680);
    
//     // Tính toán
//     float voltage = (rawValue / 4095.0) * 3.3;
//     float dustDensity = (voltage - 0.6) * 200.0; // mg/m³
//     if (dustDensity < 0) dustDensity = 0;
    
//     String quality;
//     if (dustDensity < 50) quality = "🟢 GOOD";
//     else if (dustDensity < 100) quality = "🟡 MODERATE";
//     else quality = "🔴 POOR";
    
//     Serial.printf("   [%2d] Dust: %.2f mg/m³ | V: %.2fV | %s\n", 
//                   ++count, dustDensity, voltage, quality.c_str());
    
//     delay(3000);
//   }
  
//   Serial.println("\n✅ Dust test completed!\n");
// }

// void testPIRWithActuators() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 6: PIR + ALL ACTUATORS (30s) ┃");
//   Serial.println("┃   Di chuyển để kích hoạt!           ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   Serial.println("🔍 Waiting for motion...\n");
  
//   unsigned long start = millis();
//   bool detected = false;
  
//   while (millis() - start < SENSOR_TEST_DURATION) {
//     if (digitalRead(PIR_PIN)) {
//       if (!detected) {
//         detected = true;
//         Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//         Serial.println("┃  🚶 MOTION DETECTED!                 ┃");
//         Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
//         Serial.println("💥 BẬT TẤT CẢ ACTUATORS (5 giây)...\n");
        
//         allActuatorsOn();
//         delay(5000);
        
//         Serial.println("⚫ Tắt tất cả...\n");
//         allActuatorsOff();
//       }
//     } else {
//       detected = false;
//     }
    
//     unsigned long remaining = (SENSOR_TEST_DURATION - (millis() - start)) / 1000;
//     Serial.printf("   ⏱️  %lu giây còn lại...\r", remaining);
//     delay(100);
//   }
  
//   Serial.println("\n\n✅ PIR test completed!\n");
// }

// // ========================================
// // ACTUATOR TEST FUNCTIONS
// // ========================================

// void testLED() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 7: 5 LED (10 giây)           ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   // Bật từng LED
//   int leds[] = {LED1_PIN, LED2_PIN, LED3_PIN, LED4_PIN, LED5_PIN};
//   for (int i = 0; i < 5; i++) {
//     Serial.printf("💡 LED %d (GPIO%d): ON\n", i+1, leds[i]);
//     digitalWrite(leds[i], HIGH);
//     delay(1000);
//     digitalWrite(leds[i], LOW);
//   }
  
//   // Bật tất cả
//   Serial.println("\n💡 ALL LEDs: ON (3 giây)");
//   for (int led : leds) digitalWrite(led, HIGH);
//   delay(3000);
//   for (int led : leds) digitalWrite(led, LOW);
  
//   Serial.println("✅ LED test completed!\n");
// }

// void testServo() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 8: 2 SERVO (10 giây)         ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   Serial.println("🔄 Servo: 0° → 180°");
//   for (int angle = 0; angle <= 180; angle += 15) {
//     servo1.write(angle);
//     servo2.write(angle);
//     Serial.printf("   Angle: %3d°\r", angle);
//     delay(100);
//   }
//   Serial.println();
  
//   delay(1000);
  
//   Serial.println("🔄 Servo: 180° → 0°");
//   for (int angle = 180; angle >= 0; angle -= 15) {
//     servo1.write(angle);
//     servo2.write(angle);
//     Serial.printf("   Angle: %3d°\r", angle);
//     delay(100);
//   }
//   Serial.println();
  
//   Serial.println("✅ Servo test completed!\n");
// }

// void testMotors() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 9: 2 MOTORS (10 giây)        ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   // Motor A
//   Serial.println("⚙️  Motor A: FORWARD (2s)");
//   digitalWrite(MOTOR_A_IN1, HIGH);
//   digitalWrite(MOTOR_A_IN2, LOW);
//   analogWrite(MOTOR_A_ENA, 180);
//   delay(2000);
  
//   Serial.println("⚙️  Motor A: REVERSE (2s)");
//   digitalWrite(MOTOR_A_IN1, LOW);
//   digitalWrite(MOTOR_A_IN2, HIGH);
//   delay(2000);
  
//   Serial.println("⚙️  Motor A: STOP");
//   digitalWrite(MOTOR_A_IN1, LOW);
//   digitalWrite(MOTOR_A_IN2, LOW);
//   analogWrite(MOTOR_A_ENA, 0);
  
//   // Motor B
//   Serial.println("⚙️  Motor B: FORWARD (2s)");
//   digitalWrite(MOTOR_B_IN3, HIGH);
//   digitalWrite(MOTOR_B_IN4, LOW);
//   analogWrite(MOTOR_B_ENB, 180);
//   delay(2000);
  
//   Serial.println("⚙️  Motor B: REVERSE (2s)");
//   digitalWrite(MOTOR_B_IN3, LOW);
//   digitalWrite(MOTOR_B_IN4, HIGH);
//   delay(2000);
  
//   Serial.println("⚙️  Motor B: STOP");
//   digitalWrite(MOTOR_B_IN3, LOW);
//   digitalWrite(MOTOR_B_IN4, LOW);
//   analogWrite(MOTOR_B_ENB, 0);
  
//   Serial.println("✅ Motor test completed!\n");
// }

// void testRelays() {
//   Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
//   Serial.println("┃   TEST 10: 2 RELAYS (10 giây)       ┃");
//   Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
//   // Relay 1
//   Serial.println("🔌 Relay 1: ON (2s)");
//   digitalWrite(RELAY1_PIN, HIGH);
//   delay(2000);
//   Serial.println("🔌 Relay 1: OFF");
//   digitalWrite(RELAY1_PIN, LOW);
//   delay(1000);
  
//   // Relay 2
//   Serial.println("🔌 Relay 2: ON (2s)");
//   digitalWrite(RELAY2_PIN, HIGH);
//   delay(2000);
//   Serial.println("🔌 Relay 2: OFF");
//   digitalWrite(RELAY2_PIN, LOW);
//   delay(1000);
  
//   // Both
//   Serial.println("🔌 Both Relays: ON (2s)");
//   digitalWrite(RELAY1_PIN, HIGH);
//   digitalWrite(RELAY2_PIN, HIGH);
//   delay(2000);
//   Serial.println("🔌 Both Relays: OFF");
//   digitalWrite(RELAY1_PIN, LOW);
//   digitalWrite(RELAY2_PIN, LOW);
  
//   Serial.println("✅ Relay test completed!\n");
// }

// // ========================================
// // HELPER FUNCTIONS
// // ========================================

// void allActuatorsOn() {
//   // LED
//   digitalWrite(LED1_PIN, HIGH);
//   digitalWrite(LED2_PIN, HIGH);
//   digitalWrite(LED3_PIN, HIGH);
//   digitalWrite(LED4_PIN, HIGH);
//   digitalWrite(LED5_PIN, HIGH);
  
//   // Servo
//   servo1.write(90);
//   servo2.write(90);
  
//   // Motor
//   digitalWrite(MOTOR_A_IN1, HIGH);
//   digitalWrite(MOTOR_A_IN2, LOW);
//   analogWrite(MOTOR_A_ENA, 150);
  
//   digitalWrite(MOTOR_B_IN3, HIGH);
//   digitalWrite(MOTOR_B_IN4, LOW);
//   analogWrite(MOTOR_B_ENB, 150);
  
//   // Relay
//   digitalWrite(RELAY1_PIN, HIGH);
//   digitalWrite(RELAY2_PIN, HIGH);
  
//   Serial.println("   💡 5 LED: ON");
//   Serial.println("   🔄 2 Servo: 90°");
//   Serial.println("   ⚙️  2 Motors: FORWARD");
//   Serial.println("   🔌 2 Relays: ON");
// }

// void allActuatorsOff() {
//   // LED
//   digitalWrite(LED1_PIN, LOW);
//   digitalWrite(LED2_PIN, LOW);
//   digitalWrite(LED3_PIN, LOW);
//   digitalWrite(LED4_PIN, LOW);
//   digitalWrite(LED5_PIN, LOW);
  
//   // Servo
//   servo1.write(0);
//   servo2.write(0);
  
//   // Motor
//   digitalWrite(MOTOR_A_IN1, LOW);
//   digitalWrite(MOTOR_A_IN2, LOW);
//   analogWrite(MOTOR_A_ENA, 0);
  
//   digitalWrite(MOTOR_B_IN3, LOW);
//   digitalWrite(MOTOR_B_IN4, LOW);
//   analogWrite(MOTOR_B_ENB, 0);
  
//   // Relay
//   digitalWrite(RELAY1_PIN, LOW);
//   digitalWrite(RELAY2_PIN, LOW);
// }

