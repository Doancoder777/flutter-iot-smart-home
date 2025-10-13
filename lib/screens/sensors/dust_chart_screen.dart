import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../config/app_colors.dart';

class DustChartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biểu đồ bụi mịn'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensorProvider, _) {
          final currentDust = sensorProvider.dust;
          final history = sensorProvider.history;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Value Card
                _buildCurrentValueCard(currentDust),
                SizedBox(height: 24),

                // Quality Status
                _buildQualityCard(currentDust),
                SizedBox(height: 24),

                // Chart
                Text(
                  'Lịch sử 24h',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      'Biểu đồ đang được phát triển',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Stats
                _buildStatsSection(history),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentValueCard(int dustValue) {
    final level = _getDustLevel(dustValue);
    final color = _getDustColor(dustValue);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.cloud, color: Colors.white, size: 48),
          SizedBox(height: 16),
          Text(
            '$dustValue',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'µg/m³',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 8),
          Text(
            level,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard(int dustValue) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chất lượng không khí',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildQualityLevel('Tốt', 0, 50, dustValue),
            SizedBox(height: 8),
            _buildQualityLevel('Trung bình', 51, 100, dustValue),
            SizedBox(height: 8),
            _buildQualityLevel('Kém', 101, 150, dustValue),
            SizedBox(height: 8),
            _buildQualityLevel('Xấu', 151, 200, dustValue),
            SizedBox(height: 8),
            _buildQualityLevel('Rất xấu', 201, 999, dustValue),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityLevel(String label, int min, int max, int currentValue) {
    final isActive = currentValue >= min && currentValue <= max;
    final color = _getDustColorByRange(min);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            '$label ($min-$max µg/m³)',
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? color : Colors.grey[600],
            ),
          ),
        ),
        if (isActive) Icon(Icons.check_circle, color: color, size: 20),
      ],
    );
  }

  Widget _buildStatsSection(List history) {
    if (history.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có dữ liệu'),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Trung bình', '85', 'µg/m³'),
                _buildStatItem('Cao nhất', '120', 'µg/m³'),
                _buildStatItem('Thấp nhất', '45', 'µg/m³'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDustLevel(int value) {
    if (value <= 50) return 'Tốt';
    if (value <= 100) return 'Trung bình';
    if (value <= 150) return 'Kém';
    if (value <= 200) return 'Xấu';
    return 'Rất xấu';
  }

  Color _getDustColor(int value) {
    if (value <= 50) return AppColors.success;
    if (value <= 100) return AppColors.info;
    if (value <= 150) return AppColors.warning;
    return AppColors.error;
  }

  Color _getDustColorByRange(int min) {
    if (min <= 50) return AppColors.success;
    if (min <= 100) return AppColors.info;
    if (min <= 150) return AppColors.warning;
    return AppColors.error;
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thông tin PM2.5'),
        content: SingleChildScrollView(
          child: Text(
            'PM2.5 là bụi mịn có đường kính nhỏ hơn 2.5 micromet. '
            'Chúng có thể xâm nhập sâu vào phổi và gây hại cho sức khỏe.\n\n'
            '• 0-50: Tốt\n'
            '• 51-100: Trung bình\n'
            '• 101-150: Kém\n'
            '• 151-200: Xấu\n'
            '• >200: Rất xấu',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
