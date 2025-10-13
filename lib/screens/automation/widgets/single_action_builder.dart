import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/device_provider.dart';
import '../../../models/device_model.dart';

/// Widget xây dựng hành động cho MỘT thiết bị (start + end action)
class SingleActionBuilder extends StatefulWidget {
  final Map<String, dynamic>? initialAction;
  final ValueChanged<Map<String, dynamic>> onActionChanged;
  final VoidCallback onRemove;
  final bool showRemoveButton;

  const SingleActionBuilder({
    Key? key,
    this.initialAction,
    required this.onActionChanged,
    required this.onRemove,
    this.showRemoveButton = true,
  }) : super(key: key);

  @override
  State<SingleActionBuilder> createState() => _SingleActionBuilderState();
}

class _SingleActionBuilderState extends State<SingleActionBuilder> {
  String? _deviceId;

  // Start action
  String _startAction = 'on';
  int _startServoAngle = 90;
  String _startFanPreset = 'medium';

  // End action
  bool _hasEndAction = false;
  String _endAction = 'off';
  int _endServoAngle = 0;
  String _endFanPreset = 'off';

  @override
  void initState() {
    super.initState();
    if (widget.initialAction != null) {
      _deviceId = widget.initialAction!['device'];
      _startAction = widget.initialAction!['action'] ?? 'on';

      // Load start value
      if (widget.initialAction!['value'] != null) {
        final value = widget.initialAction!['value'];
        if (value is int) {
          _startServoAngle = value;
        } else if (value is String) {
          _startFanPreset = value;
        }
      }

      // Load end action
      if (widget.initialAction!['endAction'] != null) {
        _hasEndAction = true;
        _endAction = widget.initialAction!['endAction'];

        if (widget.initialAction!['endValue'] != null) {
          final endValue = widget.initialAction!['endValue'];
          if (endValue is int) {
            _endServoAngle = endValue;
          } else if (endValue is String) {
            _endFanPreset = endValue;
          }
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }

  void _notifyChange() {
    if (_deviceId == null) return;

    final deviceProvider = context.read<DeviceProvider>();
    final device = deviceProvider.devices.firstWhere(
      (d) => d.id == _deviceId,
      orElse: () => deviceProvider.devices.first,
    );

    Map<String, dynamic> actionData = {
      'device': _deviceId,
      'action': _startAction,
    };

    // Start action value
    if (device.isServo) {
      actionData['action'] = 'set_value';
      actionData['value'] = _startServoAngle;
    } else if (device.isFan) {
      actionData['action'] = _startFanPreset;
    } else {
      actionData['action'] = _startAction; // relay: on/off
    }

    // End action (optional)
    if (_hasEndAction) {
      if (device.isServo) {
        actionData['endAction'] = 'set_value';
        actionData['endValue'] = _endServoAngle;
      } else if (device.isFan) {
        actionData['endAction'] = _endFanPreset;
      } else {
        actionData['endAction'] = _endAction; // relay: on/off
      }
    }

    widget.onActionChanged(actionData);
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final devices = deviceProvider.devices;

    if (devices.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không có thiết bị nào'),
        ),
      );
    }

    // Auto-select first device if none selected
    if (_deviceId == null && devices.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _deviceId = devices.first.id;
          _notifyChange();
        });
      });
    }

    final selectedDevice = _deviceId != null
        ? devices.firstWhere(
            (d) => d.id == _deviceId,
            orElse: () => devices.first,
          )
        : devices.first;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Device selector + Remove button
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _deviceId ?? devices.first.id,
                    decoration: const InputDecoration(
                      labelText: 'Thiết bị',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.device_hub),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                ),
                if (widget.showRemoveButton) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Xóa thiết bị',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // START ACTION
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.play_arrow, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Khi bắt đầu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActionControls(
                    device: selectedDevice,
                    isEndAction: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // END ACTION Toggle
            CheckboxListTile(
              title: const Text('Có hành động khi kết thúc'),
              value: _hasEndAction,
              onChanged: (value) {
                setState(() {
                  _hasEndAction = value ?? false;
                  _notifyChange();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // END ACTION Controls
            if (_hasEndAction) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.stop, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Khi kết thúc',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildActionControls(
                      device: selectedDevice,
                      isEndAction: true,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionControls({
    required Device device,
    required bool isEndAction,
  }) {
    // Lấy state variables tùy theo start/end
    String action = isEndAction ? _endAction : _startAction;
    int servoAngle = isEndAction ? _endServoAngle : _startServoAngle;

    if (device.isServo) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Góc quay:', style: TextStyle(fontSize: 14)),
              Text(
                '$servoAngle°',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: servoAngle.toDouble(),
            min: 0,
            max: 180,
            divisions: 36,
            label: '$servoAngle°',
            onChanged: (value) {
              setState(() {
                if (isEndAction) {
                  _endServoAngle = value.toInt();
                } else {
                  _startServoAngle = value.toInt();
                }
                _notifyChange();
              });
            },
          ),
          Wrap(
            spacing: 8,
            children: [
              _buildPresetButton('Đóng', 0, Icons.close, isEndAction),
              _buildPresetButton('Giữa', 90, Icons.swap_horiz, isEndAction),
              _buildPresetButton('Mở', 180, Icons.open_in_full, isEndAction),
            ],
          ),
        ],
      );
    } else if (device.isFan) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFanPresetButton(
            'Tắt',
            'off',
            Icons.power_settings_new,
            isEndAction,
          ),
          _buildFanPresetButton('Nhẹ', 'low', Icons.air, isEndAction),
          _buildFanPresetButton('Khá', 'medium', Icons.air, isEndAction),
          _buildFanPresetButton('Mạnh', 'high', Icons.air, isEndAction),
        ],
      );
    } else {
      // Relay
      return DropdownButtonFormField<String>(
        value: action,
        decoration: const InputDecoration(
          labelText: 'Hành động',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.flash_on),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: const [
          DropdownMenuItem(value: 'on', child: Text('Bật')),
          DropdownMenuItem(value: 'off', child: Text('Tắt')),
        ],
        onChanged: (value) {
          setState(() {
            if (isEndAction) {
              _endAction = value!;
            } else {
              _startAction = value!;
            }
            _notifyChange();
          });
        },
      );
    }
  }

  Widget _buildPresetButton(
    String label,
    int angle,
    IconData icon,
    bool isEndAction,
  ) {
    final currentAngle = isEndAction ? _endServoAngle : _startServoAngle;
    final isSelected = currentAngle == angle;

    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          if (isEndAction) {
            _endServoAngle = angle;
          } else {
            _startServoAngle = angle;
          }
          _notifyChange();
        });
      },
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildFanPresetButton(
    String label,
    String preset,
    IconData icon,
    bool isEndAction,
  ) {
    final currentPreset = isEndAction ? _endFanPreset : _startFanPreset;
    final isSelected = currentPreset == preset;

    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          if (isEndAction) {
            _endFanPreset = preset;
          } else {
            _startFanPreset = preset;
          }
          _notifyChange();
        });
      },
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
