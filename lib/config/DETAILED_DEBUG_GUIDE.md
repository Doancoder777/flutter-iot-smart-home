# 🚨 DEBUG CHI TIẾT - Tìm nguyên nhân MQTT không hoạt động

## 🎯 Mục đích
Tìm ra chính xác tại sao broker riêng không hoạt động mặc dù bạn đã nhập đúng.

## 📋 Test Steps

### 1. Thêm thiết bị với MQTT riêng
1. Mở ứng dụng
2. Vào "Thêm thiết bị"
3. Nhập:
   - **Tên:** "Test Broker Riêng"
   - **Loại:** Relay
   - **Phòng:** "Test"
4. **BẬT toggle "Cấu hình MQTT"**
5. Nhập:
   - **Broker:** `broker.hivemq.com`
   - **Port:** `1883`
   - **SSL:** TẮT
   - **Username:** Để trống
   - **Password:** Để trống
6. Nhấn "Thêm thiết bị"

### 2. Kiểm tra Debug Logs khi LƯU thiết bị
Bạn sẽ thấy log này khi lưu:
```
🔍 DEBUG: Device 0: Test Broker Riêng
🔍 DEBUG: mqttConfig: {deviceId: , broker: broker.hivemq.com, port: 1883, username: null, password: null, useSsl: false, clientId: null, customTopic: null, useCustomConfig: true, createdAt: 2024-01-01T00:00:00.000Z, updatedAt: 2024-01-01T00:00:00.000Z}
🔍 DEBUG: hasCustomMqttConfig: true
💾 Saved 1 devices for user [user_id]: true
```

**✅ Nếu thấy `useCustomConfig: true` và `hasCustomMqttConfig: true`** → Lưu đúng
**❌ Nếu thấy `useCustomConfig: false` hoặc `hasCustomMqttConfig: false`** → Có vấn đề khi tạo thiết bị

### 3. Kiểm tra Debug Logs khi LOAD thiết bị
Khi mở lại app, bạn sẽ thấy log này:
```
🔍 DEBUG: Loaded Device 0: Test Broker Riêng
🔍 DEBUG: mqttConfig: {deviceId: , broker: broker.hivemq.com, port: 1883, username: null, password: null, useSsl: false, clientId: null, customTopic: null, useCustomConfig: true, createdAt: 2024-01-01T00:00:00.000Z, updatedAt: 2024-01-01T00:00:00.000Z}
🔍 DEBUG: hasCustomMqttConfig: true
🔍 DEBUG: useCustomConfig: true
```

**✅ Nếu thấy `useCustomConfig: true` và `hasCustomMqttConfig: true`** → Load đúng
**❌ Nếu thấy `useCustomConfig: false` hoặc `hasCustomMqttConfig: false`** → Có vấn đề khi deserialize

### 4. Kiểm tra Debug Logs khi ĐIỀU KHIỂN thiết bị
Khi bật/tắt thiết bị, bạn sẽ thấy:
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

**✅ Nếu thấy "Custom Broker"** → Tính năng hoạt động đúng!
**❌ Nếu thấy "Global Broker"** → Có vấn đề với logic

## 🔍 Phân tích kết quả

### Case 1: Lưu đúng, Load đúng, Điều khiển đúng
→ **Tính năng hoạt động hoàn hảo!**

### Case 2: Lưu đúng, Load sai, Điều khiển sai
→ **Vấn đề:** `DeviceMqttConfig.fromJson()` không deserialize đúng
→ **Giải pháp:** Sửa method `fromJson()` trong `DeviceMqttConfig`

### Case 3: Lưu sai, Load sai, Điều khiển sai
→ **Vấn đề:** `DeviceMqttConfig.toJson()` không serialize đúng
→ **Giải pháp:** Sửa method `toJson()` trong `DeviceMqttConfig`

### Case 4: Lưu đúng, Load đúng, Điều khiển sai
→ **Vấn đề:** Logic trong `DeviceProvider` hoặc `DeviceMqttService`
→ **Giải pháp:** Sửa logic điều khiển

## 🚨 Action Items

1. **Test ngay** với broker `broker.hivemq.com:1883`
2. **Copy paste** tất cả debug logs bạn thấy
3. **Báo cáo** case nào bạn gặp phải
4. **Tôi sẽ sửa** vấn đề cụ thể dựa trên logs

## 📊 Expected Results

**Nếu mọi thứ hoạt động đúng, bạn sẽ thấy:**
- ✅ `useCustomConfig: true` khi lưu
- ✅ `useCustomConfig: true` khi load  
- ✅ `hasCustomMqttConfig: true` khi điều khiển
- ✅ `publishToDevice called` khi điều khiển
- ✅ `Custom Broker` trong kết quả cuối

**Nếu có vấn đề, bạn sẽ thấy:**
- ❌ `useCustomConfig: false` ở bất kỳ bước nào
- ❌ `hasCustomMqttConfig: false` khi điều khiển
- ❌ `Global Broker` trong kết quả cuối

