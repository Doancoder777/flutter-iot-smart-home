import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../home/widgets/room_card.dart';
import 'room_detail_screen.dart';

/// Màn hình danh sách các phòng - Lấy device count thật từ DeviceProvider
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        final rooms = _getRoomsWithRealCounts(deviceProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Phòng'),
            actions: [
              Text(
                '${deviceProvider.devicesCount} thiết bị',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(width: 16),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/add_room'),
            backgroundColor: Colors.green.shade600,
            child: Icon(Icons.add_home, color: Colors.white),
            tooltip: 'Thêm phòng mới',
          ),
          body: rooms.isEmpty
              ? _buildEmptyState(context)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return RoomCard(
                      roomName: room['name'],
                      icon: room['icon'],
                      deviceCount: room['deviceCount'],
                      activeDevices: room['activeDevices'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoomDetailScreen(
                              roomId: room['id'],
                              roomName: room['name'],
                              icon: room['icon'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(
              'Chưa có phòng nào',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Thêm thiết bị và phân bổ vào phòng để bắt đầu quản lý',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add_room'),
                  icon: Icon(Icons.add_home),
                  label: Text('Tạo phòng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add_device'),
                  icon: Icon(Icons.add),
                  label: Text('Thêm thiết bị'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tính device count thật từ DeviceProvider - DYNAMIC, KHÔNG HARD-CODE
  List<Map<String, dynamic>> _getRoomsWithRealCounts(DeviceProvider provider) {
    final allDevices = provider.devices;

    return [
      // Dynamic rooms based on actual devices
      ...getRoomsFromDevices(allDevices),
    ];
  }

  List<Map<String, dynamic>> getRoomsFromDevices(List<dynamic> allDevices) {
    if (allDevices.isEmpty) {
      return []; // Không có devices thì không có phòng nào
    }

    // Group devices theo room field
    Map<String, List<dynamic>> roomDevicesMap = {};
    for (final device in allDevices) {
      final roomName = device.room ?? 'Không xác định';
      roomDevicesMap[roomName] ??= [];
      roomDevicesMap[roomName]!.add(device);
    }

    // Convert thành list cho GridView
    List<Map<String, dynamic>> rooms = [];
    roomDevicesMap.forEach((roomName, devices) {
      final activeDevices = devices.where((d) => d.state).length;

      rooms.add({
        'id': roomName.toLowerCase().replaceAll(' ', '_'),
        'name': roomName,
        'icon': _getRoomIcon(roomName),
        'deviceCount': devices.length,
        'activeDevices': activeDevices,
      });
    });

    return rooms;
  }

  IconData _getRoomIcon(String roomName) {
    final lowerCaseRoom = roomName.toLowerCase();
    if (lowerCaseRoom.contains('khách') || lowerCaseRoom.contains('living')) {
      return Icons.living;
    } else if (lowerCaseRoom.contains('ngủ') ||
        lowerCaseRoom.contains('bedroom')) {
      return Icons.bed;
    } else if (lowerCaseRoom.contains('bếp') ||
        lowerCaseRoom.contains('kitchen')) {
      return Icons.kitchen;
    } else if (lowerCaseRoom.contains('tắm') ||
        lowerCaseRoom.contains('bathroom')) {
      return Icons.bathtub;
    } else if (lowerCaseRoom.contains('sân') ||
        lowerCaseRoom.contains('vườn') ||
        lowerCaseRoom.contains('garden')) {
      return Icons.yard;
    } else if (lowerCaseRoom.contains('garage') ||
        lowerCaseRoom.contains('nhà xe')) {
      return Icons.garage;
    } else {
      return Icons.room;
    }
  }

  // void _showAddRoomDialog(BuildContext context) { // Unused method - commented out
  //   // TODO: Implement add room functionality
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Tính năng thêm phòng sẽ có trong phiên bản sau'),
  //     ),
  //   );
  // }
}
