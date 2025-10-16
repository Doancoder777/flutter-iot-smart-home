# 🧪 Hướng dẫn Test Tính năng MQTT Riêng cho Thiết bị

## 📋 Tổng quan
Tính năng này cho phép mỗi thiết bị có thể kết nối đến broker MQTT riêng thay vì sử dụng broker global.

## 🔍 Debug Logs
Khi điều khiển thiết bị, bạn sẽ thấy các log sau trong console:

### Thiết bị có cấu hình MQTT riêng:
```
🔍 DEBUG: Device [Tên thiết bị] - hasCustomMqttConfig: true
🔍 DEBUG: Custom MQTT Config - Broker: [broker]:[port]
🔍 DEBUG: Custom Topic: [topic]
🔄 Device MQTT: Connecting to [broker]:[port] for device [Tên thiết bị]...
✅ Device MQTT: Connected to [broker] for device [Tên thiết bị]
📤 Device MQTT: Published to [topic]: [message] for device [Tên thiết bị]
✅ SUCCESS: Device MQTT - [topic] -> [message] (Custom Broker)
```

### Thiết bị sử dụng broker global:
```
🔍 DEBUG: Device [Tên thiết bị] - hasCustomMqttConfig: false
🔍 DEBUG: Using global MQTT config
🔍 DEBUG: Global Topic: [topic]
✅ SUCCESS: Global MQTT - [topic] -> [message] (Global Broker)
```

## 🧪 Cách Test

### 1. Test thiết bị với MQTT riêng:
1. **Thêm thiết bị mới:**
   - Mở "Thêm thiết bị"
   - Nhập thông tin cơ bản
   - **Bật toggle "Cấu hình MQTT"**
   - Nhập broker riêng (ví dụ: `test.mqtt.broker.com`)
   - Nhập port (ví dụ: `8883`)
   - Nhập username/password nếu cần
   - Lưu thiết bị

2. **Điều khiển thiết bị:**
   - Mở chi tiết thiết bị
   - Bật/tắt thiết bị
   - **Kiểm tra console log** - phải thấy "Custom Broker"

### 2. Test thiết bị với broker global:
1. **Thêm thiết bị mới:**
   - Mở "Thêm thiết bị"
   - Nhập thông tin cơ bản
   - **Không bật** toggle "Cấu hình MQTT"
   - Lưu thiết bị

2. **Điều khiển thiết bị:**
   - Mở chi tiết thiết bị
   - Bật/tắt thiết bị
   - **Kiểm tra console log** - phải thấy "Global Broker"

### 3. Test cấu hình MQTT cho thiết bị có sẵn:
1. **Mở thiết bị có sẵn:**
   - Vào chi tiết thiết bị
   - Nhấn nút **WiFi** (📶) trong AppBar
   - Cấu hình MQTT riêng
   - Lưu cấu hình

2. **Điều khiển thiết bị:**
   - Bật/tắt thiết bị
   - **Kiểm tra console log** - phải thấy "Custom Broker"

## 🚨 Xử lý Lỗi

### Lỗi kết nối:
```
❌ Device MQTT Connection Error for device [Tên]: [Lỗi]
❌ Device MQTT: Connection failed for device [Tên] - [Mã lỗi]
```
**Nguyên nhân:** Broker không tồn tại, sai port, sai credentials
**Giải pháp:** Kiểm tra lại thông tin broker

### Fallback về global:
```
⚠️ Device [ID]: Not connected to custom broker
✅ SUCCESS: Global MQTT - [topic] -> [message] (Global Broker)
```
**Nguyên nhân:** Broker riêng không kết nối được
**Giải pháp:** Hệ thống tự động fallback về broker global

## 📊 Kiểm tra Kết quả

### Thành công:
- ✅ Log hiển thị "Custom Broker" hoặc "Global Broker"
- ✅ Thiết bị phản hồi đúng lệnh
- ✅ Không có lỗi trong console

### Thất bại:
- ❌ Log hiển thị "FAILED: No MQTT provider available"
- ❌ Thiết bị không phản hồi
- ❌ Có lỗi kết nối trong console

## 🔧 Troubleshooting

### 1. Thiết bị không kết nối được broker riêng:
- Kiểm tra broker URL và port
- Kiểm tra username/password
- Kiểm tra SSL/TLS settings
- Kiểm tra firewall/network

### 2. Luôn fallback về global:
- Kiểm tra `hasCustomMqttConfig` trong log
- Kiểm tra cấu hình MQTT có được lưu đúng không
- Kiểm tra method `publishToDevice` có được gọi không

### 3. Debug sâu hơn:
- Thêm breakpoint trong `DeviceMqttService.publishToDevice`
- Kiểm tra `device.mqttConfig` có null không
- Kiểm tra `device.finalMqttTopic` có đúng không

## 📝 Ghi chú
- Mỗi thiết bị có thể có broker MQTT riêng
- Hệ thống tự động fallback về broker global nếu broker riêng lỗi
- Debug logs sẽ giúp bạn theo dõi luồng xử lý
- Có thể test với broker MQTT công khai như `test.mosquitto.org`

