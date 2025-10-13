import 'package:flutter/material.dart';

class ColorUtils {
  // Get color based on temperature value
  static Color getTemperatureColor(double temperature) {
    if (temperature < 15) {
      return Colors.blue;
    } else if (temperature < 25) {
      return Colors.green;
    } else if (temperature < 35) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Get color based on humidity value
  static Color getHumidityColor(double humidity) {
    if (humidity < 30) {
      return Colors.orange; // Dry
    } else if (humidity < 70) {
      return Colors.green; // Comfortable
    } else {
      return Colors.blue; // Humid
    }
  }

  // Get color based on gas level (PPM)
  static Color getGasColor(int gas) {
    if (gas < 500) {
      return Colors.green;
    } else if (gas < 1000) {
      return Colors.yellow;
    } else if (gas < 1500) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Get color based on dust level (μg/m³)
  static Color getDustColor(double dust) {
    if (dust < 50) {
      return Colors.green; // Good
    } else if (dust < 100) {
      return Colors.yellow; // Moderate
    } else if (dust < 150) {
      return Colors.orange; // Unhealthy for sensitive
    } else {
      return Colors.red; // Unhealthy
    }
  }

  // Get color based on soil moisture
  static Color getSoilMoistureColor(double moisture) {
    if (moisture < 30) {
      return Colors.red; // Too dry
    } else if (moisture < 60) {
      return Colors.green; // Good
    } else {
      return Colors.blue; // Too wet
    }
  }

  // Get color based on light level
  static Color getLightColor(int light) {
    if (light < 100) {
      return Colors.indigo; // Dark
    } else if (light < 300) {
      return Colors.blue; // Dim
    } else if (light < 1000) {
      return Colors.amber; // Normal
    } else {
      return Colors.orange; // Bright
    }
  }

  // Get color for device state
  static Color getDeviceStateColor(bool isOn) {
    return isOn ? Colors.green : Colors.grey;
  }

  // Get color for online/offline status
  static Color getOnlineStatusColor(bool isOnline) {
    return isOnline ? Colors.green : Colors.red;
  }

  // Get color for alert severity
  static Color getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Lighten a color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Darken a color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Make color more saturated
  static Color saturate(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final saturation = (hsl.saturation + amount).clamp(0.0, 1.0);
    return hsl.withSaturation(saturation).toColor();
  }

  // Make color less saturated
  static Color desaturate(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final saturation = (hsl.saturation - amount).clamp(0.0, 1.0);
    return hsl.withSaturation(saturation).toColor();
  }

  // Add opacity to color
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity.clamp(0.0, 1.0));
  }

  // Get contrasting text color (black or white)
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Blend two colors
  static Color blend(Color color1, Color color2, [double ratio = 0.5]) {
    assert(ratio >= 0 && ratio <= 1);
    return Color.lerp(color1, color2, ratio)!;
  }

  // Get gradient colors based on value (0.0 to 1.0)
  static Color getGradientColor(double value, List<Color> colors) {
    assert(value >= 0 && value <= 1);
    if (colors.isEmpty) return Colors.grey;
    if (colors.length == 1) return colors[0];

    final segmentSize = 1.0 / (colors.length - 1);
    final segmentIndex = (value / segmentSize).floor().clamp(
      0,
      colors.length - 2,
    );
    final segmentValue = (value - segmentIndex * segmentSize) / segmentSize;

    return Color.lerp(
      colors[segmentIndex],
      colors[segmentIndex + 1],
      segmentValue,
    )!;
  }
}
