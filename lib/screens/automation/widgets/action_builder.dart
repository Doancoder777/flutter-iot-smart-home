import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/device_provider.dart';

/// Widget xây dựng hành động cho quy tắc tự động
class ActionBuilder extends StatefulWidget {
  final Map<String, dynamic>? initialAction;
  final ValueChanged<Map<String, dynamic>> onActionChanged;

  const ActionBuilder({
    Key? key,
    this.initialAction,
    required this.onActionChanged,
  }) : super(key: key);

  @override
  State<ActionBuilder> createState() => _ActionBuilderState();
}

class _ActionBuilderState extends State<ActionBuilder> {
  String _actionType = 'device';
  String? _deviceId; // Device ID từ user's devices
  String _action = 'on';
  int _servoAngle = 90;
  String _fanPreset = 'medium'; // Preset cho fan: off/low/medium/high

  @override
  void initState() {
    super.initState();
    if (widget.initialAction != null) {
      _deviceId = widget.initialAction!['device'];
      _action = widget.initialAction!['action'] ?? 'on';

      // Load giá trị tùy theo loại action
      if (widget.initialAction!['value'] != null) {
        final value = widget.initialAction!['value'];
        if (value is int) {
          _servoAngle = value;
        } else if (value is String) {
          _fanPreset = value; // 'low', 'medium', 'high', 'off'
        }
      }
    }
    // Gọi sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  void _notifyChange() {
    if (_deviceId == null) return;

    final deviceProvider = context.read<DeviceProvider>();
    final device = deviceProvider.devices.firstWhere((d) => d.id == _deviceId);

    // Xác định action data tùy device type
    Map<String, dynamic> actionData = {
      'type': _actionType,
      'device': _deviceId,
      'action': _action,
    };

    if (device.isServo) {
      actionData['action'] = 'set_value';
      actionData['value'] = _servoAngle;
    } else if (device.isFan) {
      // Fan có thể dùng preset hoặc percent
      if (_fanPreset == 'off') {
        actionData['action'] = 'off';
      } else {
        actionData['action'] = _fanPreset; // 'low'/'medium'/'high'
      }
    } else {
      // Relay: on/off
      actionData['action'] = _action; // 'on' hoặc 'off'
    }

    widget.onActionChanged(actionData);
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final devices = deviceProvider.devices;

    // Nếu chưa có device được chọn, chọn device đầu tiên
    if (_deviceId == null && devices.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _deviceId = devices.first.id;
          _notifyChange();
        });
      });
    }

    if (devices.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không có thiết bị nào. Vui lòng thêm thiết bị trước.'),
        ),
      );
    }

    final selectedDevice = _deviceId != null
        ? devices.firstWhere(
            (d) => d.id == _deviceId,
            orElse: () => devices.first,
          )
        : devices.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hành động',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Chọn thiết bị (từ danh sách thực của user)
            DropdownButtonFormField<String>(
              value: _deviceId ?? devices.first.id,
              decoration: const InputDecoration(
                labelText: 'Thiết bị',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.device_hub),
              ),
              items: devices.map((device) {
                return DropdownMenuItem(
                  value: device.id,
                  child: Row(
                    children: [
                      Icon(
                        device.isFan
                            ? Icons.air
                            : device.isServo
                            ? Icons.zoom_out_map
                            : Icons.power_settings_new,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(device.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _deviceId = value!;
                  _notifyChange();
                });
              },
            ),
            const SizedBox(height: 16),

            // Hành động tùy theo loại thiết bị
            if (selectedDevice.isServo) ...[
              // SERVO: Slider góc 0-180°
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Góc quay:', style: TextStyle(fontSize: 14)),
                  Text(
                    '$_servoAngle°',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _servoAngle.toDouble(),
                min: 0,
                max: 180,
                divisions: 36,
                label: '$_servoAngle°',
                onChanged: (value) {
                  setState(() {
                    _servoAngle = value.toInt();
                    _notifyChange();
                  });
                },
              ),
              // Preset buttons cho servo
              Wrap(
                spacing: 8,
                children: [
                  _buildPresetButton('Đóng', 0, Icons.close),
                  _buildPresetButton('Giữa', 90, Icons.swap_horiz),
                  _buildPresetButton('Mở', 180, Icons.open_in_full),
                ],
              ),
            ] else if (selectedDevice.isFan) ...[
              // FAN: Preset buttons (Tắt/Nhẹ/Khá/Mạnh)
              const Text('Tốc độ quạt:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFanPresetButton('Tắt', 'off', Icons.power_settings_new),
                  _buildFanPresetButton('Nhẹ', 'low', Icons.air),
                  _buildFanPresetButton('Khá', 'medium', Icons.air),
                  _buildFanPresetButton('Mạnh', 'high', Icons.air),
                ],
              ),
            ] else ...[
              // RELAY: Bật/Tắt
              DropdownButtonFormField<String>(
                value: _action,
                decoration: const InputDecoration(
                  labelText: 'Hành động',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flash_on),
                ),
                items: const [
                  DropdownMenuItem(value: 'on', child: Text('Bật')),
                  DropdownMenuItem(value: 'off', child: Text('Tắt')),
                ],
                onChanged: (value) {
                  setState(() {
                    _action = value!;
                    _notifyChange();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, int angle, IconData icon) {
    final isSelected = _servoAngle == angle;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _servoAngle = angle;
          _notifyChange();
        });
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildFanPresetButton(String label, String preset, IconData icon) {
    final isSelected = _fanPreset == preset;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _fanPreset = preset;
          _notifyChange();
        });
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }
}
