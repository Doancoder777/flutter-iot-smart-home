import 'package:flutter/material.dart';
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
                    _buildStatItem('Thiết bị', _getDeviceCount(roomId)),
                    _buildStatItem('Đang bật', _getActiveCount(roomId)),
                    _buildStatItem('Đang tắt', _getInactiveCount(roomId)),
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
          // Thêm thiết bị vào phòng
        },
        child: const Icon(Icons.add),
      ),
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

  String _getDeviceCount(String roomId) {
    switch (roomId) {
      case 'living_room':
        return '2';
      case 'garden':
        return '3';
      case 'entrance':
        return '1';
      default:
        return '0';
    }
  }

  String _getActiveCount(String roomId) {
    switch (roomId) {
      case 'living_room':
        return '1';
      case 'garden':
        return '1';
      case 'entrance':
        return '0';
      default:
        return '0';
    }
  }

  String _getInactiveCount(String roomId) {
    switch (roomId) {
      case 'living_room':
        return '1';
      case 'garden':
        return '2';
      case 'entrance':
        return '1';
      default:
        return '0';
    }
  }
}
