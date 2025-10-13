# 🏛️ Kiến trúc & Best Practices - Automation Rules

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                           │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                     UI Layer                            │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │ │
│  │  │ Rules List   │  │ Add/Edit     │  │ Rule Detail │  │ │
│  │  │ Screen       │  │ Screen       │  │ Screen      │  │ │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬──────┘  │ │
│  └─────────┼──────────────────┼──────────────────┼─────────┘ │
│            │                  │                  │            │
│  ┌─────────▼──────────────────▼──────────────────▼─────────┐ │
│  │            State Management (Provider)                   │ │
│  │  ┌────────────────────────────────────────────────────┐ │ │
│  │  │        AutomationProvider (ChangeNotifier)         │ │ │
│  │  │  - rules: List<AutomationRule>                     │ │ │
│  │  │  - loadRules(), addRule(), updateRule()            │ │ │
│  │  │  - evaluateRules(sensorData)                       │ │ │
│  │  └────────┬────────────────────────┬──────────────────┘ │ │
│  └───────────┼────────────────────────┼────────────────────┘ │
│              │                        │                       │
│  ┌───────────▼────────────┐  ┌───────▼──────────────────┐   │
│  │   Rule Engine Service   │  │  Automation Database     │   │
│  │  ┌──────────────────┐  │  │  ┌────────────────────┐  │   │
│  │  │ Evaluate         │  │  │  │ SQLite Operations  │  │   │
│  │  │ Conditions       │  │  │  │ - CRUD rules       │  │   │
│  │  │ - AND logic      │  │  │  │ - History logs     │  │   │
│  │  │ - 8 sensor types │  │  │  │ - Transactions     │  │   │
│  │  │ - 5 operators    │  │  │  └────────────────────┘  │   │
│  │  └──────────────────┘  │  └──────────────────────────┘   │
│  │  ┌──────────────────┐  │                                  │
│  │  │ Debounce         │  │                                  │
│  │  │ - 30s cooldown   │  │                                  │
│  │  └──────────────────┘  │                                  │
│  └─────────┬───────────────┘                                 │
│            │                                                  │
│  ┌─────────▼──────────────────────────────────────────────┐ │
│  │                  Action Executor                        │ │
│  │  callback: onRuleTriggered(ruleId, actions)            │ │
│  └─────────┬───────────────────────────────────────────────┘ │
└────────────┼──────────────────────────────────────────────────┘
             │
             ▼
  ┌──────────────────────┐
  │   MQTT Service       │  Send commands to:
  │  ┌────────────────┐  │  - Relays (ON/OFF)
  │  │ publish()      │  │  - Servos (angle)
  │  │ - relay1: ON   │  │  - Buzzers, LEDs, etc.
  │  │ - servo1: 90   │  │
  │  └────────────────┘  │
  └──────────────────────┘
```

---

## 🔄 Data Flow

### 1. Rule Creation Flow
```
User Input → Validation → AutomationProvider.addRule() 
  → AutomationDatabase.insertRule() → SQLite → UI Update
```

### 2. Rule Evaluation Flow (Real-time)
```
Sensor Data (MQTT) → SensorData Model → AutomationProvider.evaluateRules()
  → RuleEngineService.evaluateRules() → Check ALL enabled rules
    → For each rule:
        → Evaluate conditions (AND logic)
        → If ALL true:
            → Check debounce (30s)
            → Execute actions (callback)
            → Log to history
            → Update last_triggered
```

### 3. Action Execution Flow
```
RuleEngine triggers → onRuleTriggered callback → Main App
  → MqttService.publish() → ESP32 → Physical Device
```

---

## 🗂️ Database Schema Detail

### Table: `automation_rules`

```sql
CREATE TABLE automation_rules (
  id TEXT PRIMARY KEY,              -- UUID v4
  name TEXT NOT NULL,               -- User-friendly name
  enabled INTEGER NOT NULL,         -- 1 = active, 0 = paused
  conditions TEXT NOT NULL,         -- JSON: [{"sensorType":"temp","operator":">","value":30}]
  actions TEXT NOT NULL,            -- JSON: [{"deviceId":"relay1","action":"turn_on"}]
  created_at TEXT NOT NULL,         -- ISO8601: "2025-10-11T10:30:00Z"
  last_triggered TEXT,              -- ISO8601 (nullable)
  trigger_count INTEGER DEFAULT 0,  -- Statistics
  description TEXT                  -- Optional user note
);
```

### Table: `rule_history`

```sql
CREATE TABLE rule_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rule_id TEXT NOT NULL,                    -- FK → automation_rules(id)
  triggered_at TEXT NOT NULL,               -- ISO8601
  sensor_values TEXT,                       -- JSON snapshot
  actions_executed TEXT,                    -- JSON array of action strings
  FOREIGN KEY (rule_id) REFERENCES automation_rules (id) ON DELETE CASCADE
);

-- Index for fast queries
CREATE INDEX idx_rule_history_rule_id ON rule_history(rule_id);
CREATE INDEX idx_rule_history_time ON rule_history(triggered_at DESC);
```

---

## 📦 Model Structure

### AutomationRule
```dart
class AutomationRule {
  final String id;                    // UUID
  final String name;                  // "Turn on fan when hot"
  final bool enabled;                 // true/false
  final List<Condition> conditions;   // [Condition, ...]
  final List<Action> actions;         // [Action, ...]
  final DateTime createdAt;           // Creation timestamp
  final DateTime? lastTriggered;      // Last execution time
  
  // Methods: fromJson, toJson, copyWith
}
```

### Condition
```dart
class Condition {
  final String sensorType;    // "temperature", "humidity", etc.
  final String operator;      // ">", "<", "==", ">=", "<="
  final dynamic value;        // 30.0, 50, true, etc.
  
  bool evaluate(dynamic currentValue) {
    // Compare currentValue with condition.value using operator
  }
}
```

### Action
```dart
class Action {
  final String deviceId;      // "relay1", "servo1", etc.
  final String action;        // "turn_on", "turn_off", "set_value", "toggle"
  final dynamic value;        // For "set_value": angle, brightness, etc.
}
```

---

## 🎯 Design Patterns Used

### 1. **Repository Pattern**
- `AutomationDatabase` encapsulates all SQLite operations
- Business logic doesn't know about SQL details
- Easy to swap SQLite với Hive, Firebase, etc.

### 2. **Provider Pattern (State Management)**
- `AutomationProvider` manages app-wide automation state
- UI reactively updates when rules change
- Separation of UI and business logic

### 3. **Strategy Pattern**
- Different action types (`turn_on`, `turn_off`, `set_value`) handled dynamically
- Easy to add new action types without modifying core logic

### 4. **Observer Pattern**
- MQTT sensor data triggers rule evaluation
- Rules "observe" sensor changes and react automatically

### 5. **Factory Pattern**
- `AutomationRule.fromJson()` creates objects from database
- Clean deserialization logic

---

## ⚙️ Configuration & Customization

### 1. Debounce Duration
```dart
// In rule_engine_service.dart
final Duration _debounceWindow = const Duration(seconds: 30);

// Để tắt debounce:
final Duration _debounceWindow = Duration.zero;
```

### 2. Sensor Types
```dart
// Thêm sensor type mới trong _getSensorValue()
case 'pressure':
  return data.pressure;
case 'co2':
  return data.co2Level;
```

### 3. Action Types
```dart
// Thêm action type mới
case 'blink':
  // Implement blink logic
  break;
case 'send_notification':
  // Push notification
  break;
```

### 4. Condition Logic
```dart
// Hiện tại: AND logic (tất cả conditions phải đúng)
// Để thêm OR logic:

class AutomationRule {
  final LogicOperator logicOperator; // AND / OR
}

enum LogicOperator { AND, OR }

// In RuleEngine:
if (rule.logicOperator == LogicOperator.OR) {
  // Return true nếu BẤT KỲ condition nào đúng
} else {
  // Return true nếu TẤT CẢ conditions đúng
}
```

---

## 🔒 Security Considerations

### 1. SQL Injection Prevention
✅ Dùng parameterized queries:
```dart
db.query('rules', where: 'id = ?', whereArgs: [id])
// NOT: db.rawQuery("SELECT * FROM rules WHERE id = '$id'")
```

### 2. Input Validation
✅ Validate trong `RuleEngineService.validateRule()`:
- Rule name không rỗng
- Ít nhất 1 condition & 1 action
- Sensor type hợp lệ
- Device ID không rỗng

### 3. Error Handling
✅ Try-catch ở mọi database operation
✅ Graceful degradation khi database fail
✅ User-friendly error messages

### 4. Data Integrity
✅ Foreign key constraints
✅ Transactions cho multiple operations
✅ Rollback on error

---

## 📈 Performance Optimization

### Database
- ✅ Indexes on frequently queried columns
- ✅ Limit history to 100 records/rule (auto-cleanup)
- ✅ Batch operations với transactions
- ✅ Lazy loading (không load history cho tất cả rules)

### Rule Engine
- ✅ Early exit: stop evaluating nếu 1 condition fail
- ✅ Debounce prevents excessive evaluations
- ✅ Async operations không block UI
- ✅ Rule validation trước khi save (fail fast)

### UI
- ✅ ListView.builder cho large lists
- ✅ Refresh indicator thay vì full reload
- ✅ Optimistic UI updates
- ✅ Skeleton loading states

---

## 🧪 Testing Strategy

### Unit Tests
```dart
test('Condition evaluation with > operator', () {
  final condition = Condition(sensorType: 'temperature', operator: '>', value: 30);
  expect(condition.evaluate(35), true);
  expect(condition.evaluate(25), false);
});

test('Debounce prevents rapid triggering', () async {
  // Mock RuleEngine
  // Trigger rule twice in 10s
  // Verify only 1 execution
});
```

### Integration Tests
```dart
testWidgets('Create and trigger rule end-to-end', (tester) async {
  // 1. Open automation screen
  // 2. Create new rule
  // 3. Simulate sensor data
  // 4. Verify action executed
});
```

### Manual Test Cases
- [ ] Rule with multiple conditions (AND logic)
- [ ] Rule with multiple actions
- [ ] Enable/disable while triggered
- [ ] Delete rule while evaluating
- [ ] Database corruption recovery
- [ ] Offline mode (queue actions?)

---

## 🚀 Deployment Checklist

### Before Release
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] No memory leaks (use DevTools)
- [ ] Performance profiling (< 60ms frame time)
- [ ] Database migration tested
- [ ] Error logging in production
- [ ] Analytics integration (optional)

### Documentation
- [x] README.md
- [x] QUICK_START.md
- [x] INTEGRATION_CHECKLIST.md
- [x] Code comments
- [ ] API documentation (dartdoc)
- [ ] Video tutorial (optional)

---

## 📊 Metrics to Track (Production)

### Usage Metrics
- Total rules created
- Active rules %
- Rules triggered today/week/month
- Most popular sensor types
- Most popular actions
- Average conditions per rule

### Performance Metrics
- Rule evaluation time (avg/p95/p99)
- Database query time
- UI rendering time
- Crash rate
- Error rate

### User Behavior
- Time to create first rule
- Rule edit frequency
- Rule deletion rate
- Feature adoption rate

---

## 🎓 Learning Resources

### Flutter/Dart
- Provider: https://pub.dev/packages/provider
- SQLite: https://pub.dev/packages/sqflite
- Async programming: https://dart.dev/codelabs/async-await

### Architecture
- Clean Architecture: https://blog.cleancoder.com/
- Feature-first: https://codewithandrea.com/articles/flutter-project-structure/

### Best Practices
- Effective Dart: https://dart.dev/guides/language/effective-dart
- Flutter best practices: https://flutter.dev/docs/development/data-and-backend/state-mgmt/options

---

## 🤝 Contributing Guidelines

### Code Style
- Follow Dart style guide
- Max line length: 80 characters
- Use meaningful variable names
- Add comments for complex logic

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/add-or-logic

# Make changes, commit often
git commit -m "feat: Add OR logic support for conditions"

# Push and create PR
git push origin feature/add-or-logic
```

### Pull Request Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] Performance impact: none/low/medium/high

## Screenshots (if UI changes)
[Add screenshots]
```

---

## 🏆 Credits & Acknowledgments

**Built for**: Smart Home IoT Controller v3  
**Framework**: Flutter 3.9+  
**Database**: SQLite (sqflite)  
**State Management**: Provider  
**Architecture**: Feature-first + Clean Architecture principles  

**Inspired by**:
- Home Assistant Automations
- IFTTT (If This Then That)
- Node-RED flows

---

**Last Updated**: 2025-10-11  
**Version**: 1.0.0  
**Status**: Production Ready ✅
