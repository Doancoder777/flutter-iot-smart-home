import 'package:flutter/material.dart';

enum AlertType { gas, dust, soil, rain }

class AlertBanner extends StatelessWidget {
  final AlertType type;
  final String message;
  final dynamic value;

  const AlertBanner({
    Key? key,
    required this.type,
    required this.message,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getColor(), width: 2),
      ),
      child: Row(
        children: [
          Icon(_getIcon(), color: _getColor(), size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: _getColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (value != null)
                  Text(
                    'Giá trị: $value',
                    style: TextStyle(
                      color: _getColor().withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (type) {
      case AlertType.gas:
        return Colors.red;
      case AlertType.dust:
        return Colors.orange;
      case AlertType.soil:
        return Colors.brown;
      case AlertType.rain:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case AlertType.gas:
        return Icons.warning;
      case AlertType.dust:
        return Icons.air;
      case AlertType.soil:
        return Icons.grass;
      case AlertType.rain:
        return Icons.cloud;
    }
  }
}
