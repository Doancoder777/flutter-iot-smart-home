# 🔍 MQTT Connection Troubleshooting Guide

## Vấn đề hiện tại:
- ✅ SSL handshake thành công
- ✅ Socket connected  
- ❌ **KHÔNG nhận được CONNACK từ HiveMQ**
- → Broker từ chối connection (khả năng cao: **credentials SAI**)

## 📋 Checklist Debug:

### 1. Test với MQTTX Desktop Client
Download: https://mqttx.app/

**Settings:**
- Name: Test HiveMQ
- Host: `26d1fcc0724b46c495e45a93d79c78d2.s1.eu.hivemq.cloud`
- Port: `8883`
- SSL/TLS: **Enabled** ✅
- Username: `sigma`
- Password: `[your-password]`

**Nếu MQTTX cũng fail → Password 100% SAI**

### 2. Kiểm tra HiveMQ Cloud Console

1. Vào: https://console.hivemq.cloud
2. Login vào account
3. Chọn cluster: `26d1fcc0724b46c495e45a93d79c78d2`
4. Click tab **"Access Management"**
5. Kiểm tra:
   - ✅ User `sigma` có tồn tại không?
   - ✅ Password có đúng không?
   - ✅ Permissions: phải có **Publish + Subscribe**

### 3. Reset Password nếu cần

1. Trong Access Management
2. Click vào user `sigma`
3. Click **"Change Password"**
4. Nhập password mới (VD: `Sigma123!@#`)
5. Copy password
6. Paste vào app Flutter

### 4. Test với Mosquitto CLI (Optional)

```bash
# Windows (nếu đã cài mosquitto)
mosquitto_pub -h 26d1fcc0724b46c495e45a93d79c78d2.s1.eu.hivemq.cloud -p 8883 \
  -u sigma -P [password] \
  --capath /etc/ssl/certs/ \
  -t test/topic -m "Hello"
```

Nếu lệnh này fail → **Password SAI**

## 🎯 Kết luận:

Dựa trên log của bạn:
```
3-2025-10-14 06:44:18.793567 -- MqttConnectionBase::_onDone - calling disconnected callback
```

→ Broker **ĐÃ ĐÓNG CONNECTION** ngay sau khi nhận CONNECT message

**Nguyên nhân phổ biến nhất: Username/Password SAI**

## ✅ Action Plan:

1. **Test với MQTTX trước** (quan trọng nhất!)
2. Nếu MQTTX fail → Reset password trong HiveMQ Console
3. Nhập lại password vào app Flutter
4. Xóa device cũ, add lại với password mới
5. Check Home Screen xem device có chấm xanh không

## 📱 Troubleshooting App:

Sau khi fix password, nếu vẫn fail:

1. Xóa app data: Settings → Apps → Your App → Clear Data
2. Uninstall & reinstall app
3. Login lại
4. Add device mới với MQTT config đúng

## 🔐 Password Requirements:

HiveMQ Cloud thường yêu cầu:
- Tối thiểu 8 ký tự
- Có chữ hoa, chữ thường
- Có số
- Có ký tự đặc biệt

**Đừng dùng password quá đơn giản!**
