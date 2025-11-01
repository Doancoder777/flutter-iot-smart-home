/*
/*
 * ============================================================================
 * FULL SYSTEM TEST - TẤT CẢ THIẾT BỊ
 * ============================================================================
 * Test tất cả thiết bị theo chu kỳ:
 * 
 * 1. PIR Motion Sensor (GPIO33)
 * 2. 5 LED (GPIO5, 18, 19, 21, 13)
 * 3. 2 Servo SG90 (GPIO22, 23)
 * 4. 2 Motor L298N (GPIO14,25,26 và GPIO27,32,15)
 * 
 * Chu kỳ test (lặp lại mãi):
 * - 5 giây: Test LED (bật từng cái)
 * - 5 giây: Test Servo (quét 0° → 180° → 0°)
 * - 5 giây: Test Motor A (xuôi-ngược-dừng)
 * - 5 giây: Test Motor B (xuôi-ngược-dừng)
 * - 10 giây: Chờ PIR phát hiện chuyển động
 * - Nếu có motion: BẬT TẤT CẢ 3 giây
 * ============================================================================
 */

#include <ESP32Servo.h>

// ========================================
// PIN DEFINITIONS
// ========================================
// PIR Motion Sensor
#define PIR_PIN         33

// 5 LED
#define LED1_PIN        5
#define LED2_PIN        18
#define LED3_PIN        19
#define LED4_PIN        21
#define LED5_PIN        13

// 2 Servo
#define SERVO1_PIN      22
#define SERVO2_PIN      23

// Motor A (L298N)
#define MOTOR_A_ENA     14
#define MOTOR_A_IN1     25
#define MOTOR_A_IN2     26

// Motor B (L298N)
#define MOTOR_B_ENB     27
#define MOTOR_B_IN3     32
#define MOTOR_B_IN4     15

// ========================================
// OBJECTS
// ========================================
Servo servo1;
Servo servo2;

// ========================================
// SETUP
// ========================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n╔════════════════════════════════════════════════╗");
  Serial.println("║         FULL SYSTEM TEST - ALL DEVICES         ║");
  Serial.println("║    PIR + 5 LED + 2 Servo + 2 Motor L298N       ║");
  Serial.println("╚════════════════════════════════════════════════╝\n");
  
  // Setup PIR
  pinMode(PIR_PIN, INPUT);
  
  // Setup 5 LED
  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);
  pinMode(LED3_PIN, OUTPUT);
  pinMode(LED4_PIN, OUTPUT);
  pinMode(LED5_PIN, OUTPUT);
  
  // Setup Servo
  servo1.attach(SERVO1_PIN);
  servo2.attach(SERVO2_PIN);
  servo1.write(0);
  servo2.write(0);
  
  // Setup Motor A
  pinMode(MOTOR_A_ENA, OUTPUT);
  pinMode(MOTOR_A_IN1, OUTPUT);
  pinMode(MOTOR_A_IN2, OUTPUT);
  
  // Setup Motor B
  pinMode(MOTOR_B_ENB, OUTPUT);
  pinMode(MOTOR_B_IN3, OUTPUT);
  pinMode(MOTOR_B_IN4, OUTPUT);
  
  // Tắt tất cả
  allOff();
  
  Serial.println("✅ Hardware initialized!");
  Serial.println("\n📌 DEVICE LIST:");
  Serial.println("   1. PIR Sensor:     GPIO33");
  Serial.println("   2. LED 1-5:        GPIO5, 18, 19, 21, 13");
  Serial.println("   3. Servo 1-2:      GPIO22, 23");
  Serial.println("   4. Motor A:        GPIO14, 25, 26");
  Serial.println("   5. Motor B:        GPIO27, 32, 15");
  
  Serial.println("\n🔄 Starting test cycle...\n");
  Serial.println("═══════════════════════════════════════════════\n");
  delay(2000);
}

// ========================================
// LOOP
// ========================================
void loop() {
  // TEST 1: LED (5 giây)
  testLED();
  
  // TEST 2: SERVO (5 giây)
  testServo();
  
  // TEST 3: MOTOR A (5 giây)
  testMotorA();
  
  // TEST 4: MOTOR B (5 giây)
  testMotorB();
  
  // TEST 5: PIR (10 giây chờ motion)
  testPIR();
  
  // Nghỉ 3 giây trước chu kỳ mới
  Serial.println("\n⏸️  Pause 3 giây trước chu kỳ mới...\n");
  allOff();
  delay(3000);
}

// ========================================
// TEST FUNCTIONS
// ========================================

void testLED() {
  Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
  Serial.println("┃      TEST 1: 5 LED (5 giây)         ┃");
  Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
  // Bật từng LED 1 giây
  Serial.println("💡 LED 1 (GPIO5):  ON");
  digitalWrite(LED1_PIN, HIGH);
  delay(1000);
  digitalWrite(LED1_PIN, LOW);
  
  Serial.println("💡 LED 2 (GPIO18): ON");
  digitalWrite(LED2_PIN, HIGH);
  delay(1000);
  digitalWrite(LED2_PIN, LOW);
  
  Serial.println("💡 LED 3 (GPIO19): ON");
  digitalWrite(LED3_PIN, HIGH);
  delay(1000);
  digitalWrite(LED3_PIN, LOW);
  
  Serial.println("💡 LED 4 (GPIO21): ON");
  digitalWrite(LED4_PIN, HIGH);
  delay(1000);
  digitalWrite(LED4_PIN, LOW);
  
  Serial.println("💡 LED 5 (GPIO13): ON");
  digitalWrite(LED5_PIN, HIGH);
  delay(1000);
  digitalWrite(LED5_PIN, LOW);
  
  Serial.println("✅ LED test completed!\n");
}

void testServo() {
  Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
  Serial.println("┃      TEST 2: 2 SERVO (5 giây)       ┃");
  Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
  // Quét từ 0° → 180°
  Serial.println("🔄 Servo 1 & 2: 0° → 180°");
  for (int angle = 0; angle <= 180; angle += 10) {
    servo1.write(angle);
    servo2.write(angle);
    Serial.printf("   Angle: %3d°\r", angle);
    delay(50);
  }
  Serial.println();
  
  delay(1000);
  
  // Quét từ 180° → 0°
  Serial.println("🔄 Servo 1 & 2: 180° → 0°");
  for (int angle = 180; angle >= 0; angle -= 10) {
    servo1.write(angle);
    servo2.write(angle);
    Serial.printf("   Angle: %3d°\r", angle);
    delay(50);
  }
  Serial.println();
  
  Serial.println("✅ Servo test completed!\n");
}

void testMotorA() {
  Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
  Serial.println("┃      TEST 3: MOTOR A (5 giây)       ┃");
  Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
  // Quay xuôi
  Serial.println("⚙️  Motor A: FORWARD (70%)");
  digitalWrite(MOTOR_A_IN1, HIGH);
  digitalWrite(MOTOR_A_IN2, LOW);
  analogWrite(MOTOR_A_ENA, 180);
  delay(2000);
  
  // Dừng
  Serial.println("⚙️  Motor A: STOP");
  digitalWrite(MOTOR_A_IN1, LOW);
  digitalWrite(MOTOR_A_IN2, LOW);
  analogWrite(MOTOR_A_ENA, 0);
  delay(500);
  
  // Quay ngược
  Serial.println("⚙️  Motor A: REVERSE (70%)");
  digitalWrite(MOTOR_A_IN1, LOW);
  digitalWrite(MOTOR_A_IN2, HIGH);
  analogWrite(MOTOR_A_ENA, 180);
  delay(2000);
  
  // Dừng
  Serial.println("⚙️  Motor A: STOP");
  digitalWrite(MOTOR_A_IN1, LOW);
  digitalWrite(MOTOR_A_IN2, LOW);
  analogWrite(MOTOR_A_ENA, 0);
  delay(500);
  
  Serial.println("✅ Motor A test completed!\n");
}

void testMotorB() {
  Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
  Serial.println("┃      TEST 4: MOTOR B (5 giây)       ┃");
  Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
  // Quay xuôi
  Serial.println("⚙️  Motor B: FORWARD (78%)");
  digitalWrite(MOTOR_B_IN3, HIGH);
  digitalWrite(MOTOR_B_IN4, LOW);
  analogWrite(MOTOR_B_ENB, 200);
  delay(2000);
  
  // Dừng
  Serial.println("⚙️  Motor B: STOP");
  digitalWrite(MOTOR_B_IN3, LOW);
  digitalWrite(MOTOR_B_IN4, LOW);
  analogWrite(MOTOR_B_ENB, 0);
  delay(500);
  
  // Quay ngược
  Serial.println("⚙️  Motor B: REVERSE (78%)");
  digitalWrite(MOTOR_B_IN3, LOW);
  digitalWrite(MOTOR_B_IN4, HIGH);
  analogWrite(MOTOR_B_ENB, 200);
  delay(2000);
  
  // Dừng
  Serial.println("⚙️  Motor B: STOP");
  digitalWrite(MOTOR_B_IN3, LOW);
  digitalWrite(MOTOR_B_IN4, LOW);
  analogWrite(MOTOR_B_ENB, 0);
  delay(500);
  
  Serial.println("✅ Motor B test completed!\n");
}

void testPIR() {
  Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
  Serial.println("┃      TEST 5: PIR (10 giây)          ┃");
  Serial.println("┃      Di chuyển trước sensor!        ┃");
  Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
  
  Serial.println("🔍 Waiting for motion (10 seconds)...\n");
  
  unsigned long startTime = millis();
  bool motionDetected = false;
  
  while (millis() - startTime < 10000) {
    if (digitalRead(PIR_PIN)) {
      if (!motionDetected) {
        motionDetected = true;
        Serial.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
        Serial.println("┃  🚶 MOTION DETECTED!                 ┃");
        Serial.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n");
        Serial.println("💥 BẬT TẤT CẢ THIẾT BỊ (3 giây)...\n");
        
        // BẬT TẤT CẢ
        allOn();
        delay(3000);
        
        // TẮT TẤT CẢ
        Serial.println("⚫ Tắt tất cả...\n");
        allOff();
      }
    } else {
      motionDetected = false;
    }
    
    // Hiển thị countdown
    unsigned long remaining = 10 - (millis() - startTime) / 1000;
    Serial.printf("   ⏱️  %lu giây còn lại...\r", remaining);
    delay(100);
  }
  
  Serial.println("\n✅ PIR test completed!\n");
}

void allOn() {
  // LED
  digitalWrite(LED1_PIN, HIGH);
  digitalWrite(LED2_PIN, HIGH);
  digitalWrite(LED3_PIN, HIGH);
  digitalWrite(LED4_PIN, HIGH);
  digitalWrite(LED5_PIN, HIGH);
  
  // Servo
  servo1.write(90);
  servo2.write(90);
  
  // Motor A
  digitalWrite(MOTOR_A_IN1, HIGH);
  digitalWrite(MOTOR_A_IN2, LOW);
  analogWrite(MOTOR_A_ENA, 150);
  
  // Motor B
  digitalWrite(MOTOR_B_IN3, HIGH);
  digitalWrite(MOTOR_B_IN4, LOW);
  analogWrite(MOTOR_B_ENB, 150);
  
  Serial.println("   💡 5 LED: ON");
  Serial.println("   🔄 2 Servo: 90°");
  Serial.println("   ⚙️  Motor A: FORWARD (59%)");
  Serial.println("   ⚙️  Motor B: FORWARD (59%)");
}

void allOff() {
  // LED
  digitalWrite(LED1_PIN, LOW);
  digitalWrite(LED2_PIN, LOW);
  digitalWrite(LED3_PIN, LOW);
  digitalWrite(LED4_PIN, LOW);
  digitalWrite(LED5_PIN, LOW);
  
  // Servo
  servo1.write(0);
  servo2.write(0);
  
  // Motor A
  digitalWrite(MOTOR_A_IN1, LOW);
  digitalWrite(MOTOR_A_IN2, LOW);
  analogWrite(MOTOR_A_ENA, 0);
  
  // Motor B
  digitalWrite(MOTOR_B_IN3, LOW);
  digitalWrite(MOTOR_B_IN4, LOW);
  analogWrite(MOTOR_B_ENB, 0);
}


*/