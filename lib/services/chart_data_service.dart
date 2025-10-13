import '../config/constants.dart';

class ChartDataService {
  // ════════════════════════════════════════════════════════
  // PROCESS SENSOR DATA FOR CHARTS
  // ════════════════════════════════════════════════════════

  /// Process dust data for line chart
  static List<Map<String, dynamic>> processDustData(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) return [];

    // Limit to max data points
    if (history.length > AppConstants.maxDataPoints) {
      history = history.sublist(history.length - AppConstants.maxDataPoints);
    }

    return history.map((data) {
      return {
        'time': DateTime.parse(data['timestamp'] as String),
        'value': data['value'] as int,
      };
    }).toList();
  }

  /// Process temperature data for line chart
  static List<Map<String, dynamic>> processTemperatureData(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) return [];

    if (history.length > AppConstants.maxDataPoints) {
      history = history.sublist(history.length - AppConstants.maxDataPoints);
    }

    return history.map((data) {
      return {
        'time': DateTime.parse(data['timestamp'] as String),
        'value': (data['value'] as num).toDouble(),
      };
    }).toList();
  }

  /// Process humidity data for line chart
  static List<Map<String, dynamic>> processHumidityData(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) return [];

    if (history.length > AppConstants.maxDataPoints) {
      history = history.sublist(history.length - AppConstants.maxDataPoints);
    }

    return history.map((data) {
      return {
        'time': DateTime.parse(data['timestamp'] as String),
        'value': (data['value'] as num).toDouble(),
      };
    }).toList();
  }

  /// Process gas data for line chart
  static List<Map<String, dynamic>> processGasData(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) return [];

    if (history.length > AppConstants.maxDataPoints) {
      history = history.sublist(history.length - AppConstants.maxDataPoints);
    }

    return history.map((data) {
      return {
        'time': DateTime.parse(data['timestamp'] as String),
        'value': data['value'] as int,
      };
    }).toList();
  }

  /// Process soil moisture data for line chart
  static List<Map<String, dynamic>> processSoilData(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) return [];

    if (history.length > AppConstants.maxDataPoints) {
      history = history.sublist(history.length - AppConstants.maxDataPoints);
    }

    return history.map((data) {
      return {
        'time': DateTime.parse(data['timestamp'] as String),
        'value': data['value'] as int,
      };
    }).toList();
  }

  /// Process multiple sensors data for comparison
  static List<Map<String, dynamic>> processMultipleSensors(
    Map<String, List<Map<String, dynamic>>> sensorsData,
  ) {
    List<Map<String, dynamic>> combined = [];

    sensorsData.forEach((sensor, data) {
      for (var point in data) {
        combined.add({
          'sensor': sensor,
          'time': DateTime.parse(point['timestamp'] as String),
          'value': point['value'],
        });
      }
    });

    // Sort by time
    combined.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );

    return combined;
  }

  // ════════════════════════════════════════════════════════
  // STATISTICS CALCULATIONS
  // ════════════════════════════════════════════════════════

  /// Calculate statistics (min, max, average) for sensor data
  static Map<String, dynamic> calculateStatistics(
    List<Map<String, dynamic>> data,
  ) {
    if (data.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'average': 0.0,
        'median': 0.0,
        'count': 0,
      };
    }

    final values = data.map((d) => (d['value'] as num).toDouble()).toList();
    values.sort();

    final min = values.first;
    final max = values.last;
    final sum = values.reduce((a, b) => a + b);
    final average = sum / values.length;

    // Calculate median
    final median = values.length % 2 == 0
        ? (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2
        : values[values.length ~/ 2];

    return {
      'min': min,
      'max': max,
      'average': average,
      'median': median,
      'count': values.length,
    };
  }

  /// Get hourly averages from sensor data
  static List<Map<String, dynamic>> getHourlyAverages(
    List<Map<String, dynamic>> data,
  ) {
    if (data.isEmpty) return [];

    Map<int, List<double>> hourlyData = {};

    for (var point in data) {
      final time = point['time'] as DateTime;
      final hour = time.hour;
      final value = (point['value'] as num).toDouble();

      if (!hourlyData.containsKey(hour)) {
        hourlyData[hour] = [];
      }
      hourlyData[hour]!.add(value);
    }

    List<Map<String, dynamic>> result = [];
    hourlyData.forEach((hour, values) {
      final average = values.reduce((a, b) => a + b) / values.length;
      result.add({'hour': hour, 'average': average, 'count': values.length});
    });

    result.sort((a, b) => (a['hour'] as int).compareTo(b['hour'] as int));
    return result;
  }

  /// Get daily averages from sensor data
  static List<Map<String, dynamic>> getDailyAverages(
    List<Map<String, dynamic>> data,
  ) {
    if (data.isEmpty) return [];

    Map<String, List<double>> dailyData = {};

    for (var point in data) {
      final time = point['time'] as DateTime;
      final dateKey =
          '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
      final value = (point['value'] as num).toDouble();

      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = [];
      }
      dailyData[dateKey]!.add(value);
    }

    List<Map<String, dynamic>> result = [];
    dailyData.forEach((date, values) {
      final average = values.reduce((a, b) => a + b) / values.length;
      result.add({
        'date': date,
        'average': average,
        'count': values.length,
        'min': values.reduce((a, b) => a < b ? a : b),
        'max': values.reduce((a, b) => a > b ? a : b),
      });
    });

    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return result;
  }

  /// Get latest N data points
  static List<Map<String, dynamic>> getLatestData(
    List<Map<String, dynamic>> data,
    int count,
  ) {
    if (data.isEmpty) return [];

    if (data.length <= count) return data;

    return data.sublist(data.length - count);
  }

  /// Filter data by date range
  static List<Map<String, dynamic>> filterByDateRange(
    List<Map<String, dynamic>> data,
    DateTime startDate,
    DateTime endDate,
  ) {
    return data.where((point) {
      final time = point['time'] as DateTime;
      return time.isAfter(startDate) && time.isBefore(endDate);
    }).toList();
  }

  /// Get data for specific hour
  static List<Map<String, dynamic>> getDataForHour(
    List<Map<String, dynamic>> data,
    int hour,
  ) {
    return data.where((point) {
      final time = point['time'] as DateTime;
      return time.hour == hour;
    }).toList();
  }

  /// Calculate trend (increasing/decreasing)
  static String calculateTrend(List<Map<String, dynamic>> data) {
    if (data.length < 2) return 'stable';

    final first = (data.first['value'] as num).toDouble();
    final last = (data.last['value'] as num).toDouble();

    final difference = last - first;
    final percentChange = (difference / first) * 100;

    if (percentChange > 5) {
      return 'increasing';
    } else if (percentChange < -5) {
      return 'decreasing';
    } else {
      return 'stable';
    }
  }

  /// Get peak values (highest and lowest)
  static Map<String, dynamic> getPeakValues(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return {
        'highest': {'value': 0, 'time': DateTime.now()},
        'lowest': {'value': 0, 'time': DateTime.now()},
      };
    }

    var highest = data.first;
    var lowest = data.first;

    for (var point in data) {
      final value = (point['value'] as num).toDouble();
      final highestValue = (highest['value'] as num).toDouble();
      final lowestValue = (lowest['value'] as num).toDouble();

      if (value > highestValue) {
        highest = point;
      }
      if (value < lowestValue) {
        lowest = point;
      }
    }

    return {
      'highest': {'value': highest['value'], 'time': highest['time']},
      'lowest': {'value': lowest['value'], 'time': lowest['time']},
    };
  }

  /// Smooth data using moving average
  static List<Map<String, dynamic>> smoothData(
    List<Map<String, dynamic>> data,
    int windowSize,
  ) {
    if (data.length < windowSize) return data;

    List<Map<String, dynamic>> smoothed = [];

    for (int i = 0; i < data.length; i++) {
      int start = i - windowSize ~/ 2;
      int end = i + windowSize ~/ 2;

      if (start < 0) start = 0;
      if (end > data.length) end = data.length;

      final window = data.sublist(start, end);
      final values = window.map((d) => (d['value'] as num).toDouble()).toList();
      final average = values.reduce((a, b) => a + b) / values.length;

      smoothed.add({'time': data[i]['time'], 'value': average});
    }

    return smoothed;
  }

  /// Detect anomalies (values beyond threshold)
  static List<Map<String, dynamic>> detectAnomalies(
    List<Map<String, dynamic>> data,
    double threshold,
  ) {
    if (data.isEmpty) return [];

    final stats = calculateStatistics(data);
    final average = stats['average'] as double;

    return data.where((point) {
      final value = (point['value'] as num).toDouble();
      final deviation = (value - average).abs();
      return deviation > threshold;
    }).toList();
  }

  /// Group data by time intervals (hourly, daily, weekly)
  static Map<String, List<Map<String, dynamic>>> groupByInterval(
    List<Map<String, dynamic>> data,
    String interval, // 'hour', 'day', 'week'
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var point in data) {
      final time = point['time'] as DateTime;
      String key;

      switch (interval) {
        case 'hour':
          key = '${time.year}-${time.month}-${time.day}-${time.hour}';
          break;
        case 'day':
          key = '${time.year}-${time.month}-${time.day}';
          break;
        case 'week':
          final weekNumber = ((time.day - 1) ~/ 7) + 1;
          key = '${time.year}-${time.month}-W$weekNumber';
          break;
        default:
          key = time.toIso8601String();
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(point);
    }

    return grouped;
  }
}
