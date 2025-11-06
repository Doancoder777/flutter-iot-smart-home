/*
 * ============================================================================
 * DHT11 SENSOR TEST - RIÊNG CHO CẢM BIẾN NHIỆT ĐỘ/ẨM
 * ============================================================================
 * 
 * Chỉ test DHT11 sensor để kiểm tra xem cảm biến có hoạt động không
 * 
 * 🔌 ĐẤU DÂY DHT11:
 * - VCC  → 3.3V hoặc 5V (ESP32)
 * - GND  → GND (ESP32)
 * - DATA → GPIO4 (ESP32)
 * - Resistor 10kΩ giữa VCC và DATA (pull-up resistor)
 * 
 * 📊 KẾT QUẢ MONG ĐỢI:
 * - Status: 0 → Đọc thành công ✅
 * - Status: 1 → Timeout (lỗi kết nối) ❌
 * - Status: 2 → Checksum error (lỗi dữ liệu) ❌
 * 
 * ============================================================================
 */

#include "DHTesp.h"

// ============================================================================
// PIN DEFINITION
// ============================================================================
#define DHT_PIN  4    // GPIO4 - DHT11 DATA pin

// ============================================================================
// OBJECT
// ============================================================================
DHTesp dht;

// ============================================================================
// SETUP
// ============================================================================
void setup() {
  Serial.begin(115200);
  delay(2000);  // Đợi Serial Monitor khởi động
  
  Serial.println("\n╔════════════════════════════════════════════════╗");
  Serial.println("║       DHT11 SENSOR TEST - GPIO4               ║");
  Serial.println("╚════════════════════════════════════════════════╝\n");
  
  // ✅ Setup DHT11 sensor
  dht.setup(DHT_PIN, DHTesp::DHT22); // 🔄 ĐỔI THÀNH DHT22 nếu dùng DHT22
  
  Serial.println("🔧 DHT11 Configuration:");
  Serial.println("   - Sensor Type: DHT11");
  Serial.println("   - Data Pin: GPIO4");
  Serial.println("   - VCC: 3.3V or 5V");
  Serial.println("   - Pull-up: 10kΩ (VCC to DATA)\n");
  
  Serial.println("📊 Reading sensor every 3 seconds...\n");
  Serial.println("═══════════════════════════════════════════════\n");
}

// ============================================================================
// MAIN LOOP
// ============================================================================
void loop() {
  // ⏱️ Delay 3 giây (DHT11 chỉ đọc được mỗi 1 giây)
  delay(3000);
  
  // 📖 Đọc dữ liệu từ DHT11
  TempAndHumidity data = dht.getTempAndHumidity();
  int status = dht.getStatus();
  
  // 📊 Hiển thị kết quả
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  Serial.print("⏰ Time: ");
  Serial.print(millis() / 1000);
  Serial.println(" seconds");
  Serial.println("─────────────────────────────────────────────");
  
  // 🌡️ Temperature
  Serial.print("🌡️  Temperature: ");
  if (status == 0) {
    Serial.print(data.temperature, 1);
    Serial.println("°C");
  } else {
    Serial.println("ERROR - No data");
  }
  
  // 💧 Humidity
  Serial.print("💧 Humidity:    ");
  if (status == 0) {
    Serial.print(data.humidity, 1);
    Serial.println("%");
  } else {
    Serial.println("ERROR - No data");
  }
  
  // ✅ Status
  Serial.print("📡 Status:      ");
  switch (status) {
    case DHTesp::ERROR_NONE:
      Serial.println("0 - OK ✅");
      break;
    case DHTesp::ERROR_TIMEOUT:
      Serial.println("1 - TIMEOUT ❌ (Kiểm tra đấu dây!)");
      break;
    case DHTesp::ERROR_CHECKSUM:
      Serial.println("2 - CHECKSUM ERROR ❌ (Lỗi dữ liệu)");
      break;
    default:
      Serial.print(status);
      Serial.println(" - UNKNOWN ERROR ❌");
      break;
  }
  
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
  
  // 🔥 CẢNH BÁO nếu có lỗi
  if (status != 0) {
    Serial.println("⚠️  CẢNH BÁO: Cảm biến không hoạt động!");
    Serial.println("   Kiểm tra:");
    Serial.println("   1. VCC nối đúng 3.3V hoặc 5V");
    Serial.println("   2. GND nối đúng GND");
    Serial.println("   3. DATA nối đúng GPIO4");
    Serial.println("   4. Có resistor 10kΩ giữa VCC và DATA không?");
    Serial.println("   5. Cảm biến có bị hỏng không?\n");
  }
}
