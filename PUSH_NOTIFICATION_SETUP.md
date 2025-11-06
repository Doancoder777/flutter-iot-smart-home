# 🔔 Hướng dẫn cài đặt Push Notification với Firebase Cloud Messaging

## ✅ Đã hoàn thành

### 1. **Cài đặt Firebase Cloud Messaging**
- ✅ Đã thêm package `firebase_messaging: ^16.0.3` vào `pubspec.yaml`
- ✅ Đã chạy `flutter pub add firebase_messaging` để cài đặt
- ✅ Package đã được tải về thành công

### 2. **Nâng cấp NotificationService**
File: `lib/services/notification_service.dart`

**Các thay đổi:**
- ✅ Thêm imports: `firebase_messaging`, `cloud_firestore`
- ✅ Chuyển sang singleton pattern để dễ truy cập global
- ✅ Thêm Firebase Messaging instance
- ✅ Thêm FCM token field và getter
- ✅ Thêm background message handler: `firebaseMessagingBackgroundHandler()`
- ✅ Nâng cấp `init()` method với FCM initialization
- ✅ Thêm `_initializeFCM()` method để:
  - Request FCM permissions
  - Lấy FCM token
  - Listen token refresh
  - Handle foreground messages
  - Handle background notification taps
  - Handle terminated app notification taps

**Các method mới:**
```dart
// Lưu FCM token vào Firestore
Future<void> saveFcmTokenToFirestore(String userId)

// Sensor-specific alerts
Future<void> showGasAlert(int gasValue)
Future<void> showHighTemperatureAlert(double temperature)
Future<void> showLowTemperatureAlert(double temperature)
Future<void> showRainAlert()
Future<void> showHighDustAlert(int dustValue)
```

### 3. **Update main.dart**
File: `lib/main.dart`

**Đã thêm:**
- ✅ Import `firebase_messaging`
- ✅ Register background message handler: `FirebaseMessaging.onBackgroundMessage()`

---

## 🔄 Cần làm tiếp

### 1. **Hot Restart App**
```bash
# Trong VS Code, nhấn:
# - Shift + F5 (Stop)
# - F5 (Start lại)
# Hoặc terminal:
flutter run
```

### 2. **Integrate vào SensorProvider**
File: `lib/providers/sensor_provider.dart`

Thêm logic kiểm tra ngưỡng cảm biến và gửi thông báo:

```dart
void _checkSensorThresholds(UserSensor sensor, dynamic newValue) {
  // Gas Alert
  if (sensor.type == SensorType.gas && newValue is int && newValue > 400) {
    _notificationService.showGasAlert(newValue);
  }
  
  // Temperature Alerts
  if (sensor.type == SensorType.temperature && newValue is double) {
    if (newValue > 35) {
      _notificationService.showHighTemperatureAlert(newValue);
    } else if (newValue < 18) {
      _notificationService.showLowTemperatureAlert(newValue);
    }
  }
  
  // Rain Alert
  if (sensor.type == SensorType.rain && newValue is int && newValue > 60) {
    _notificationService.showRainAlert();
  }
  
  // Dust Alert
  if (sensor.type == SensorType.dust && newValue is int && newValue > 150) {
    _notificationService.showHighDustAlert(newValue);
  }
}
```

### 3. **Save FCM Token sau khi login**
File: `lib/providers/auth_provider.dart` hoặc `lib/screens/auth/login_screen.dart`

```dart
// Sau khi login thành công:
final notificationService = NotificationService();
await notificationService.saveFcmTokenToFirestore(userId);
```

### 4. **Cấu hình Firebase Console** (Optional - để gửi từ backend)
1. Vào Firebase Console → Cloud Messaging
2. Lấy Server Key hoặc Private Key
3. Sử dụng FCM token từ Firestore để gửi notification từ server

---

## 📋 Ngưỡng cảnh báo mặc định

| Cảm biến | Ngưỡng | Mức độ |
|----------|--------|--------|
| **Gas** | > 400 ppm | 🔴 Nguy hiểm |
| **Nhiệt độ cao** | > 35°C | 🔥 Cao |
| **Nhiệt độ thấp** | < 18°C | ❄️ Thấp |
| **Mưa** | > 60% | 🌧️ Mưa lớn |
| **Bụi PM2.5** | > 150 µg/m³ | 🫁 Độc hại |

---

## 🎯 Cách test Push Notifications

### Test 1: Foreground Notification (App mở)
1. Mở app
2. Trigger sensor vượt ngưỡng (ví dụ: gas > 400)
3. Notification xuất hiện ở trên màn hình

### Test 2: Background Notification (App minimize)
1. Minimize app (home button)
2. Trigger sensor vượt ngưỡng
3. Notification xuất hiện ở notification tray
4. Tap notification → App mở lại

### Test 3: Terminated Notification (App đóng hoàn toàn)
1. Đóng app hoàn toàn (swipe away)
2. Gửi notification từ Firebase Console
3. Notification xuất hiện ở notification tray
4. Tap notification → App khởi động

---

## 🔧 Troubleshooting

### Lỗi: "Target of URI doesn't exist: firebase_messaging"
**Giải pháp:** 
```bash
# 1. Stop app
flutter clean
flutter pub get
flutter run
```

### Không nhận được notification
**Kiểm tra:**
1. ✅ `init()` đã được gọi trong `main.dart`
2. ✅ FCM permissions đã được grant
3. ✅ Token đã được lưu vào Firestore
4. ✅ Sensor data thực sự vượt ngưỡng

### FCM Token null
**Giải pháp:**
```dart
// Gọi sau khi init() hoàn tất:
print('FCM Token: ${notificationService.fcmToken}');
```

---

## 📱 Platform-specific setup (Nếu cần)

### Android (google-services.json)
- ✅ File đã có trong `android/app/google-services.json`
- ✅ Firebase đã được config trong `build.gradle`

### iOS (GoogleService-Info.plist)
- Thêm file vào `ios/Runner/GoogleService-Info.plist`
- Update iOS permissions trong `Info.plist`

---

## 🎉 Tính năng hoàn thiện

✅ Firebase Cloud Messaging đã tích hợp
✅ Background handler đã setup
✅ Foreground handler đã setup
✅ Alert methods đã có cho từng loại sensor
✅ FCM token management đã có
✅ Firestore integration đã có

**Next:** Integrate vào SensorProvider để tự động gửi alerts! 🚀
