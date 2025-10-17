import 'package:flutter/foundation.dart';
import '../../../models/automation_rule.dart';
import '../../../models/sensor_data.dart';
import '../../../models/user_sensor.dart';
import '../../../models/device_model.dart';
import '../data/automation_database.dart';
import '../data/rule_engine_service.dart';

/// Provider for managing automation rules state
class AutomationProvider with ChangeNotifier {
  final AutomationDatabase _database = AutomationDatabase();
  late final RuleEngineService _ruleEngine;

  List<AutomationRule> _rules = [];
  bool _isLoading = false;
  String? _error;

  // Callback for executing device actions
  final Function(String ruleId, List<Action> actions)? onRuleTriggered;

  // 🔄 Data sources for dynamic rule evaluation
  List<UserSensor> _userSensors = [];
  List<Device> _userDevices = [];

  AutomationProvider({this.onRuleTriggered}) {
    _ruleEngine = RuleEngineService(
      onRuleTriggered: (ruleId, actions) {
        onRuleTriggered?.call(ruleId, actions);
        notifyListeners();
      },
    );
  }

  /// 🔄 UPDATE DATA SOURCES - Call this when user data changes
  void updateDataSources({
    required List<UserSensor> userSensors,
    required List<Device> userDevices,
  }) {
    _userSensors = userSensors;
    _userDevices = userDevices;

    // Update rule engine with new data
    _ruleEngine.updateDataSources(
      userSensors: _userSensors,
      userDevices: _userDevices,
    );

    print('🔄 AutomationProvider: Updated data sources');
  }

  // ════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════

  List<AutomationRule> get rules => _rules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  List<AutomationRule> get enabledRules =>
      _rules.where((r) => r.enabled).toList();

  List<AutomationRule> get disabledRules =>
      _rules.where((r) => !r.enabled).toList();

  int get totalRules => _rules.length;
  int get enabledCount => enabledRules.length;

  // 🔄 GETTERS FOR UI
  List<UserSensor> get availableSensors =>
      _userSensors.where((s) => s.isActive).toList();
  List<Device> get availableDevices =>
      _userDevices.where((d) => d.isOn).toList();

  // ════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ════════════════════════════════════════════════════════

  /// Load all rules from database
  Future<void> loadRules() async {
    _setLoading(true);
    _clearError();

    try {
      _rules = await _database.getAllRules();
      print('✅ Loaded ${_rules.length} automation rules');
    } catch (e) {
      _setError('Failed to load rules: $e');
      print('❌ Error loading rules: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new rule
  Future<bool> addRule(AutomationRule rule) async {
    _clearError();

    // Validate rule
    final validationError = _ruleEngine.validateRule(rule);
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    try {
      await _database.insertRule(rule);
      _rules.add(rule);
      notifyListeners();
      print('✅ Added rule: ${rule.name}');
      return true;
    } catch (e) {
      _setError('Failed to add rule: $e');
      print('❌ Error adding rule: $e');
      return false;
    }
  }

  /// Update an existing rule
  Future<bool> updateRule(AutomationRule rule) async {
    _clearError();

    // Validate rule
    final validationError = _ruleEngine.validateRule(rule);
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    try {
      await _database.updateRule(rule);
      final index = _rules.indexWhere((r) => r.id == rule.id);
      if (index != -1) {
        _rules[index] = rule;
        notifyListeners();
        print('✅ Updated rule: ${rule.name}');
      }
      return true;
    } catch (e) {
      _setError('Failed to update rule: $e');
      print('❌ Error updating rule: $e');
      return false;
    }
  }

  /// Toggle rule enabled/disabled
  Future<void> toggleRule(String id) async {
    try {
      final index = _rules.indexWhere((r) => r.id == id);
      if (index != -1) {
        final updatedRule = _rules[index].copyWith(
          enabled: !_rules[index].enabled,
        );
        await _database.toggleRule(id, updatedRule.enabled);
        _rules[index] = updatedRule;
        notifyListeners();
        print('✅ Toggled rule: ${updatedRule.name} -> ${updatedRule.enabled}');
      }
    } catch (e) {
      _setError('Failed to toggle rule: $e');
      print('❌ Error toggling rule: $e');
    }
  }

  /// Delete a rule
  Future<bool> deleteRule(String id) async {
    _clearError();

    try {
      await _database.deleteRule(id);
      _rules.removeWhere((r) => r.id == id);
      notifyListeners();
      print('✅ Deleted rule: $id');
      return true;
    } catch (e) {
      _setError('Failed to delete rule: $e');
      print('❌ Error deleting rule: $e');
      return false;
    }
  }

  /// Delete all rules
  Future<void> deleteAllRules() async {
    try {
      await _database.deleteAllRules();
      _rules.clear();
      notifyListeners();
      print('✅ Deleted all rules');
    } catch (e) {
      _setError('Failed to delete all rules: $e');
      print('❌ Error deleting all rules: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // RULE EVALUATION
  // ════════════════════════════════════════════════════════

  /// Evaluate rules against sensor data (called when new data arrives)
  Future<void> evaluateRules(SensorData sensorData) async {
    await _ruleEngine.evaluateRules(sensorData);
  }

  /// Test a rule without triggering actions
  Future<bool> testRule(AutomationRule rule, SensorData sensorData) async {
    return await _ruleEngine.testRule(rule, sensorData);
  }

  /// Get rule history
  Future<List<Map<String, dynamic>>> getRuleHistory(String ruleId) async {
    return await _database.getRuleHistory(ruleId);
  }

  // ════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  AutomationRule? getRuleById(String id) {
    try {
      return _rules.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear debounce for manual testing
  void clearDebounce(String ruleId) {
    _ruleEngine.clearDebounce(ruleId);
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}
