import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/automation_rule.dart';

/// Service để quản lý automation rules trên Firestore
///
/// Features:
/// - CRUD operations cho automation rules
/// - Real-time listeners để auto-sync
/// - Query by enabled status
/// - Track last triggered time
class FirestoreAutomationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 📍 COLLECTION PATHS
  // ========================================

  /// Lấy collection reference cho automation rules của user
  CollectionReference _rulesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('automation_rules');
  }

  // ========================================
  // 📖 READ OPERATIONS
  // ========================================

  /// Load tất cả automation rules của user
  Future<List<AutomationRule>> loadUserRules(String userId) async {
    try {
      print('🔍 Firestore: Loading automation rules for user $userId...');

      final snapshot = await _rulesCollection(userId).get();

      final rules = snapshot.docs
          .map((doc) {
            try {
              return AutomationRule.fromJson(
                doc.data() as Map<String, dynamic>,
              );
            } catch (e) {
              print('❌ Error parsing rule ${doc.id}: $e');
              return null;
            }
          })
          .whereType<AutomationRule>()
          .toList();

      print('✅ Firestore: Loaded ${rules.length} automation rules');
      return rules;
    } catch (e) {
      print('❌ Firestore: Error loading automation rules: $e');
      return [];
    }
  }

  /// Load 1 rule theo ID
  Future<AutomationRule?> getRule(String userId, String ruleId) async {
    try {
      final doc = await _rulesCollection(userId).doc(ruleId).get();

      if (!doc.exists) {
        print('⚠️ Rule $ruleId not found');
        return null;
      }

      return AutomationRule.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error getting rule: $e');
      return null;
    }
  }

  // ========================================
  // ✍️ WRITE OPERATIONS
  // ========================================

  /// Thêm automation rule mới
  Future<bool> addRule(String userId, AutomationRule rule) async {
    try {
      print('➕ Firestore: Adding automation rule ${rule.name}...');

      await _rulesCollection(userId).doc(rule.id).set(rule.toJson());

      print('✅ Firestore: Rule added successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error adding rule: $e');
      return false;
    }
  }

  /// Update automation rule
  Future<bool> updateRule(String userId, AutomationRule rule) async {
    try {
      print('🔄 Firestore: Updating automation rule ${rule.name}...');

      await _rulesCollection(
        userId,
      ).doc(rule.id).set(rule.toJson(), SetOptions(merge: false));

      print('✅ Firestore: Rule updated successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error updating rule: $e');
      return false;
    }
  }

  /// Toggle rule enabled/disabled
  Future<bool> toggleRule(String userId, String ruleId, bool enabled) async {
    try {
      print('🔄 Firestore: Toggling rule $ruleId to $enabled...');

      await _rulesCollection(userId).doc(ruleId).update({'enabled': enabled});

      print('✅ Firestore: Rule toggled successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error toggling rule: $e');
      return false;
    }
  }

  /// Update last triggered time
  Future<bool> updateLastTriggered(
    String userId,
    String ruleId,
    DateTime timestamp,
  ) async {
    try {
      await _rulesCollection(
        userId,
      ).doc(ruleId).update({'lastTriggered': timestamp.toIso8601String()});

      return true;
    } catch (e) {
      print('❌ Error updating last triggered: $e');
      return false;
    }
  }

  /// Xóa automation rule
  Future<bool> deleteRule(String userId, String ruleId) async {
    try {
      print('🗑️ Firestore: Deleting automation rule $ruleId...');

      await _rulesCollection(userId).doc(ruleId).delete();

      print('✅ Firestore: Rule deleted successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error deleting rule: $e');
      return false;
    }
  }

  /// Lưu tất cả rules (bulk save)
  Future<bool> saveAllRules(String userId, List<AutomationRule> rules) async {
    try {
      print('💾 Firestore: Saving ${rules.length} automation rules...');

      final batch = _firestore.batch();

      for (final rule in rules) {
        final docRef = _rulesCollection(userId).doc(rule.id);
        batch.set(docRef, rule.toJson());
      }

      await batch.commit();

      print('✅ Firestore: All rules saved successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error saving rules: $e');
      return false;
    }
  }

  // ========================================
  // 🔴 REAL-TIME LISTENERS
  // ========================================

  /// Lắng nghe thay đổi của tất cả automation rules (Real-time)
  Stream<List<AutomationRule>> watchUserRules(String userId) {
    print('👂 Firestore: Setting up real-time listener for automation rules');

    return _rulesCollection(userId).snapshots().map((snapshot) {
      print(
        '📡 Firestore: Received rules update - ${snapshot.docs.length} rules',
      );

      return snapshot.docs
          .map((doc) {
            try {
              return AutomationRule.fromJson(
                doc.data() as Map<String, dynamic>,
              );
            } catch (e) {
              print('❌ Error parsing rule ${doc.id}: $e');
              return null;
            }
          })
          .whereType<AutomationRule>()
          .toList();
    });
  }

  /// Lắng nghe 1 rule cụ thể
  Stream<AutomationRule?> watchRule(String userId, String ruleId) {
    return _rulesCollection(userId).doc(ruleId).snapshots().map((doc) {
      if (!doc.exists) return null;

      try {
        return AutomationRule.fromJson(doc.data() as Map<String, dynamic>);
      } catch (e) {
        print('❌ Error parsing rule: $e');
        return null;
      }
    });
  }

  // ========================================
  // 🔍 QUERY OPERATIONS
  // ========================================

  /// Lấy enabled rules
  Future<List<AutomationRule>> getEnabledRules(String userId) async {
    try {
      final snapshot = await _rulesCollection(
        userId,
      ).where('enabled', isEqualTo: true).get();

      return snapshot.docs
          .map(
            (doc) =>
                AutomationRule.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('❌ Error getting enabled rules: $e');
      return [];
    }
  }

  /// Lấy disabled rules
  Future<List<AutomationRule>> getDisabledRules(String userId) async {
    try {
      final snapshot = await _rulesCollection(
        userId,
      ).where('enabled', isEqualTo: false).get();

      return snapshot.docs
          .map(
            (doc) =>
                AutomationRule.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('❌ Error getting disabled rules: $e');
      return [];
    }
  }

  /// Đếm số lượng rules
  Future<int> getRuleCount(String userId) async {
    try {
      final snapshot = await _rulesCollection(userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error counting rules: $e');
      return 0;
    }
  }

  /// Đếm số enabled rules
  Future<int> getEnabledRuleCount(String userId) async {
    try {
      final snapshot = await _rulesCollection(
        userId,
      ).where('enabled', isEqualTo: true).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error counting enabled rules: $e');
      return 0;
    }
  }

  // ========================================
  // 🧹 UTILITY
  // ========================================

  /// Xóa tất cả automation rules của user
  Future<bool> deleteAllRules(String userId) async {
    try {
      print('⚠️ Firestore: Deleting ALL automation rules for user $userId...');

      final snapshot = await _rulesCollection(userId).get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('✅ Firestore: All automation rules deleted');
      return true;
    } catch (e) {
      print('❌ Firestore: Error deleting all rules: $e');
      return false;
    }
  }

  /// Disable tất cả rules (emergency)
  Future<bool> disableAllRules(String userId) async {
    try {
      print('⚠️ Firestore: Disabling ALL automation rules...');

      final snapshot = await _rulesCollection(userId).get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'enabled': false});
      }

      await batch.commit();

      print('✅ Firestore: All automation rules disabled');
      return true;
    } catch (e) {
      print('❌ Firestore: Error disabling all rules: $e');
      return false;
    }
  }
}
