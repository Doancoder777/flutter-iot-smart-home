import 'package:flutter/material.dart';
import '../../../utils/number_formatter.dart';
import '../../../utils/color_utils.dart';

/// Card hiển thị nhiệt độ
class TemperatureCard extends StatelessWidget {
  final double temperature;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? previousValue;

  const TemperatureCard({
    Key? key,
    required this.temperature,
    this.onTap,
    this.showTrend = false,
    this.previousValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.getTemperatureColor(temperature);
    String? trend;
    IconData? trendIcon;

    if (showTrend && previousValue != null) {
      if (temperature > previousValue!) {
        trend = '+${(temperature - previousValue!).toStringAsFixed(1)}°C';
        trendIcon = Icons.trending_up;
      } else if (temperature < previousValue!) {
        trend = '${(temperature - previousValue!).toStringAsFixed(1)}°C';
        trendIcon = Icons.trending_down;
      }
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.thermostat, color: color, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Nhiệt độ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormatter.formatTemperature(temperature),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (trend != null) ...[
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Icon(
                          trendIcon,
                          size: 20,
                          color: trendIcon == Icons.trending_up
                              ? Colors.red
                              : Colors.blue,
                        ),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusText(temperature),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(double temp) {
    String status;
    Color statusColor;

    if (temp < 15) {
      status = 'Lạnh';
      statusColor = Colors.blue;
    } else if (temp < 25) {
      status = 'Mát mẻ';
      statusColor = Colors.green;
    } else if (temp < 30) {
      status = 'Ấm';
      statusColor = Colors.orange;
    } else if (temp < 35) {
      status = 'Nóng';
      statusColor = Colors.deepOrange;
    } else {
      status = 'Rất nóng';
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
