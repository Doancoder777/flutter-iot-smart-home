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
  String _device = 'pump';
  String _action = 'on';
  int _servoAngle = 90;
  int _fanSpeed = 50;
  String _fanMode = 'auto';

  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
    if (widget.initialAction != null) {
      _device = widget.initialAction!['device'] ?? 'pump';
      _action = widget.initialAction!['action'] ?? 'on';
      _servoAngle = widget.initialAction!['value'] ?? 90;
      _fanSpeed = widget.initialAction!['speed'] ?? 50;
      _fanMode = widget.initialAction!['mode'] ?? 'auto';
    }

    // Ensure selected device exists in the list
    if (_devices.isNotEmpty) {
      final deviceExists = _devices.any((d) => d['id'] == _device);
      if (!deviceExists) {
        _device = _devices.first['id'] as String;
      }
    }

    // Gọi sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  void _loadDevices() {
    // Load devices from provider
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    _devices = deviceProvider.devices.map<Map<String, dynamic>>((device) {
      return <String, dynamic>{
        'id': device.id,
        'name': device.name,
        'type': device.type
            .toString()
            .split('.')
            .last, // Convert enum to string
      };
    }).toList();
  }

  void _resetValuesForDeviceType() {
    final selectedDevice = _devices.firstWhere(
      (d) => d['id'] == _device,
      orElse: () => <String, dynamic>{
        'id': '',
        'name': 'No device',
        'type': 'relay',
      },
    );
    final deviceType = selectedDevice['type'] as String;

    switch (deviceType) {
      case 'servo':
        _servoAngle = 90; // Reset to center position
        break;
      case 'fan':
        _fanSpeed = 50; // Reset to medium speed
        _fanMode = 'auto'; // Reset to auto mode
        break;
      case 'relay':
      default:
        _action = 'on'; // Reset to turn on
        break;
    }
  }

  Widget _buildFanPresetButton(String label, int speed) {
    final isSelected = _fanSpeed == speed;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _fanSpeed = speed;
          _notifyChange();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.red : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _notifyChange() {
    if (_devices.isEmpty) return; // Skip if no devices loaded

    final deviceInfo = _devices.firstWhere(
      (d) => d['id'] == _device,
      orElse: () => <String, dynamic>{
        'id': '',
        'name': 'No device',
        'type': 'relay',
      },
    );

    // Xác định action phù hợp với loại thiết bị
    String action = _action;
    if (deviceInfo['type'] == 'servo') {
      action = 'set_angle'; // Servo luôn dùng set_angle
    } else if (deviceInfo['type'] == 'fan') {
      action = 'set_speed'; // Fan luôn dùng set_speed
    }
    // Relay giữ nguyên action (turn_on/turn_off)

    widget.onActionChanged({
      'type': _actionType,
      'device': _device,
      'action': action,
      'value': deviceInfo['type'] == 'servo' ? _servoAngle : null,
      'speed': deviceInfo['type'] == 'fan' ? _fanSpeed : null,
      'mode': deviceInfo['type'] == 'fan' ? _fanMode : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = _devices.firstWhere(
      (d) => d['id'] == _device,
      orElse: () => <String, dynamic>{
        'id': '',
        'name': 'No device',
        'type': 'relay',
      },
    );
    final deviceType = selectedDevice['type'] as String;
    final isServo = deviceType == 'servo';
    final isFan = deviceType == 'fan';

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

            // Chọn thiết bị
            DropdownButtonFormField<String>(
              value: _device,
              decoration: const InputDecoration(
                labelText: 'Thiết bị',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.device_hub),
              ),
              items: _devices.map((device) {
                return DropdownMenuItem<String>(
                  value: device['id'] as String,
                  child: Text(device['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _device = value!;
                  // Reset values when device type changes
                  _resetValuesForDeviceType();
                  _notifyChange();
                });
              },
            ),
            const SizedBox(height: 16),

            // Hành động
            if (isServo) ...[
              // Servo: Slider góc
              Row(
                children: [
                  const Icon(Icons.rotate_right, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Điều khiển Servo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Góc: $_servoAngle°', style: const TextStyle(fontSize: 14)),
              Slider(
                value: _servoAngle.toDouble(),
                min: 0,
                max: 180,
                divisions: 18,
                label: '$_servoAngle°',
                onChanged: (value) {
                  setState(() {
                    _servoAngle = value.toInt();
                    _notifyChange();
                  });
                },
              ),
            ] else if (isFan) ...[
              // Fan: Avatar + Slider + Preset buttons (giống quản lý thiết bị)
              Row(
                children: [
                  // Avatar giống quản lý thiết bị
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.toys, size: 24, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedDevice['name'] ?? 'Unknown Device',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$_fanSpeed°',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Slider giống quản lý thiết bị
              Slider(
                value: _fanSpeed.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$_fanSpeed%',
                activeColor: Colors.red,
                onChanged: (value) {
                  setState(() {
                    _fanSpeed = value.toInt();
                    _notifyChange();
                  });
                },
              ),
              // Labels cho slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tắt',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    'Mạnh',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Fan preset buttons giống quản lý thiết bị
              Row(
                children: [
                  Expanded(child: _buildFanPresetButton('Tắt', 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFanPresetButton('Nhẹ', 33)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFanPresetButton('Khá', 67)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFanPresetButton('Mạnh', 100)),
                ],
              ),
            ] else ...[
              // Relay: Bật/Tắt
              Row(
                children: [
                  const Icon(
                    Icons.electrical_services,
                    size: 20,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Điều khiển Relay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
}
