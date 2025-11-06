/*
 * ============================================================================
 * MQ-2 GAS SENSOR TEST - RIÊNG CHO CẢM BIẾN KHÍ GAS
 * ============================================================================
 * 
 * Chỉ test MQ-2 Gas sensor để kiểm tra xem cảm biến có hoạt động không
 * 
 * 🔌 ĐẤU DÂY MQ-2:
 * - VCC  → 5V (ESP32) - MQ-2 CẦN 5V để hoạt động ổn định
 * - GND  → GND (ESP32)
 * - AO   → GPIO34 (ESP32) - Analog Output
 * - DO   → Không dùng (Digital Output)
 * 
 * ⚠️ LƯU Ý:
 * - MQ-2 cần WARM-UP 24-48 giờ lần đầu để ổn định
 * - Trong 2-3 phút đầu, giá trị sẽ dao động nhiều (đang hâm nóng)
 * - Giá trị bình thường (không khí sạch): 300-800 ppm
 * - Giá trị nguy hiểm (có gas): > 2000 ppm
 * d
 * 🔥 TEST:
 * - Giá trị ban đầu: 300-800 (không khí sạch)
 * - Thổi vào sensor: Giá trị tăng lên
 * - Dùng lighter (KHÔNG BẬT LỬA): Giá trị tăng cao > 2000
 * 
 * ============================================================================
 */

// ============================================================================
// PIN DEFINITION
// ============================================================================
#define MQ2_PIN  34   // GPIO34 - MQ-2 Analog Output (ADC1_6)

// ============================================================================
// THRESHOLDS
// ============================================================================
const int CLEAN_AIR_MAX = 1000;      // < 1000 ppm: Không khí sạch
const int MODERATE_LEVEL = 2000;     // 1000-2000: Mức trung bình
const int DANGER_LEVEL = 3000;       // > 3000: Nguy hiểm!

// ============================================================================
// SETUP
// ============================================================================
void setup() {
  Serial.begin(115200);
  delay(2000);  // Đợi Serial Monitor khởi động
  
  Serial.println("\n╔════════════════════════════════════════════════╗");
  Serial.println("║     MQ-2 GAS SENSOR TEST - GPIO34             ║");
  Serial.println("╚════════════════════════════════════════════════╝\n");
  
  // ✅ Setup MQ-2 sensor
  pinMode(MQ2_PIN, INPUT);
  
  Serial.println("🔧 MQ-2 Gas Sensor Configuration:");
  Serial.println("   - Sensor Type: MQ-2 (LPG, Propane, Hydrogen)");
  Serial.println("   - Analog Pin: GPIO34 (ADC1_6)");
  Serial.println("   - VCC: 5V (QUAN TRỌNG!)");
  Serial.println("   - Warm-up: 2-3 phút (24-48h lần đầu)\n");
  
  Serial.println("⏱️  WARM-UP - Đợi sensor hâm nóng...");
  Serial.println("   (Trong 2-3 phút đầu, giá trị sẽ dao động)\n");
  
  // Warm-up 30 giây với countdown
  for (int i = 30; i > 0; i--) {
    Serial.print("   Còn ");
    Serial.print(i);
    Serial.println(" giây...");
    delay(1000);
  }
  
  Serial.println("\n✅ Warm-up hoàn tất! Bắt đầu đọc sensor...\n");
  Serial.println("📊 THRESHOLDS:");
  Serial.println("   < 1000 ppm:  Không khí sạch ✅");
  Serial.println("   1000-2000:   Mức trung bình ⚠️");
  Serial.println("   2000-3000:   Cao ⚠️");
  Serial.println("   > 3000:      NGUY HIỂM! 🚨\n");
  Serial.println("═══════════════════════════════════════════════\n");
}

// ============================================================================
// MAIN LOOP
// ============================================================================
void loop() {
  // ⏱️ Delay 2 giây
  delay(2000);
  
  // 📖 Đọc dữ liệu từ MQ-2
  int gasRaw = analogRead(MQ2_PIN);
  
  // Chuyển đổi raw value (0-4095) sang ppm (0-10000)
  // ESP32 ADC: 0-4095 (12-bit)
  // Giả sử: 4095 = 10000 ppm (max scale)
  float gasPPM = (gasRaw / 4095.0) * 10000.0;
  
  // Tính % theo scale 0-10000 ppm
  float gasPercent = (gasPPM / 10000.0) * 100.0;
  
  // 📊 Hiển thị kết quả
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  Serial.print("⏰ Time: ");
  Serial.print(millis() / 1000);
  Serial.println(" seconds");
  Serial.println("─────────────────────────────────────────────");
  
  // 📈 Raw Value
  Serial.print("📈 Raw Value:   ");
  Serial.print(gasRaw);
  Serial.println(" / 4095");
  
  // 💨 Gas Concentration
  Serial.print("💨 Gas Level:   ");
  Serial.print(gasPPM, 0);
  Serial.print(" ppm (");
  Serial.print(gasPercent, 1);
  Serial.println("%)");
  
  // 🎯 Status & Level
  Serial.print("🎯 Status:      ");
  if (gasPPM < CLEAN_AIR_MAX) {
    Serial.println("✅ Không khí sạch");
  } else if (gasPPM < MODERATE_LEVEL) {
    Serial.println("⚠️  Mức trung bình");
  } else if (gasPPM < DANGER_LEVEL) {
    Serial.println("⚠️  CAO - Cần thông gió!");
  } else {
    Serial.println("🚨 NGUY HIỂM - Thoát ra ngay!");
  }
  
  // 📊 Visual Bar (0-100%)
  Serial.print("📊 Bar Graph:   [");
  int barLength = (int)(gasPercent / 5); // Chia 5 để có 20 ô
  for (int i = 0; i < 20; i++) {
    if (i < barLength) {
      Serial.print("█");
    } else {
      Serial.print("░");
    }
  }
  Serial.println("]");
  
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
  
  // 🔥 CẢNH BÁO nếu nguy hiểm
  if (gasPPM >= DANGER_LEVEL) {
    Serial.println("🚨🚨🚨 CẢNH BÁO NGUY HIỂM 🚨🚨🚨");
    Serial.println("   Phát hiện nồng độ khí gas cao!");
    Serial.println("   1. Tắt nguồn điện");
    Serial.println("   2. Mở cửa sổ thông gió");
    Serial.println("   3. Không bật lửa/thiết bị điện");
    Serial.println("   4. Rời khỏi khu vực ngay!\n");
  }
  
  // 💡 GỢI Ý TEST
  if (millis() < 60000) { // Trong 60 giây đầu
    Serial.println("💡 TEST GỢI Ý:");
    Serial.println("   - Thổi vào sensor → Giá trị tăng nhẹ");
    Serial.println("   - Lighter không bật lửa → Giá trị tăng cao");
    Serial.println("   - Tránh xa → Giá trị giảm về bình thường\n");
  }
}
