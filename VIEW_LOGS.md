# 📊 XEM LOGS KHI TEST VOICE CONTROL

## 🎯 Cách xem logs real-time:

### Cách 1: Xem tất cả logs
```powershell
flutter logs
```

### Cách 2: Filter chỉ xem debug info (KHUYẾN NGHỊ)
```powershell
flutter logs | Select-String "DEBUG INFO|BẠN NÓI|SUCCESS|FAILED"
```

### Cách 3: Lưu logs ra file
```powershell
flutter logs > voice_logs.txt
```

---

## 📝 OUTPUT MẪU KHI TEST:

### ✅ KHI THÀNH CÔNG:

```
═══════════════════════════════════════
🔍 DEBUG INFO:
   Command: "Nhiệt độ bao nhiêu?"
   User ID: abc123
   Devices count: 8
   Sensor data (REAL from ESP32):
      Temperature: 26.2°C
      Humidity: 100.0%
      Rain: 0
      Light: 450 lux
      Gas: 120 ppm
      Dust: 0
═══════════════════════════════════════
🤖 AI Voice: Processing command: "Nhiệt độ bao nhiêu?"
🤖 AI Voice: Available devices: 8
🤖 AI Voice: Sensor data included: true
💰 Token saved: 0
✅ AI Voice: Sensor Query - temperature: 26.2
═══════════════════════════════════════
📥 AI RESULT:
   Success: true
   Response Type: ResponseType.sensorQuery
   Sensor Type: temperature
   Sensor Value: 26.2
═══════════════════════════════════════

✅✅✅ SUCCESS! ✅✅✅
📝 BẠN NÓI: "Nhiệt độ bao nhiêu?"
🎯 LOẠI: Hỏi cảm biến
📡 CẢM BIẾN: temperature
📊 GIÁ TRỊ: 26.2
🔄 Formatting sensor data...
   Input: temperature = 26.2
   Output: 🌡️ Nhiệt độ: 26.2°C (Mát)
💬 HIỂN THỊ: 🌡️ Nhiệt độ: 26.2°C (Mát)
✅✅✅✅✅✅✅✅✅✅✅✅✅
```

---

### ❌ KHI THẤT BẠI:

```
═══════════════════════════════════════
🔍 DEBUG INFO:
   Command: "xyz abc 123"
   User ID: abc123
   Devices count: 8
   Sensor data (REAL from ESP32):
      Temperature: 26.2°C
      Humidity: 100.0%
      ...
═══════════════════════════════════════
🤖 AI Voice: Processing command: "xyz abc 123"
❌ AI Voice: Failed - Không hiểu lệnh
═══════════════════════════════════════
📥 AI RESULT:
   Success: false
   Error: Không hiểu lệnh
═══════════════════════════════════════

❌❌❌ FAILED! ❌❌❌
📝 BẠN NÓI: "xyz abc 123"
⚠️ LỖI: Không hiểu lệnh
❌❌❌❌❌❌❌❌❌❌❌❌❌
```

---

## 🔍 PHÂN TÍCH LOGS:

### 1️⃣ Kiểm tra Sensor Data:
```
Sensor data (REAL from ESP32):
   Temperature: 26.2°C  ← ✅ KHÔNG PHẢI 0!
   Humidity: 100.0%     ← ✅ KHÔNG PHẢI 0!
```

**NẾU TẤT CẢ = 0:**
→ ESP32 chưa gửi data, cần kiểm tra MQTT connection

---

### 2️⃣ Kiểm tra AI có nhận sensor data không:
```
🤖 AI Voice: Sensor data included: true  ← ✅ PHẢI LÀ TRUE!
```

**NẾU = false khi hỏi về sensor:**
→ Keyword không match, AI nghĩ đây là device control

---

### 3️⃣ Kiểm tra kết quả AI:
```
📥 AI RESULT:
   Success: true                          ← ✅
   Response Type: ResponseType.sensorQuery ← ✅
   Sensor Type: temperature               ← ✅
   Sensor Value: 26.2                     ← ✅
```

**NẾU Success = false:**
→ Xem field "Error" để biết lý do

---

### 4️⃣ Kiểm tra UI hiển thị:
```
💬 HIỂN THỊ: 🌡️ Nhiệt độ: 26.2°C (Mát)
```

**NẾU không hiển thị:**
→ Lỗi format hoặc setState

---

## 🧪 TEST CASES ĐỂ THỬ:

### Test 1: Hỏi nhiệt độ
```
Input: "Nhiệt độ bao nhiêu?"
Expected: 🌡️ Nhiệt độ: XX°C (Mát/Ấm/Nóng/Lạnh)
```

### Test 2: Hỏi độ ẩm
```
Input: "Độ ẩm thế nào?"
Expected: 💧 Độ ẩm: XX% (Khô/Bình thường/Ẩm)
```

### Test 3: Hỏi có nóng không
```
Input: "Có nóng không?"
Expected: 🌡️ Nhiệt độ: XX°C (+ đánh giá)
```

### Test 4: Bật đèn
```
Input: "Bật đèn phòng ngủ"
Expected: ✅ Đã bật Đèn phòng ngủ
```

---

## 🚀 QUICK COMMANDS:

```powershell
# 1. Chạy app debug mode
flutter run --debug

# 2. Xem logs (terminal khác)
flutter logs | Select-String "BẠN NÓI"

# 3. Hot reload khi sửa code
r

# 4. Restart app
R

# 5. Quit
q
```

---

## 📸 LƯU LOGS ĐỂ DEBUG:

```powershell
# Lưu tất cả logs
flutter logs > all_logs.txt

# Lưu chỉ debug logs
flutter logs | Select-String "DEBUG|SUCCESS|FAILED" > debug_logs.txt

# Xem logs real-time và lưu đồng thời
flutter logs | Tee-Object -FilePath logs.txt
```

---

## 💡 TIPS:

1. **Mở 2 terminal:**
   - Terminal 1: `flutter run --debug`
   - Terminal 2: `flutter logs | Select-String "BẠN NÓI"`

2. **Filter logs hiệu quả:**
   ```powershell
   # Chỉ xem success
   flutter logs | Select-String "SUCCESS"
   
   # Chỉ xem failed
   flutter logs | Select-String "FAILED"
   
   # Xem cả hai
   flutter logs | Select-String "SUCCESS|FAILED"
   ```

3. **Clear logs cũ:**
   ```powershell
   flutter logs --clear
   ```

---

## 🐛 TROUBLESHOOTING:

### Không thấy logs gì:
```powershell
# Check app có đang chạy không
flutter devices

# Restart logs
Ctrl+C (stop logs)
flutter logs (start again)
```

### Logs bị ngắt quãng:
```powershell
# Tăng buffer size
flutter logs --verbose
```

### Muốn xem logs chi tiết hơn:
```powershell
flutter logs -v
```
