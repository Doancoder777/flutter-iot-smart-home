import 'package:flutter/material.dart';

class ServoSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final bool enabled;
  final int min;
  final int max;

  const ServoSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.enabled = true,
    this.min = 0,
    this.max = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              '$value°',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$value°',
          onChanged: enabled ? (v) => onChanged(v.round()) : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$min°', style: Theme.of(context).textTheme.bodySmall),
            Text('$max°', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
