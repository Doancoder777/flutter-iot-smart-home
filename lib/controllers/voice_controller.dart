import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/ai_voice_service.dart';
import '../providers/device_provider.dart';
import '../models/device_model.dart';

/// 🎤 Voice Controller
///
/// Quản lý voice recognition và xử lý voice commands
/// - Speech to Text (nhận diện giọng nói)
/// - Parse command bằng Gemini AI
/// - Điều khiển thiết bị qua MQTT
class VoiceController extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final AiVoiceService _aiService;
  final DeviceProvider _deviceProvider;

  // State
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _lastCommand = '';
  String _statusMessage = '';
  String _errorMessage = '';
  List<String> _commandHistory = [];

  VoiceController({
    required AiVoiceService aiService,
    required DeviceProvider deviceProvider,
  }) : _aiService = aiService,
       _deviceProvider = deviceProvider;

  // Getters
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isInitialized => _isInitialized;
  bool get isBusy => _isListening || _isProcessing;
  String get lastCommand => _lastCommand;
  String get statusMessage => _statusMessage;
  String get errorMessage => _errorMessage;
  List<String> get commandHistory => _commandHistory;

  /// 🎬 Khởi tạo Voice Controller
  Future<bool> initialize() async {
    try {
      print('🎤 Voice Controller: Initializing...');

      // Check if speech recognition is available
      bool available = await _speechToText.initialize(
        onError: (error) {
          print('❌ Voice Controller: Error - ${error.errorMsg}');
          _errorMessage = 'Lỗi: ${error.errorMsg}';
          _isListening = false; // ✅ Dừng nghe khi có lỗi
          notifyListeners();
        },
        onStatus: (status) {
          print('🎤 Voice Controller: Status - $status');
          // ✅ Tự động dừng khi hết timeout hoặc done
          if (status == 'done' || status == 'notListening') {
            if (_isListening) {
              _isListening = false;
              if (_lastCommand.isEmpty) {
                _statusMessage = '⚠️ Không nhận được lệnh';
              }
              notifyListeners();
            }
          }
        },
      );

      if (!available) {
        _statusMessage = '❌ Không hỗ trợ nhận diện giọng nói';
        _errorMessage = 'Thiết bị không hỗ trợ Speech Recognition';
        _isInitialized = false;
        notifyListeners();
        return false;
      }

      // ✅ Check available locales
      List<dynamic> locales = await _speechToText.locales();
      print('📋 Available locales: ${locales.length}');
      for (var locale in locales.take(5)) {
        print('   - ${locale.localeId}: ${locale.name}');
      }

      // Check if vi-VN is available
      bool hasVietnamese = locales.any((l) => l.localeId.contains('vi'));
      print('🇻🇳 Vietnamese available: $hasVietnamese');

      _isInitialized = true;
      _statusMessage = hasVietnamese
          ? '✅ Sẵn sàng nhận lệnh giọng nói (Tiếng Việt)'
          : '⚠️ Sẵn sàng (chưa có tiếng Việt)';
      _errorMessage = '';
      notifyListeners();

      print('✅ Voice Controller: Initialized successfully');
      return true;
    } catch (e) {
      print('❌ Voice Controller: Initialize failed - $e');
      _statusMessage = '❌ Lỗi khởi tạo';
      _errorMessage = e.toString();
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  /// 🎤 Bắt đầu nghe
  Future<void> startListening() async {
    if (!_isInitialized) {
      print('⚠️ Voice Controller: Not initialized');
      _statusMessage = '⚠️ Chưa khởi tạo';
      notifyListeners();
      return;
    }

    if (_isListening) {
      print('⚠️ Voice Controller: Already listening');
      return;
    }

    try {
      _isListening = true;
      _statusMessage = '🎤 Đang nghe...';
      _errorMessage = '';
      _lastCommand = '';
      notifyListeners();

      print('🎤 Voice Controller: Start listening...');

      // ✅ Kiểm tra xem có locale nào available không
      List<dynamic> locales = await _speechToText.locales();
      String localeToUse = 'vi-VN';

      // Nếu không có tiếng Việt, dùng English hoặc system locale
      bool hasVietnamese = locales.any((l) => l.localeId.contains('vi'));
      if (!hasVietnamese && locales.isNotEmpty) {
        var systemLocale = await _speechToText.systemLocale();
        localeToUse = systemLocale?.localeId ?? 'en-US';
        print('⚠️ Vietnamese not available, using: $localeToUse');
      }

      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: localeToUse,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        listenFor: Duration(seconds: 10), // ✅ Auto stop sau 10 giây
        pauseFor: Duration(seconds: 5), // ✅ Dừng sau 5 giây không nói
      );

      print(
        '🎤 Voice Controller: Listening started (locale: $localeToUse, timeout: 10s)',
      );
    } catch (e) {
      print('❌ Voice Controller: Start listening failed - $e');
      _isListening = false;
      _statusMessage = '❌ Lỗi khi bắt đầu nghe';
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 🛑 Dừng nghe
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;

      if (_lastCommand.isEmpty) {
        _statusMessage = '⚠️ Không nhận được lệnh';
      }

      notifyListeners();
      print('🛑 Voice Controller: Stopped listening');
    } catch (e) {
      print('❌ Voice Controller: Stop listening failed - $e');
      _isListening = false;
      notifyListeners();
    }
  }

  /// 📝 Callback khi nhận được kết quả speech
  void _onSpeechResult(result) {
    _lastCommand = result.recognizedWords;

    print(
      '🔊 Voice Controller: Recognized - "$_lastCommand" (final: ${result.finalResult})',
    );

    if (result.finalResult) {
      print('✅ Voice Controller: Final result - "$_lastCommand"');
      _isListening = false;
      _statusMessage = '📝 Nhận được: "$_lastCommand"';
      notifyListeners();

      // Process command
      if (_lastCommand.isNotEmpty) {
        processCommand(_lastCommand);
      } else {
        print('⚠️ Voice Controller: Empty final result');
        _statusMessage = '⚠️ Không nhận được lệnh';
      }
    } else {
      // Partial result - hiển thị để user biết nó đang nghe
      print('🎤 Voice Controller: Partial - "$_lastCommand"');
      _statusMessage = '🎤 Đang nghe: "$_lastCommand"';
      notifyListeners();
    }
  }

  /// 🤖 Xử lý voice command bằng Gemini AI
  Future<void> processCommand(String command) async {
    if (_isProcessing) {
      print('⚠️ Voice Controller: Already processing');
      return;
    }

    try {
      _isProcessing = true;
      _statusMessage = '🤖 Đang xử lý lệnh...';
      _errorMessage = '';
      notifyListeners();

      print('🤖 Voice Controller: Processing command - "$command"');

      // Lấy danh sách thiết bị từ DeviceProvider
      final devices = _deviceProvider.devices;

      if (devices.isEmpty) {
        _statusMessage = '⚠️ Không có thiết bị nào';
        _errorMessage = 'Bạn chưa có thiết bị nào để điều khiển';
        _isProcessing = false;
        notifyListeners();
        return;
      }

      print('📱 Voice Controller: Available devices - ${devices.length}');

      // Gửi command đến Gemini AI
      final result = await _aiService.processVoiceCommand(
        userId: _deviceProvider.currentUserId ?? '',
        voiceCommand: command,
        devices: devices,
      );

      // Xử lý kết quả
      if (result == null || !result.success) {
        _statusMessage = '❌ ${result?.error ?? "Không hiểu lệnh"}';
        _errorMessage = result?.error ?? "Không hiểu lệnh";
        _isProcessing = false;
        notifyListeners();
        return;
      }

      print(
        '✅ Voice Controller: AI parsed - Device: ${result.deviceKeyName}, Action: ${result.action}',
      );

      // Tìm device bằng FUZZY MATCHING (nhiều cách)
      Device? device = _findDeviceByKey(devices, result.deviceKeyName!);

      if (device == null) {
        _statusMessage = '❌ Không tìm thấy thiết bị "${result.deviceKeyName}"';
        _errorMessage = 'Thiết bị không tồn tại trong hệ thống';
        _isProcessing = false;
        notifyListeners();
        return;
      }

      print(
        '📱 Voice Controller: Found device - ${device.name} (${device.deviceCode})',
      );

      // Thực hiện action
      await _executeAction(device, result.action!, result.value);

      // Add to history
      _commandHistory.insert(0, command);
      if (_commandHistory.length > 10) {
        _commandHistory = _commandHistory.sublist(0, 10);
      }

      _statusMessage =
          '✅ Đã thực hiện: ${device.name} - ${_getActionText(result.action!)}';
      _errorMessage = '';
      _isProcessing = false;
      notifyListeners();

      print('✅ Voice Controller: Command executed successfully');
    } catch (e) {
      print('❌ Voice Controller: Process command failed - $e');
      _statusMessage = '❌ Lỗi xử lý: $e';
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 🎯 Thực hiện action trên device
  Future<void> _executeAction(
    Device device,
    String action,
    dynamic value,
  ) async {
    print('🎯 Voice Controller: Executing action - $action on ${device.name}');

    switch (action) {
      case 'turn_on':
        // ✅ Sử dụng updateDeviceState để gửi MQTT + update Firestore
        _deviceProvider.updateDeviceState(device.id, true);
        break;

      case 'turn_off':
        // ✅ Sử dụng updateDeviceState để gửi MQTT + update Firestore
        _deviceProvider.updateDeviceState(device.id, false);
        break;

      case 'toggle':
        // ✅ toggleDevice đã có MQTT
        _deviceProvider.toggleDevice(device.id);
        break;

      case 'set_value':
        if (value != null) {
          int intValue = value is int
              ? value
              : int.tryParse(value.toString()) ?? 0;
          // ✅ Sử dụng updateServoValue cho servo/fan (có MQTT)
          _deviceProvider.updateServoValue(device.id, intValue);
        }
        break;

      default:
        print('⚠️ Voice Controller: Unknown action - $action');
    }
  }

  /// 📝 Lấy text hiển thị cho action
  String _getActionText(String action) {
    switch (action) {
      case 'turn_on':
        return 'Bật';
      case 'turn_off':
        return 'Tắt';
      case 'toggle':
        return 'Đảo trạng thái';
      case 'set_value':
        return 'Đặt giá trị';
      default:
        return action;
    }
  }

  /// 🔍 Tìm thiết bị bằng FUZZY MATCHING (nhiều cách)
  Device? _findDeviceByKey(List<Device> devices, String searchKey) {
    if (devices.isEmpty || searchKey.isEmpty) return null;

    // Chuẩn hóa search key
    final normalizedSearch = _normalizeString(searchKey);

    print(
      '🔍 Tìm thiết bị với key: "$searchKey" (normalized: "$normalizedSearch")',
    );

    // 1. Tìm chính xác bằng keyName
    var device = devices
        .where((d) => d.keyName == normalizedSearch)
        .firstOrNull;
    if (device != null) {
      print('✅ Tìm thấy (exact keyName): ${device.name}');
      return device;
    }

    // 2. Tìm chính xác bằng deviceCode
    device = devices.where((d) => d.deviceCode == searchKey).firstOrNull;
    if (device != null) {
      print('✅ Tìm thấy (exact deviceCode): ${device.name}');
      return device;
    }

    // 3. Tìm bằng tên hiển thị (normalize cả 2 bên)
    device = devices
        .where((d) => _normalizeString(d.name) == normalizedSearch)
        .firstOrNull;
    if (device != null) {
      print('✅ Tìm thấy (normalized name): ${device.name}');
      return device;
    }

    // 4. Tìm kiếm partial match (keyName chứa search key)
    device = devices
        .where((d) => d.keyName.contains(normalizedSearch))
        .firstOrNull;
    if (device != null) {
      print('✅ Tìm thấy (partial keyName): ${device.name}');
      return device;
    }

    // 5. Tìm kiếm partial match (tên hiển thị chứa search key)
    device = devices
        .where((d) => _normalizeString(d.name).contains(normalizedSearch))
        .firstOrNull;
    if (device != null) {
      print('✅ Tìm thấy (partial name): ${device.name}');
      return device;
    }

    // 6. Tìm theo từ khóa (split và match)
    final keywords = normalizedSearch.split('_').where((s) => s.isNotEmpty);
    for (final d in devices) {
      final deviceName = _normalizeString(d.name);
      final deviceKey = d.keyName;

      // Đếm số từ khóa khớp
      int matchCount = 0;
      for (final keyword in keywords) {
        if (deviceName.contains(keyword) || deviceKey.contains(keyword)) {
          matchCount++;
        }
      }

      // Nếu khớp >= 50% số từ khóa → chấp nhận
      if (matchCount >= keywords.length * 0.5) {
        print(
          '✅ Tìm thấy (keyword match $matchCount/${keywords.length}): ${d.name}',
        );
        return d;
      }
    }

    print('❌ Không tìm thấy thiết bị nào phù hợp');
    return null;
  }

  /// Chuẩn hóa chuỗi (lowercase, bỏ dấu, trim)
  String _normalizeString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .trim();
  }

  /// 🧹 Xóa lịch sử commands
  void clearHistory() {
    _commandHistory.clear();
    notifyListeners();
  }

  /// 🔄 Reset state
  void reset() {
    _isListening = false;
    _isProcessing = false;
    _lastCommand = '';
    _statusMessage = '✅ Sẵn sàng nhận lệnh giọng nói';
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
