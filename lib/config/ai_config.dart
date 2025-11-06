import 'package:shared_preferences/shared_preferences.dart';

/// 🤖 AI Configuration for Gemini Voice Control
///
/// Get your API key from: https://aistudio.google.com/app/apikey
class AiConfig {
  /// Gemini API Key (Default - fallback)
  ///
  /// ⚠️ QUAN TRỌNG:
  /// - Người dùng có thể thay đổi API key trong Settings
  /// - API key được lưu trong SharedPreferences
  /// - Không commit API key cá nhân lên Git public repo
  static const String _defaultApiKey =
      'AIzaSyCVaAcxkhRJeSHffVwtD3Mwc1xWS02aVuU';

  /// Get API key from SharedPreferences or use default
  static Future<String> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('gemini_api_key');
      if (savedKey != null && savedKey.isNotEmpty) {
        return savedKey;
      }
    } catch (e) {
      print('⚠️ Error loading API key from SharedPreferences: $e');
    }
    return _defaultApiKey;
  }

  /// Legacy getter for backward compatibility
  static String get geminiApiKey => _defaultApiKey;

  /// Model name: gemini-2.0-flash-exp
  ///
  /// ⚡ Gemini 2.0 Flash - Experimental (Fastest & Latest)
  /// - Tốc độ: Nhanh nhất trong các model Gemini
  /// - Khả năng: Multimodal (text, image, audio, video)
  /// - Giá: Miễn phí trong thời gian experimental
  /// - Phù hợp: Real-time voice control, smart home automation
  static const String modelName = 'gemini-2.0-flash-exp';

  /// Timeout cho AI request (milliseconds)
  static const int requestTimeout = 10000; // 10 giây

  /// Số lần retry nếu request thất bại
  static const int maxRetries = 2;

  /// Temperature cho AI response (0.0 - 1.0)
  /// - 0.0: Deterministic (luôn trả về kết quả giống nhau)
  /// - 1.0: Creative (kết quả đa dạng hơn)
  static const double temperature = 0.1; // Low = consistent commands

  /// Maximum tokens cho response
  static const int maxTokens = 512;

  /// Safety settings (optional)
  static const bool enableSafetySettings =
      false; // Disable cho smart home commands
}
