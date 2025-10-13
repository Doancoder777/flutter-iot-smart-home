import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/device_provider.dart';
import 'widgets/statistics_card.dart';
import 'widgets/energy_chart.dart';

/// Màn hình Dashboard tổng quan
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Làm mới dữ liệu
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thống kê nhanh
            const Text(
              'Tổng quan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQuickStats(context),
            const SizedBox(height: 24),

            // Biểu đồ năng lượng
            const Text(
              'Thống kê năng lượng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const EnergyChart(),
            const SizedBox(height: 24),

            // Thống kê chi tiết
            const Text(
              'Thống kê chi tiết',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailedStats(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer2<SensorProvider, DeviceProvider>(
      builder: (context, sensorProvider, deviceProvider, child) {
        final activeDevices = deviceProvider.devices
            .where((d) => d.state)
            .length;

        return Row(
          children: [
            Expanded(
              child: StatisticsCard(
                title: 'Thiết bị',
                value: '${deviceProvider.devices.length}',
                subtitle: '$activeDevices đang bật',
                icon: Icons.devices,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticsCard(
                title: 'Nhiệt độ',
                value: '${sensorProvider.temperature.toStringAsFixed(1)}°C',
                subtitle: 'Hiện tại',
                icon: Icons.thermostat,
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedStats(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatisticsCard(
                    title: 'Độ ẩm',
                    value: '${sensorProvider.humidity.toStringAsFixed(1)}%',
                    subtitle: 'Không khí',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatisticsCard(
                    title: 'Ánh sáng',
                    value: '${sensorProvider.light} lux',
                    subtitle: 'Cường độ',
                    icon: Icons.light_mode,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatisticsCard(
                    title: 'Khí gas',
                    value: '${sensorProvider.gas} ppm',
                    subtitle: sensorProvider.gas > 1500
                        ? 'Cảnh báo!'
                        : 'Bình thường',
                    icon: Icons.cloud,
                    color: sensorProvider.gas > 1500
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatisticsCard(
                    title: 'Bụi',
                    value: '${sensorProvider.dust} µg/m³',
                    subtitle: sensorProvider.dust > 150 ? 'Cao' : 'Tốt',
                    icon: Icons.air,
                    color: sensorProvider.dust > 150
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
