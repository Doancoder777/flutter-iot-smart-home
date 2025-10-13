import 'package:flutter/material.dart';
import '../../../widgets/charts/animated_bar_chart.dart';

/// Biểu đồ năng lượng tiêu thụ
class EnergyChart extends StatelessWidget {
  const EnergyChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dữ liệu demo cho 7 ngày
    final data = [
      ChartData(label: 'CN', value: 3.2),
      ChartData(label: 'T2', value: 4.5),
      ChartData(label: 'T3', value: 3.8),
      ChartData(label: 'T4', value: 5.2),
      ChartData(label: 'T5', value: 4.1),
      ChartData(label: 'T6', value: 3.9),
      ChartData(label: 'T7', value: 4.8),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Năng lượng tuần này',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '12%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tổng: 29.5 kWh',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: AnimatedBarChart(
                data: data,
                maxValue: 6.0,
                barColor: Colors.blue,
                unit: 'kWh',
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Điện', Colors.blue),
        const SizedBox(width: 16),
        _buildLegendItem('Tiết kiệm', Colors.green),
        const SizedBox(width: 16),
        _buildLegendItem('Cao', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
