import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../models/user_sensor.dart';
import '../../config/app_colors.dart';
import 'add_sensor_screen.dart';

class SensorsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cảm biến'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'Lịch sử',
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensorProvider, _) {
          final data = sensorProvider.currentData;

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(Duration(seconds: 1));
            },
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Temperature & Humidity Cards
                Row(
                  children: [
                    Expanded(
                      child: TemperatureCard(
                        temperature: data.temperature,
                        onTap: () => _navigateToDetail(context, 'temperature'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: HumidityCard(
                        humidity: data.humidity,
                        onTap: () => _navigateToDetail(context, 'temperature'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Sensor Gauges
                Row(
                  children: [
                    Expanded(
                      child: SensorGauge(
                        label: 'Ánh sáng',
                        value: data.light.toDouble(),
                        minValue: 0,
                        maxValue: 1000,
                        unit: 'lux',
                        color: AppColors.light,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: SensorGauge(
                        label: 'Độ ẩm đất',
                        value: data.soilMoisture.toDouble(),
                        minValue: 0,
                        maxValue: 100,
                        unit: '%',
                        color: AppColors.soil,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Rain & Light
                _buildSensorCard(
                  context,
                  title: 'Mưa & Ánh sáng',
                  icon: Icons.wb_sunny,
                  color: AppColors.light,
                  children: [
                    _buildSensorItem(
                      '🌧️ Cảm biến mưa',
                      data.rain == 1 ? 'Có mưa' : 'Không mưa',
                      data.rain == 1 ? AppColors.rain : Colors.grey,
                    ),
                    Divider(),
                    _buildSensorItem(
                      '☀️ Ánh sáng',
                      '${data.light} lux',
                      AppColors.light,
                    ),
                  ],
                  onTap: () => _navigateToDetail(context, 'light'),
                ),
                SizedBox(height: 16),

                // Soil Moisture
                _buildSensorCard(
                  context,
                  title: 'Độ ẩm đất',
                  icon: Icons.grass,
                  color: AppColors.soil,
                  children: [
                    _buildSensorItem(
                      '🌱 Độ ẩm đất',
                      '${data.soilMoisture}%',
                      AppColors.soil,
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: data.soilMoisture / 100,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.soil,
                    ),
                  ],
                  onTap: () => _navigateToDetail(context, 'soil'),
                ),
                SizedBox(height: 16),

                // Gas
                _buildSensorCard(
                  context,
                  title: 'Khí Gas',
                  icon: Icons.air,
                  color: AppColors.gas,
                  children: [
                    _buildSensorItem(
                      '⚠️ Nồng độ Gas',
                      '${data.gas} ppm',
                      data.gas > 1500 ? AppColors.error : AppColors.gas,
                    ),
                    if (data.gas > 1500) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: AppColors.error,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cảnh báo: Nồng độ gas cao!',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  onTap: () => Navigator.pushNamed(context, '/gas_monitor'),
                ),
                SizedBox(height: 16),

                // Dust
                _buildSensorCard(
                  context,
                  title: 'Bụi mịn',
                  icon: Icons.cloud,
                  color: AppColors.dust,
                  children: [
                    _buildSensorItem(
                      '🫁 Bụi PM2.5',
                      '${data.dust} µg/m³',
                      data.dust > 150 ? AppColors.error : AppColors.dust,
                    ),
                    if (data.dust > 150) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: AppColors.error,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cảnh báo: Nồng độ bụi cao!',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  onTap: () => Navigator.pushNamed(context, '/dust_chart'),
                ),
                SizedBox(height: 16),

                // Motion
                _buildSensorCard(
                  context,
                  title: 'Cảm biến chuyển động',
                  icon: Icons.directions_walk,
                  color: AppColors.motion,
                  children: [
                    _buildSensorItem(
                      '🚶 Trạng thái',
                      data.motionDetected
                          ? 'Phát hiện chuyển động'
                          : 'Không có chuyển động',
                      data.motionDetected ? AppColors.warning : Colors.grey,
                    ),
                  ],
                  onTap: () => _navigateToDetail(context, 'motion'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, String sensorType) {
    Navigator.pushNamed(context, '/sensor_detail', arguments: sensorType);
  }
}
