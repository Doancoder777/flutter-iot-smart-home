import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/local_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final LocalStorageService _storageService;

  UserSettings _settings = UserSettings();

  UserSettings get settings => _settings;
  bool get isDarkMode => _settings.darkMode;
  bool get notificationsEnabled => _settings.notificationsEnabled;
  bool get gasAlertEnabled => _settings.gasAlertEnabled;
  bool get rainAlertEnabled => _settings.rainAlertEnabled;
  bool get soilAlertEnabled => _settings.soilAlertEnabled;
  bool get dustAlertEnabled => _settings.dustAlertEnabled;
  bool get motionAlertEnabled => _settings.motionAlertEnabled;
  int get gasThreshold => _settings.gasThreshold;
  int get dustThreshold => _settings.dustThreshold;
  double get soilThreshold => _settings.soilThreshold;
  String get language => _settings.language;

  SettingsProvider(this._storageService) {
    _loadSettings();
  }

  void _loadSettings() {
    final stored = _storageService.getUserSettings();
    if (stored != null) {
      _settings = UserSettings.fromJson(stored);
      print('⚙️ Settings loaded');
    } else {
      print('⚙️ Using default settings');
    }
  }

  void _saveSettings() {
    _storageService.saveUserSettings(_settings.toJson());
    print('💾 Settings saved');
  }

  void setDarkMode(bool value) {
    _settings = _settings.copyWith(darkMode: value);
    _saveSettings();
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _settings = _settings.copyWith(notificationsEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void setGasAlertEnabled(bool value) {
    _settings = _settings.copyWith(gasAlertEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void setRainAlertEnabled(bool value) {
    _settings = _settings.copyWith(rainAlertEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void setSoilAlertEnabled(bool value) {
    _settings = _settings.copyWith(soilAlertEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void setDustAlertEnabled(bool value) {
    _settings = _settings.copyWith(dustAlertEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void setMotionAlertEnabled(bool value) {
    _settings = _settings.copyWith(motionAlertEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void setGasThreshold(int value) {
    _settings = _settings.copyWith(gasThreshold: value);
    _saveSettings();
    notifyListeners();
  }

  void setDustThreshold(int value) {
    _settings = _settings.copyWith(dustThreshold: value);
    _saveSettings();
    notifyListeners();
  }

  void setSoilThreshold(double value) {
    _settings = _settings.copyWith(soilThreshold: value);
    _saveSettings();
    notifyListeners();
  }

  void setLanguage(String value) {
    _settings = _settings.copyWith(language: value);
    _saveSettings();
    notifyListeners();
  }

  void resetToDefaults() {
    _settings = UserSettings();
    _saveSettings();
    notifyListeners();
    print('🔄 Settings reset to defaults');
  }

  void updateSettings(UserSettings newSettings) {
    _settings = newSettings;
    _saveSettings();
    notifyListeners();
  }
}
