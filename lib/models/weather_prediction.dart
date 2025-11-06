/// Model dự báo thời tiết dựa trên cảm biến
class WeatherPrediction {
  final WeatherCondition condition;
  final double temperature;
  final double humidity;
  final double rainProbability;
  final String description;
  final List<String> recommendations;
  final DateTime timestamp;

  WeatherPrediction({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
    required this.description,
    required this.recommendations,
    required this.timestamp,
  });

  /// Icon emoji cho điều kiện thời tiết
  String get icon {
    switch (condition) {
      case WeatherCondition.sunny:
        return '☀️';
      case WeatherCondition.partlyCloudy:
        return '⛅';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.rainy:
        return '🌧️';
      case WeatherCondition.stormy:
        return '⛈️';
      case WeatherCondition.hot:
        return '🔥';
      case WeatherCondition.cold:
        return '❄️';
    }
  }

  /// Màu sắc theo điều kiện
  String get colorHex {
    switch (condition) {
      case WeatherCondition.sunny:
        return '#FFD700'; // Gold
      case WeatherCondition.partlyCloudy:
        return '#FFA500'; // Orange
      case WeatherCondition.cloudy:
        return '#B0B0B0'; // Gray
      case WeatherCondition.rainy:
        return '#4682B4'; // Steel Blue
      case WeatherCondition.stormy:
        return '#483D8B'; // Dark Slate Blue
      case WeatherCondition.hot:
        return '#FF4500'; // Orange Red
      case WeatherCondition.cold:
        return '#00CED1'; // Dark Turquoise
    }
  }
}

/// Các điều kiện thời tiết
enum WeatherCondition {
  sunny, // Nắng
  partlyCloudy, // Có mây
  cloudy, // U ám
  rainy, // Mưa
  stormy, // Giông bão
  hot, // Nóng
  cold, // Lạnh
}
