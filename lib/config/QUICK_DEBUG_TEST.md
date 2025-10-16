# 🚨 DEBUG SCRIPT - Kiểm tra MQTT Riêng

## 📋 Test nhanh

### 1. Thêm thiết bị với broker riêng:
- **Tên:** "Test Broker Riêng"
- **Loại:** Relay
- **Phòng:** "Test"
- **BẬT** toggle "Cấu hình MQTT"
- **Broker:** `broker.hivemq.com` (broker công khai)
- **Port:** `1883`
- **SSL:** TẮT
- **Username:** Để trống
- **Password:** Để trống

### 2. Điều khiển thiết bị và xem console log:

**✅ Nếu hoạt động đúng, bạn sẽ thấy:**
```
🔍 DEBUG: Device Test Broker Riêng - hasCustomMqttConfig: true
🔍 DEBUG: mqttConfig is null: false
🔍 DEBUG: useCustomConfig: true
🔍 DEBUG: broker: broker.hivemq.com
🔍 DEBUG: port: 1883
🔍 DEBUG: publishToDevice called for device Test Broker Riêng
🔍 DEBUG: hasCustomMqttConfig: true
🔍 DEBUG: Using custom broker: broker.hivemq.com:1883
🔍 DEBUG: Topic: smart_home/devices/test/test_broker_rieng
🔍 DEBUG: Message: 1
🔄 Device MQTT: Connecting to broker.hivemq.com:1883 for device Test Broker Riêng...
✅ Device MQTT: Connected to broker.hivemq.com for device Test Broker Riêng
📤 Device MQTT: Published to smart_home/devices/test/test_broker_rieng: 1 for device Test Broker Riêng
✅ SUCCESS: Device MQTT - smart_home/devices/test/test_broker_rieng -> 1 (Custom Broker)
```

**❌ Nếu vẫn dùng broker global:**
```
🔍 DEBUG: Device Test Broker Riêng - hasCustomMqttConfig: false
🔍 DEBUG: mqttConfig is null: true
❌ DEBUG: Device does not have custom MQTT config, returning false
✅ SUCCESS: Global MQTT - smart_home/devices/test/test_broker_rieng -> 1 (Global Broker)
```

## 🔍 Phân tích log của bạn:

Từ log bạn gửi:
```
Topic: smart_home/status/app_online
QoS: 0
offline
Topic: smart_home/status/app_online
QoS: 0
online
```

**Đây là log từ broker GLOBAL**, không phải từ broker riêng của bạn!

**Topic `smart_home/status/app_online`** là topic status của app, không phải topic điều khiển thiết bị.

## 🎯 Kết luận:

**Nếu bạn thấy log "Custom Broker"** → Tính năng hoạt động đúng!
**Nếu bạn thấy log "Global Broker"** → Có vấn đề với việc lưu/đọc cấu hình MQTT.

## 🚨 Action cần làm:

1. **Test ngay** với broker `broker.hivemq.com:1883`
2. **Xem console log** khi điều khiển thiết bị
3. **Báo cáo** log bạn thấy được

**Topic `smart_home/status/app_online` là bình thường** - đó là status của app, không phải của thiết bị!

