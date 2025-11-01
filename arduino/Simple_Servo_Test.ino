/*
 * ============================================================================
 * SIMPLE SERVO TEST - GPIO13
 * ============================================================================
 * Test đơn giản cho 1 servo motor ở GPIO13
 * Quét từ 0° → 180° → 0° liên tục
 * ============================================================================
 */

#include <ESP32Servo.h>

// Pin definition
#define SERVO_PIN 13  // GPIO13

// Object
Servo myServo;

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n╔════════════════════════════════════╗");
  Serial.println("║   SIMPLE SERVO TEST - GPIO13      ║");
  Serial.println("╚════════════════════════════════════╝\n");
  
  // Attach servo to GPIO13
  myServo.attach(SERVO_PIN);
  
  Serial.println("✅ Servo attached to GPIO13");
  Serial.println("🔄 Starting sweep test...\n");
  
  // Test lần đầu
  Serial.println("Test 1: Moving to 0°");
  myServo.write(0);
  delay(1000);
  
  Serial.println("Test 2: Moving to 90°");
  myServo.write(90);
  delay(1000);
  
  Serial.println("Test 3: Moving to 180°");
  myServo.write(180);
  delay(1000);
  
  Serial.println("Test 4: Moving back to 0°");
  myServo.write(0);
  delay(1000);
  
  Serial.println("\n✅ Initial test complete!");
  Serial.println("🔄 Starting continuous sweep...\n");
}

void loop() {
  // Quét từ 0 đến 180 độ
  Serial.println("📈 Sweeping 0° → 180°");
  for (int angle = 0; angle <= 180; angle += 10) {
    myServo.write(angle);
    Serial.printf("   Angle: %d°, PWM: %d us\n", angle, myServo.readMicroseconds());
    delay(500);  // Đợi 0.5 giây mỗi bước
  }
  
  delay(1000);  // Dừng ở 180° trong 1 giây
  
  // Quét từ 180 về 0 độ
  Serial.println("📉 Sweeping 180° → 0°");
  for (int angle = 180; angle >= 0; angle -= 10) {
    myServo.write(angle);
    Serial.printf("   Angle: %d°, PWM: %d us\n", angle, myServo.readMicroseconds());
    delay(500);  // Đợi 0.5 giây mỗi bước
  }
  
  delay(1000);  // Dừng ở 0° trong 1 giây
  
  Serial.println("✅ Sweep cycle complete!\n");
}
