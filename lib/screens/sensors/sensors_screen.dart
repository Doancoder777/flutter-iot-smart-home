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
        title: const Text('Cảm biến'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddSensor(context),
            tooltip: 'Thêm cảm biến',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'Lịch sử',
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensorProvider, _) {
          final userSensors = sensorProvider.userSensors;

          if (userSensors.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Weather sensors section
                _buildWeatherSensorsSection(context, sensorProvider),
                const SizedBox(height: 24),

                // All sensors section
                _buildAllSensorsSection(context, sensorProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có cảm biến nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm cảm biến để bắt đầu theo dõi',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddSensor(context),
            icon: const Icon(Icons.add),
            label: const Text('Thêm cảm biến đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSensorsSection(
    BuildContext context,
    SensorProvider sensorProvider,
  ) {
    final weatherSensors = sensorProvider.userSensors
        .where((s) => s.isWeatherSensor && s.isActive)
        .toList();

    if (weatherSensors.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wb_sunny, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Cảm biến thời tiết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (sensorProvider.hasWeatherSensors())
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Đầy đủ',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: weatherSensors.length,
          itemBuilder: (context, index) {
            return _buildSensorCard(context, weatherSensors[index]);
          },
        ),
      ],
    );
  }

  Widget _buildAllSensorsSection(
    BuildContext context,
    SensorProvider sensorProvider,
  ) {
    final allSensors = sensorProvider.userSensors
        .where((s) => s.isActive)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.sensors, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Tất cả cảm biến',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allSensors.length,
          itemBuilder: (context, index) {
            return _buildSensorListItem(
              context,
              allSensors[index],
              sensorProvider,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSensorCard(BuildContext context, UserSensor sensor) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showSensorOptions(context, sensor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(sensor.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sensor.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                sensor.formattedValue,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              if (sensor.lastUpdateAt != null)
                Text(
                  'Cập nhật: ${_formatLastUpdate(sensor.lastUpdateAt!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorListItem(
    BuildContext context,
    UserSensor sensor,
    SensorProvider sensorProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(sensor.icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(sensor.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Topic: ${sensor.mqttTopic}'),
            if (sensor.lastUpdateAt != null)
              Text(
                'Cập nhật: ${_formatLastUpdate(sensor.lastUpdateAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sensor.formattedValue,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleSensorAction(context, sensor, value, sensorProvider),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showSensorOptions(context, sensor),
      ),
    );
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  Future<void> _navigateToAddSensor(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSensorScreen()),
    );

    // Refresh nếu đã thêm sensor
    if (result == true && context.mounted) {
      final sensorProvider = Provider.of<SensorProvider>(
        context,
        listen: false,
      );
      // Reload user sensors
      if (sensorProvider.userSensors.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  void _showSensorOptions(BuildContext context, UserSensor sensor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(sensor.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensor.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        sensor.sensorType?.name ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editSensor(context, sensor);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh sửa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteSensor(context, sensor);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Xóa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editSensor(BuildContext context, UserSensor sensor) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit_sensor',
      arguments: sensor,
    );

    // Provider sẽ tự update UI khi có thay đổi
    if (result == true) {
      // Có thể thêm snackbar thông báo ở đây nếu cần
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã cập nhật cảm biến'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleSensorAction(
    BuildContext context,
    UserSensor sensor,
    String action,
    SensorProvider sensorProvider,
  ) {
    switch (action) {
      case 'edit':
        // TODO: Implement edit sensor
        break;
      case 'delete':
        _confirmDeleteSensor(context, sensor);
        break;
    }
  }

  void _confirmDeleteSensor(BuildContext context, UserSensor sensor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa cảm biến "${sensor.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSensor(context, sensor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSensor(BuildContext context, UserSensor sensor) async {
    try {
      final sensorProvider = Provider.of<SensorProvider>(
        context,
        listen: false,
      );
      await sensorProvider.deleteSensor(sensor.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã xóa cảm biến "${sensor.displayName}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
