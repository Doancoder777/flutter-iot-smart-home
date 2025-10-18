import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/device_provider.dart';
import '../../../models/device_model.dart';
// import '../../devices/device_detail_screen.dart'; // Unused - removed

/// Widget danh sách thiết bị trong phòng - Sử dụng data thực từ DeviceProvider
class RoomDeviceList extends StatelessWidget {
  final String roomId;
  final String roomName;

  const RoomDeviceList({Key? key, required this.roomId, required this.roomName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        // Lấy devices thật từ provider theo phòng
        final devices = _getDevicesFromProvider(deviceProvider, roomId);

        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không có thiết bị nào trong phòng này',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phòng: $roomName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add_device'),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm thiết bị'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        print('🔍 DEBUG: Building ListView with ${devices.length} devices');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            print(
              '🔍 DEBUG: Building device $index: ${device.name} (${device.type})',
            );

            // Hiển thị device dựa trên type
            if (device.type == DeviceType.relay) {
              print('🔍 DEBUG: Building relay device: ${device.name}');
              return _buildRelayDevice(context, device, deviceProvider);
            } else if (device.type == DeviceType.servo) {
              print('🔍 DEBUG: Building servo device: ${device.name}');
              return _buildServoDevice(context, device, deviceProvider);
            } else if (device.type == DeviceType.fan) {
              print('🔍 DEBUG: Building fan device: ${device.name}');
              return _buildServoDevice(
                context,
                device,
                deviceProvider,
              ); // Fan sử dụng servo UI
            }

            print('🔍 DEBUG: Unknown device type: ${device.type}');
            return Container(); // fallback
          },
        );
      },
    );
  }

  // Lấy devices từ provider theo phòng - SỬ DỤNG FIELD ROOM THAY VÌ HARD-CODE
  List<Device> _getDevicesFromProvider(DeviceProvider provider, String roomId) {
    final allDevices = provider.devices;

    // Debug: In ra tất cả devices và room của chúng
    print('🔍 DEBUG: All devices and their rooms:');
    for (final device in allDevices) {
      print('  - ${device.name} (${device.id}) -> room: "${device.room}"');
    }

    // Convert roomId từ format "living_room" về tên phòng thực tế để match với device.room
    final roomName = _convertRoomIdToName(roomId);
    print(
      '🔍 DEBUG: Looking for devices in room: "$roomName" (from roomId: "$roomId")',
    );

    // Lấy tất cả devices có room field khớp với roomName
    // Tìm kiếm linh hoạt: exact match hoặc partial match
    final devices = allDevices.where((device) {
      if (device.room == null) return false;

      // Exact match
      if (device.room == roomName) return true;

      // Partial match (case insensitive)
      if (device.room!.toLowerCase().contains(roomName.toLowerCase()) ||
          roomName.toLowerCase().contains(device.room!.toLowerCase())) {
        return true;
      }

      // Match với roomId (trường hợp thiết bị có room = tên thiết bị)
      if (device.room!.toLowerCase() == roomId.toLowerCase()) {
        return true;
      }

      return false;
    }).toList();
    print('🔍 DEBUG: Found ${devices.length} devices in room "$roomName"');

    // Debug: In ra chi tiết thiết bị được tìm thấy
    for (final device in devices) {
      print(
        '  ✅ Found device: ${device.name} (${device.id}) - Type: ${device.type}',
      );
    }

    return devices;
  }

  // Convert roomId từ format "living_room" về tên phòng thực tế
  String _convertRoomIdToName(String roomId) {
    switch (roomId) {
      case 'phòng_khách':
        return 'Phòng khách';
      case 'phòng_ngủ':
        return 'Phòng ngủ';
      case 'bếp':
        return 'Bếp';
      case 'phòng_tắm':
        return 'Phòng tắm';
      case 'sân_vườn':
        return 'Sân vườn';
      case 'living_room':
        return 'Phòng khách';
      case 'bedroom':
        return 'Phòng ngủ';
      case 'kitchen':
        return 'Bếp';
      case 'bathroom':
        return 'Phòng tắm';
      case 'garden':
        return 'Sân vườn';
      default:
        // Fallback: convert từ snake_case về Title Case
        return roomId
            .split('_')
            .map(
              (word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
            )
            .join(' ');
    }
  }

  Widget _buildRelayDevice(
    BuildContext context,
    Device device,
    DeviceProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.state ? Colors.green : Colors.grey,
          child: Text(device.icon ?? '⚡', style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: device.state ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              device.state ? 'Đang bật' : 'Đang tắt',
              style: TextStyle(color: device.state ? Colors.green : Colors.red),
            ),
          ],
        ),
        trailing: Switch(
          value: device.state,
          onChanged: (value) {
            provider.updateDeviceState(device.id, value);
          },
        ),
        onTap: () {
          Navigator.pushNamed(context, '/device_detail', arguments: device);
        },
      ),
    );
  }

  Widget _buildServoDevice(
    BuildContext context,
    Device device,
    DeviceProvider provider,
  ) {
    final value = device.value ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/device_detail', arguments: device);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: value > 0 ? Colors.blue : Colors.grey,
                    child: Text(
                      device.icon ?? '🎚️',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getServoStatusText(device, value),
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // On/Off switch cho fan_living
                  if (device.id == 'fan_living')
                    Switch(
                      value: device.state,
                      onChanged: (isOn) {
                        provider.toggleDevice(device.id);
                      },
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Slider điều khiển
              Row(
                children: [
                  Text(_getSliderLabel(device)),
                  Expanded(
                    child: Slider(
                      value: value.toDouble(),
                      min: 0,
                      max: _getSliderMax(device),
                      divisions: _getSliderDivisions(device),
                      onChanged: device.state || device.id != 'fan_living'
                          ? (newValue) {
                              provider.updateServoValue(
                                device.id,
                                newValue.round(),
                              );
                            }
                          : null, // Disable khi fan tắt
                    ),
                  ),
                  Text(_getSliderValueText(device, value)),
                ],
              ),

              // Preset buttons cho quạt
              if (device.id == 'fan_living') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPresetButton(
                      provider,
                      device,
                      'Chậm',
                      'low',
                      Colors.green,
                      value == 80,
                    ),
                    _buildPresetButton(
                      provider,
                      device,
                      'Vừa',
                      'medium',
                      Colors.orange,
                      value == 150,
                    ),
                    _buildPresetButton(
                      provider,
                      device,
                      'Nhanh',
                      'high',
                      Colors.red,
                      value == 255,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getServoStatusText(Device device, int value) {
    if (device.type == DeviceType.fan) {
      if (value == 0) return 'Tắt';
      return 'Tốc độ: ${((value / 255) * 100).round()}%';
    }
    return 'Góc: $value°';
  }

  String _getSliderLabel(Device device) {
    return device.type == DeviceType.fan ? 'Tốc độ: ' : 'Góc: ';
  }

  double _getSliderMax(Device device) {
    return device.type == DeviceType.fan ? 255 : 180;
  }

  int _getSliderDivisions(Device device) {
    return device.type == DeviceType.fan ? 10 : 18;
  }

  String _getSliderValueText(Device device, int value) {
    if (device.type == DeviceType.fan) {
      return '${((value / 255) * 100).round()}%';
    }
    return '$value°';
  }

  Widget _buildPresetButton(
    DeviceProvider provider,
    Device device,
    String label,
    String preset,
    Color color,
    bool isSelected,
  ) {
    return ElevatedButton(
      onPressed: () {
        provider.setFanPreset(device.id, preset);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.3),
        foregroundColor: isSelected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
