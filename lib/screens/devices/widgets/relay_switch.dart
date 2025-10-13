import 'package:flutter/material.dart';

class RelaySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final bool enabled;

  const RelaySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}
