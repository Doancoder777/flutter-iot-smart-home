# 🔧 Integration Checklist - Automation Rules

Làm theo checklist này để tích hợp Automation Rules vào app của bạn.

---

## ☑️ Pre-Integration (Kiểm tra)

- [ ] Project đã có `provider` package
- [ ] Project đã có `sqflite` package  
- [ ] Project đã có `timeago` package
- [ ] Model `AutomationRule` đã tồn tại trong `lib/models/`
- [ ] MQTT Service hoặc device control service đã có

---

## 📝 Step-by-Step Integration

### Step 1: Setup Provider (5 phút)

**File**: `lib/main.dart`

```dart
import 'features/automation/providers/automation_provider.dart';
import 'features/automation/data/automation_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialize database
  await AutomationDatabase().database;
  
  runApp(
    MultiProvider(
      providers: [
        // ... existing providers
        
        // ✅ Add AutomationProvider
        ChangeNotifierProvider(
          create: (_) => AutomationProvider(
            onRuleTriggered: (ruleId, actions) {
              // TODO: Implement action execution
              print('Rule $ruleId triggered with ${actions.length} actions');
            },
          )..loadRules(),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

- [ ] Code đã thêm
- [ ] App build thành công
- [ ] Console có log "✅ Automation Database: Tables created"

---

### Step 2: Connect Rule Engine với Sensor Data (10 phút)

**File**: `lib/services/mqtt_service.dart` (hoặc nơi nhận sensor data)

```dart
import 'package:provider/provider.dart';
import '../features/automation/providers/automation_provider.dart';

class MqttService extends ChangeNotifier {
  // ... existing code
  
  // ✅ Add context reference or callback
  BuildContext? _context;
  
  void setContext(BuildContext context) {
    _context = context;
  }
  
  void _onSensorDataReceived(String payload) {
    final sensorData = SensorData.fromJson(jsonDecode(payload));
    
    // ✅ Evaluate automation rules
    if (_context != null) {
      _context!.read<AutomationProvider>().evaluateRules(sensorData);
    }
    
    notifyListeners();
  }
}
```

**Hoặc trong HomePage/Dashboard:**

```dart
@override
void initState() {
  super.initState();
  final mqttService = context.read<MqttService>();
  mqttService.setContext(context);
}
```

- [ ] Code đã thêm
- [ ] Test với sensor data
- [ ] Console có log "🎯 Triggering rule: ..." khi conditions met

---

### Step 3: Implement Action Execution (15 phút)

**File**: `lib/main.dart` (cập nhật callback)

```dart
ChangeNotifierProvider(
  create: (_) => AutomationProvider(
    onRuleTriggered: (ruleId, actions) {
      // ✅ Get MQTT service
      final mqttService = /* get from provider or global */;
      
      // ✅ Execute each action
      for (final action in actions) {
        switch (action.action) {
          case 'turn_on':
            mqttService.publishCommand(action.deviceId, 'ON');
            break;
          case 'turn_off':
            mqttService.publishCommand(action.deviceId, 'OFF');
            break;
          case 'set_value':
            mqttService.publishCommand(action.deviceId, '${action.value}');
            break;
          case 'toggle':
            // Implement toggle logic
            break;
        }
      }
      
      print('✅ Executed ${actions.length} actions for rule $ruleId');
    },
  )..loadRules(),
),
```

**Test**: 
- [ ] Tạo rule đơn giản
- [ ] Enable rule
- [ ] Trigger manually với test data
- [ ] Verify device responds (relay bật/tắt, servo move)

---

### Step 4: Add Navigation (5 phút)

**Option A: Trong Settings Screen**

```dart
ListTile(
  leading: const Icon(Icons.auto_awesome),
  title: const Text('Automation Rules'),
  subtitle: const Text('Create smart automations'),
  trailing: const Icon(Icons.chevron_right),
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

**Option B: Thêm vào Drawer/Menu**

```dart
import 'features/automation/screens/automation_rules_screen.dart';

ListTile(
  leading: Icon(Icons.auto_awesome),
  title: Text('Automation'),
  onTap: () {
    Navigator.pop(context); // close drawer
    Navigator.push(context, 
      MaterialPageRoute(builder: (_) => AutomationRulesScreen())
    );
  },
),
```

**Option C: Thêm route vào go_router**

```dart
GoRoute(
  path: '/automation',
  name: 'automation',
  builder: (context, state) => const AutomationRulesScreen(),
),
```

- [ ] Navigation hoạt động
- [ ] Screen hiển thị đúng
- [ ] Có thể tạo/sửa/xóa rules

---

### Step 5: Test End-to-End (10 phút)

**Scenario 1: Temperature Rule**
1. [ ] Tạo rule: "IF temp > 30 THEN turn ON relay1"
2. [ ] Enable rule
3. [ ] Gửi sensor data với temp = 35
4. [ ] Verify relay1 nhận command "ON"
5. [ ] Check history log

**Scenario 2: Multiple Conditions**
1. [ ] Tạo rule: "IF temp > 25 AND humidity > 70 THEN turn ON relay2"
2. [ ] Test với data không đủ điều kiện → không trigger
3. [ ] Test với data đủ điều kiện → trigger
4. [ ] Verify debounce (không trigger lại trong 30s)

**Scenario 3: Edit & Delete**
1. [ ] Edit rule đã tạo
2. [ ] Disable rule → không trigger nữa
3. [ ] Enable lại → trigger normal
4. [ ] Delete rule → confirm dialog → rule bị xóa

---

### Step 6: Optional Enhancements

**A. Notification khi rule trigger**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

onRuleTriggered: (ruleId, actions) {
  // Execute actions...
  
  // ✅ Show notification
  _notificationService.show(
    id: ruleId.hashCode,
    title: 'Automation Triggered',
    body: 'Rule executed successfully',
  );
},
```

- [ ] Notifications hoạt động

**B. Add to Home Screen Widget**

```dart
// Show active rules count on home
Consumer<AutomationProvider>(
  builder: (context, provider, _) {
    return Text('${provider.enabledCount} active rules');
  },
),
```

- [ ] Widget hiển thị

**C. Export/Import Rules (Advanced)**

```dart
// Export to JSON
final rules = provider.rules;
final json = jsonEncode(rules.map((r) => r.toJson()).toList());
await File('rules_backup.json').writeAsString(json);

// Import from JSON
final json = await File('rules_backup.json').readAsString();
final List rules = jsonDecode(json);
for (final rule in rules) {
  await provider.addRule(AutomationRule.fromJson(rule));
}
```

- [ ] Export/Import hoạt động

---

## ✅ Final Verification

### Functional Tests
- [ ] Tạo rule mới → thành công
- [ ] Edit rule → thay đổi được lưu
- [ ] Delete rule → xóa thành công
- [ ] Toggle enable/disable → state thay đổi
- [ ] Rule trigger khi conditions met → actions executed
- [ ] Debounce hoạt động (30s cooldown)
- [ ] History log được ghi nhận

### UI/UX Tests
- [ ] Empty state hiển thị đúng
- [ ] Loading indicator khi fetch data
- [ ] Error handling khi có lỗi
- [ ] Form validation hoạt động
- [ ] Confirmation dialogs hiển thị
- [ ] Refresh indicator hoạt động

### Performance Tests
- [ ] Load 10+ rules không lag
- [ ] Evaluate rules < 10ms
- [ ] Database query < 50ms
- [ ] UI responsive, không freeze

### Edge Cases
- [ ] Rule với 0 conditions → không cho lưu
- [ ] Rule với 0 actions → không cho lưu
- [ ] Sensor type không hợp lệ → validation error
- [ ] Device ID rỗng → validation error
- [ ] Database full → graceful degradation

---

## 🐛 Common Issues & Solutions

### Issue 1: Rules không trigger
**Symptoms**: Tạo rule nhưng không thấy trigger dù conditions đúng

**Solutions**:
- [ ] Kiểm tra rule có enabled không (toggle switch)
- [ ] Verify `evaluateRules()` được gọi khi có sensor data mới
- [ ] Check console logs: `flutter logs | grep RuleEngine`
- [ ] Clear debounce: `provider.clearDebounce(ruleId)`
- [ ] Restart app để reload rules

### Issue 2: Actions không execute
**Symptoms**: Rule trigger nhưng device không phản hồi

**Solutions**:
- [ ] Verify callback `onRuleTriggered` có được implement
- [ ] Check MQTT connection status
- [ ] Verify device ID đúng (e.g., "relay1" not "Relay1")
- [ ] Test MQTT publish trực tiếp
- [ ] Check device logs/status

### Issue 3: Database errors
**Symptoms**: SQLite errors khi load/save rules

**Solutions**:
- [ ] Delete app data & reinstall
- [ ] Check database path: `getDatabasesPath()`
- [ ] Verify table schema: `SELECT * FROM sqlite_master`
- [ ] Migration issue → bump DB version
- [ ] Disk space full → free up space

### Issue 4: UI không update
**Symptoms**: Tạo rule nhưng list không refresh

**Solutions**:
- [ ] Verify Provider được wrap trong `Consumer` hoặc `watch()`
- [ ] Check `notifyListeners()` được gọi
- [ ] Force refresh: pull-to-refresh
- [ ] Restart app

---

## 📊 Monitoring & Analytics (Optional)

### Add Logging

```dart
// In rule_engine_service.dart
print('📊 Stats: ${enabledRules.length} rules evaluated in ${elapsed}ms');

// In automation_provider.dart  
print('💾 Database: ${_rules.length} rules loaded');
```

### Track Metrics
- [ ] Total rules created
- [ ] Active rules count
- [ ] Total triggers today/week
- [ ] Most triggered rule
- [ ] Average evaluation time

---

## 🎉 Done!

Khi tất cả checklist đã tick ✅, bạn đã hoàn thành tích hợp!

**Next**: Thử tạo một vài rules thực tế và tận hưởng smart home automation! 🏠✨

---

## 📞 Need Help?

- Read: `README.md` (full documentation)
- Quick: `QUICK_START.md` (5-minute guide)
- Examples: `INTEGRATION_EXAMPLE.dart` (code samples)

**Estimated total time**: 30-45 phút ⏱️
