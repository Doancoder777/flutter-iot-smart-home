import 'package:flutter/material.dart';
import 'sensor_type.dart';

/// Mức độ sức khỏe của cảm biến
enum HealthLevel {
  excellent, // Xuất sắc
  good, // Tốt
  moderate, // Trung bình
  poor, // Xấu
  dangerous, // Nguy hiểm
  unknown, // Chưa có dữ liệu
}

/// Thông tin về mức độ sức khỏe
class HealthInfo {
  final HealthLevel level;
  final String label;
  final String description;
  final Color color;
  final IconData icon;
  final String? actionAdvice; // Gợi ý hành động

  const HealthInfo({
    required this.level,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    this.actionAdvice,
  });

  /// Lấy màu theo level
  static Color getColorForLevel(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return const Color(0xFF00C853); // Xanh đậm
      case HealthLevel.good:
        return const Color(0xFF4CAF50); // Xanh
      case HealthLevel.moderate:
        return const Color(0xFFFFC107); // Vàng
      case HealthLevel.poor:
        return const Color(0xFFFF9800); // Cam
      case HealthLevel.dangerous:
        return const Color(0xFFF44336); // Đỏ
      case HealthLevel.unknown:
        return const Color(0xFF9E9E9E); // Xám
    }
  }

  /// Lấy icon theo level
  static IconData getIconForLevel(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return Icons.check_circle;
      case HealthLevel.good:
        return Icons.thumb_up;
      case HealthLevel.moderate:
        return Icons.warning_amber;
      case HealthLevel.poor:
        return Icons.error_outline;
      case HealthLevel.dangerous:
        return Icons.dangerous;
      case HealthLevel.unknown:
        return Icons.help_outline;
    }
  }
}

/// Ngưỡng cho các loại cảm biến
class SensorThresholds {
  // 🌡️ NHIỆT ĐỘ (°C)
  static const Map<String, List<double>> temperature = {
    'excellent': [20, 26], // 20-26°C
    'good': [18, 28], // 18-28°C
    'moderate': [15, 32], // 15-32°C
    'poor': [10, 35], // 10-35°C
    // < 10 hoặc > 35 = dangerous
  };

  // 💧 ĐỘ ẨM KHÔNG KHÍ (%)
  static const Map<String, List<double>> humidity = {
    'excellent': [40, 60], // 40-60% - Lý tưởng
    'good': [30, 70], // 30-70% - Tốt
    'moderate': [20, 85], // 20-85% - Hơi ẩm/khô
    'poor': [15, 95], // 15-95% - Ẩm ướt hoặc hanh khô
    // < 15 = rất khô, > 95 = cực kỳ ẩm (hiếm khi xảy ra)
  };

  // 🌱 ĐỘ ẨM ĐẤT (%)
  static const Map<String, List<double>> soilMoisture = {
    'excellent': [40, 70], // 40-70%
    'good': [30, 80], // 30-80%
    'moderate': [20, 90], // 20-90%
    'poor': [10, 95], // 10-95%
    // < 10 = dangerous (cần tưới ngay)
  };

  // ☀️ ÁNH SÁNG (lux)
  static const Map<String, List<double>> light = {
    'excellent': [500, 1000], // Lý tưởng cho sinh hoạt
    'good': [200, 1500], // Đủ sáng
    'moderate': [100, 2000], // Hơi tối/sáng
    'poor': [30, 3000], // Tối hoặc chói
    // < 30 = rất tối, > 3000 = rất chói (không phải "nguy hiểm")
  };

  // ☁️ KHÍ GAS (ppm)
  static const Map<String, List<double>> gas = {
    'excellent': [0, 100],
    'good': [100, 200],
    'moderate': [200, 300],
    'poor': [300, 400],
    // > 400 = dangerous
  };

  // 🌫️ BỤI PM2.5 (µg/m³)
  static const Map<String, List<double>> dust = {
    'excellent': [0, 35],
    'good': [35, 75],
    'moderate': [75, 115],
    'poor': [115, 150],
    // > 150 = dangerous
  };

  // 🔥 KHÓI (ppm)
  static const Map<String, List<double>> smoke = {
    'excellent': [0, 50],
    'good': [50, 100],
    'moderate': [100, 200],
    'poor': [200, 500],
    // > 500 = dangerous
  };

  // 🔽 ÁP SUẤT (hPa)
  static const Map<String, List<double>> pressure = {
    'excellent': [1010, 1020],
    'good': [1000, 1030],
    'moderate': [990, 1040],
    'poor': [980, 1050],
    // Ngoài range = unusual
  };

  // ☢️ TIA UV (index)
  static const Map<String, List<double>> uv = {
    'excellent': [0, 2],
    'good': [3, 5],
    'moderate': [6, 7],
    'poor': [8, 10],
    // > 10 = very high/dangerous
  };

  // 💨 GIÓ (km/h) - cho tương lai
  static const Map<String, List<double>> wind = {
    'excellent': [0, 10],
    'good': [10, 20],
    'moderate': [20, 40],
    'poor': [40, 60],
    // > 60 = storm
  };

  // 🔊 TIẾNG ỒN (dB)
  static const Map<String, List<double>> noise = {
    'excellent': [0, 40],
    'good': [40, 55],
    'moderate': [55, 70],
    'poor': [70, 85],
    // > 85 = harmful
  };

  // ⚗️ pH
  static const Map<String, List<double>> ph = {
    'excellent': [6.5, 7.5],
    'good': [6.0, 8.0],
    'moderate': [5.5, 8.5],
    'poor': [5.0, 9.0],
    // < 5 hoặc > 9 = dangerous
  };

  // 💨 CO2 (ppm)
  static const Map<String, List<double>> co2 = {
    'excellent': [0, 600],
    'good': [600, 1000],
    'moderate': [1000, 1500],
    'poor': [1500, 2000],
    // > 2000 = poor air quality
  };

  // 🌧️ CẢM BIẾN MƯA (0-1023, analog sensor)
  // Giá trị CAO = KHÔ, giá trị THẤP = ƯỚT (rain detected)
  static const Map<String, List<double>> rain = {
    'excellent': [700, 1023], // Rất khô ráo
    'good': [500, 699], // Khô
    'moderate': [300, 499], // Hơi ẩm
    'poor': [100, 299], // Có mưa nhẹ
    // < 100 = Mưa to (không phải "dangerous", chỉ là mưa thôi)
  };

  /// Lấy threshold cho sensor type
  static Map<String, List<double>>? getThresholds(String sensorTypeId) {
    switch (sensorTypeId) {
      case 'temperature':
        return temperature;
      case 'humidity':
        return humidity;
      case 'soil_moisture':
        return soilMoisture;
      case 'light':
        return light;
      case 'gas':
        return gas;
      case 'dust':
        return dust;
      case 'smoke':
        return smoke;
      case 'pressure':
        return pressure;
      case 'uv':
        return uv;
      case 'wind':
        return wind;
      case 'noise':
        return noise;
      case 'ph':
        return ph;
      case 'co2':
        return co2;
      case 'rain':
        return rain;
      default:
        return null; // Không có threshold định nghĩa
    }
  }
}

/// Helper class để tính toán health level
class SensorHealthCalculator {
  /// Tính health level dựa trên giá trị và sensor type
  static HealthInfo calculateHealth({
    required String sensorTypeId,
    required dynamic value,
    SensorType? sensorType,
  }) {
    // Nếu value null hoặc không hợp lệ
    if (value == null) {
      return HealthInfo(
        level: HealthLevel.unknown,
        label: 'Chưa có dữ liệu',
        description: 'Chưa nhận được dữ liệu từ cảm biến',
        color: HealthInfo.getColorForLevel(HealthLevel.unknown),
        icon: HealthInfo.getIconForLevel(HealthLevel.unknown),
      );
    }

    // Chuyển value thành double
    double numValue;
    try {
      numValue = (value as num).toDouble();
    } catch (e) {
      return HealthInfo(
        level: HealthLevel.unknown,
        label: 'Dữ liệu không hợp lệ',
        description: 'Không thể đọc giá trị cảm biến',
        color: HealthInfo.getColorForLevel(HealthLevel.unknown),
        icon: HealthInfo.getIconForLevel(HealthLevel.unknown),
      );
    }

    // Lấy threshold cho sensor type
    final thresholds = SensorThresholds.getThresholds(sensorTypeId);

    if (thresholds == null) {
      // Không có threshold → dùng auto mode dựa trên min/max
      return _calculateAutoHealth(numValue, sensorType);
    }

    // Tính health level dựa trên threshold
    return _calculateThresholdHealth(sensorTypeId, numValue, thresholds);
  }

  /// Tính health tự động dựa trên min/max
  static HealthInfo _calculateAutoHealth(double value, SensorType? sensorType) {
    if (sensorType == null ||
        sensorType.minValue == null ||
        sensorType.maxValue == null) {
      return HealthInfo(
        level: HealthLevel.good,
        label: 'Bình thường',
        description: 'Giá trị đang trong phạm vi cho phép',
        color: HealthInfo.getColorForLevel(HealthLevel.good),
        icon: HealthInfo.getIconForLevel(HealthLevel.good),
      );
    }

    final min = sensorType.minValue!;
    final max = sensorType.maxValue!;
    final range = max - min;
    final percent = ((value - min) / range * 100).clamp(0, 100);

    // Phân loại theo %
    if (percent >= 40 && percent <= 60) {
      return HealthInfo(
        level: HealthLevel.excellent,
        label: 'Xuất sắc',
        description: 'Giá trị trong khoảng tối ưu',
        color: HealthInfo.getColorForLevel(HealthLevel.excellent),
        icon: HealthInfo.getIconForLevel(HealthLevel.excellent),
      );
    } else if (percent >= 30 && percent <= 70) {
      return HealthInfo(
        level: HealthLevel.good,
        label: 'Tốt',
        description: 'Giá trị ở mức tốt',
        color: HealthInfo.getColorForLevel(HealthLevel.good),
        icon: HealthInfo.getIconForLevel(HealthLevel.good),
      );
    } else if (percent >= 20 && percent <= 80) {
      return HealthInfo(
        level: HealthLevel.moderate,
        label: 'Trung bình',
        description: 'Giá trị chấp nhận được',
        color: HealthInfo.getColorForLevel(HealthLevel.moderate),
        icon: HealthInfo.getIconForLevel(HealthLevel.moderate),
      );
    } else if (percent >= 10 && percent <= 90) {
      return HealthInfo(
        level: HealthLevel.poor,
        label: 'Xấu',
        description: 'Giá trị không tốt',
        color: HealthInfo.getColorForLevel(HealthLevel.poor),
        icon: HealthInfo.getIconForLevel(HealthLevel.poor),
      );
    } else {
      return HealthInfo(
        level: HealthLevel.dangerous,
        label: 'Nguy hiểm',
        description: 'Giá trị ngoài phạm vi an toàn',
        color: HealthInfo.getColorForLevel(HealthLevel.dangerous),
        icon: HealthInfo.getIconForLevel(HealthLevel.dangerous),
      );
    }
  }

  /// Tính health dựa trên threshold định nghĩa
  static HealthInfo _calculateThresholdHealth(
    String sensorTypeId,
    double value,
    Map<String, List<double>> thresholds,
  ) {
    // Kiểm tra từng level từ excellent → poor
    final excellent = thresholds['excellent'];
    final good = thresholds['good'];
    final moderate = thresholds['moderate'];
    final poor = thresholds['poor'];

    HealthLevel level;
    String label;
    String description;
    String? advice;

    if (excellent != null && value >= excellent[0] && value <= excellent[1]) {
      level = HealthLevel.excellent;
      label = 'Xuất sắc';
      description = _getDescription(sensorTypeId, level);
      advice = null;
    } else if (good != null && value >= good[0] && value <= good[1]) {
      level = HealthLevel.good;
      label = 'Tốt';
      description = _getDescription(sensorTypeId, level);
      advice = null;
    } else if (moderate != null &&
        value >= moderate[0] &&
        value <= moderate[1]) {
      level = HealthLevel.moderate;
      label = 'Trung bình';
      description = _getDescription(sensorTypeId, level);
      advice = _getAdvice(sensorTypeId, level, value);
    } else if (poor != null && value >= poor[0] && value <= poor[1]) {
      level = HealthLevel.poor;
      label = 'Xấu';
      description = _getDescription(sensorTypeId, level);
      advice = _getAdvice(sensorTypeId, level, value);
    } else {
      level = HealthLevel.dangerous;
      label = 'Nguy hiểm';
      description = _getDescription(sensorTypeId, level);
      advice = _getAdvice(sensorTypeId, level, value);
    }

    return HealthInfo(
      level: level,
      label: label,
      description: description,
      color: HealthInfo.getColorForLevel(level),
      icon: HealthInfo.getIconForLevel(level),
      actionAdvice: advice,
    );
  }

  /// Lấy mô tả cho từng sensor type và level
  static String _getDescription(String sensorTypeId, HealthLevel level) {
    switch (sensorTypeId) {
      case 'temperature':
        switch (level) {
          case HealthLevel.excellent:
            return 'Nhiệt độ rất thoải mái';
          case HealthLevel.good:
            return 'Nhiệt độ dễ chịu';
          case HealthLevel.moderate:
            return 'Nhiệt độ chấp nhận được';
          case HealthLevel.poor:
            return 'Nhiệt độ không thoải mái';
          case HealthLevel.dangerous:
            return 'Nhiệt độ quá cao hoặc quá thấp';
          default:
            return '';
        }
      case 'humidity':
        switch (level) {
          case HealthLevel.excellent:
            return 'Độ ẩm lý tưởng';
          case HealthLevel.good:
            return 'Độ ẩm thoải mái';
          case HealthLevel.moderate:
            return 'Hơi ẩm ướt';
          case HealthLevel.poor:
            return 'Ẩm ướt hoặc hanh khô';
          case HealthLevel.dangerous:
            return 'Cực kỳ ẩm ướt hoặc khô';
          default:
            return '';
        }
      case 'soil_moisture':
        switch (level) {
          case HealthLevel.excellent:
            return 'Độ ẩm đất lý tưởng';
          case HealthLevel.good:
            return 'Độ ẩm đất tốt';
          case HealthLevel.moderate:
            return 'Cần theo dõi độ ẩm đất';
          case HealthLevel.poor:
            return 'Đất hơi khô';
          case HealthLevel.dangerous:
            return 'Đất rất khô - cần tưới ngay';
          default:
            return '';
        }
      case 'gas':
      case 'smoke':
        switch (level) {
          case HealthLevel.excellent:
            return 'Không khí sạch';
          case HealthLevel.good:
            return 'Chất lượng không khí tốt';
          case HealthLevel.moderate:
            return 'Phát hiện khí/khói nhẹ';
          case HealthLevel.poor:
            return 'Khí/khói vượt mức an toàn';
          case HealthLevel.dangerous:
            return '⚠️ NGUY HIỂM - Nồng độ khí/khói rất cao!';
          default:
            return '';
        }
      case 'dust':
        switch (level) {
          case HealthLevel.excellent:
            return 'Không khí rất sạch';
          case HealthLevel.good:
            return 'Chất lượng không khí tốt';
          case HealthLevel.moderate:
            return 'Ô nhiễm không khí vừa phải';
          case HealthLevel.poor:
            return 'Ô nhiễm không khí xấu';
          case HealthLevel.dangerous:
            return 'Ô nhiễm nghiêm trọng';
          default:
            return '';
        }
      case 'light':
        switch (level) {
          case HealthLevel.excellent:
            return 'Ánh sáng lý tưởng';
          case HealthLevel.good:
            return 'Ánh sáng tốt';
          case HealthLevel.moderate:
            return 'Hơi tối hoặc hơi sáng';
          case HealthLevel.poor:
            return 'Quá tối hoặc quá chói';
          case HealthLevel.dangerous:
            return 'Rất tối hoặc rất chói';
          default:
            return '';
        }
      case 'rain':
        switch (level) {
          case HealthLevel.excellent:
            return 'Trời nắng đẹp';
          case HealthLevel.good:
            return 'Khô ráo';
          case HealthLevel.moderate:
            return 'Hơi ẩm';
          case HealthLevel.poor:
            return 'Có mưa nhẹ';
          case HealthLevel.dangerous:
            return 'Đang mưa to';
          default:
            return '';
        }
      default:
        switch (level) {
          case HealthLevel.excellent:
            return 'Giá trị xuất sắc';
          case HealthLevel.good:
            return 'Giá trị tốt';
          case HealthLevel.moderate:
            return 'Giá trị trung bình';
          case HealthLevel.poor:
            return 'Giá trị xấu';
          case HealthLevel.dangerous:
            return 'Giá trị nguy hiểm';
          default:
            return '';
        }
    }
  }

  /// Lấy lời khuyên hành động
  static String? _getAdvice(
    String sensorTypeId,
    HealthLevel level,
    double value,
  ) {
    if (level == HealthLevel.excellent || level == HealthLevel.good) {
      return null; // Không cần lời khuyên
    }

    switch (sensorTypeId) {
      case 'temperature':
        if (value > 30) return '💡 Bật quạt hoặc điều hòa';
        if (value < 18) return '💡 Bật máy sưởi';
        return null;
      case 'humidity':
        if (value > 80) return '💡 Bật quạt hút ẩm';
        if (value < 25) return '💡 Bật máy tạo ẩm';
        return null;
      case 'soil_moisture':
        if (value < 30) return '💧 Cần tưới nước cho cây';
        return null;
      case 'light':
        if (value < 100) return '💡 Bật đèn';
        if (value > 2500) return '🪟 Kéo rèm hoặc giảm độ sáng';
        return null;
      case 'rain':
        if (value < 100) return '☂️ Đóng dàn phơi';
        if (value < 300) return '🌂 Nên mang ô';
        return null;
      case 'gas':
      case 'smoke':
        return '🚪 Mở cửa sổ ngay lập tức!';
      case 'dust':
        if (level == HealthLevel.dangerous)
          return '😷 Hạn chế ra ngoài, đeo khẩu trang';
        if (level == HealthLevel.poor)
          return '😷 Nên đeo khẩu trang khi ra ngoài';
        return null;
      default:
        return null;
    }
  }
}
