# 📊 HƯỚNG DẪN TEST REAL-TIME SENSOR UPDATE

## 🐞 **Bug đã phát hiện và sửa:**

### **Vấn đề:**
App **KHÔNG** cập nhật real-time khi ESP32 gửi dữ liệu cảm biến lên MQTT!

### **Nguyên nhân:**
- User thêm sensor với topic: `smart_home/devices/DHT22_001/cmd`
- Arduino gửi dữ liệu đến: `smart_home/devices/DHT22_001/state` 
- Code tìm sensor bằng `s.mqttTopic == topic` → **KHÔNG KHỚP!**

### **Đã sửa:**
✅ Logic tìm sensor giờ hỗ trợ:
1. Tìm theo **exact topic** (backward compatibility)
2. Nếu không thấy, tìm theo **device code** (DHT22_001)

---

## 🧪 **Cách test:**

### **1️⃣ Chuẩn bị:**

#### **A. Arduino ESP32:**
```arduino
// File: arduino/FullMQTT_Complete_Test.ino
// ĐANG COMMENT TOÀN BỘ - Cần uncomment trước khi upload

1. Copy toàn bộ nội dung file
2. Mở Arduino IDE
3. Paste và UNCOMMENT (xóa // ở đầu mỗi dòng)
4. Upload lên ESP32
```

**Thiết bị cần test:** DHT22 (Temperature/Humidity)
- Device code: `DHT22_001`
- Publish topic: `smart_home/devices/DHT22_001/state`
- JSON format: `{"type":"temperature","value":25.5,"timestamp":12345}`

#### **B. Flutter App:**
```bash
cd flutter-iot-smart-home
flutter run
```

---

### **2️⃣ Thêm sensor trong app:**

1. Mở app → **"Thêm cảm biến"**
2. Điền thông tin:
   - **Tên hiển thị:** `DHT22 Temperature`
   - **Loại cảm biến:** `Nhiệt độ` (Temperature)
   - **Device Code:** `DHT22_001` (QUAN TRỌNG!)
   - **MQTT Topic:** `smart_home/devices/DHT22_001/cmd`
3. Lưu sensor

---

### **3️⃣ Test real-time update:**

#### **Bước 1: Xem logs ESP32**
```
📊 Reading sensors...
   DHT22: 25.5°C, 60.0%
   Gas: 100 ppm
   ...
✅ Sensors published!
```

#### **Bước 2: Xem logs Flutter app** (Debug Console)
```
📨 handleMqttMessage: topic=smart_home/devices/DHT22_001/state, message={"type":"temperature","value":25.5,...}
🔍 Searching sensor by device code: DHT22_001
✅ Found sensor by device code: DHT22 Temperature (temperature)
📊 Parsed JSON value: 25.5
📊 Final value (double): 25.5
✅ Updated sensor: DHT22 Temperature = 25.5
```

#### **Bước 3: Kiểm tra UI update**

**A. Màn hình Dashboard:**
- Widget nhiệt độ hiển thị `25.5°C`
- Tự động cập nhật khi ESP32 gửi data mới (mỗi 5 phút)

**B. Màn hình Sensors:**
- Danh sách sensor hiển thị giá trị mới nhất
- `DHT22 Temperature: 25.5°C`

---

## 📋 **Checklist test đầy đủ:**

### ✅ **Test case 1: Sensor đúng device code**
- [ ] Thêm sensor với device code = `DHT22_001`
- [ ] ESP32 gửi data đến `smart_home/devices/DHT22_001/state`
- [ ] App nhận được message (xem logs)
- [ ] UI cập nhật giá trị mới
- [ ] **Kết quả mong đợi:** ✅ Hoạt động bình thường

### ✅ **Test case 2: Sensor sai device code**
- [ ] Thêm sensor với device code = `WRONG_CODE`
- [ ] ESP32 gửi data đến `smart_home/devices/DHT22_001/state`
- [ ] App nhận message nhưng không tìm thấy sensor
- [ ] **Kết quả mong đợi:** ❌ Logs hiển thị "No sensor found"

### ✅ **Test case 3: Multiple sensors cùng lúc**
- [ ] Thêm 3 sensors: DHT22_001, GAS_MQ2_001, SOIL_001
- [ ] ESP32 gửi data cho cả 3 sensors
- [ ] UI cập nhật đúng giá trị cho từng sensor
- [ ] **Kết quả mong đợi:** ✅ Tất cả sensors update

### ✅ **Test case 4: JSON parsing**
- [ ] ESP32 gửi JSON: `{"type":"temperature","value":25.5}`
- [ ] App parse đúng value = 25.5
- [ ] **Kết quả mong đợi:** ✅ Parse thành công

### ✅ **Test case 5: Plain text parsing**
- [ ] ESP32 gửi plain text: `25.5`
- [ ] App parse theo sensor dataType
- [ ] **Kết quả mong đợi:** ✅ Parse thành công

---

## 🔍 **Debug tips:**

### **1. Kiểm tra MQTT subscription:**
```dart
// File: lib/services/mqtt_service.dart (line 116)
subscribe('${MqttTopics.base}/devices/#');
// ✅ Đã subscribe đến smart_home/devices/# (tất cả sub-topics)
```

### **2. Kiểm tra topic format:**
```
✅ ĐÚNG: smart_home/devices/DHT22_001/state
❌ SAI:  smart_home/sensors/DHT22_001/state
❌ SAI:  devices/DHT22_001/state
```

### **3. Kiểm tra device code khớp:**
```dart
// Arduino
const char* SENSOR_DHT_CODE = "DHT22_001";

// App - phải khớp!
deviceCode: "DHT22_001"
```

### **4. Xem MQTT messages trên HiveMQ broker:**
- Login: https://console.hivemq.cloud
- Cluster: 16257efaa31f4843a11e19f83c34e594
- Web Client → Subscribe to `smart_home/devices/#`
- Xem messages ESP32 gửi lên

---

## 🚀 **Kết quả mong đợi sau khi fix:**

### **Trước fix:**
❌ ESP32 gửi data → App không nhận → UI không update
```
📨 handleMqttMessage: topic=smart_home/devices/DHT22_001/state
❌ No sensor found (vì tìm theo mqttTopic = .../cmd)
```

### **Sau fix:**
✅ ESP32 gửi data → App nhận → UI update real-time
```
📨 handleMqttMessage: topic=smart_home/devices/DHT22_001/state
🔍 Searching by device code: DHT22_001
✅ Found sensor by device code
✅ Updated sensor: DHT22 Temperature = 25.5
```

---

## 📌 **Lưu ý quan trọng:**

1. **Device code phải khớp chính xác:**
   - Arduino: `DHT22_001`
   - App: `DHT22_001`
   - **KHÔNG** được viết `dht22_001` hay `DHT22001`

2. **Topic format chuẩn:**
   - App MQTT topic (lưu): `smart_home/devices/{CODE}/cmd`
   - Arduino publish: `smart_home/devices/{CODE}/state`
   - Code match theo `{CODE}`, không cần full topic khớp

3. **JSON format từ Arduino:**
   ```json
   {
     "type": "temperature",
     "value": 25.5,
     "timestamp": 12345
   }
   ```
   - Key `value` là BẮT BUỘC
   - Key `type` là optional (để identify sensor type)

4. **Interval gửi data:**
   - Hiện tại: 5 phút (300000ms)
   - Để test nhanh, có thể giảm xuống 10s (10000ms) trong Arduino code

---

## 🐞 **Nếu vẫn không hoạt động:**

### **Kiểm tra logs Flutter:**
```
📨 handleMqttMessage: topic=..., message=...
🔍 Searching sensor by device code: XXX
❌ No sensor found with device code: XXX
```

→ **Nguyên nhân:** Device code trong app không khớp với Arduino

### **Kiểm tra logs Arduino:**
```
✅ MQTT: Connected successfully!
📥 Subscribed to all topics
📊 Reading sensors...
✅ Sensors published!
```

→ **Nguyên nhân:** ESP32 chưa publish data, hoặc publish sai topic

### **Kiểm tra Firestore:**
- Mở Firestore Console
- Collection: `users/{userId}/sensors`
- Document của sensor
- Check field `deviceCode` khớp với Arduino không

---

## ✅ **Kết luận:**

**Bug đã được fix!** Giờ app sẽ nhận và cập nhật real-time từ ESP32.

**Điều quan trọng:** Device code phải khớp chính xác giữa Arduino và App!

---

Tạo bởi: GitHub Copilot  
Ngày: 30/10/2025
