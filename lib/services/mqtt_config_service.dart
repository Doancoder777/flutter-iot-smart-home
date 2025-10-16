import '../models/mqtt_config.dart';
import '../services/local_storage_service.dart';
import '../config/mqtt_config.dart' as global;

class MqttConfigService {
  final LocalStorageService _storageService;

  MqttConfigService(this._storageService);

  /// Load MQTT config for specific user, fallback to default if not found
  Future<MqttConfig> loadUserMqttConfig(String? userId) async {
    try {
      final configData = _storageService.getMqttConfig(userId: userId);

      if (configData != null) {
        print('📡 Loading custom MQTT config for user: $userId');
        return MqttConfig.fromJson(configData);
      } else {
        print(
          '📡 No custom MQTT config found for user: $userId, using default',
        );
        return _getDefaultConfig();
      }
    } catch (e) {
      print('❌ Error loading MQTT config: $e');
      return _getDefaultConfig();
    }
  }

  /// Save MQTT config for specific user
  Future<void> saveUserMqttConfig(String userId, MqttConfig config) async {
    try {
      await _storageService.saveMqttConfig(config.toJson(), userId: userId);
      print('💾 Saved MQTT config for user: $userId');
    } catch (e) {
      print('❌ Error saving MQTT config: $e');
      rethrow;
    }
  }

  /// Get default MQTT configuration từ file cấu hình tập trung
  MqttConfig _getDefaultConfig() {
    return MqttConfig.fromJson(global.MqttConfig.toJson());
  }

  /// Clear MQTT config for user
  Future<void> clearUserMqttConfig(String userId) async {
    try {
      // This would remove the config from storage
      // For now, we don't have a direct delete method, so we can save empty config
      await _storageService.saveMqttConfig({}, userId: userId);
      print('🗑️ Cleared MQTT config for user: $userId');
    } catch (e) {
      print('❌ Error clearing MQTT config: $e');
    }
  }
}
