# 🔍 DEBUG SENSOR LOGS - Tìm logs liên quan đến sensor DHT22_001
# Chạy script này trong terminal PowerShell để filter logs

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🔍 DEBUG SENSOR DATA FLOW - DHT22_001                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Instructions
Write-Host "📋 HƯỚNG DẪN DEBUG:" -ForegroundColor Yellow
Write-Host "1. Mở VS Code Debug Console (Ctrl + Shift + Y)" -ForegroundColor White
Write-Host "2. Scroll lên tìm các log pattern bên dưới" -ForegroundColor White
Write-Host "3. Hoặc copy toàn bộ logs và search (Ctrl + F)`n" -ForegroundColor White

# Pattern to search
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ LOGS CẦN TÌM (Search in Debug Console)                ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

$patterns = @(
    "📨 handleMqttMessage",
    "🔍 Searching sensor by device code",
    "✅ Found sensor by device code",
    "📊 Parsed JSON value",
    "✅ Updated sensor",
    "📡 Received real-time sensor update",
    "❌ No sensor found",
    "⚠️ handleMqttMessage error"
)

foreach ($pattern in $patterns) {
    Write-Host "   🔎 Search: '$pattern'" -ForegroundColor Cyan
}

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  🧪 STEP-BY-STEP DEBUG                                     ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

Write-Host "STEP 1: Check MQTT Connection" -ForegroundColor Yellow
Write-Host "   → In app: Settings → MQTT" -ForegroundColor White
Write-Host "   → Status should be: 'Connected' ✅" -ForegroundColor White
Write-Host "   → If 'Disconnected': Tap 'Kết nối' button`n" -ForegroundColor White

Write-Host "STEP 2: Check Sensor Exists" -ForegroundColor Yellow
Write-Host "   → In app: Sensors Screen" -ForegroundColor White
Write-Host "   → Find sensor with name containing 'Nhiệt độ' or 'DHT22'" -ForegroundColor White
Write-Host "   → Tap sensor → Check 'Mã thiết bị' = 'DHT22_001' ✅`n" -ForegroundColor White

Write-Host "STEP 3: Publish MQTT Message (MQTTX)" -ForegroundColor Yellow
Write-Host "   → Topic:   smart_home/sensors/DHT22_001/state" -ForegroundColor White
Write-Host "   → Payload: {""type"":""temperature"",""value"":25.5}" -ForegroundColor White
Write-Host "   → QoS:     1 (At least once)" -ForegroundColor White
Write-Host "   → Click 'Publish' button ✅`n" -ForegroundColor White

Write-Host "STEP 4: Watch Debug Console (VS Code)" -ForegroundColor Yellow
Write-Host "   → Should see logs IMMEDIATELY after publish:" -ForegroundColor White
Write-Host "      📨 handleMqttMessage: topic=smart_home/sensors/DHT22_001/state" -ForegroundColor Gray
Write-Host "      🔍 Searching sensor by device code: DHT22_001" -ForegroundColor Gray
Write-Host "      ✅ Found sensor by device code: Nhiệt độ (temperature)" -ForegroundColor Gray
Write-Host "      📊 Final value (double): 25.5" -ForegroundColor Gray
Write-Host "      ✅ Updated sensor: Nhiệt độ = 25.5" -ForegroundColor Gray
Write-Host "      📡 Received real-time sensor update: 1 sensors`n" -ForegroundColor Gray

Write-Host "STEP 5: Check UI Update" -ForegroundColor Yellow
Write-Host "   → In app: Sensors Screen" -ForegroundColor White
Write-Host "   → Card 'Cảm biến thời tiết' should show:" -ForegroundColor White
Write-Host "      🌡️ Nhiệt độ" -ForegroundColor Gray
Write-Host "      25.5°C          ← NEW VALUE! ✅" -ForegroundColor Green
Write-Host "      Cập nhật: vài giây trước`n" -ForegroundColor Gray

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║  ❌ TROUBLESHOOTING - Nếu không thấy logs                 ║" -ForegroundColor Red
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Red

Write-Host "Problem 1: No '📨 handleMqttMessage' log" -ForegroundColor Yellow
Write-Host "   → MQTT not connected!" -ForegroundColor Red
Write-Host "   → Fix: Settings → MQTT → Tap 'Kết nối' button" -ForegroundColor White
Write-Host "   → Check log: '✅ MQTT: Connected callback'`n" -ForegroundColor White

Write-Host "Problem 2: Log says '❌ No sensor found'" -ForegroundColor Yellow
Write-Host "   → Device code không khớp!" -ForegroundColor Red
Write-Host "   → Check: Sensor 'Mã thiết bị' = 'DHT22_001' exactly" -ForegroundColor White
Write-Host "   → Case-sensitive! DHT22_001 ≠ dht22_001`n" -ForegroundColor White

Write-Host "Problem 3: Log says '⚠️ handleMqttMessage error'" -ForegroundColor Yellow
Write-Host "   → JSON format sai!" -ForegroundColor Red
Write-Host "   → Check payload: {""type"":""temperature"",""value"":25.5}" -ForegroundColor White
Write-Host "   → Must have 'value' key!`n" -ForegroundColor White

Write-Host "Problem 4: Logs OK but UI không update" -ForegroundColor Yellow
Write-Host "   → Firestore listener issue!" -ForegroundColor Red
Write-Host "   → Fix: Hot restart app (R in terminal)" -ForegroundColor White
Write-Host "   → Or: Navigate away and back to Sensors Screen`n" -ForegroundColor White

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  🎯 QUICK TEST COMMANDS                                    ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Test với giá trị khác nhau (publish từ MQTTX):" -ForegroundColor Yellow
Write-Host ""
Write-Host "   // Test 1: Nhiệt độ 26.0°C" -ForegroundColor Cyan
Write-Host "   {""type"":""temperature"",""value"":26.0}" -ForegroundColor White
Write-Host ""
Write-Host "   // Test 2: Nhiệt độ 27.5°C" -ForegroundColor Cyan
Write-Host "   {""type"":""temperature"",""value"":27.5}" -ForegroundColor White
Write-Host ""
Write-Host "   // Test 3: Nhiệt độ 30.0°C" -ForegroundColor Cyan
Write-Host "   {""type"":""temperature"",""value"":30.0}" -ForegroundColor White
Write-Host ""
Write-Host "   → UI should update REALTIME after each publish! ⚡`n" -ForegroundColor Green

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  📊 LOG ANALYSIS COMMANDS (In VS Code Terminal)            ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

Write-Host "Sau khi publish message, check logs bằng các lệnh sau:`n" -ForegroundColor Yellow

Write-Host "# 1. Filter sensor-related logs (copy output từ Debug Console)" -ForegroundColor Cyan
Write-Host 'Select-String -Pattern "DHT22_001|handleMqttMessage|Found sensor" -InputObject $logs' -ForegroundColor White
Write-Host ""

Write-Host "# 2. Count messages received" -ForegroundColor Cyan
Write-Host 'Select-String -Pattern "📨 handleMqttMessage" -InputObject $logs | Measure-Object' -ForegroundColor White
Write-Host ""

Write-Host "# 3. Check for errors" -ForegroundColor Cyan
Write-Host 'Select-String -Pattern "❌|⚠️|error" -InputObject $logs' -ForegroundColor White
Write-Host ""

Write-Host "`n═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
Write-Host "🎯 BẮT ĐẦU DEBUG:" -ForegroundColor Green -BackgroundColor Black
Write-Host "1. Run app: flutter run --debug (if not running)" -ForegroundColor White
Write-Host "2. Open MQTTX → Publish message" -ForegroundColor White
Write-Host "3. Watch Debug Console trong VS Code" -ForegroundColor White
Write-Host "4. Look for '📨 handleMqttMessage' log" -ForegroundColor White
Write-Host "5. Check sensor card in app - Value should change!" -ForegroundColor White
Write-Host "`n═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Offer to open Debug Console
Write-Host "💡 TIP: Bấm Ctrl + Shift + Y để mở Debug Console trong VS Code`n" -ForegroundColor Yellow

# Wait for user
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
