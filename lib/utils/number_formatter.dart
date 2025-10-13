import 'package:intl/intl.dart';

class NumberFormatter {
  // Format number with decimal places
  static String format(double value, {int decimals = 1}) {
    return value.toStringAsFixed(decimals);
  }

  // Format temperature
  static String formatTemperature(double value) {
    return '${value.toStringAsFixed(1)}°C';
  }

  // Format humidity
  static String formatHumidity(double value) {
    return '${value.toStringAsFixed(0)}%';
  }

  // Format percentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(0)}%';
  }

  // Format gas concentration (PPM)
  static String formatGas(int value) {
    return '$value ppm';
  }

  // Format dust concentration (μg/m³)
  static String formatDust(double value) {
    return '${value.toStringAsFixed(0)} µg/m³';
  }

  // Format light intensity (lux)
  static String formatLight(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k lux';
    }
    return '$value lux';
  }

  // Format soil moisture
  static String formatSoilMoisture(double value) {
    return '${value.toStringAsFixed(0)}%';
  }

  // Format large numbers with K, M suffix
  static String formatCompact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  // Format with thousand separators
  static String formatWithSeparator(int value) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(value);
  }

  // Format decimal with thousand separators
  static String formatDecimalWithSeparator(double value, {int decimals = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'vi_VN');
    return formatter.format(value);
  }

  // Format servo angle
  static String formatServoAngle(int value) {
    return '$value°';
  }

  // Format duration
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$bytes B';
  }

  // Parse string to double safely
  static double parseDouble(String value, {double defaultValue = 0.0}) {
    return double.tryParse(value) ?? defaultValue;
  }

  // Parse string to int safely
  static int parseInt(String value, {int defaultValue = 0}) {
    return int.tryParse(value) ?? defaultValue;
  }

  // Clamp value between min and max
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  // Map value from one range to another
  static double mapRange(
    double value,
    double fromMin,
    double fromMax,
    double toMin,
    double toMax,
  ) {
    return (value - fromMin) / (fromMax - fromMin) * (toMax - toMin) + toMin;
  }
}
