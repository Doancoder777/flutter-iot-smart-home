import '../models/sensor_data.dart';
import '../models/weather_prediction.dart';

/// Service dự báo thời tiết dựa trên dữ liệu cảm biến
class WeatherPredictionService {
  /// Phân tích dữ liệu cảm biến và dự báo thời tiết
  static WeatherPrediction predictWeather({required SensorData sensorData}) {
    // Lấy dữ liệu cảm biến từ SensorData object
    final temperature = sensorData.temperature;
    final humidity = sensorData.humidity;
    final rainLevel = sensorData.rain.toDouble();

    // Xác định điều kiện thời tiết
    WeatherCondition condition;
    String description;
    List<String> recommendations = [];

    // Logic dự báo dựa trên cảm biến
    if (rainLevel > 60) {
      // Mưa to / Bão
      condition = (humidity > 85 && temperature < 25)
          ? WeatherCondition.stormy
          : WeatherCondition.rainy;
      description = condition == WeatherCondition.stormy
          ? 'Có khả năng giông bão'
          : 'Trời đang mưa';
      recommendations = [
        '☔ Mang theo ô khi ra ngoài',
        '🏠 Nên ở trong nhà',
        '⚡ Cảnh giác với sấm sét',
      ];
    } else if (rainLevel > 20) {
      // Có mây, có thể mưa
      condition = WeatherCondition.partlyCloudy;
      description = 'Trời nhiều mây, có thể mưa';
      recommendations = [
        '☁️ Trời u ám, chuẩn bị ô',
        '👕 Mặc áo khoác nhẹ',
        '🌂 Có thể mưa rào',
      ];
    } else if (temperature > 35) {
      // Nóng
      condition = WeatherCondition.hot;
      description = 'Thời tiết rất nóng';
      recommendations = [
        '🔥 Tránh ra ngoài trời nắng',
        '💧 Uống nhiều nước',
        '🧴 Thoa kem chống nắng',
        '❄️ Bật điều hòa hoặc quạt',
      ];
    } else if (temperature < 18) {
      // Lạnh
      condition = WeatherCondition.cold;
      description = 'Thời tiết lạnh';
      recommendations = [
        '🧥 Mặc áo ấm khi ra ngoài',
        '☕ Uống nước ấm',
        '🌡️ Giữ ấm cơ thể',
      ];
    } else if (humidity < 40 && rainLevel < 5) {
      // Nắng ráo
      condition = WeatherCondition.sunny;
      description = 'Trời nắng đẹp';
      recommendations = [
        '☀️ Thời tiết lý tưởng để ra ngoài',
        '🌳 Tốt cho hoạt động ngoài trời',
        '🧴 Đừng quên kem chống nắng',
      ];
    } else {
      // U ám
      condition = WeatherCondition.cloudy;
      description = 'Trời nhiều mây';
      recommendations = [
        '☁️ Thời tiết mát mẻ',
        '🚶 Phù hợp đi dạo',
        '📷 Ánh sáng tốt cho chụp ảnh',
      ];
    }

    // Tính xác suất mưa dựa trên độ ẩm và rain sensor
    double rainProbability = _calculateRainProbability(humidity, rainLevel);

    return WeatherPrediction(
      condition: condition,
      temperature: temperature,
      humidity: humidity,
      rainProbability: rainProbability,
      description: description,
      recommendations: recommendations,
      timestamp: DateTime.now(),
    );
  }

  /// Tính xác suất mưa (%)
  static double _calculateRainProbability(double humidity, double rainLevel) {
    double probability = 0.0;

    // Độ ẩm cao → khả năng mưa cao
    if (humidity > 85) {
      probability += 40;
    } else if (humidity > 75) {
      probability += 25;
    } else if (humidity > 65) {
      probability += 15;
    }

    // Rain sensor phát hiện → khả năng mưa rất cao
    if (rainLevel > 60) {
      probability += 60; // Đang mưa rồi!
    } else if (rainLevel > 30) {
      probability += 35;
    } else if (rainLevel > 10) {
      probability += 20;
    }

    // Giới hạn 0-100%
    return probability.clamp(0.0, 100.0);
  }

  /// Lấy lời khuyên chi tiết theo điều kiện
  static String getDetailedAdvice(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 'Thời tiết tuyệt vời! Hãy tận hưởng ngày nắng đẹp nhưng đừng quên bảo vệ da.';
      case WeatherCondition.partlyCloudy:
        return 'Trời có mây, thoải mái hơn nhưng vẫn nên chuẩn bị ô phòng mưa bất chợt.';
      case WeatherCondition.cloudy:
        return 'Trời u ám, không nắng gắt. Thời điểm tốt cho các hoạt động ngoài trời.';
      case WeatherCondition.rainy:
        return 'Đang mưa! Hạn chế ra ngoài, nếu cần thiết hãy mang ô và mặc áo mưa.';
      case WeatherCondition.stormy:
        return 'Cảnh báo giông bão! Hãy ở trong nhà và tránh xa cửa sổ, thiết bị điện.';
      case WeatherCondition.hot:
        return 'Thời tiết nóng bức! Hạn chế tiếp xúc trực tiếp với nắng, uống nhiều nước.';
      case WeatherCondition.cold:
        return 'Thời tiết lạnh! Mặc ấm khi ra ngoài và giữ cơ thể luôn khô ráo.';
    }
  }
}
