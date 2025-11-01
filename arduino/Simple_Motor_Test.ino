/*
 * ============================================================================
 * SIMPLE MOTOR TEST - L298N Driver (NO MQTT)
 * ============================================================================
 * 
 * Test đơn giản cho 2 motor DC với L298N
 * Không cần WiFi, MQTT - chỉ test phần cứng
 * 
 * TEST SEQUENCE:
 * 1. Motor A: OFF → FORWARD 128 → FORWARD 255 → REVERSE 128 → OFF
 * 2. Motor B: OFF → FORWARD 128 → FORWARD 255 → REVERSE 128 → OFF
 * 3. Loop lại mỗi 20 giây
 * 
 * ============================================================================
 */

// ============================================================================
// PIN DEFINITIONS
// ============================================================================
// Motor A (3 chân)
#define MOTOR_A_ENA     16   // GPIO16 - Motor A PWM Speed
#define MOTOR_A_IN1     17   // GPIO17 - Motor A Direction 1
#define MOTOR_A_IN2     25   // GPIO25 - Motor A Direction 2

// Motor B (3 chân)
#define MOTOR_B_ENB     26   // GPIO26 - Motor B PWM Speed
#define MOTOR_B_IN3     27   // GPIO27 - Motor B Direction 1
#define MOTOR_B_IN4     12   // GPIO12 - Motor B Direction 2

// ============================================================================
// SETUP
// ============================================================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n╔════════════════════════════════════════════════╗");
  Serial.println("║      SIMPLE MOTOR TEST - L298N Driver         ║");
  Serial.println("║      ESP32 DevKit v1 - NO WiFi/MQTT           ║");
  Serial.println("╚════════════════════════════════════════════════╝\n");
  
  // Setup Motor A pins
  pinMode(MOTOR_A_ENA, OUTPUT);
  pinMode(MOTOR_A_IN1, OUTPUT);
  pinMode(MOTOR_A_IN2, OUTPUT);
  
  // Setup Motor B pins
  pinMode(MOTOR_B_ENB, OUTPUT);
  pinMode(MOTOR_B_IN3, OUTPUT);
  pinMode(MOTOR_B_IN4, OUTPUT);
  
  // Initialize motors OFF
  digitalWrite(MOTOR_A_IN1, LOW);
  digitalWrite(MOTOR_A_IN2, LOW);
  analogWrite(MOTOR_A_ENA, 0);
  
  digitalWrite(MOTOR_B_IN3, LOW);
  digitalWrite(MOTOR_B_IN4, LOW);
  analogWrite(MOTOR_B_ENB, 0);
  
  Serial.println("✅ Motor pins initialized!");
  Serial.println("\n📌 GPIO MAPPING:");
  Serial.println("   Motor A: GPIO16 (ENA), GPIO17 (IN1), GPIO25 (IN2)");
  Serial.println("   Motor B: GPIO26 (ENB), GPIO27 (IN3), GPIO12 (IN4)");
  Serial.println("\n🔄 Starting motor test sequence...\n");
  Serial.println("═══════════════════════════════════════════════\n");
  
  delay(2000); // Wait 2 seconds before starting
}

// ============================================================================
// MAIN LOOP
// ============================================================================
void loop() {
  // ========================================
  // TEST MOTOR A - CHỈ TEST TỐC ĐỘ (KHÔNG TEST CHIỀU)
  // ========================================
  Serial.println("🔵 TESTING MOTOR A SPEED:");
  Serial.println("───────────────────────────────────────────────");
  
  // Motor A - OFF
  Serial.println("1️⃣  Motor A: OFF");
  controlMotorA(0);
  delay(2000);
  
  // Motor A - Very Slow (25%)
  Serial.println("2️⃣  Motor A: 64/255 (25% - Very Slow)");
  controlMotorA(64);
  delay(4000);
  
  // Motor A - Slow (50%)
  Serial.println("3️⃣  Motor A: 128/255 (50% - Slow)");
  controlMotorA(128);
  delay(4000);
  
  // Motor A - Medium (75%)
  Serial.println("4️⃣  Motor A: 192/255 (75% - Medium)");
  controlMotorA(192);
  delay(4000);
  
  // Motor A - Full Speed (100%)
  Serial.println("5️⃣  Motor A: 255/255 (100% - Full Speed)");
  controlMotorA(255);
  delay(4000);
  
  // Motor A - OFF
  Serial.println("6️⃣  Motor A: OFF");
  controlMotorA(0);
  delay(2000);
  
  Serial.println("✅ Motor A speed test completed!\n");
  
  Serial.println("═══════════════════════════════════════════════");
  Serial.println("🔁 Restarting test sequence in 5 seconds...\n");
  delay(5000);
}

// ============================================================================
// CONTROL FUNCTIONS
// ============================================================================

void controlMotorA(int speed) {
  speed = constrain(speed, -255, 255);
  
  if (speed == 0) {
    // ⚠️ TẮT MOTOR: IN1=LOW, IN2=LOW, PWM=0
    digitalWrite(MOTOR_A_IN1, LOW);
    digitalWrite(MOTOR_A_IN2, LOW);
    analogWrite(MOTOR_A_ENA, 0);
    Serial.println("   💤 Motor A: OFF | IN1=LOW | IN2=LOW | PWM=0");
  } else if (speed > 0) {
    // ✅ QUAY THUẬN: IN1=HIGH, IN2=LOW, PWM=speed
    digitalWrite(MOTOR_A_IN1, HIGH);
    digitalWrite(MOTOR_A_IN2, LOW);
    analogWrite(MOTOR_A_ENA, speed);
    Serial.printf("   ➡️  Motor A: FORWARD %d/255 | IN1=HIGH | IN2=LOW | PWM=%d\n", speed, speed);
  } else {
    // ✅ QUAY NGƯỢC: IN1=LOW, IN2=HIGH, PWM=abs(speed)
    digitalWrite(MOTOR_A_IN1, LOW);
    digitalWrite(MOTOR_A_IN2, HIGH);
    analogWrite(MOTOR_A_ENA, abs(speed));
    Serial.printf("   ⬅️  Motor A: REVERSE %d/255 | IN1=LOW | IN2=HIGH | PWM=%d\n", abs(speed), abs(speed));
  }
}

void controlMotorB(int speed) {
  speed = constrain(speed, -255, 255);
  
  if (speed == 0) {
    // ⚠️ TẮT MOTOR: IN3=LOW, IN4=LOW, PWM=0
    digitalWrite(MOTOR_B_IN3, LOW);
    digitalWrite(MOTOR_B_IN4, LOW);
    analogWrite(MOTOR_B_ENB, 0);
    Serial.println("   💤 Motor B: OFF | IN3=LOW | IN4=LOW | PWM=0");
  } else if (speed > 0) {
    // ✅ QUAY THUẬN: IN3=HIGH, IN4=LOW, PWM=speed
    digitalWrite(MOTOR_B_IN3, HIGH);
    digitalWrite(MOTOR_B_IN4, LOW);
    analogWrite(MOTOR_B_ENB, speed);
    Serial.printf("   ➡️  Motor B: FORWARD %d/255 | IN3=HIGH | IN4=LOW | PWM=%d\n", speed, speed);
  } else {
    // ✅ QUAY NGƯỢC: IN3=LOW, IN4=HIGH, PWM=abs(speed)
    digitalWrite(MOTOR_B_IN3, LOW);
    digitalWrite(MOTOR_B_IN4, HIGH);
    analogWrite(MOTOR_B_ENB, abs(speed));
    Serial.printf("   ⬅️  Motor B: REVERSE %d/255 | IN3=LOW | IN4=HIGH | PWM=%d\n", abs(speed), abs(speed));
  }
}
