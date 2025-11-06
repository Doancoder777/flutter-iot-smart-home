# 🤖 DANH SÁCH THIẾT BỊ VÀ KEY CHO AI TRUY VẤN

**Ngày cập nhật:** 2 tháng 11, 2025

---

## 📋 CẤU TRÚC DỮ LIỆU THIẾT BỊ

```dart
class Device {
  String id;              // Firebase document ID (unique)
  String name;            // Tên hiển thị cho người dùng
  String keyName;         // 🎯 TÊN CHUẨN HÓA CHO AI VOICE CONTROL
  String deviceCode;      // 🔑 MÃ THIẾT BỊ 6 KÝ TỰ (MQTT identifier)
  DeviceType type;        // relay | servo | fan
  bool state;             // ON/OFF state
  int? value;             // Giá trị (servo angle, fan speed)
  String? room;           // Phòng đặt thiết bị
  String userId;          // Owner ID
  bool isPinned;          // Ghim lên điều khiển nhanh
}
```

---

## 📊 TỔNG QUAN THIẾT BỊ

**Tổng số:** 9 thiết bị
- **Relay:** 4 thiết bị (đèn, bơm)
- **Servo:** 2 thiết bị (cửa, dàn phơi)
- **Fan PWM:** 2 thiết bị (quạt)

### ✅ Device Codes đã xác nhận (từ MQTT logs):
1. `RELAY_PUMP_001` - Motor bơm nước
2. `RELAY_LIGHT_001` - Đèn phòng
3. `LED_WHITE_001` - Đèn trắng
4. `LED_RED_001` - Đèn đỏ
5. `SERVO_DOOR_001` - Cửa cổng
6. `SERVO_ROOF_001` - Dàn phơi đồ
7. `MOTOR_FAN_A_001` - Quạt A
8. `MOTOR_FAN_B_001` - Quạt B

---

## 🏠 DANH SÁCH THIẾT BỊ HIỆN TẠI

### 📌 THIẾT BỊ RELAY (4 thiết bị)

#### 1. MOTOR BƠM NƯỚC
- **Tên hiển thị:** `MOTOR BOM NUOC`
- **Key Name (AI):** `motor_bom_nuoc` hoặc `water_pump`
- **Device Code:** `RELAY_PUMP_001` ✅
- **Device Type:** `relay`
- **Trạng thái:** Đang tắt (OFF)
- **Icon:** 💡
- **Phòng:** Vườn/Sân
- **MQTT Topic:** `smart_home/devices/RELAY_PUMP_001/cmd`
- **Lệnh điều khiển:**
  - Bật: `{"state": true}`
  - Tắt: `{"state": false}`

#### 2. ĐÈN PHÒNG (RELAY_LIGHT_001)
- **Tên hiển thị:** `DEN PHONG KHACH` hoặc `DEN BEP`
- **Key Name (AI):** `den_phong` hoặc `light_room`
- **Device Code:** `RELAY_LIGHT_001` ✅
- **Device Type:** `relay`
- **Trạng thái:** Đang tắt
- **Icon:** 💡
- **Phòng:** Phòng khách/Bếp
- **MQTT Topic:** `smart_home/devices/RELAY_LIGHT_001/cmd`

#### 3. ĐÈN TRẮNG (LED_WHITE_001)
- **Tên hiển thị:** `DEN NHA VE SINH` hoặc tương tự
- **Key Name (AI):** `den_trang` hoặc `light_white`
- **Device Code:** `LED_WHITE_001` ✅
- **Device Type:** `relay`
- **Trạng thái:** Đang tắt
- **Icon:** 💡
- **Phòng:** Nhà vệ sinh
- **MQTT Topic:** `smart_home/devices/LED_WHITE_001/cmd`

#### 4. ĐÈN ĐỎ (LED_RED_001)
- **Tên hiển thị:** `Phun suong` hoặc LED cảnh báo
- **Key Name (AI):** `den_do` hoặc `light_red`
- **Device Code:** `LED_RED_001` ✅
- **Device Type:** `relay`
- **Trạng thái:** Đang tắt
- **Icon:** 💡
- **Phòng:** Trang trí/Cảnh báo
- **MQTT Topic:** `smart_home/devices/LED_RED_001/cmd`

---

### 🎚️ THIẾT BỊ SERVO (2 thiết bị)

#### 5. CỬA CỔNG (SERVO_DOOR_001)
- **Tên hiển thị:** `CUA CONG`
- **Key Name (AI):** `cua_cong` hoặc `gate_servo`
- **Device Code:** `SERVO_DOOR_001` ✅
- **Device Type:** `servo`
- **Góc xoay:** 0° - 180°
- **Giá trị hiện tại:** 0°
- **Icon:** 🎛️
- **Phòng:** Cổng
- **MQTT Topic:** `smart_home/devices/SERVO_DOOR_001/cmd`
- **Lệnh điều khiển:**
  - Xoay góc: `{"value": 90}` (0-180)
  - Đóng: `{"value": 0}`
  - Mở: `{"value": 180}`

#### 6. DÀN PHƠI ĐỒ (SERVO_ROOF_001)
- **Tên hiển thị:** `DAN PHOI DO` hoặc `sevo phơi đồ`
- **Key Name (AI):** `dan_phoi_do` hoặc `roof_servo`
- **Device Code:** `SERVO_ROOF_001` ✅
- **Device Type:** `servo`
- **Góc xoay:** 0° - 180°
- **Giá trị hiện tại:** 0°
- **Icon:** 🎛️
- **Phòng:** Sân phơi
- **MQTT Topic:** `smart_home/devices/SERVO_ROOF_001/cmd`

---

### 🌪️ THIẾT BỊ QUẠT PWM (2 thiết bị)

#### 8. QUẠT A (MOTOR_FAN_A_001)
- **Tên hiển thị:** `Quat Nha Bep` hoặc `Quat Phong Khach`
- **Key Name (AI):** `quat_a` hoặc `fan_a`
- **Device Code:** `MOTOR_FAN_A_001` ✅
- **Device Type:** `fan`
- **Tốc độ:** Tắt (0%)
- **Icon:** 🌪️
- **Phòng:** Bếp/Phòng khách
- **MQTT Topic:** `smart_home/devices/MOTOR_FAN_A_001/cmd`
- **Lệnh điều khiển:**
  - Tắt: `{"state": false, "value": 0}`
  - Nhẹ: `{"state": true, "value": 85}` (0-85)
  - Khá: `{"state": true, "value": 170}` (86-170)
  - Mạnh: `{"state": true, "value": 255}` (171-255)

#### 9. QUẠT B (MOTOR_FAN_B_001)
- **Tên hiển thị:** `Quat Phong Khach` hoặc thứ 2
- **Key Name (AI):** `quat_b` hoặc `fan_b`
- **Device Code:** `MOTOR_FAN_B_001` ✅
- **Device Type:** `fan`
- **Tốc độ:** Tắt (0%)
- **Icon:** 🌪️
- **Phòng:** Phòng khách
- **MQTT Topic:** `smart_home/devices/MOTOR_FAN_B_001/cmd`

---

## 🔑 KEY QUAN TRỌNG CHO AI

### 1️⃣ Truy vấn theo `keyName` (Voice Control)
```dart
// Ví dụ: "Bật đèn bếp"
final device = devices.firstWhere(
  (d) => d.keyName == 'den_bep' || d.keyName == 'light_kitchen'
);
```

### 2️⃣ Truy vấn theo `deviceCode` (MQTT)
```dart
// Ví dụ: Gửi lệnh qua MQTT
String topic = 'smart_home/devices/SERVO_DOOR_001/cmd';
String payload = '{"value": 90}';
```

### 3️⃣ Truy vấn theo `name` (Display Name)
```dart
// Ví dụ: Tìm thiết bị theo tên hiển thị
final device = devices.firstWhere(
  (d) => d.name.toLowerCase().contains('đèn bếp')
);
```

### 4️⃣ Truy vấn theo `type` (Device Type)
```dart
// Ví dụ: Lấy tất cả relay
final relays = devices.where((d) => d.type == DeviceType.relay);

// Lấy tất cả servo
final servos = devices.where((d) => d.type == DeviceType.servo);

// Lấy tất cả quạt
final fans = devices.where((d) => d.type == DeviceType.fan);
```

### 5️⃣ Truy vấn theo `room` (Phòng)
```dart
// Ví dụ: Lấy tất cả thiết bị trong bếp
final kitchenDevices = devices.where((d) => d.room == 'Bếp');
```

### 6️⃣ Truy vấn theo `isPinned` (Ghim)
```dart
// Ví dụ: Lấy thiết bị được ghim (Quick Control)
final pinnedDevices = devices.where((d) => d.isPinned);
```

---

## 📡 MQTT TOPICS

### Device Command Topics (App → ESP32)
```
smart_home/devices/{DEVICE_CODE}/cmd
```

**Ví dụ:**
- `smart_home/devices/SERVO_DOOR_001/cmd`
- `smart_home/devices/RELAY_PUMP_001/cmd`
- `smart_home/devices/MOTOR_FAN_A_001/cmd`

### Device Ping Topics (App → ESP32 → App)
```
smart_home/devices/{DEVICE_CODE}/ping
```

**Payload:** `"ping"` hoặc `"1"` (response)

---

## 📋 BẢNG TỔNG HỢP DEVICE CODES

| # | Tên hiển thị | Device Code | Type | MQTT Topic |
|---|---|---|---|---|
| 1 | MOTOR BƠM NƯỚC | `RELAY_PUMP_001` | relay | `smart_home/devices/RELAY_PUMP_001/cmd` |
| 2 | ĐÈN PHÒNG | `RELAY_LIGHT_001` | relay | `smart_home/devices/RELAY_LIGHT_001/cmd` |
| 3 | ĐÈN TRẮNG | `LED_WHITE_001` | relay | `smart_home/devices/LED_WHITE_001/cmd` |
| 4 | ĐÈN ĐỎ | `LED_RED_001` | relay | `smart_home/devices/LED_RED_001/cmd` |
| 5 | CỬA CỔNG | `SERVO_DOOR_001` | servo | `smart_home/devices/SERVO_DOOR_001/cmd` |
| 6 | DÀN PHƠI ĐỒ | `SERVO_ROOF_001` | servo | `smart_home/devices/SERVO_ROOF_001/cmd` |
| 7 | QUẠT A | `MOTOR_FAN_A_001` | fan | `smart_home/devices/MOTOR_FAN_A_001/cmd` |
| 8 | QUẠT B | `MOTOR_FAN_B_001` | fan | `smart_home/devices/MOTOR_FAN_B_001/cmd` |

---

## 🎯 AI VOICE CONTROL MAPPING

| Lệnh giọng nói | keyName | deviceCode | Action |
|---|---|---|---|
| "Bật đèn bếp" | `den_bep` | `LED_xxx_001` | `{"state": true}` |
| "Tắt đèn phòng khách" | `den_phong_khach` | `RELAY_xxx_001` | `{"state": false}` |
| "Mở cửa cổng" | `cua_cong` | `SERVO_DOOR_001` | `{"value": 180}` |
| "Đóng cửa cổng" | `cua_cong` | `SERVO_DOOR_001` | `{"value": 0}` |
| "Thu dàn phơi" | `dan_phoi_do` | `SERVO_ROOF_001` | `{"value": 0}` |
| "Mở dàn phơi" | `dan_phoi_do` | `SERVO_ROOF_001` | `{"value": 180}` |
| "Bật quạt bếp tốc độ mạnh" | `quat_nha_bep` | `FAN_xxx_001` | `{"state": true, "value": 255}` |
| "Tắt quạt phòng khách" | `quat_phong_khach` | `MOTOR_FAN_A_001` | `{"state": false, "value": 0}` |
| "Bật phun sương" | `phun_suong` | `MIST_xxx_001` | `{"state": true}` |
| "Bật bơm nước" | `motor_bom_nuoc` | `RELAY_PUMP_001` | `{"state": true}` |

---

## 🔍 CÁC TRUY VẤN FIRESTORE

### Lấy tất cả thiết bị của user
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('devices')
  .get();
```

### Lấy thiết bị theo ID
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('devices')
  .doc(deviceId)
  .get();
```

### Lấy thiết bị theo deviceCode
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('devices')
  .where('deviceCode', isEqualTo: 'SERVO_DOOR_001')
  .get();
```

### Lấy thiết bị theo type
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('devices')
  .where('type', isEqualTo: 'relay')
  .get();
```

### Cập nhật trạng thái thiết bị
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('devices')
  .doc(deviceId)
  .update({
    'state': true,
    'value': 90, // for servo/fan
    'lastUpdated': FieldValue.serverTimestamp(),
  });
```

---

## ⚠️ LƯU Ý

1. **Device Code chưa đầy đủ:** Một số thiết bị chưa có deviceCode trong ảnh, cần kiểm tra Firestore để lấy đầy đủ.

2. **KeyName chuẩn hóa:** Đảm bảo tất cả thiết bị có `keyName` để AI voice control hoạt động tốt.

3. **MQTT Topics:** Tất cả device codes phải khớp với Arduino ESP32 để gửi/nhận lệnh đúng.

4. **Room field:** Một số thiết bị chưa có thông tin phòng, nên cập nhật để dễ quản lý.

5. **Icon và Avatar:** Có thể thêm icon/avatar tùy chỉnh cho mỗi thiết bị để UI đẹp hơn.

---

## � DANH SÁCH CẢM BIẾN (từ logs)

| # | Tên hiển thị | Sensor Code | Type | Data Type | Unit | MQTT Topic |
|---|---|---|---|---|---|---|
| 1 | Nhiệt độ | `DHT22_001` | temperature | double | °C | `smart_home/sensors/DHT22_001/state` |
| 2 | Độ ẩm | `DHT22_002` | humidity | double | % | `smart_home/sensors/DHT22_002/state` |
| 3 | Ánh sáng | `LDR_001` | light | int | lux | `smart_home/sensors/LDR_001/state` |
| 4 | Độ ẩm đất | `SOIL_001` | soil_moisture | int | % | `smart_home/sensors/SOIL_001/state` |
| 5 | Bụi PM2.5 | `GP2Y_001` | dust | int | µg/m³ | `smart_home/sensors/GP2Y_001/state` |
| 6 | Chuyển động | `PIR_001` | motion | bool | - | `smart_home/sensors/PIR_001/state` |
| 7 | Cảm biến mưa | `RAIN_001` | rain | int | - | `smart_home/sensors/RAIN_001/state` |
| 8 | Khí gas | `MQ2_001` | gas | int | ppm | `smart_home/sensors/MQ2_001/state` |

### Sensor Data Format (JSON từ Arduino):
```json
{
  "type": "motion",
  "value": 1,
  "timestamp": 4020502
}
```

**Giá trị từ logs:**
- Nhiệt độ: `27.1°C`
- Độ ẩm: `96.0%`
- Ánh sáng: `450 lux`
- Độ ẩm đất: `26%`
- Bụi PM2.5: `0 µg/m³`
- Chuyển động: `true` (Có) / `false` (Không)
- Mưa: `9`
- Khí gas: `3574 ppm`

---

## �📌 CHECKLIST CẦN LÀM

- [ ] Kiểm tra và bổ sung đầy đủ `deviceCode` cho tất cả thiết bị
- [ ] Chuẩn hóa `keyName` cho AI voice control
- [ ] Thêm thông tin `room` cho các thiết bị chưa có
- [ ] Test MQTT topics với Arduino
- [ ] Verify automation rules hoạt động với device keys
- [ ] Document thêm các lệnh voice control phổ biến

---

**Để lấy device codes chính xác, chạy lệnh sau trong Flutter app:**

```dart
final devices = await Provider.of<DeviceProvider>(context, listen: false).userDevices;
devices.forEach((device) {
  print('${device.name}: ${device.deviceCode}');
});
```
