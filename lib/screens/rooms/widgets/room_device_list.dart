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
          return const Center(
            child: Text('Không có thiết bị nào trong phòng này'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];

            print('🔧 Rendering device: ${device.name}, type: ${device.type}');

            // Hiển thị device dựa trên type
            if (device.type == DeviceType.relay) {
              return _buildRelayDevice(context, device, deviceProvider);
            } else if (device.type == DeviceType.servo) {
              return _buildServoDevice(context, device, deviceProvider);
            } else if (device.type == DeviceType.fan) {
              return _buildFanDevice(context, device, deviceProvider);
            } else {
              // Fallback: hiển thị generic device card
              print(
                '⚠️ Unknown device type: ${device.type} for ${device.name}',
              );
              return _buildRelayDevice(context, device, deviceProvider);
            }
          },
        );
      },
    );
  }

  // Lấy devices từ provider theo phòng - Filter by room field
  List<Device> _getDevicesFromProvider(DeviceProvider provider, String roomId) {
    // Lấy devices của user hiện tại
    final allDevices = provider.devices;

    print('');
    print('═══════════════════════════════════════');
    print('🏠 RoomDeviceList - Debug Info');
    print('═══════════════════════════════════════');
    print('📍 Current roomId: $roomId');
    print('📊 Total devices: ${allDevices.length}');
    print('');

    for (var device in allDevices) {
      print('  • Device: ${device.name}');
      print('    Room: "${device.room}"');
      print('    Match: ${device.room == roomId}');
    }

    // Filter theo room field (room được lưu khi user tạo device)
    final filtered = allDevices
        .where((device) => device.room == roomId)
        .toList();

    print('');
    print('✅ Filtered devices for room "$roomId": ${filtered.length}');
    print('═══════════════════════════════════════');
    print('');

    return filtered;
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
    if (device.id == 'fan_living') {
      if (value == 0) return 'Tắt';
      return 'Tốc độ: ${((value / 255) * 100).round()}%';
    }
    return 'Góc: $value°';
  }

  String _getSliderLabel(Device device) {
    return device.id == 'fan_living' ? 'Tốc độ: ' : 'Góc: ';
  }

  double _getSliderMax(Device device) {
    return device.id == 'fan_living' ? 255 : 180;
  }

  int _getSliderDivisions(Device device) {
    return device.id == 'fan_living' ? 10 : 18;
  }

  String _getSliderValueText(Device device, int value) {
    if (device.id == 'fan_living') {
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

  Widget _buildFanDevice(
    BuildContext context,
    Device device,
    DeviceProvider provider,
  ) {
    final speed = device.fanSpeed;
    final speedPercent = ((speed / 255) * 100).round();
    final isOn = speed > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isOn ? Colors.blue : Colors.grey,
          child: Icon(isOn ? Icons.air : Icons.wind_power, color: Colors.white),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isOn ? 'Tốc độ: $speedPercent%' : 'Đang tắt',
          style: TextStyle(
            fontSize: 12,
            color: isOn ? Colors.blue : Colors.grey,
          ),
        ),
        trailing: Switch(
          value: isOn,
          onChanged: (value) {
            if (value) {
              provider.setFanSpeed(device.id, Device.fanSpeedMedium);
            } else {
              provider.setFanSpeed(device.id, 0);
            }
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Speed Slider
                Row(
                  children: [
                    const Text('Tốc độ: '),
                    Expanded(
                      child: Slider(
                        value: speed.toDouble(),
                        min: 0,
                        max: 255,
                        divisions: 10,
                        label: '$speedPercent%',
                        onChanged: (value) {
                          provider.setFanSpeed(device.id, value.toInt());
                        },
                      ),
                    ),
                    Text('$speedPercent%'),
                  ],
                ),
                const SizedBox(height: 8),
                // Speed Presets
                Wrap(
                  spacing: 8,
                  children: [
                    _buildPresetButton(
                      provider,
                      device,
                      'Thấp',
                      'low',
                      Colors.green,
                      speed == Device.fanSpeedLow,
                    ),
                    _buildPresetButton(
                      provider,
                      device,
                      'Trung bình',
                      'medium',
                      Colors.orange,
                      speed == Device.fanSpeedMedium,
                    ),
                    _buildPresetButton(
                      provider,
                      device,
                      'Cao',
                      'high',
                      Colors.red,
                      speed == Device.fanSpeedHigh,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
