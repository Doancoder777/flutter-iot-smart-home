import 'dart:async';
import '../../../models/automation_rule.dart';
import '../../../models/sensor_data.dart';
import '../../../models/user_sensor.dart';
import '../../../models/device_model.dart';
// import '../data/automation_database.dart'; // ❌ REMOVED - Using Firestore now

/// Rule engine that evaluates automation rules against sensor data
class RuleEngineService {
  // final AutomationDatabase _database; // ❌ REMOVED - Using Firestore now
  final Function(String ruleId, List<Action> actions) onRuleTriggered;
  final Function(String ruleId, List<Action> actions)? onRuleEnded;

  // Debounce mechanism to prevent rapid re-triggering
  final Map<String, DateTime> _lastTriggerTimes = {};
  final Duration _debounceWindow = const Duration(seconds: 30);

  // 🔄 Track rule states (triggered/ended)
  final Map<String, bool> _ruleStates = {}; // true = triggered, false = ended

  // 🔄 Dynamic data sources
  List<UserSensor> _userSensors = [];
  List<Device> _userDevices = [];

  RuleEngineService({
    required this.onRuleTriggered,
    this.onRuleEnded,
    // AutomationDatabase? database, // ❌ REMOVED - Using Firestore now
  }); // : _database = database ?? AutomationDatabase();

  /// 🔄 UPDATE DATA SOURCES - Call this when user sensors/devices change
  void updateDataSources({
    required List<UserSensor> userSensors,
    required List<Device> userDevices,
  }) {
    _userSensors = userSensors;
    _userDevices = userDevices;
    print(
      '🔄 RuleEngine: Updated data sources - ${_userSensors.length} sensors, ${_userDevices.length} devices',
    );
  }

  /// Evaluate all enabled rules against current sensor data
  Future<void> evaluateRules(SensorData sensorData) async {
    try {
      // ❌ DEPRECATED - Use AutomationProvider with Firestore instead
      // final enabledRules = await _database.getEnabledRules();
      final enabledRules = <AutomationRule>[]; // ❌ DISABLED - No database

      for (final rule in enabledRules) {
        // Check debounce
        if (_shouldDebounce(rule.id)) {
          continue;
        }

        final conditionsMet = _evaluateConditions(rule.conditions, sensorData);
        final wasTriggered = _ruleStates[rule.id] ?? false;

        if (conditionsMet && !wasTriggered) {
          // Conditions just became true - trigger start actions
          await _triggerRule(rule, sensorData, isStart: true);
        } else if (!conditionsMet && wasTriggered) {
          // Conditions just became false - trigger end actions
          await _triggerRule(rule, sensorData, isStart: false);
        }
      }
    } catch (e) {
      print('❌ RuleEngine: Error evaluating rules: $e');
    }
  }

  /// Check if all conditions are met (AND logic)
  bool _evaluateConditions(List<Condition> conditions, SensorData sensorData) {
    if (conditions.isEmpty) return false;

    for (final condition in conditions) {
      // 🔄 SỬ DỤNG SENSOR ID THAY VÌ SENSOR TYPE
      final currentValue = _getSensorValue(condition.sensorId, sensorData);
      if (currentValue == null) {
        print('⚠️ Cannot get value for sensor: ${condition.sensorId}');
        return false;
      }

      if (!condition.evaluate(currentValue)) {
        return false; // One condition failed
      }
    }

    return true; // All conditions passed
  }

  /// Get sensor value by sensor ID (from user's actual sensors)
  dynamic _getSensorValue(String sensorId, SensorData data) {
    // 🔄 TÌM SENSOR THEO ID trong user's sensors
    final userSensor = _userSensors.firstWhere(
      (sensor) => sensor.id == sensorId,
      orElse: () => throw Exception('Sensor not found: $sensorId'),
    );

    // 🔄 LẤY GIÁ TRỊ TỪ SENSOR TYPE của user sensor
    final sensorType = userSensor.sensorType;
    if (sensorType == null) {
      print('⚠️ Sensor type not found for sensor: $sensorId');
      return null;
    }

    // 🔄 MAPPING theo sensor type ID thực tế
    switch (sensorType.id.toLowerCase()) {
      case 'temperature':
        return data.temperature;
      case 'humidity':
        return data.humidity;
      case 'rain':
        return data.rain;
      case 'light':
        return data.light;
      case 'soilmoisture':
      case 'soil_moisture':
        return data.soilMoisture;
      case 'gas':
        return data.gas;
      case 'dust':
        return data.dust;
      case 'motion':
      case 'motiondetected':
        return data.motionDetected ? 1 : 0;
      default:
        print('⚠️ Unknown sensor type: ${sensorType.id} for sensor: $sensorId');
        return null;
    }
  }

  /// Trigger rule actions (start or end)
  Future<void> _triggerRule(
    AutomationRule rule,
    SensorData sensorData, {
    required bool isStart,
  }) async {
    final actionType = isStart ? 'START' : 'END';
    print('🎯 $actionType Triggering rule: ${rule.name}');

    // Update last trigger time and rule state
    _lastTriggerTimes[rule.id] = DateTime.now();
    _ruleStates[rule.id] = isStart;

    // Get appropriate actions
    final actions = isStart ? rule.startActions : rule.getEffectiveEndActions();

    // Execute actions via callback
    if (isStart) {
      onRuleTriggered(rule.id, actions);
    } else if (onRuleEnded != null) {
      onRuleEnded!(rule.id, actions);
    }

    // Log to database
    // ❌ DEPRECATED - Use AutomationProvider with Firestore instead
    // await _database.markRuleTriggered(rule.id);

    // Log history with sensor context
    // ❌ DEPRECATED - Use AutomationProvider with Firestore instead
    // await _database.logRuleTrigger(
    //   ruleId: rule.id,
    //   sensorValues: {
    //     'temperature': sensorData.temperature,
    //     'humidity': sensorData.humidity,
    //     'light': sensorData.light,
    //     'rain': sensorData.rain,
    //     'soilMoisture': sensorData.soilMoisture,
    //     'gas': sensorData.gas,
    //     'dust': sensorData.dust,
    //     'motion': sensorData.motionDetected,
    //   },
    //   actionsExecuted: actions
    //       .map(
    //         (a) =>
    //             '${a.deviceId}: ${a.action}${a.value != null ? " (${a.value})" : ""}',
    //       )
    //       .toList(),
    // );
  }

  /// Check if rule should be debounced
  bool _shouldDebounce(String ruleId) {
    final lastTrigger = _lastTriggerTimes[ruleId];
    if (lastTrigger == null) return false;

    final elapsed = DateTime.now().difference(lastTrigger);
    return elapsed < _debounceWindow;
  }

  /// Clear debounce for a specific rule (useful after manual trigger)
  void clearDebounce(String ruleId) {
    _lastTriggerTimes.remove(ruleId);
  }

  /// Clear all debounces
  void clearAllDebounces() {
    _lastTriggerTimes.clear();
  }

  /// Test a rule against current sensor data (dry run)
  Future<bool> testRule(AutomationRule rule, SensorData sensorData) async {
    return _evaluateConditions(rule.conditions, sensorData);
  }

  /// Validate rule (check if conditions/actions are valid)
  String? validateRule(AutomationRule rule) {
    if (rule.name.trim().isEmpty) {
      return 'Rule name cannot be empty';
    }

    if (rule.conditions.isEmpty) {
      return 'At least one condition is required';
    }

    if (rule.startActions.isEmpty) {
      return 'At least one start action is required';
    }

    // Validate conditions
    for (final condition in rule.conditions) {
      if (!_isValidSensorType(condition.sensorId)) {
        return 'Invalid sensor type: ${condition.sensorId}';
      }

      if (!_isValidOperator(condition.operator)) {
        return 'Invalid operator: ${condition.operator}';
      }

      if (condition.value == null) {
        return 'Condition value cannot be null';
      }
    }

    // Validate start actions
    for (final action in rule.startActions) {
      if (action.deviceId.trim().isEmpty) {
        return 'Start action device ID cannot be empty';
      }

      if (!_isValidAction(action.action)) {
        return 'Invalid start action: ${action.action}';
      }
    }

    // Validate end actions (if custom)
    if (rule.hasEndActions) {
      for (final action in rule.endActions) {
        if (action.deviceId.trim().isEmpty) {
          return 'End action device ID cannot be empty';
        }

        if (!_isValidAction(action.action)) {
          return 'Invalid end action: ${action.action}';
        }
      }
    }

    return null; // Valid
  }

  bool _isValidSensorType(String type) {
    return [
      'temperature',
      'humidity',
      'rain',
      'light',
      'soilmoisture',
      'soil_moisture',
      'gas',
      'dust',
      'motion',
      'motiondetected',
    ].contains(type.toLowerCase());
  }

  bool _isValidOperator(String op) {
    return ['>', '<', '==', '>=', '<=', '!='].contains(op);
  }

  bool _isValidAction(String action) {
    return [
      'turn_on',
      'turn_off',
      'set_value',
      'set_angle',
      'set_speed',
      'toggle',
    ].contains(action.toLowerCase());
  }
}
