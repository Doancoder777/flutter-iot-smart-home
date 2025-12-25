void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("==== ESP32-S3 CHIP INFO ====");
  Serial.printf("Model: %s\n", ESP.getChipModel());
  Serial.printf("Cores: %d\n", ESP.getChipCores());
  Serial.printf("Revision: %d\n", ESP.getChipRevision());

  Serial.printf("Flash Size sigma sigmaa: %d MB\n", ESP.getFlashChipSize() / (1024*1024));
  Serial.printf("Flash Speed: %d MHz\n", ESP.getFlashChipSpeed() / 1000000);

  Serial.printf("PSRAM: %d bytes\n", ESP.getPsramSize());
}

void loop() {}
