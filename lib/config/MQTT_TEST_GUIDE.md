# 🧪 Test Script - Kiểm tra MQTT Riêng cho Thiết bị

## 🎯 Mục đích
Kiểm tra xem thiết bị có thực sự sử dụng broker MQTT riêng hay không.

## 📋 Các bước test

### 1. Thêm thiết bị với MQTT riêng
1. Mở ứng dụng
2. Vào "Thêm thiết bị"
3. Nhập thông tin:
   - **Tên:** "Test Device MQTT"
   - **Loại:** Relay
   - **Phòng:** "Test Room"
4. **BẬT toggle "Cấu hình MQTT"**
5. Nhập thông tin MQTT:
   - **Broker:** `test.mosquitto.org` (broker công khai để test)
   - **Port:** `1883` (port không SSL)
   - **SSL:** TẮT
   - **Username:** Để trống
   - **Password:** Để trống
6. Nhấn "Thêm thiết bị"

### 2. Kiểm tra Debug Logs
Khi điều khiển thiết bị, bạn sẽ thấy trong console:

**✅ Nếu hoạt động đúng:**
```
🔍 DEBUG: Device Test Device MQTT - hasCustomMqttConfig: true
🔍 DEBUG: mqttConfig is null: false
🔍 DEBUG: useCustomConfig: true
🔍 DEBUG: broker: test.mosquitto.org
🔍 DEBUG: port: 1883
🔍 DEBUG: Custom MQTT Config - Broker: test.mosquitto.org:1883
🔍 DEBUG: Custom Topic: smart_home/devices/test_room/test_device_mqtt
🔄 Device MQTT: Connecting to test.mosquitto.org:1883 for device Test Device MQTT...
✅ Device MQTT: Connected to test.mosquitto.org for device Test Device MQTT
📤 Device MQTT: Published to smart_home/devices/test_room/test_device_mqtt: 1 for device Test Device MQTT
✅ SUCCESS: Device MQTT - smart_home/devices/test_room/test_device_mqtt -> 1 (Custom Broker)
```

**❌ Nếu vẫn dùng broker global:**
```
🔍 DEBUG: Device Test Device MQTT - hasCustomMqttConfig: false
🔍 DEBUG: mqttConfig is null: true
🔍 DEBUG: Using global MQTT config
🔍 DEBUG: Global Topic: smart_home/devices/test_room/test_device_mqtt
✅ SUCCESS: Global MQTT - smart_home/devices/test_room/test_device_mqtt -> 1 (Global Broker)
```

### 3. Test với thiết bị không có MQTT riêng
1. Thêm thiết bị mới:
   - **Tên:** "Test Device Global"
   - **Loại:** Relay
   - **Phòng:** "Test Room"
   - **KHÔNG BẬT** toggle "Cấu hình MQTT"
2. Điều khiển thiết bị
3. Kiểm tra log - phải thấy "Global Broker"

## 🔍 Troubleshooting

### Nếu vẫn thấy "Global Broker":
1. **Kiểm tra cấu hình có được lưu không:**
   - Mở chi tiết thiết bị
   - Nhấn nút WiFi (📶)
   - Xem cấu hình MQTT có hiển thị đúng không

2. **Kiểm tra database:**
   - Có thể cấu hình không được lưu vào storage
   - Thử thêm thiết bị mới với cấu hình khác

3. **Kiểm tra method `hasCustomMqttConfig`:**
   - Log phải hiển thị `hasCustomMqttConfig: true`
   - Nếu `false`, có vấn đề với việc lưu/đọc cấu hình

### Nếu kết nối broker riêng thất bại:
1. **Kiểm tra broker:**
   - `test.mosquitto.org` có thể không hoạt động
   - Thử broker khác như `broker.hivemq.com`

2. **Kiểm tra port:**
   - Port 1883 (không SSL) hoặc 8883 (SSL)
   - Đảm bảo SSL setting đúng

3. **Kiểm tra network:**
   - Có thể bị chặn firewall
   - Thử trên mạng khác

## 📊 Kết quả mong đợi

### Thành công:
- ✅ Log hiển thị "Custom Broker"
- ✅ Thiết bị kết nối đến broker riêng
- ✅ Message được gửi đến topic đúng

### Thất bại:
- ❌ Log hiển thị "Global Broker"
- ❌ `hasCustomMqttConfig: false`
- ❌ `mqttConfig is null: true`

## 🎯 Kết luận
Nếu bạn thấy log "Custom Broker", tính năng đã hoạt động đúng!
Nếu vẫn thấy "Global Broker", có vấn đề với việc lưu/đọc cấu hình MQTT.

