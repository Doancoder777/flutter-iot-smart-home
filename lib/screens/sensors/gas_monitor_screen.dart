import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../config/app_colors.dart';

class GasMonitorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giám sát Gas'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensorProvider, _) {
          final currentGas = sensorProvider.gas;
          final isWarning = currentGas > 1500;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Banner
                if (isWarning)
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CẢNH BÁO!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Nồng độ gas vượt ngưỡng an toàn',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Current Value Card
                _buildCurrentValueCard(currentGas),
                SizedBox(height: 24),

                // Safety Level
                _buildSafetyCard(currentGas),
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

                // Safety Tips
                _buildSafetyTips(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentValueCard(int gasValue) {
    final color = gasValue > 1500 ? AppColors.error : AppColors.success;

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
          Icon(Icons.air, color: Colors.white, size: 48),
          SizedBox(height: 16),
          Text(
            '$gasValue',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'ppm',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 8),
          Text(
            gasValue > 1500 ? 'NGUY HIỂM' : 'AN TOÀN',
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

  Widget _buildSafetyCard(int gasValue) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mức độ an toàn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildSafetyLevel('An toàn', 0, 1000, gasValue, AppColors.success),
            SizedBox(height: 8),
            _buildSafetyLevel(
              'Cảnh báo',
              1001,
              1500,
              gasValue,
              AppColors.warning,
            ),
            SizedBox(height: 8),
            _buildSafetyLevel(
              'Nguy hiểm',
              1501,
              9999,
              gasValue,
              AppColors.error,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.info, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ngưỡng cảnh báo: 1500 ppm',
                      style: TextStyle(color: AppColors.info, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyLevel(
    String label,
    int min,
    int max,
    int currentValue,
    Color color,
  ) {
    final isActive = currentValue >= min && currentValue <= max;

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
            '$label (${min > 0 ? "$min-" : ""}${max < 9999 ? "$max" : "+"} ppm)',
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

  Widget _buildSafetyTips() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lưu ý an toàn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildTipItem('Kiểm tra định kỳ hệ thống gas'),
            _buildTipItem('Đảm bảo thông gió tốt'),
            _buildTipItem('Tắt nguồn gas khi không sử dụng'),
            _buildTipItem('Gọi cứu hộ nếu phát hiện rò rỉ'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thông tin Gas'),
        content: SingleChildScrollView(
          child: Text(
            'Cảm biến MQ-2 phát hiện các loại khí dễ cháy như LPG, propane, methane, và hydro.\n\n'
            '• 0-1000 ppm: An toàn\n'
            '• 1001-1500 ppm: Cảnh báo\n'
            '• >1500 ppm: Nguy hiểm\n\n'
            'Khi phát hiện nồng độ gas cao, hệ thống sẽ tự động cảnh báo và có thể kích hoạt các biện pháp an toàn.',
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
