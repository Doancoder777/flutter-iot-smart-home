import 'package:cloud_firestore/cloud_firestore.dart';

/// Service để quản lý user settings trên Firestore
///
/// Features:
/// - Lưu/load settings của user
/// - Real-time listener để auto-sync
/// - Default settings nếu chưa có
class FirestoreSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 📍 DOCUMENT PATHS
  // ========================================

  /// Lấy document reference cho settings của user
  DocumentReference _settingsDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('settings');
  }

  // ========================================
  // 📖 READ OPERATIONS
  // ========================================

  /// Load settings của user
  Future<Map<String, dynamic>> loadUserSettings(String userId) async {
    try {
      print('🔍 Firestore: Loading settings for user $userId...');

      final doc = await _settingsDoc(userId).get();

      if (!doc.exists) {
        print('ℹ️ No settings found, returning defaults');
        return _getDefaultSettings();
      }

      final settings = doc.data() as Map<String, dynamic>;
      print('✅ Firestore: Loaded settings');
      return settings;
    } catch (e) {
      print('❌ Firestore: Error loading settings: $e');
      return _getDefaultSettings();
    }
  }

  /// Lấy 1 setting value cụ thể
  Future<dynamic> getSetting(String userId, String key) async {
    try {
      final doc = await _settingsDoc(userId).get();

      if (!doc.exists) {
        return _getDefaultSettings()[key];
      }

      final settings = doc.data() as Map<String, dynamic>;
      return settings[key];
    } catch (e) {
      print('❌ Error getting setting: $e');
      return _getDefaultSettings()[key];
    }
  }

  // ========================================
  // ✍️ WRITE OPERATIONS
  // ========================================

  /// Lưu tất cả settings
  Future<bool> saveUserSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      print('💾 Firestore: Saving settings for user $userId...');

      await _settingsDoc(userId).set(settings, SetOptions(merge: true));

      print('✅ Firestore: Settings saved successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error saving settings: $e');
      return false;
    }
  }

  /// Update 1 setting cụ thể
  Future<bool> updateSetting(String userId, String key, dynamic value) async {
    try {
      print('🔄 Firestore: Updating setting $key...');

      await _settingsDoc(userId).set({key: value}, SetOptions(merge: true));

      print('✅ Firestore: Setting updated successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error updating setting: $e');
      return false;
    }
  }

  /// Update multiple settings
  Future<bool> updateSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      print('🔄 Firestore: Updating multiple settings...');

      await _settingsDoc(userId).set(settings, SetOptions(merge: true));

      print('✅ Firestore: Settings updated successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error updating settings: $e');
      return false;
    }
  }

  /// Xóa settings (reset về default)
  Future<bool> deleteSettings(String userId) async {
    try {
      print('🗑️ Firestore: Deleting settings for user $userId...');

      await _settingsDoc(userId).delete();

      print('✅ Firestore: Settings deleted successfully');
      return true;
    } catch (e) {
      print('❌ Firestore: Error deleting settings: $e');
      return false;
    }
  }

  // ========================================
  // 🔴 REAL-TIME LISTENERS
  // ========================================

  /// Lắng nghe thay đổi settings (Real-time)
  Stream<Map<String, dynamic>> watchUserSettings(String userId) {
    print('👂 Firestore: Setting up real-time listener for settings');

    return _settingsDoc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        print('ℹ️ Settings not found, using defaults');
        return _getDefaultSettings();
      }

      print('📡 Firestore: Received settings update');
      return doc.data() as Map<String, dynamic>;
    });
  }

  // ========================================
  // 🎯 DEFAULT SETTINGS
  // ========================================

  /// Default settings nếu chưa có
  Map<String, dynamic> _getDefaultSettings() {
    return {
      // Theme
      'theme': 'system', // light, dark, system
      'primaryColor': '#2196F3',

      // Language
      'language': 'vi', // vi, en
      // Notifications
      'notificationsEnabled': true,
      'alertSounds': true,
      'vibration': true,

      // Automation
      'automationEnabled': true,
      'runAutomationInBackground': true,

      // Display
      'showSensorHistory': true,
      'historyDays': 7,
      'temperatureUnit': 'celsius', // celsius, fahrenheit
      // MQTT
      'mqttReconnectAutomatically': true,
      'mqttQos': 1,

      // App
      'firstLaunch': true,
      'tutorialCompleted': false,
      'appVersion': '1.0.0',

      // Timestamps
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // ========================================
  // 🔧 SPECIFIC SETTINGS HELPERS
  // ========================================

  /// Theme settings
  Future<bool> updateTheme(String userId, String theme) async {
    return updateSetting(userId, 'theme', theme);
  }

  Future<String> getTheme(String userId) async {
    final value = await getSetting(userId, 'theme');
    return value ?? 'system';
  }

  /// Language settings
  Future<bool> updateLanguage(String userId, String language) async {
    return updateSetting(userId, 'language', language);
  }

  Future<String> getLanguage(String userId) async {
    final value = await getSetting(userId, 'language');
    return value ?? 'vi';
  }

  /// Notification settings
  Future<bool> toggleNotifications(String userId, bool enabled) async {
    return updateSetting(userId, 'notificationsEnabled', enabled);
  }

  Future<bool> getNotificationsEnabled(String userId) async {
    final value = await getSetting(userId, 'notificationsEnabled');
    return value ?? true;
  }

  /// Automation settings
  Future<bool> toggleAutomation(String userId, bool enabled) async {
    return updateSetting(userId, 'automationEnabled', enabled);
  }

  Future<bool> getAutomationEnabled(String userId) async {
    final value = await getSetting(userId, 'automationEnabled');
    return value ?? true;
  }

  // ========================================
  // 🧹 UTILITY
  // ========================================

  /// Reset settings về default
  Future<bool> resetToDefaults(String userId) async {
    try {
      print('🔄 Firestore: Resetting settings to defaults...');

      await _settingsDoc(userId).set(_getDefaultSettings());

      print('✅ Firestore: Settings reset to defaults');
      return true;
    } catch (e) {
      print('❌ Firestore: Error resetting settings: $e');
      return false;
    }
  }

  /// Check if settings exist
  Future<bool> settingsExist(String userId) async {
    try {
      final doc = await _settingsDoc(userId).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking settings existence: $e');
      return false;
    }
  }
}
