import 'dart:async';
import '../../../models/automation_rule.dart';
import '../../../models/sensor_data.dart';
import '../data/automation_database.dart';

/// Rule engine that evaluates automation rules against sensor data
class RuleEngineService {
  final AutomationDatabase _database;
  final Function(String ruleId, List<Action> actions) onRuleTriggered;

  // Debounce mechanism to prevent rapid re-triggering
  final Map<String, DateTime> _lastTriggerTimes = {};
  final Duration _debounceWindow = const Duration(seconds: 30);

  RuleEngineService({
    required this.onRuleTriggered,
    AutomationDatabase? database,
  }) : _database = database ?? AutomationDatabase();

  /// Evaluate all enabled rules against current sensor data
  Future<void> evaluateRules(SensorData sensorData) async {
    try {
      final enabledRules = await _database.getEnabledRules();

      for (final rule in enabledRules) {
        // Check debounce
        if (_shouldDebounce(rule.id)) {
          continue;
        }

        // Evaluate all conditions (AND logic)
        if (_evaluateConditions(rule.conditions, sensorData)) {
          await _triggerRule(rule, sensorData);
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
      final currentValue = _getSensorValue(condition.sensorType, sensorData);
      if (currentValue == null) return false;

      if (!condition.evaluate(currentValue)) {
        return false; // One condition failed
      }
    }

    return true; // All conditions passed
  }

  /// Get sensor value by type
  dynamic _getSensorValue(String sensorType, SensorData data) {
    switch (sensorType.toLowerCase()) {
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
        print('⚠️ Unknown sensor type: $sensorType');
        return null;
    }
  }

  /// Trigger rule actions
  Future<void> _triggerRule(AutomationRule rule, SensorData sensorData) async {
    print('🎯 Triggering rule: ${rule.name}');

    // Update last trigger time
    _lastTriggerTimes[rule.id] = DateTime.now();

    // Execute actions via callback
    onRuleTriggered(rule.id, rule.actions);

    // Log to database
    await _database.markRuleTriggered(rule.id);

    // Log history with sensor context
    await _database.logRuleTrigger(
      ruleId: rule.id,
      sensorValues: {
        'temperature': sensorData.temperature,
        'humidity': sensorData.humidity,
        'light': sensorData.light,
        'rain': sensorData.rain,
        'soilMoisture': sensorData.soilMoisture,
        'gas': sensorData.gas,
        'dust': sensorData.dust,
        'motion': sensorData.motionDetected,
      },
      actionsExecuted: rule.actions
          .map(
            (a) =>
                '${a.deviceId}: ${a.action}${a.value != null ? " (${a.value})" : ""}',
          )
          .toList(),
    );
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

    if (rule.actions.isEmpty) {
      return 'At least one action is required';
    }

    // Validate conditions
    for (final condition in rule.conditions) {
      if (!_isValidSensorType(condition.sensorType)) {
        return 'Invalid sensor type: ${condition.sensorType}';
      }

      if (!_isValidOperator(condition.operator)) {
        return 'Invalid operator: ${condition.operator}';
      }

      if (condition.value == null) {
        return 'Condition value cannot be null';
      }
    }

    // Validate actions
    for (final action in rule.actions) {
      if (action.deviceId.trim().isEmpty) {
        return 'Action device ID cannot be empty';
      }

      if (!_isValidAction(action.action)) {
        return 'Invalid action: ${action.action}';
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
      'toggle',
    ].contains(action.toLowerCase());
  }
}
