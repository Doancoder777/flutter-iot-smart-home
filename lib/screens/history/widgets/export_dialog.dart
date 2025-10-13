import 'package:flutter/material.dart';

/// Dialog xuất dữ liệu
class ExportDialog extends StatefulWidget {
  final String sensorType;
  final String period;

  const ExportDialog({Key? key, required this.sensorType, required this.period})
    : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _format = 'csv';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xuất dữ liệu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xuất dữ liệu ${_getSensorName(widget.sensorType)} ${_getPeriodName(widget.period)}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          const Text(
            'Định dạng:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: const Text('CSV'),
            subtitle: const Text('Comma-separated values'),
            value: 'csv',
            groupValue: _format,
            onChanged: (value) {
              setState(() {
                _format = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('JSON'),
            subtitle: const Text('JavaScript Object Notation'),
            value: 'json',
            groupValue: _format,
            onChanged: (value) {
              setState(() {
                _format = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Excel'),
            subtitle: const Text('Microsoft Excel (.xlsx)'),
            value: 'excel',
            groupValue: _format,
            onChanged: (value) {
              setState(() {
                _format = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _handleExport(context);
          },
          icon: const Icon(Icons.file_download),
          label: const Text('Xuất'),
        ),
      ],
    );
  }

  void _handleExport(BuildContext context) {
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đang xuất dữ liệu định dạng ${_format.toUpperCase()}...',
        ),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {
            // Mở file đã xuất
          },
        ),
      ),
    );

    // TODO: Implement actual export functionality
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xuất dữ liệu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  String _getSensorName(String id) {
    switch (id) {
      case 'temperature':
        return 'Nhiệt độ';
      case 'humidity':
        return 'Độ ẩm';
      case 'gas':
        return 'Khí gas';
      case 'dust':
        return 'Bụi';
      case 'light':
        return 'Ánh sáng';
      case 'soil':
        return 'Độ ẩm đất';
      default:
        return id;
    }
  }

  String _getPeriodName(String id) {
    switch (id) {
      case 'day':
        return 'hôm nay';
      case 'week':
        return 'tuần này';
      case 'month':
        return 'tháng này';
      case 'year':
        return 'năm này';
      default:
        return id;
    }
  }
}
