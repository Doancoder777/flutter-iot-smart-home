import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import 'widgets/history_chart.dart';
import 'widgets/export_dialog.dart';

/// Màn hình lịch sử dữ liệu cảm biến
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedSensor = 'temperature';
  String _selectedPeriod = 'day';

  final List<Map<String, String>> _sensors = [
    {'id': 'temperature', 'name': 'Nhiệt độ'},
    {'id': 'humidity', 'name': 'Độ ẩm'},
    {'id': 'gas', 'name': 'Khí gas'},
    {'id': 'dust', 'name': 'Bụi'},
    {'id': 'light', 'name': 'Ánh sáng'},
    {'id': 'soil', 'name': 'Độ ẩm đất'},
  ];

  final List<Map<String, String>> _periods = [
    {'id': 'day', 'name': 'Hôm nay'},
    {'id': 'week', 'name': 'Tuần này'},
    {'id': 'month', 'name': 'Tháng này'},
    {'id': 'year', 'name': 'Năm này'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              _showExportDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Bộ lọc
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSensor,
                    decoration: const InputDecoration(
                      labelText: 'Cảm biến',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _sensors.map((sensor) {
                      return DropdownMenuItem(
                        value: sensor['id'],
                        child: Text(sensor['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSensor = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _periods.map((period) {
                      return DropdownMenuItem(
                        value: period['id'],
                        child: Text(period['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Biểu đồ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getSensorName(_selectedSensor),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          HistoryChart(
                            sensorType: _selectedSensor,
                            period: _selectedPeriod,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thống kê
                  _buildStatistics(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        // Dữ liệu demo
        final avgValue = 25.5;
        final maxValue = 35.2;
        final minValue = 18.7;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Trung bình', avgValue, Colors.blue),
                    _buildStatItem('Cao nhất', maxValue, Colors.red),
                    _buildStatItem('Thấp nhất', minValue, Colors.green),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          _getUnit(_selectedSensor),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _getSensorName(String id) {
    return _sensors.firstWhere((s) => s['id'] == id)['name']!;
  }

  String _getUnit(String sensor) {
    switch (sensor) {
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

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          ExportDialog(sensorType: _selectedSensor, period: _selectedPeriod),
    );
  }
}
