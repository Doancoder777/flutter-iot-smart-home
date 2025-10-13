import 'package:flutter/material.dart';
import '../../../widgets/charts/animated_line_chart.dart';

/// Widget biểu đồ lịch sử
class HistoryChart extends StatelessWidget {
  final String sensorType;
  final String period;

  const HistoryChart({Key? key, required this.sensorType, required this.period})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = _getChartData();
    final labels = _getLabels();

    return SizedBox(
      height: 250,
      child: AnimatedLineChart(
        dataPoints: data,
        labels: labels,
        minValue: _getMinValue(),
        maxValue: _getMaxValue(),
        lineColor: _getColor(),
        fillColor: _getColor(),
      ),
    );
  }

  List<double> _getChartData() {
    // Dữ liệu demo dựa vào period
    switch (period) {
      case 'day':
        // 24 giờ
        return List.generate(24, (i) => 20 + (i % 5) * 2.5 + (i % 3) * 1.5);
      case 'week':
        // 7 ngày
        return List.generate(7, (i) => 22 + i * 1.5 + (i % 2) * 2);
      case 'month':
        // 30 ngày
        return List.generate(30, (i) => 20 + (i % 7) * 2);
      case 'year':
        // 12 tháng
        return List.generate(12, (i) => 18 + i * 1.2);
      default:
        return [];
    }
  }

  List<String> _getLabels() {
    switch (period) {
      case 'day':
        return ['0h', '4h', '8h', '12h', '16h', '20h', '24h'];
      case 'week':
        return ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      case 'month':
        return ['1', '5', '10', '15', '20', '25', '30'];
      case 'year':
        return [
          'T1',
          'T2',
          'T3',
          'T4',
          'T5',
          'T6',
          'T7',
          'T8',
          'T9',
          'T10',
          'T11',
          'T12',
        ];
      default:
        return [];
    }
  }

  double _getMinValue() {
    switch (sensorType) {
      case 'temperature':
        return 0;
      case 'humidity':
      case 'soil':
        return 0;
      case 'gas':
        return 0;
      case 'dust':
        return 0;
      case 'light':
        return 0;
      default:
        return 0;
    }
  }

  double _getMaxValue() {
    switch (sensorType) {
      case 'temperature':
        return 50;
      case 'humidity':
      case 'soil':
        return 100;
      case 'gas':
        return 3000;
      case 'dust':
        return 300;
      case 'light':
        return 1000;
      default:
        return 100;
    }
  }

  Color _getColor() {
    switch (sensorType) {
      case 'temperature':
        return Colors.orange;
      case 'humidity':
        return Colors.blue;
      case 'gas':
        return Colors.red;
      case 'dust':
        return Colors.brown;
      case 'light':
        return Colors.amber;
      case 'soil':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
