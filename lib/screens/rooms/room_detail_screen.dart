import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import 'widgets/room_device_list.dart';

/// Màn hình chi tiết phòng
class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  final String roomName;
  final IconData icon;

  const RoomDetailScreen({
    Key? key,
    required this.roomId,
    required this.roomName,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        // Get devices in this room
        final roomDevices = deviceProvider.devices
            .where((device) => device.room == roomId)
            .toList();

        final totalDevices = roomDevices.length;
        final activeDevices = roomDevices.where((d) => d.state).length;
        final inactiveDevices = totalDevices - activeDevices;

        return Scaffold(
          appBar: AppBar(
            title: Text(roomName),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Cài đặt phòng
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Header với icon và thống kê
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      roomName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Thiết bị', totalDevices.toString()),
                        _buildStatItem('Đang bật', activeDevices.toString()),
                        _buildStatItem('Đang tắt', inactiveDevices.toString()),
                      ],
                    ),
                  ],
                ),
              ),

              // Danh sách thiết bị
              Expanded(
                child: RoomDeviceList(roomId: roomId, roomName: roomName),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Thêm thiết bị vào phòng - Navigate to Add Device
              Navigator.pushNamed(context, '/add-device');
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }
}
