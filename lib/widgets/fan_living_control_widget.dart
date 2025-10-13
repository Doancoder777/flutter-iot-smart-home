import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/device_model.dart';

class FanLivingControlWidget extends StatelessWidget {
  final Device device;

  const FanLivingControlWidget({Key? key, required this.device})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        final currentSpeed = device.value ?? 0;
        final isOn = device.state;
        final percentage = ((currentSpeed / 255) * 100).round();

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      device.icon ?? '🌀',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isOn ? 'Tốc độ: $percentage%' : 'Tắt',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isOn ? Colors.green : Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // On/Off Switch
                    Switch(
                      value: isOn,
                      onChanged: (value) {
                        deviceProvider.toggleDevice(device.id);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Speed Slider
                Row(
                  children: [
                    const Text('Tốc độ: '),
                    Expanded(
                      child: Slider(
                        value: currentSpeed.toDouble(),
                        min: 0,
                        max: 255,
                        divisions: 10,
                        label: '$percentage%',
                        onChanged: isOn
                            ? (value) {
                                deviceProvider.updateServoValue(
                                  device.id,
                                  value.round(),
                                );
                              }
                            : null,
                      ),
                    ),
                    Text('$percentage%'),
                  ],
                ),

                const SizedBox(height: 12),

                // Preset Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPresetButton(
                      context,
                      deviceProvider,
                      'Chậm',
                      'low',
                      Colors.green,
                      currentSpeed == 80,
                    ),
                    _buildPresetButton(
                      context,
                      deviceProvider,
                      'Vừa',
                      'medium',
                      Colors.orange,
                      currentSpeed == 150,
                    ),
                    _buildPresetButton(
                      context,
                      deviceProvider,
                      'Nhanh',
                      'high',
                      Colors.red,
                      currentSpeed == 255,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Technical Info
                if (isOn)
                  Text(
                    'PWM: $currentSpeed/255 • L298N Motor Driver',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    DeviceProvider deviceProvider,
    String label,
    String preset,
    Color color,
    bool isSelected,
  ) {
    return ElevatedButton(
      onPressed: () {
        deviceProvider.setFanPreset(device.id, preset);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.3),
        foregroundColor: isSelected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }
}
