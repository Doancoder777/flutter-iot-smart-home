# Automation Rules Feature

## 📋 Tổng quan

Feature **Automation Rules** cho phép người dùng tạo các quy tắc tự động để điều khiển thiết bị dựa trên dữ liệu cảm biến real-time.

### Tính năng chính
- ✅ Tạo, sửa, xóa quy tắc tự động
- ✅ Điều kiện dựa trên sensor data (temperature, humidity, light, v.v.)
- ✅ Hành động tự động (bật/tắt relay, điều chỉnh servo)
- ✅ Lưu trữ bền vững với SQLite
- ✅ Debounce mechanism (30s) để tránh trigger liên tục
- ✅ History log của mỗi lần rule được kích hoạt
- ✅ Enable/Disable rules động

---

## 🏗️ Kiến trúc

```
lib/features/automation/
├── data/
│   ├── automation_database.dart    # SQLite CRUD operations
│   └── rule_engine_service.dart    # Rule evaluation logic
├── providers/
│   └── automation_provider.dart    # State management
├── screens/
│   ├── automation_rules_screen.dart  # List all rules
│   ├── add_edit_rule_screen.dart     # Create/Edit rule
│   └── rule_detail_screen.dart       # Rule details & history
└── widgets/
    └── (custom widgets if needed)
```

---

## 🔌 Tích hợp vào app

### Bước 1: Thêm Provider vào main.dart

```dart
import 'package:provider/provider.dart';
import 'features/automation/providers/automation_provider.dart';
import 'services/mqtt_service.dart'; // service điều khiển thiết bị

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final db = AutomationDatabase();
  await db.database; // Ensure db is ready
  
  runApp(
    MultiProvider(
      providers: [
        // Existing providers...
        ChangeNotifierProvider(
          create: (_) => AutomationProvider(
            onRuleTriggered: (ruleId, actions) {
              // Execute actions when rule is triggered
              _executeActions(actions);
            },
          )..loadRules(), // Load rules on startup
        ),
      ],
      child: MyApp(),
    ),
  );
}

void _executeActions(List<Action> actions) {
  final mqttService = MqttService(); // or get from provider
  
  for (final action in actions) {
    switch (action.action) {
      case 'turn_on':
        mqttService.publishCommand(action.deviceId, 'ON');
        break;
      case 'turn_off':
        mqttService.publishCommand(action.deviceId, 'OFF');
        break;
      case 'toggle':
        // Implement toggle logic
        break;
      case 'set_value':
        mqttService.publishCommand(action.deviceId, action.value.toString());
        break;
    }
  }
}
```

### Bước 2: Kết nối Rule Engine với MQTT Service

Trong `mqtt_service.dart` hoặc nơi nhận sensor data:

```dart
import 'package:provider/provider.dart';
import '../features/automation/providers/automation_provider.dart';
import '../models/sensor_data.dart';

class MqttService {
  // ... existing code
  
  void _handleSensorData(SensorData data, BuildContext context) {
    // Update UI state
    notifyListeners();
    
    // ⭐ Evaluate automation rules
    context.read<AutomationProvider>().evaluateRules(data);
  }
}
```

### Bước 3: Thêm route navigation

Trong `go_router` config hoặc Navigator:

```dart
import 'features/automation/screens/automation_rules_screen.dart';

// Add route
GoRoute(
  path: '/automation',
  builder: (context, state) => const AutomationRulesScreen(),
),
```

Hoặc với Navigator:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const AutomationRulesScreen(),
  ),
);
```

### Bước 4: Thêm vào Settings/Menu

```dart
ListTile(
  leading: const Icon(Icons.auto_awesome),
  title: const Text('Automation Rules'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AutomationRulesScreen(),
      ),
    );
  },
),
```

---

## 📊 Database Schema

### Table: `automation_rules`
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | Primary key (UUID) |
| name | TEXT | Rule name |
| enabled | INTEGER | 1 = enabled, 0 = disabled |
| conditions | TEXT | JSON array của conditions |
| actions | TEXT | JSON array của actions |
| created_at | TEXT | ISO8601 timestamp |
| last_triggered | TEXT | ISO8601 timestamp (nullable) |
| trigger_count | INTEGER | Số lần rule được trigger |

### Table: `rule_history`
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Auto-increment PK |
| rule_id | TEXT | Foreign key → automation_rules(id) |
| triggered_at | TEXT | ISO8601 timestamp |
| sensor_values | TEXT | JSON snapshot của sensor data |
| actions_executed | TEXT | JSON array của actions executed |

---

## 🔧 API Usage

### Provider Methods

```dart
final provider = context.read<AutomationProvider>();

// Load all rules
await provider.loadRules();

// Add new rule
final rule = AutomationRule(
  id: uuid.v4(),
  name: 'Turn on fan when hot',
  enabled: true,
  conditions: [
    Condition(
      sensorType: 'temperature',
      operator: '>',
      value: 30.0,
    ),
  ],
  actions: [
    Action(
      deviceId: 'relay1',
      action: 'turn_on',
    ),
  ],
  createdAt: DateTime.now(),
);

await provider.addRule(rule);

// Toggle rule
await provider.toggleRule(ruleId);

// Delete rule
await provider.deleteRule(ruleId);

// Evaluate rules (call when sensor data arrives)
await provider.evaluateRules(sensorData);

// Get rule history
final history = await provider.getRuleHistory(ruleId);
```

---

## 🧪 Testing

### Test Rule Locally

```dart
final provider = context.read<AutomationProvider>();
final rule = provider.getRuleById(ruleId);

final testData = SensorData(
  temperature: 35.0,
  humidity: 60.0,
  // ... other fields
);

final willTrigger = await provider.testRule(rule, testData);
print('Rule will trigger: $willTrigger');
```

---

## 🎯 Ví dụ Rules

### 1. Bật quạt khi nóng
```dart
Conditions:
  - Temperature > 30°C

Actions:
  - Turn ON relay1 (fan)
```

### 2. Tưới cây khi đất khô
```dart
Conditions:
  - Soil Moisture < 30

Actions:
  - Turn ON relay2 (water pump)
```

### 3. Bật đèn khi tối và có chuyển động
```dart
Conditions:
  - Light < 50
  - Motion == 1

Actions:
  - Turn ON relay3 (light)
```

### 4. Đóng cửa sổ khi mưa
```dart
Conditions:
  - Rain > 500

Actions:
  - Set servo1 to 0 (close window)
```

---

## ⚙️ Configuration

### Debounce Duration
Mặc định: 30 giây. Để thay đổi:

```dart
// In rule_engine_service.dart
final Duration _debounceWindow = const Duration(seconds: 60); // 60s
```

### Sensor Type Mapping
Nếu bạn có sensor type khác, thêm vào `_getSensorValue()` trong `rule_engine_service.dart`:

```dart
case 'my_custom_sensor':
  return data.customValue;
```

---

## 🐛 Troubleshooting

### Rules không trigger
1. Kiểm tra rule có enabled không
2. Kiểm tra `evaluateRules()` có được gọi khi sensor data update
3. Kiểm tra debounce (rule chỉ trigger mỗi 30s)
4. Xem log console: `print` statements trong `rule_engine_service.dart`

### Database errors
```dart
// Reset database nếu cần
final db = await AutomationDatabase().database;
await db.execute('DROP TABLE IF EXISTS automation_rules');
await db.execute('DROP TABLE IF EXISTS rule_history');
// Restart app để recreate tables
```

### Actions không execute
- Kiểm tra callback `onRuleTriggered` có được implement đúng
- Kiểm tra MQTT service có kết nối
- Kiểm tra device ID có đúng

---

## 🚀 Future Enhancements

- [ ] OR logic giữa conditions (hiện tại là AND)
- [ ] Time-based conditions (e.g., chỉ chạy vào ban đêm)
- [ ] Notification khi rule trigger
- [ ] UI để test rule với mock data
- [ ] Import/Export rules (JSON)
- [ ] Rule templates
- [ ] Priority/ordering của rules
- [ ] Async actions (với delay/retry)

---

## 📝 License & Credits

Created for Smart Home IoT Controller v3  
Built with Flutter & SQLite
