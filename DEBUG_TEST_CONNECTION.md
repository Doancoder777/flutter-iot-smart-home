# 🐛 Debug Test Connection Issues

## 🔍 Vấn đề hiện tại

**Triệu chứng:**
- ✅ Thêm thiết bị OK
- ✅ Bật/tắt thiết bị → MQTT có hiện cmd
- ❌ Test Connection → Không gửi ping lên MQTT

---

## 📊 Debug Logs

### **Đã thêm MqttDebugManager với log chi tiết:**

```dart
═══════════════════════════════════════
🧪 TEST CONNECTION START
═══════════════════════════════════════

🔌 [DEBUG] Connecting device: den_phong_khach
   ID: test_1234567890
   Broker: broker.hivemq.com:1883
   DeviceID: ESP32_A4CF12
   Result: ✅ Connected / ❌ Failed

📥 [DEBUG] Subscribing...
   DeviceID: test_1234567890
   Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/state

📤 [DEBUG] Publishing...
   DeviceID: test_1234567890
   Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/ping
   Message: ping
   Result: ✅ Published / ❌ Failed

⏳ Waiting for pong (3 seconds)...

═══════════════════════════════════════
🧪 TEST RESULT: SUCCESS ✅ / FAILED ⚠️
═══════════════════════════════════════
```

---

## 🧪 Test Steps

### **1. Build và chạy app với log:**
```bash
flutter run --debug
```

### **2. Bấm "Test Connection" và xem log**

#### **Scenario A: Connect thất bại**
```
🔌 [DEBUG] Connecting device: den_phong_khach
   ID: test_1234567890
   Broker: broker.hivemq.com:1883
   DeviceID: ESP32_A4CF12
   Result: ❌ Failed

❌ Exception: Không thể kết nối MQTT Broker
```

**Nguyên nhân:**
- Username/Password sai
- Broker URL sai
- Port sai
- Network issue

**Fix:**
- Kiểm tra credentials
- Test với MQTTX trước

---

#### **Scenario B: Connect OK nhưng Publish failed**
```
🔌 [DEBUG] Connecting device: den_phong_khach
   Result: ✅ Connected

📥 [DEBUG] Subscribing...
   Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/state

📤 [DEBUG] Publishing...
   DeviceID: test_1234567890
   Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/ping
   Message: ping
   Result: ❌ Failed
   
   ⚠️ Checking device state...
   Connected: false  ← 🚨 DEVICE DISCONNECTED!
```

**Nguyên nhân:**
- Device connected → Nhưng bị disconnect trước khi publish
- Race condition: Subscribe chưa xong đã publish
- Broker kicked device (HiveMQ 1-connection limit?)

**Fix:**
- Tăng delay sau khi connect
- Kiểm tra HiveMQ connection limit

---

#### **Scenario C: Publish OK nhưng no response**
```
📤 [DEBUG] Publishing...
   Result: ✅ Published

📩 [DEBUG] Message received  ← KHÔNG THẤY LOG NÀY!
   
⏳ Waiting for pong (3 seconds)...

🧪 TEST RESULT: FAILED ⚠️
```

**Nguyên nhân:**
- Ping đã gửi lên MQTT
- ESP32 không trả lời (offline hoặc code sai)
- Subscribe topic sai

**Fix:**
- Kiểm tra MQTTX xem có ping message không
- Check ESP32 Serial Monitor
- Verify topic structure

---

## 🛠️ Debug với MQTTX

### **1. Subscribe tất cả messages:**
```
Topic: smart_home/devices/#
```

### **2. Bấm Test Connection, xem có message nào không:**

#### **Nếu không thấy gì:**
→ App không publish lên MQTT
→ Check logs: `📤 [DEBUG] Publishing... Result: ❌ Failed`

#### **Nếu thấy ping nhưng không có pong:**
```
✅ Received: smart_home/devices/ESP32_A4CF12/den_phong_khach/ping = "ping"
❌ KHÔNG có: .../state = "online"
```
→ ESP32 không trả lời
→ Check ESP32 code

#### **Nếu thấy cả ping và pong:**
```
✅ .../ping = "ping"
✅ .../state = "online"
```
→ App không nhận được message
→ Subscribe callback không chạy

---

## 🔧 Quick Fixes

### **Fix 1: Tăng delay sau connect**
```dart
final connected = await mqttManager.connectDevice(testDevice);
await Future.delayed(const Duration(seconds: 2));  // ← Tăng từ 0.5s lên 2s
```

### **Fix 2: Check connection state trước publish**
```dart
final pingTopic = testDevice.mqttPingTopic;
debugPrint('Checking connection before publish...');

if (!mqttManager.isDeviceConnected(testDevice.id)) {
  throw Exception('Device disconnected before publish!');
}

debugPrint('Device still connected, publishing...');
mqttManager.publishToDevice(testDevice.id, pingTopic, 'ping');
```

### **Fix 3: Subscribe callback với timeout**
```dart
bool callbackCalled = false;

mqttManager.subscribeToTopic(testDevice.id, stateTopic, (topic, message) {
  callbackCalled = true;
  debugPrint('✅ Callback được gọi!');
  if (message == 'online' || message == '1') {
    receivedPong = true;
  }
});

await Future.delayed(const Duration(seconds: 3));

debugPrint('Callback called: $callbackCalled');
debugPrint('Received pong: $receivedPong');
```

---

## 📝 Action Items

### **Ngay bây giờ:**
1. ✅ Chạy app với debug logs
2. ✅ Bấm Test Connection
3. ✅ Copy full logs và paste vào chat
4. ✅ Mở MQTTX, subscribe `smart_home/devices/#`
5. ✅ Bấm Test Connection lần nữa, xem MQTTX có nhận message không

### **Để tìm root cause:**
- [ ] Nếu MQTTX **KHÔNG** thấy ping → App không publish (check connect state)
- [ ] Nếu MQTTX **CÓ** ping nhưng app failed → Subscribe callback issue
- [ ] Nếu MQTTX **CÓ** cả ping+pong → App subscribe sai topic

---

## 🎯 Expected Logs (Thành công)

```
═══════════════════════════════════════
🧪 TEST CONNECTION START
═══════════════════════════════════════

🔌 [DEBUG] Connecting device: den_phong_khach
   ID: test_1234567890
   Broker: broker.hivemq.com:1883
   DeviceID: ESP32_A4CF12
   Result: ✅ Connected

📥 [DEBUG] Subscribing...
   DeviceID: test_1234567890
   Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/state

📤 [DEBUG] Publishing...
   DeviceID: test_1234567890
   Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/ping
   Message: ping
   Result: ✅ Published

⏳ Waiting for pong (3 seconds)...

📩 [DEBUG] Message received
   Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/state
   Message: online

✅ Step 2: Device responded to ping!

═══════════════════════════════════════
🧪 TEST RESULT: SUCCESS ✅
═══════════════════════════════════════
```

---

**Hành động tiếp theo:** Paste logs từ app vào chat để phân tích! 📊
