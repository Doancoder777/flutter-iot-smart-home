# 📡 Tính năng Auto-Ping Thiết Bị & Hiển Thị Trạng Thái Kết Nối

## 🎯 Mục tiêu
Tự động kiểm tra kết nối MQTT của tất cả thiết bị và hiển thị trạng thái kết nối trực quan trên giao diện.

## ✨ Tính năng đã implement

### 1. **Auto-Ping Background (Không block UI)**
- **Khi mở app**: Tự động ping tất cả thiết bị
- **Định kỳ**: Ping lại mỗi 5 phút
- **Silent mode**: Chạy background, không hiển thị loading hoặc làm gián đoạn UX
- **Parallel execution**: Ping tất cả thiết bị song song để nhanh hơn
- **Timeout ngắn**: 3 giây cho mỗi ping (thay vì 5 giây)

### 2. **ConnectionStatusBadge trên AppBar**
- Hiển thị số thiết bị đã kết nối / tổng số thiết bị
- **Màu xanh** 🟢: Có thiết bị kết nối (`X/Y thiết bị`)
- **Màu đỏ** 🔴: Không có thiết bị nào kết nối (`Không có kết nối`)
- **Màu đỏ** 🔴: Không có thiết bị nào (`No MQTT config available`)
- Tự động cập nhật khi trạng thái thay đổi

### 3. **Online Indicator (Chấm xanh như Messenger)**
- Hiển thị chấm xanh ở góc dưới phải của `DeviceAvatar`
- Chỉ hiển thị khi thiết bị đang online
- Có viền trắng để nổi bật trên background
- Áp dụng cho:
  - `DeviceCard` (màn hình Devices)
  - `RoomDeviceList` (màn hình Rooms - cả relay và servo/fan)

### 4. **State Management**
- Lưu trạng thái kết nối trong `Map<String, bool>` (`deviceId -> isConnected`)
- Tự động cập nhật UI khi trạng thái thay đổi qua `notifyListeners()`
- Persist state giữa các lần ping

## 📁 Các file đã thay đổi

### 1. **lib/providers/device_provider.dart**
**Thêm mới:**
- `Map<String, bool> _deviceConnectionStatus`: Lưu trạng thái kết nối
- `Timer? _autoPingTimer`: Timer cho auto-ping 5 phút
- `bool _isAutoPinging`: Flag để tránh ping trùng lặp
- `bool isDeviceConnected(String deviceId)`: Getter cho trạng thái kết nối
- `int get connectedDevicesCount`: Đếm số thiết bị đã kết nối
- `Future<void> pingAllDevices({bool silent})`: Ping tất cả thiết bị
- `Future<bool> _pingDeviceSilent(Device device)`: Ping 1 thiết bị (silent mode)
- `void startAutoPing()`: Bắt đầu auto-ping timer
- `void stopAutoPing()`: Dừng auto-ping timer
- Override `dispose()`: Cleanup timers

**Cập nhật:**
- `checkMqttConnection()`: Lưu kết quả vào `_deviceConnectionStatus`

### 2. **lib/widgets/connection_status_badge.dart** (NEW)
Widget hiển thị trạng thái kết nối trên AppBar:
- Consumer `DeviceProvider` để lắng nghe thay đổi
- Logic hiển thị dựa trên số lượng thiết bị và kết nối
- Responsive với màu sắc và text phù hợp

### 3. **lib/screens/devices/widgets/device_card.dart**
**Thêm:**
- Import `DeviceProvider` và `Consumer`
- Wrap `DeviceAvatar` trong `Stack` với `Consumer<DeviceProvider>`
- Thêm `Positioned` widget cho chấm xanh online indicator
- Chỉ hiển thị khi `provider.isDeviceConnected(device.id) == true`

### 4. **lib/screens/rooms/widgets/room_device_list.dart**
**Cập nhật:**
- `_buildRelayDevice()`: Thêm online indicator cho relay devices
- `_buildServoDevice()`: Thêm online indicator cho servo/fan devices
- Cùng style với `DeviceCard` (chấm xanh 12x12, viền trắng 2px)

### 5. **lib/screens/home/home_screen.dart**
**Thêm:**
- Import `ConnectionStatusBadge`
- Method `_startDevicePing()`: Trigger auto-ping khi mở app
- Gọi `deviceProvider.startAutoPing()` trong `initState`
- Override `dispose()`: Gọi `deviceProvider.stopAutoPing()`

**Cập nhật:**
- AppBar: Thay `StatusIndicator` bằng `ConnectionStatusBadge`

## 🚀 Cách hoạt động

### Flow khi mở app:
```
1. HomeScreen.initState()
   ↓
2. _startDevicePing()
   ↓
3. deviceProvider.startAutoPing()
   ↓
4. Ping ngay lập tức (lần đầu)
   ↓
5. Setup Timer(5 phút) cho các lần ping sau
```

### Flow auto-ping:
```
1. Timer trigger (5 phút)
   ↓
2. pingAllDevices(silent: true)
   ↓
3. Ping tất cả devices SONG SONG
   ↓
4. Mỗi device: _pingDeviceSilent()
   ↓
5. Subscribe → Publish "ping" → Wait response "1" (timeout 3s)
   ↓
6. Lưu kết quả vào _deviceConnectionStatus[deviceId]
   ↓
7. notifyListeners() → Update UI
```

### UI Update Flow:
```
DeviceProvider.notifyListeners()
   ↓
Consumer<DeviceProvider> trong:
   - ConnectionStatusBadge (AppBar)
   - DeviceCard (Devices Screen)
   - RoomDeviceList (Rooms Screen)
   ↓
Rebuild với trạng thái mới
```

## 🎨 UI Design

### ConnectionStatusBadge:
```
┌─────────────────────────┐
│ ● 3/5 thiết bị         │  ← Xanh (có kết nối)
└─────────────────────────┘

┌─────────────────────────┐
│ ● Không có kết nối     │  ← Đỏ (0 kết nối)
└─────────────────────────┘

┌─────────────────────────────────┐
│ ● No MQTT config available    │  ← Đỏ (0 thiết bị)
└─────────────────────────────────┘
```

### Online Indicator (Chấm xanh):
```
   ┌─────────┐
   │ Avatar  │
   │         │
   │       ●─┼─  ← Chấm xanh (14x14) với viền trắng
   └─────────┘
```

## ⚙️ Configuration

### Thời gian:
- **Auto-ping interval**: 5 phút (`Duration(minutes: 5)`)
- **Ping timeout**: 3 giây (`Duration(seconds: 3)`)
- **Parallel ping**: Tất cả thiết bị cùng lúc

### Màu sắc:
- **Online indicator**: `Colors.green`
- **Badge success**: `Colors.green[600]`
- **Badge error**: `Colors.red[600]`
- **Indicator border**: `Colors.white` (2px)

## 🔧 Tối ưu hiệu năng

1. **Silent mode**: Không hiển thị loading, không block UI
2. **Parallel execution**: Ping tất cả thiết bị song song
3. **Timeout ngắn**: 3 giây thay vì 5 giây
4. **Prevent spam**: Check `_isAutoPinging` flag
5. **Cleanup**: Hủy timers và callbacks trong `dispose()`
6. **State-based UI**: Chỉ rebuild các widget cần thiết qua `Consumer`

## 📝 Notes

- Auto-ping chỉ chạy khi có thiết bị
- Online indicator chỉ hiển thị khi `isDeviceConnected == true`
- Timer tự động cleanup khi dispose HomeScreen
- Không gây lag hoặc freeze UI nhờ async + parallel execution
- Compatible với existing MQTT ping/pong mechanism

