import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../models/automation_rule.dart';
import '../../../models/sensor_data.dart';
import '../../../models/user_sensor.dart';
import '../../../models/device_model.dart';
import '../../../services/firestore_automation_service.dart';
import '../data/rule_engine_service.dart';

/// Provider for managing automation rules state
class AutomationProvider with ChangeNotifier {
  final FirestoreAutomationService _firestoreService =
      FirestoreAutomationService();
  late final RuleEngineService _ruleEngine;

  List<AutomationRule> _rules = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId; // User isolation

  // 🔴 Real-time listener subscription
  StreamSubscription<List<AutomationRule>>? _rulesSubscription;

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

  /// Set current user và setup real-time listener
  Future<void> setCurrentUser(String? userId) async {
    if (_currentUserId == userId) return;

    // 🛑 HỦY LISTENER CŨ
    _rulesSubscription?.cancel();
    _rulesSubscription = null;

    _currentUserId = userId;

    if (userId != null) {
      await _setupRealtimeListener(userId);
    } else {
      _rules = [];
      notifyListeners();
    }
  }

  /// Setup real-time listener để tự động sync rules từ Firestore
  Future<void> _setupRealtimeListener(String userId) async {
    try {
      debugPrint('👂 Setting up real-time listener for automation rules...');

      // 🔴 LẮng nghe real-time changes từ Firestore
      _rulesSubscription = _firestoreService
          .watchUserRules(userId)
          .listen(
            (rules) {
              debugPrint(
                '📡 Received real-time rules update: ${rules.length} rules',
              );

              _rules = rules;
              notifyListeners();
            },
            onError: (error) {
              debugPrint('❌ Error in real-time rules listener: $error');
              _setError('Real-time sync error: $error');
            },
          );

      debugPrint('✅ Real-time rules listener setup complete');
    } catch (e) {
      debugPrint('❌ Error setting up real-time rules listener: $e');
      _setError('Failed to setup real-time sync: $e');
    }
  }

  /// Clear user data when logout
  void clearUserData() {
    _rulesSubscription?.cancel();
    _rulesSubscription = null;

    _currentUserId = null;
    _rules = [];
    _clearError();
    notifyListeners();
    print('🧹 AutomationProvider: Cleared user data');
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

  /// Load all rules from Firestore (1 lần, không real-time)
  /// Deprecated: Use setCurrentUser để auto-setup real-time listener
  @Deprecated('Use setCurrentUser instead')
  Future<void> loadRules() async {
    if (_currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      _rules = await _firestoreService.loadUserRules(_currentUserId!);
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
    if (_currentUserId == null) {
      _setError('No current user');
      return false;
    }

    _clearError();

    // Validate rule
    final validationError = _ruleEngine.validateRule(rule);
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    try {
      // 🔥 LƯU VÀO FIRESTORE → Real-time listener sẽ tự động update _rules
      await _firestoreService.addRule(_currentUserId!, rule);
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
    if (_currentUserId == null) {
      _setError('No current user');
      return false;
    }

    _clearError();

    // Validate rule
    final validationError = _ruleEngine.validateRule(rule);
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    try {
      // 🔥 UPDATE VÀO FIRESTORE → Real-time listener sẽ tự động update _rules
      await _firestoreService.updateRule(_currentUserId!, rule);
      print('✅ Updated rule: ${rule.name}');
      return true;
    } catch (e) {
      _setError('Failed to update rule: $e');
      print('❌ Error updating rule: $e');
      return false;
    }
  }

  /// Toggle rule enabled/disabled
  Future<void> toggleRule(String id) async {
    if (_currentUserId == null) return;

    try {
      final rule = _rules.firstWhere((r) => r.id == id);
      final newEnabled = !rule.enabled;

      // 🔥 UPDATE VÀO FIRESTORE
      await _firestoreService.toggleRule(_currentUserId!, id, newEnabled);

      print('✅ Toggled rule: ${rule.name} -> $newEnabled');
    } catch (e) {
      _setError('Failed to toggle rule: $e');
      print('❌ Error toggling rule: $e');
    }
  }

  /// Delete a rule
  Future<bool> deleteRule(String id) async {
    if (_currentUserId == null) {
      _setError('No current user');
      return false;
    }

    _clearError();

    try {
      // 🔥 XÓA KHỎI FIRESTORE → Real-time listener sẽ tự động update _rules
      await _firestoreService.deleteRule(_currentUserId!, id);
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
    if (_currentUserId == null) return;

    try {
      // 🔥 XÓA TẤT CẢ KHỎI FIRESTORE
      await _firestoreService.deleteAllRules(_currentUserId!);
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

  /// Get rule history (DEPRECATED - không còn database local)
  @Deprecated('History feature needs to be reimplemented with Firestore')
  Future<List<Map<String, dynamic>>> getRuleHistory(String ruleId) async {
    // TODO: Implement with Firestore if needed
    return [];
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
    _rulesSubscription?.cancel(); // 🔴 Cancel real-time listener
    super.dispose();
  }
}
