/// 🤖 AI Configuration for Gemini Voice Control
///
/// Get your API key from: https://aistudio.google.com/app/apikey
class AiConfig {
  /// Gemini API Key
  ///
  /// ⚠️ QUAN TRỌNG:
  /// - API key đã được setup sẵn
  /// - Không commit API key lên Git public repo
  static const String geminiApiKey = 'AIzaSyC8CAUR5s5euV4xeiOolhdxZAUjgjPTw5k';

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
