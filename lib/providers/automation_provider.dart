import 'package:flutter/material.dart';
import '../models/automation_rule.dart';
import '../services/local_storage_service.dart';

class AutomationProvider extends ChangeNotifier {
  final LocalStorageService _storageService;

  List<AutomationRule> _rules = [];
  String? _currentUserId; // User isolation

  List<AutomationRule> get rules => _rules;
  List<AutomationRule> get activeRules =>
      _rules.where((r) => r.enabled).toList();
  int get rulesCount => _rules.length;
  int get activeRulesCount => activeRules.length;

  AutomationProvider(this._storageService) {
    // Không load rules ngay, chờ setCurrentUser
  }

  /// Set current user và load automation rules của user đó
  Future<void> setCurrentUser(String? userId) async {
    if (_currentUserId == userId) return;

    _currentUserId = userId;

    if (userId != null) {
      _loadRules();
    } else {
      _rules = [];
      notifyListeners();
    }
  }

  /// Clear user data when logout
  void clearUserData() {
    _currentUserId = null;
    _rules = [];
    notifyListeners();
    print('🧹 AutomationProvider: Cleared user data');
  }

  void _loadRules() {
    if (_currentUserId == null) {
      _rules = [];
      return;
    }

    final stored = _storageService.getAutomationRules(userId: _currentUserId);
    _rules = stored.map((json) => AutomationRule.fromJson(json)).toList();
    print(
      '🤖 Loaded ${_rules.length} automation rules for user: $_currentUserId',
    );
  }

  void _saveRules() {
    if (_currentUserId == null) return;

    final jsonList = _rules.map((rule) => rule.toJson()).toList();
    _storageService.saveAutomationRules(jsonList, userId: _currentUserId);
    print(
      '💾 Saved ${_rules.length} automation rules for user: $_currentUserId',
    );
  }

  void addRule(AutomationRule rule) {
    _rules.add(rule);
    _saveRules();
    notifyListeners();
    print('✅ Added rule: ${rule.name}');
  }

  void updateRule(String id, AutomationRule updatedRule) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rules[index] = updatedRule;
      _saveRules();
      notifyListeners();
      print('✏️ Updated rule: ${updatedRule.name}');
    }
  }

  void deleteRule(String id) {
    final rule = _rules.firstWhere((r) => r.id == id);
    _rules.removeWhere((r) => r.id == id);
    _saveRules();
    notifyListeners();
    print('🗑️ Deleted rule: ${rule.name}');
  }

  void toggleRule(String id) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _rules[index];
      _rules[index] = rule.copyWith(enabled: !rule.enabled);
      _saveRules();
      notifyListeners();
      print('🔄 Toggled rule: ${rule.name} -> ${!rule.enabled}');
    }
  }

  void enableRule(String id) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _rules[index];
      _rules[index] = rule.copyWith(enabled: true);
      _saveRules();
      notifyListeners();
      print('✅ Enabled rule: ${rule.name}');
    }
  }

  void disableRule(String id) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _rules[index];
      _rules[index] = rule.copyWith(enabled: false);
      _saveRules();
      notifyListeners();
      print('⏸️ Disabled rule: ${rule.name}');
    }
  }

  AutomationRule? getRuleById(String id) {
    try {
      return _rules.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  void markRuleTriggered(String id) {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _rules[index];
      _rules[index] = rule.copyWith(lastTriggered: DateTime.now());
      _saveRules();
      notifyListeners();
      print('⚡ Rule triggered: ${rule.name}');
    }
  }

  void clearAllRules() {
    _rules.clear();
    _saveRules();
    notifyListeners();
    print('🗑️ Cleared all automation rules');
  }

  bool _isWithinTimeRange(AutomationRule rule) {
    if (rule.startTime == null && rule.endTime == null) {
      return true; // No time restriction
    }

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    if (rule.startTime != null) {
      final startParts = rule.startTime!.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

      if (rule.endTime != null) {
        final endParts = rule.endTime!.split(':');
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

        final inRange = startMinutes <= endMinutes
            ? (nowMinutes >= startMinutes && nowMinutes <= endMinutes)
            : (nowMinutes >= startMinutes || nowMinutes <= endMinutes);

        // Debug log
        print(
          '🕐 Time check for "${rule.name}": Now ${now.hour}:${now.minute.toString().padLeft(2, '0')}, Range ${rule.startTime}-${rule.endTime}, InRange: $inRange',
        );

        return inRange;
      }
    }

    return true;
  }

  bool checkConditions(AutomationRule rule, Map<String, dynamic> sensorData) {
    // Check time range first
    final withinTime = _isWithinTimeRange(rule);
    if (!withinTime) {
      // Debug: Uncomment để debug thời gian
      // print('⏰ Rule "${rule.name}" not in time range');
      return false;
    }

    print(
      '📋 Rule "${rule.name}" - conditions: ${rule.conditions.length}, sensorData keys: ${sensorData.keys.toList()}',
    );

    // If no sensor conditions, only time matters
    if (rule.conditions.isEmpty) {
      print('✅ Rule "${rule.name}" triggered (time-based only)');
      return true;
    }

    // If sensor data is empty but rule has conditions
    // For time-based rules, ignore sensor conditions if no data available
    if (sensorData.isEmpty) {
      print(
        '⚠️ Rule "${rule.name}" has conditions but no sensor data - treating as time-only rule',
      );
      return true; // Cho phép trigger nếu đã trong time range
    }

    // Check if all conditions are met
    for (var condition in rule.conditions) {
      final sensorValue = sensorData[condition.sensorId];
      if (sensorValue == null) {
        // Debug: sensor value not available
        // print('⚠️ Sensor "${condition.sensorId}" value not available for rule "${rule.name}"');
        continue;
      }

      // Use the evaluate method from Condition class
      if (!condition.evaluate(sensorValue)) {
        return false;
      }
    }

    print('✅ Rule "${rule.name}" triggered (condition met)');
    return true;
  }

  List<AutomationRule> getTriggeredRules(Map<String, dynamic> sensorData) {
    return activeRules
        .where((rule) => checkConditions(rule, sensorData))
        .toList();
  }

  // Method to evaluate and execute rules (called from SensorProvider)
  void evaluateRules(
    Map<String, dynamic> sensorData,
    Function(String deviceId, dynamic action) executeAction,
  ) {
    print('🔍 Evaluating ${activeRules.length} active rules');
    for (var rule in activeRules) {
      print(
        '🔎 Checking rule "${rule.name}" (enabled: ${rule.enabled}, startActions: ${rule.startActions.length})',
      );
      if (checkConditions(rule, sensorData)) {
        print(
          '⚡ Rule "${rule.name}" matched! Actions count: ${rule.startActions.length}',
        );

        // Execute all start actions
        for (var action in rule.startActions) {
          print('🎬 Executing action: ${action.deviceId} - ${action.action}');
          executeAction(action.deviceId, action);
        }

        // Mark as triggered
        markRuleTriggered(rule.id);
      }
    }
  }
}
