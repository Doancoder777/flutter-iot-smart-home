# Automation Rules - Quick Start Guide

## 🚀 Cài đặt nhanh (5 phút)

### Bước 1: Setup Provider

Mở `lib/main.dart` và thêm:

```dart
import 'features/automation/providers/automation_provider.dart';

// Trong runApp MultiProvider:
ChangeNotifierProvider(
  create: (_) => AutomationProvider()..loadRules(),
),
```

### Bước 2: Kết nối với MQTT

Tìm nơi nhận sensor data và thêm:

```dart
// Khi nhận được sensor data mới:
final sensorData = SensorData.fromJson(json);
context.read<AutomationProvider>().evaluateRules(sensorData);
```

### Bước 3: Thêm Navigation

Trong settings screen:

```dart
import 'features/automation/screens/automation_rules_screen.dart';

ListTile(
  leading: Icon(Icons.auto_awesome),
  title: Text('Automation Rules'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AutomationRulesScreen()),
  ),
),
```

### Bước 4: Chạy app

```bash
flutter pub get
flutter run
```

---

## 📱 Sử dụng

### Tạo Rule đầu tiên

1. Mở app → Settings → Automation Rules
2. Nhấn nút "New Rule" (FAB)
3. Nhập tên: "Bật quạt khi nóng"
4. Thêm Condition:
   - Sensor: Temperature
   - Operator: >
   - Value: 30
5. Thêm Action:
   - Device ID: relay1
   - Action: Turn On
6. Nhấn "Create Rule"

### Test Rule

Khi nhiệt độ > 30°C, rule sẽ tự động bật relay1!

---

## 🔍 Kiểm tra

### Xem logs:

```bash
flutter logs | grep -E "RuleEngine|Automation"
```

Bạn sẽ thấy:
```
✅ Loaded 1 automation rules
🎯 Triggering rule: Bật quạt khi nóng
📤 MQTT: home/device/relay1/command → ON
```

### Xem database:

```bash
# Android
adb shell
run-as com.your.app
cd app_flutter
sqlite3 databases/automation_rules.db
SELECT * FROM automation_rules;
```

---

## 💡 Tips

- **Rules không chạy?** → Kiểm tra toggle "Enabled"
- **Trigger liên tục?** → Có debounce 30s
- **Muốn test?** → Dùng Rule Detail screen
- **Cần help?** → Xem `README.md` đầy đủ

---

## 📚 Ví dụ Rules phổ biến

```dart
// 1. Tưới cây tự động
Conditions: Soil Moisture < 30
Actions: Turn ON relay2 (water pump)

// 2. Bật đèn ban đêm
Conditions: Light < 50 AND Motion == 1
Actions: Turn ON relay3

// 3. Đóng cửa sổ khi mưa
Conditions: Rain > 500
Actions: Set servo1 = 0

// 4. Cảnh báo gas
Conditions: Gas > 300
Actions: Turn ON buzzer (relay4)
```

---

## 🎯 Next Steps

- Thêm notification khi rule trigger
- Tạo rule templates
- Export/Import rules
- Time-based conditions

Happy Automating! 🤖✨
