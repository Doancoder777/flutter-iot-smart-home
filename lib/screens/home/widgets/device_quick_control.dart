import 'package:flutter/material.dart';

class DeviceQuickControl extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isOn;
  final Function(bool) onToggle;
  final Color color;

  const DeviceQuickControl({
    Key? key,
    required this.icon,
    required this.title,
    required this.isOn,
    required this.onToggle,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isOn ? color.withOpacity(0.2) : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isOn ? color : Colors.grey[600], size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isOn ? 'Đang BẬT' : 'Đang TẮT',
          style: TextStyle(color: isOn ? color : Colors.grey, fontSize: 14),
        ),
        trailing: Switch(value: isOn, onChanged: onToggle, activeColor: color),
      ),
    );
  }
}
