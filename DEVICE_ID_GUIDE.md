# 📱 Hướng dẫn sử dụng Device ID trong Smart Home App

## 🎯 Tổng quan

App đã được nâng cấp để hỗ trợ **Device ID** (ID ESP32), giúp:
- ✅ Một ESP32 điều khiển nhiều thiết bị (đèn, quạt, servo, cảm biến...)
- ✅ Không cho phép trùng tên thiết bị trong cùng 1 ESP32
- ✅ Phòng (Room) vẫn được giữ để người dùng dễ phân loại giao diện
- ✅ Topic structure chuẩn cho production

---

## 📊 So sánh Old vs New

### ⚠️ Cách cũ (Không dùng Device ID)
```
Topic: smart_home/devices/phong_khach/den_1
```
**Vấn đề:**
- ❌ Mỗi thiết bị cần 1 ESP32 riêng
- ❌ ESP32 không biết room của người dùng (phòng khách, phòng ngủ...)
- ❌ Khó mở rộng

### ✅ Cách mới (Dùng Device ID)
```
Topic: smart_home/devices/ESP32_A4CF12/den_1/cmd
       smart_home/devices/ESP32_A4CF12/quat_tran/cmd
       smart_home/devices/ESP32_A4CF12/servo_cua/cmd
```
**Ưu điểm:**
- ✅ 1 ESP32 điều khiển nhiều thiết bị
- ✅ ESP32 chỉ cần biết Device ID của nó (từ MAC address)
- ✅ Room chỉ dùng cho UI (người dùng tự phân loại)
- ✅ Dễ debug, dễ mở rộng

---

## 🔧 Cách tạo Device ID trong ESP32

### **Phương pháp 1: Tự động từ MAC Address** (Khuyên dùng)

```cpp
#include <WiFi.h>
#include <PubSubClient.h>

String deviceId;
WiFiClient espClient;
PubSubClient mqttClient(espClient);

void setup() {
  Serial.begin(115200);
  
  // Tạo Device ID từ MAC address
  uint8_t mac[6];
  WiFi.macAddress(mac);
  deviceId = "ESP32_";
  for (int i = 0; i < 6; i++) {
    char buf[3];
    sprintf(buf, "%02X", mac[i]);
    deviceId += String(buf);
  }
  
  Serial.println("╔════════════════════════════════╗");
  Serial.println("║    SMART HOME DEVICE          ║");
  Serial.println("╠════════════════════════════════╣");
  Serial.print  ("║ Device ID: ");
  Serial.print(deviceId);
  Serial.println("     ║");
  Serial.println("╚════════════════════════════════╝");
  
  // Kết nối WiFi và MQTT
  connectWiFi();
  connectMQTT();
}

void connectMQTT() {
  mqttClient.setServer("broker.hivemq.com", 1883);
  mqttClient.setCallback(mqttCallback);
  
  while (!mqttClient.connected()) {
    if (mqttClient.connect(deviceId.c_str())) {
      Serial.println("✅ MQTT Connected!");
      
      // Subscribe all device topics
      String baseTopic = "smart_home/devices/" + deviceId + "/";
      mqttClient.subscribe((baseTopic + "den_phong_khach/cmd").c_str());
      mqttClient.subscribe((baseTopic + "quat_tran/cmd").c_str());
      mqttClient.subscribe((baseTopic + "servo_cua/cmd").c_str());
      mqttClient.subscribe((baseTopic + "+/ping").c_str()); // Wildcard
    }
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String topicStr = String(topic);
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  String baseTopic = "smart_home/devices/" + deviceId + "/";
  
  // Xử lý từng thiết bị
  if (topicStr == baseTopic + "den_phong_khach/cmd") {
    digitalWrite(LED_PIN, message == "1" ? HIGH : LOW);
    mqttClient.publish((baseTopic + "den_phong_khach/state").c_str(), message.c_str());
  }
  else if (topicStr == baseTopic + "quat_tran/cmd") {
    digitalWrite(FAN_PIN, message == "1" ? HIGH : LOW);
    mqttClient.publish((baseTopic + "quat_tran/state").c_str(), message.c_str());
  }
  else if (topicStr == baseTopic + "servo_cua/cmd") {
    int angle = message.toInt();
    doorServo.write(angle);
    mqttClient.publish((baseTopic + "servo_cua/state").c_str(), message.c_str());
  }
  else if (topicStr.endsWith("/ping")) {
    // Trả lời ping
    String deviceName = extractDeviceName(topicStr);
    String stateTopic = baseTopic + deviceName + "/state";
    mqttClient.publish(stateTopic.c_str(), "online");
  }
}

String extractDeviceName(String topic) {
  // Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/ping
  // Return: den_phong_khach
  int lastSlash = topic.lastIndexOf('/');
  int secondLastSlash = topic.lastIndexOf('/', lastSlash - 1);
  return topic.substring(secondLastSlash + 1, lastSlash);
}

void loop() {
  if (!mqttClient.connected()) {
    connectMQTT();
  }
  mqttClient.loop();
}
```

---

## 📱 Cách sử dụng trong Flutter App

### **1. Thêm thiết bị mới**

1. Mở app → **Thêm thiết bị**
2. Nhập thông tin:
   - **Tên thiết bị**: `den_phong_khach` *(không dấu, dùng _ thay khoảng trắng)*
   - **Display Name**: `Đèn phòng khách` *(tên hiển thị cho người dùng)*
   - **Phòng**: `Phòng khách` *(dùng để phân loại UI)*
   - **ESP32 Device ID**: `ESP32_A4CF12B23D5E` *(copy từ Serial Monitor của ESP32)*
   - **MQTT Broker**: `broker.hivemq.com`

3. **Validation tự động**:
   - ✅ Không cho trùng tên trong cùng ESP32
   - ✅ Device ID phải bắt đầu bằng `ESP32_`

### **2. Kiểm tra trong MQTTX**

```bash
# Subscribe tất cả topic của 1 ESP32
smart_home/devices/ESP32_A4CF12/#

# Kết quả:
smart_home/devices/ESP32_A4CF12/den_phong_khach/cmd
smart_home/devices/ESP32_A4CF12/den_phong_khach/state
smart_home/devices/ESP32_A4CF12/quat_tran/cmd
smart_home/devices/ESP32_A4CF12/quat_tran/state
```

---

## 🎨 UI Flow

### **Home Screen - Phân loại theo Room**

```
📍 Phòng khách
├── 💡 Đèn phòng khách (ESP32_A4CF12)
├── 🌀 Quạt trần (ESP32_A4CF12)
└── 🚪 Servo cửa (ESP32_A4CF12)

📍 Phòng ngủ
├── 💡 Đèn ngủ (ESP32_B1D423)
└── ❄️ Quạt hơi (ESP32_B1D423)
```

**Lưu ý:** Mặc dù UI hiển thị theo Room, nhưng topic MQTT **không có Room**, chỉ có Device ID!

---

## 🧪 Test Connection

App hỗ trợ **Test Connection** bằng ping-pong:

```dart
// App gửi ping
Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/ping
Payload: "ping"

// ESP32 trả lời
Topic: smart_home/devices/ESP32_A4CF12/den_phong_khach/state
Payload: "online"
```

---

## 🚨 Validation Rules

### **1. Không được trùng tên trong cùng ESP32**

```dart
❌ Lỗi:
ESP32_A4CF12
├── den_1
└── den_1  // ❌ TRÙNG TÊN

✅ Đúng:
ESP32_A4CF12
├── den_1
└── den_2
```

### **2. Room chỉ dùng cho UI**

```dart
// Cùng ESP32, khác room → OK
ESP32_A4CF12
├── den_1 (Phòng khách)
└── den_1 (Phòng ngủ)  // ❌ VẪN LÀ TRÙNG TÊN

// Phải đặt tên khác:
ESP32_A4CF12
├── den_phong_khach
└── den_phong_ngu  // ✅ OK
```

---

## 🤖 Tích hợp Gemini AI (Future)

```dart
User: "Bật đèn phòng khách"

App:
1. Tra mapping: "Đèn phòng khách" → Device ID: ESP32_A4CF12, Name: den_phong_khach
2. Publish: smart_home/devices/ESP32_A4CF12/den_phong_khach/cmd = "1"
3. ESP32 nhận và bật đèn
4. ESP32 trả feedback: .../state = "1"
5. App hiển thị: "✅ Đã bật đèn phòng khách"
```

---

## 📊 Topic Structure

```
smart_home/devices/{device_id}/{device_name}/{function}

Trong đó:
- device_id: ESP32_A4CF12 (từ MAC address)
- device_name: den_phong_khach (tên kỹ thuật, không dấu)
- function: cmd | state | ping
```

**Ví dụ đầy đủ:**

```
Command:  smart_home/devices/ESP32_A4CF12/den_phong_khach/cmd
State:    smart_home/devices/ESP32_A4CF12/den_phong_khach/state
Ping:     smart_home/devices/ESP32_A4CF12/den_phong_khach/ping
```

---

## 🔄 Migration từ Old → New

### **Nếu đang dùng cách cũ (không có Device ID)**

1. **Không bắt buộc phải đổi ngay** - App vẫn hỗ trợ backward compatibility
2. Khi thêm Device ID, app sẽ tự động dùng topic structure mới
3. Nếu không có Device ID, app fallback về topic cũ

### **Code trong Device Model**

```dart
String get mqttCommandTopic {
  if (deviceId == null) {
    // Fallback to old format
    return 'smart_home/devices/${_cleanDeviceName}/cmd';
  }
  // New format
  return 'smart_home/devices/$deviceId/${_cleanDeviceName}/cmd';
}
```

---

## 📝 Checklist cho Production

- [ ] In nhãn dán Device ID lên từng ESP32
- [ ] Update firmware ESP32 với code generate Device ID từ MAC
- [ ] Test ping-pong connection
- [ ] Test điều khiển nhiều thiết bị trên 1 ESP32
- [ ] Test validation không cho trùng tên
- [ ] Test MQTTX subscribe wildcard: `smart_home/devices/ESP32_A4CF12/#`
- [ ] Document cho người dùng cách nhập Device ID

---

## 🎯 Next Steps

1. ✅ **Done**: Update Device Model + Add Device UI
2. 🔄 **In Progress**: Test với ESP32 thật
3. ⏳ **Todo**: Tích hợp Gemini AI
4. ⏳ **Todo**: QR Code scan để nhập Device ID nhanh
5. ⏳ **Todo**: Migration sang Firebase storage

---

## 💡 Tips

### **Đặt tên thiết bị (device_name)**
- ✅ `den_phong_khach`, `quat_tran`, `servo_cua`
- ❌ `Đèn phòng khách` (có dấu, có khoảng trắng)

### **Display Name (hiển thị UI)**
- ✅ Dùng thoải mái tiếng Việt có dấu
- VD: "Đèn phòng khách", "Quạt trần phòng ngủ"

### **Room (phòng)**
- ✅ Chỉ dùng để phân loại UI
- ✅ Không ảnh hưởng đến topic MQTT
- VD: "Phòng khách", "Phòng ngủ", "Bếp"

---

**Tác giả:** GitHub Copilot  
**Ngày cập nhật:** 2025-10-14
