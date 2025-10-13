import 'package:flutter/material.dart';
import '../../../utils/number_formatter.dart';
import '../../../utils/color_utils.dart';

/// Card hiển thị độ ẩm
class HumidityCard extends StatelessWidget {
  final double humidity;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? previousValue;

  const HumidityCard({
    Key? key,
    required this.humidity,
    this.onTap,
    this.showTrend = false,
    this.previousValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.getHumidityColor(humidity);
    String? trend;
    IconData? trendIcon;

    if (showTrend && previousValue != null) {
      if (humidity > previousValue!) {
        trend = '+${(humidity - previousValue!).toStringAsFixed(1)}%';
        trendIcon = Icons.trending_up;
      } else if (humidity < previousValue!) {
        trend = '${(humidity - previousValue!).toStringAsFixed(1)}%';
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
                  Icon(Icons.water_drop, color: color, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Độ ẩm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormatter.formatHumidity(humidity),
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
                              ? Colors.blue
                              : Colors.orange,
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
              _buildStatusText(humidity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(double hum) {
    String status;
    Color statusColor;

    if (hum < 30) {
      status = 'Khô';
      statusColor = Colors.orange;
    } else if (hum < 60) {
      status = 'Bình thường';
      statusColor = Colors.green;
    } else if (hum < 80) {
      status = 'Ẩm';
      statusColor = Colors.blue;
    } else {
      status = 'Rất ẩm';
      statusColor = Colors.indigo;
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
