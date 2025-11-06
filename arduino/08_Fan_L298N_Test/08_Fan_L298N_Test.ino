/*
 * SƠ ĐỒ ĐẤU NỐI GP2Y1014 VỚI ESP32 38-PIN
 * 
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * QUAN TRỌNG: GPIO36 = ADC1_0 (BÊN TRÁI, HÀNG THỨ 3)
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * 
 * ESP32 BÊN TRÁI (từ trên xuống):
 * ─────────────────────────────────
 * 1. 3V3
 * 2. RESTART/EN
 * 3. GPIO36 (ADC1_0) ← ĐÂY LÀ CHÂN ĐỌC Vo! ⚫ DÂY ĐEN
 * 4. GPIO39 (ADC1_3)
 * 5. GPIO34 (ADC1_6)
 * 6. GPIO35 (ADC1_7)
 * 7. GPIO32
 * 8. GPIO33
 * 9. GPIO25 ← Điều khiển LED! 🔵⚪ DÂY XANH + TRẮNG
 * 10. GPIO26
 * 11. GPIO27
 * 12. GPIO14
 * 13. GPIO12
 * 14. GND ← Ground! 🟢🟡 DÂY XANH LÁ + VÀNG
 * 
 * ESP32 BÊN PHẢI (từ trên xuống):
 * ─────────────────────────────────
 * 1. GND
 * 2. GPIO23
 * 3. GPIO22
 * 4. GPIO1 (TX0)
 * 5. GPIO3 (RX0)
 * 6. GPIO21
 * 7. GND
 * 8. GPIO19
 * 9. GPIO18
 * 10. GPIO5
 * 11. GPIO17
 * 12. GPIO16
 * 13. GPIO4
 * 14. GPIO0
 * 15. GPIO2 (LED)
 * 16. GPIO15
 * 17. GND
 * 18. 5V ← Nguồn 5V! 🔴 DÂY ĐỎ
 * 
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * BẢNG KẾT NỐI CHÍNH XÁC:
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * 
 * GP2Y1014          Màu          ESP32 38-pin
 * ──────────────────────────────────────────────────
 * PIN 1 (V-LED)  →  🔵 Xanh     → GPIO25 (qua R 150Ω)
 *                                  ↑ BÊN TRÁI, HÀNG 9
 * 
 * PIN 2 (LED-GND)→  🟢 Xanh lá  → GND
 *                                  ↑ BÊN TRÁI, HÀNG 14
 *                                  hoặc BÊN PHẢI
 * 
 * PIN 3 (LED)    →  ⚪ Trắng    → GPIO25
 *                                  ↑ BÊN TRÁI, HÀNG 9
 * 
 * PIN 4 (S-GND)  →  🟡 Vàng     → GND
 *                                  ↑ BÊN TRÁI, HÀNG 14
 *                                  hoặc BÊN PHẢI
 * 
 * PIN 5 (Vo)     →  ⚫ ĐEN      → GPIO36 (ADC1_0)
 *                                  ↑ BÊN TRÁI, HÀNG 3 !!!
 * 
 * PIN 6 (Vcc)    →  🔴 Đỏ       → 5V (+ tụ 220µF)
 *                                  ↑ BÊN PHẢI, HÀNG 18
 * 
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 */

#define LED_PIN   25    // GPIO25 - BÊN TRÁI, HÀNG 9
#define DUST_PIN  36    // GPIO36 (ADC1_0) - BÊN TRÁI, HÀNG 3

#define SAMPLING_TIME    280
#define DELTA_TIME       40
#define SLEEP_TIME       9680

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH);
  
  pinMode(DUST_PIN, INPUT);
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);
  
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║  GP2Y1014 + ESP32 38-PIN              ║");
  Serial.println("╚════════════════════════════════════════╝");
  Serial.println();
  Serial.println("📍 VỊ TRÍ CÁC CHÂN:");
  Serial.println("   • GPIO36 (Vo): BÊN TRÁI, HÀNG 3");
  Serial.println("   • GPIO25 (LED): BÊN TRÁI, HÀNG 9");
  Serial.println("   • GND: BÊN TRÁI HÀNG 14 hoặc BÊN PHẢI");
  Serial.println("   • 5V: BÊN PHẢI, HÀNG 18 (cuối cùng)");
  Serial.println();
  Serial.println("⚠️ KIỂM TRA NGAY:");
  Serial.println("   1. Dây ĐEN ⚫ cắm BÊN TRÁI, HÀNG 3?");
  Serial.println("   2. Dây XANH + TRẮNG cắm HÀNG 9?");
  Serial.println("   3. Dây ĐỎ 🔴 cắm BÊN PHẢI cuối (5V)?");
  Serial.println();
  Serial.println("========================================");
  delay(3000);
}

void loop() {
  // Bật LED
  digitalWrite(LED_PIN, LOW);
  delayMicroseconds(SAMPLING_TIME);
  
  // Đọc ADC
  int adcValue = analogRead(DUST_PIN);
  
  delayMicroseconds(DELTA_TIME);
  digitalWrite(LED_PIN, HIGH);
  delayMicroseconds(SLEEP_TIME);
  
  // Chuyển đổi
  float voltage = (adcValue / 4095.0) * 3.3;
  float dustDensity = 0.0;
  if (voltage >= 0.6) {
    dustDensity = (voltage - 0.6) / 0.005;
  }
  
  // Hiển thị
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  Serial.print("📍 Chân đọc: GPIO36 (ADC1_0) = ");
  Serial.println(DUST_PIN);
  
  Serial.print("📊 ADC Raw: ");
  Serial.println(adcValue);
  
  Serial.print("⚡ Điện áp Vo: ");
  Serial.print(voltage, 3);
  Serial.println(" V");
  
  Serial.print("💨 Nồng độ bụi: ");
  Serial.print(dustDensity, 2);
  Serial.println(" μg/m³");
  
  // Đánh giá
  if (adcValue == 0) {
    Serial.println();
    Serial.println("❌ LỖI: Không đọc được tín hiệu!");
    Serial.println("🔧 KIỂM TRA:");
    Serial.println("   → Dây ĐEN ⚫ có cắm HÀNG 3 BÊN TRÁI?");
    Serial.println("   → Dây ĐỎ 🔴 có cắm 5V BÊN PHẢI?");
    Serial.println("   → Dây XANH LÁ 🟢 + VÀNG 🟡 cắm GND?");
  } else if (voltage < 0.5) {
    Serial.println("⚠️ Điện áp thấp - Kiểm tra nguồn 5V");
  } else {
    if (dustDensity < 12) {
      Serial.println("🌍 ✅ TỐT");
    } else if (dustDensity < 35.5) {
      Serial.println("🌍 🟢 TRUNG BÌNH");
    } else if (dustDensity < 55.5) {
      Serial.println("🌍 🟡 KÉM");
    } else if (dustDensity < 150.5) {
      Serial.println("🌍 🟠 XẤU");
    } else {
      Serial.println("🌍 🔴 RẤT XẤU");
    }
  }
  
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  Serial.println();
  
  delay(1000);
}

/*
 * ╔══════════════════════════════════════════════════╗
 * ║  TÓM TẮT VỊ TRÍ CHÂN TRÊN ESP32 38-PIN:         ║
 * ╚══════════════════════════════════════════════════╝
 * 
 *        ESP32 DevKit 38-PIN
 *        
 *   BÊN TRÁI              BÊN PHẢI
 *   ─────────            ─────────
 *   3V3                  GND
 *   RESTART/EN           GPIO23
 *   GPIO36 ●───Vo        GPIO22
 *   GPIO39               GPIO1
 *   GPIO34               GPIO3
 *   GPIO35               GPIO21
 *   GPIO32               GND
 *   GPIO33               GPIO19
 *   GPIO25 ●───LED       GPIO18
 *   GPIO26               GPIO5
 *   GPIO27               GPIO17
 *   GPIO14               GPIO16
 *   GPIO12               GPIO4
 *   GND ●──────┐         GPIO0
 *              │         GPIO2
 *            Ground      GPIO15
 *                        GND
 *                        5V ●─── Nguồn
 *                        
 * Kết nối:
 * • Vo (đen) → GPIO36 (trái, hàng 3)
 * • LED (xanh+trắng) → GPIO25 (trái, hàng 9)
 * • GND (xanh lá+vàng) → GND (trái, hàng 14)
 * • Vcc (đỏ) → 5V (phải, cuối cùng)
 */