import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../utils/number_formatter.dart';
import '../../utils/color_utils.dart';
import '../../utils/date_formatter.dart';
import 'widgets/line_chart_widget.dart';
import 'widgets/sensor_gauge.dart';

/// Màn hình chi tiết cảm biến
class SensorDetailScreen extends StatelessWidget {
  final String sensorType;

  const SensorDetailScreen({Key? key, required this.sensorType})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getSensorTitle(sensorType))),
      body: Consumer<SensorProvider>(
        builder: (context, sensorProvider, child) {
          final currentValue = _getCurrentValue(sensorProvider);
          final history = _getHistory(sensorProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gauge hiện tại
                Center(
                  child: SensorGauge(
                    value: currentValue,
                    minValue: _getMinValue(sensorType),
                    maxValue: _getMaxValue(sensorType),
                    label: _getSensorTitle(sensorType),
                    unit: _getUnit(sensorType),
                    color: _getColor(sensorType, currentValue),
                    size: 200,
                    ranges: _getRanges(sensorType),
                  ),
                ),
                const SizedBox(height: 32),

                // Thông tin chi tiết
                _buildInfoCard(context, sensorProvider),
                const SizedBox(height: 16),

                // Biểu đồ lịch sử
                const Text(
                  'Lịch sử 24 giờ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LineChartWidget(
                      dataPoints: history,
                      minValue: _getMinValue(sensorType),
                      maxValue: _getMaxValue(sensorType),
                      lineColor: _getColor(sensorType, currentValue),
                      fillColor: _getColor(sensorType, currentValue),
                      height: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Thống kê
                _buildStatistics(history),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, SensorProvider provider) {
    final lastUpdate = provider.currentData.timestamp;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Loại cảm biến', _getSensorTitle(sensorType)),
            const Divider(),
            _buildInfoRow('Đơn vị', _getUnit(sensorType)),
            const Divider(),
            _buildInfoRow(
              'Cập nhật lần cuối',
              DateFormatter.formatRelativeTime(lastUpdate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(List<double> history) {
    if (history.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Chưa có dữ liệu')),
        ),
      );
    }

    final min = history.reduce((a, b) => a < b ? a : b);
    final max = history.reduce((a, b) => a > b ? a : b);
    final avg = history.reduce((a, b) => a + b) / history.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Trung bình', avg, Colors.blue),
                _buildStatItem('Thấp nhất', min, Colors.green),
                _buildStatItem('Cao nhất', max, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          _formatValue(value),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getSensorTitle(String type) {
    switch (type) {
      case 'temperature':
        return 'Nhiệt độ';
      case 'humidity':
        return 'Độ ẩm';
      case 'gas':
        return 'Khí gas';
      case 'dust':
        return 'Bụi';
      case 'light':
        return 'Ánh sáng';
      case 'soil':
        return 'Độ ẩm đất';
      default:
        return type;
    }
  }

  String _getUnit(String type) {
    switch (type) {
      case 'temperature':
        return '°C';
      case 'humidity':
      case 'soil':
        return '%';
      case 'gas':
        return 'ppm';
      case 'dust':
        return 'µg/m³';
      case 'light':
        return 'lux';
      default:
        return '';
    }
  }

  double _getMinValue(String type) {
    switch (type) {
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

  double _getMaxValue(String type) {
    switch (type) {
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

  Color _getColor(String type, double value) {
    switch (type) {
      case 'temperature':
        return ColorUtils.getTemperatureColor(value);
      case 'humidity':
        return ColorUtils.getHumidityColor(value);
      case 'gas':
        return ColorUtils.getGasColor(value.toInt());
      case 'dust':
        return ColorUtils.getDustColor(value);
      case 'light':
        return ColorUtils.getLightColor(value.toInt());
      case 'soil':
        return ColorUtils.getSoilMoistureColor(value);
      default:
        return Colors.blue;
    }
  }

  double _getCurrentValue(SensorProvider provider) {
    switch (sensorType) {
      case 'temperature':
        return provider.temperature;
      case 'humidity':
        return provider.humidity;
      case 'gas':
        return provider.gas.toDouble();
      case 'dust':
        return provider.dust.toDouble();
      case 'light':
        return provider.light.toDouble();
      case 'soil':
        return provider.soilMoisture.toDouble();
      default:
        return 0;
    }
  }

  List<double> _getHistory(SensorProvider provider) {
    // Giả lập dữ liệu lịch sử (trong thực tế sẽ lấy từ database)
    final currentValue = _getCurrentValue(provider);
    return List.generate(24, (index) {
      return currentValue + (index % 3 - 1) * (currentValue * 0.1);
    });
  }

  List<GaugeRange>? _getRanges(String type) {
    switch (type) {
      case 'gas':
        return [
          GaugeRange(start: 0, end: 1500, color: Colors.green),
          GaugeRange(start: 1500, end: 2000, color: Colors.orange),
          GaugeRange(start: 2000, end: 3000, color: Colors.red),
        ];
      case 'dust':
        return [
          GaugeRange(start: 0, end: 150, color: Colors.green),
          GaugeRange(start: 150, end: 200, color: Colors.orange),
          GaugeRange(start: 200, end: 300, color: Colors.red),
        ];
      default:
        return null;
    }
  }

  String _formatValue(double value) {
    switch (sensorType) {
      case 'temperature':
        return NumberFormatter.formatTemperature(value);
      case 'humidity':
        return NumberFormatter.formatHumidity(value);
      case 'gas':
        return NumberFormatter.formatGas(value.toInt());
      case 'dust':
        return NumberFormatter.formatDust(value);
      case 'light':
        return NumberFormatter.formatLight(value.toInt());
      case 'soil':
        return NumberFormatter.formatSoilMoisture(value);
      default:
        return value.toStringAsFixed(1);
    }
  }
}
