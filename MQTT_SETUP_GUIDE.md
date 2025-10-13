# 📡 Hướng dẫn cấu hình MQTT

## 🎯 Tại sao cần cấu hình MQTT?

MQTT là giao thức truyền thông giữa app và thiết bị IoT của bạn. Mặc định app sử dụng **broker công cộng** (broker.hivemq.com) - điều này có nghĩa là:

- ⚠️ **Không bảo mật**: Mọi người đều có thể kết nối
- ⚠️ **Không riêng tư**: Dữ liệu của bạn có thể bị đọc bởi người khác
- ⚠️ **Không ổn định**: Broker công cộng có thể bị quá tải

## ✅ Giải pháp: Sử dụng broker riêng

### Tùy chọn 1: HiveMQ Cloud (Khuyến nghị - Free tier)

1. **Đăng ký tài khoản**: https://www.hivemq.com/mqtt-cloud-broker/
2. **Tạo cluster miễn phí** (Free tier đủ cho dự án nhỏ)
3. **Lấy thông tin kết nối**:
   - Broker: `<your-cluster-id>.s1.eu.hivemq.cloud`
   - Port: `8883` (SSL)
   - Username/Password: Tự tạo trong console

4. **Nhập vào app**:
   - Mở app → Settings → Cấu hình MQTT
   - Nhập Broker URL
   - Nhập Port: 8883
   - Nhập Username và Password
   - Bật SSL/TLS
   - Nhấn "Test kết nối" → "Lưu"

### Tùy chọn 2: Eclipse Mosquitto (Self-hosted)

Nếu bạn có server riêng hoặc chạy local:

```bash
# Cài đặt Mosquitto
sudo apt-get install mosquitto mosquitto-clients

# Cấu hình authentication (tùy chọn)
sudo mosquitto_passwd -c /etc/mosquitto/passwd <username>

# Start Mosquitto
sudo systemctl start mosquitto
```

**Thông tin kết nối**:
- Broker: `your-server-ip` hoặc `localhost`
- Port: `1883` (không SSL) hoặc `8883` (SSL)
- Username/Password: Theo cấu hình của bạn

### Tùy chọn 3: Các broker công cộng khác

**⚠️ Chỉ dùng cho testing, không dùng cho production!**

| Broker | URL | Port | SSL | Auth |
|--------|-----|------|-----|------|
| HiveMQ Public | broker.hivemq.com | 1883 | ❌ | ❌ |
| Eclipse | mqtt.eclipseprojects.io | 1883 | ❌ | ❌ |
| Mosquitto | test.mosquitto.org | 1883/8883 | ✅ | ❌ |

## 🔧 Cách nhập vào app

1. **Mở app** → Vào **Settings** (⚙️)
2. Tìm mục **"Kết nối MQTT"**
3. Nhấn **"Cấu hình MQTT"**
4. Điền thông tin:
   ```
   MQTT Broker: your-broker-url.com
   Port: 8883 (SSL) hoặc 1883 (không SSL)
   Username: your-username
   Password: your-password
   Sử dụng SSL/TLS: ✅ (khuyến nghị)
   ```
5. Nhấn **"Test kết nối"** để kiểm tra
6. Nhấn **"Lưu"** để áp dụng

## 📱 Cấu hình thiết bị ESP32/Arduino

Sau khi có broker, bạn cần cấu hình code ESP32:

```cpp
// File config.h
const char* mqtt_server = "your-broker-url.com";
const int mqtt_port = 8883;
const char* mqtt_user = "your-username";
const char* mqtt_password = "your-password";
const char* mqtt_topic = "smart_home/devices/<room>/<device_id>";
```

## 🎯 MQTT Topics cho thiết bị

App sử dụng topic format:
```
smart_home/devices/<room>/<device_id>
```

Ví dụ:
- `smart_home/devices/living/fan_living` - Quạt phòng khách
- `smart_home/devices/bedroom/light_bedroom` - Đèn phòng ngủ
- `smart_home/devices/kitchen/pump_kitchen` - Máy bơm nhà bếp

## ❓ FAQ

**Q: Tôi có cần trả tiền không?**
- A: HiveMQ Cloud có free tier đủ dùng cho dự án nhỏ (100 connections, 10GB data/month)

**Q: Dữ liệu có bị lộ không?**
- A: Với broker riêng + SSL + authentication → An toàn. Broker công cộng → Không an toàn.

**Q: Làm sao biết đã kết nối thành công?**
- A: Xem góc phải trên cùng màn hình Home, sẽ hiện biểu tượng WiFi xanh khi connected.

**Q: Tôi quên mật khẩu MQTT?**
- A: Đăng nhập vào HiveMQ Console để reset, hoặc tạo lại user mới.

## 🚀 Next Steps

Sau khi cấu hình MQTT:
1. ✅ Thêm thiết bị trong app (Devices tab)
2. ✅ Cấu hình ESP32 với topic tương ứng
3. ✅ Upload code lên ESP32
4. ✅ Test điều khiển từ app
5. ✅ Tạo automation rules (Automation tab)

## 📞 Support

Nếu gặp vấn đề:
- Kiểm tra broker URL và port
- Kiểm tra username/password
- Kiểm tra firewall/network
- Xem logs trong Settings → About
