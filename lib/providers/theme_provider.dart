import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _storageService;

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider(this._storageService) {
    _loadTheme();
  }

  void _loadTheme() {
    _isDarkMode = _storageService.getDarkMode();
    print('🎨 Theme loaded: ${_isDarkMode ? "Dark" : "Light"}');
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storageService.setDarkMode(_isDarkMode);
    notifyListeners();
    print('🎨 Theme changed to: ${_isDarkMode ? "Dark" : "Light"}');
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _storageService.setDarkMode(value);
    notifyListeners();
    print('🎨 Theme set to: ${_isDarkMode ? "Dark" : "Light"}');
  }

  void setLightMode() {
    setDarkMode(false);
  }
}
