import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../models/user_sensor.dart';
import '../../models/sensor_type.dart';
import '../../providers/sensor_provider.dart';

class EditSensorScreen extends StatefulWidget {
  final UserSensor sensor;

  const EditSensorScreen({super.key, required this.sensor});

  @override
  State<EditSensorScreen> createState() => _EditSensorScreenState();
}

class _EditSensorScreenState extends State<EditSensorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mqttTopicController;
  late TextEditingController _maxValueController;
  late TextEditingController _trueLabelController;
  late TextEditingController _falseLabelController;

  String? _selectedIcon;
  String? _customImagePath;
  DisplayType _displayType = DisplayType.percentage;
  bool _isLoading = false;

  // Available sensor icons
  final List<String> _sensorIcons = [
    '🌡️',
    '💧',
    '🌧️',
    '☀️',
    '🌱',
    '☁️',
    '🌫️',
    '🚶',
    '🔽',
    '☢️',
    '🔥',
    '⚡',
    '🚰',
    '🧪',
    '📡',
    '🔧',
    '📊',
    '💡',
    '🔋',
    '🌀',
    '🎯',
    '📈',
    '⭐',
    '🔔',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sensor.displayName);
    _mqttTopicController = TextEditingController(text: widget.sensor.mqttTopic);
    _selectedIcon = widget.sensor.customIcon ?? widget.sensor.icon;

    // Initialize display config
    if (widget.sensor.displayConfig != null) {
      _displayType = widget.sensor.displayConfig!.type;
      _maxValueController = TextEditingController(
        text: widget.sensor.displayConfig!.maxValue?.toString() ?? '',
      );
      _trueLabelController = TextEditingController(
        text: widget.sensor.displayConfig!.trueLabel ?? '',
      );
      _falseLabelController = TextEditingController(
        text: widget.sensor.displayConfig!.falseLabel ?? '',
      );
    } else {
      _maxValueController = TextEditingController();
      _trueLabelController = TextEditingController();
      _falseLabelController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mqttTopicController.dispose();
    _maxValueController.dispose();
    _trueLabelController.dispose();
    _falseLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        setState(() {
          _customImagePath = image.path;
          _selectedIcon =
              null; // Clear emoji icon when custom image is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateSensor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final sensorProvider = Provider.of<SensorProvider>(
        context,
        listen: false,
      );

      // Create display config
      DisplayConfig? displayConfig;
      switch (_displayType) {
        case DisplayType.boolean:
          displayConfig = DisplayConfig(
            type: DisplayType.boolean,
            trueLabel: _trueLabelController.text.trim().isEmpty
                ? null
                : _trueLabelController.text.trim(),
            falseLabel: _falseLabelController.text.trim().isEmpty
                ? null
                : _falseLabelController.text.trim(),
          );
          break;
        case DisplayType.pulse:
          displayConfig = DisplayConfig(type: DisplayType.pulse);
          break;
        case DisplayType.percentage:
          final maxValue = double.tryParse(_maxValueController.text.trim());
          displayConfig = DisplayConfig(
            type: DisplayType.percentage,
            maxValue: maxValue,
          );
          break;
      }

      // Create updated sensor
      final updatedSensor = widget.sensor.copyWith(
        displayName: _nameController.text.trim(),
        mqttTopic: _mqttTopicController.text.trim(),
        customIcon: _selectedIcon,
        displayConfig: displayConfig,
      );

      await sensorProvider.updateSensor(updatedSensor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cập nhật cảm biến "${_nameController.text.trim()}"',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật cảm biến: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa cảm biến'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showDeleteDialog(context),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Preview Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Xem trước cảm biến',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: _customImagePath != null
                            ? ClipOval(
                                child: Image.file(
                                  File(_customImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.error,
                                      size: 40,
                                      color: Colors.red,
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Text(
                                  _selectedIcon ?? '📊',
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _nameController.text.isEmpty
                            ? 'Tên cảm biến'
                            : _nameController.text,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.sensor.sensorType?.name ?? 'Cảm biến',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Basic Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin cơ bản',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên hiển thị',
                          hintText: 'Nhập tên hiển thị cho cảm biến',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên cảm biến';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // Refresh preview
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mqttTopicController,
                        decoration: const InputDecoration(
                          labelText: 'MQTT Topic',
                          hintText: 'smart_home/sensors/...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.wifi),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập MQTT topic';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Icon Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Biểu tượng',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Ảnh tùy chỉnh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              childAspectRatio: 1,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _sensorIcons.length,
                        itemBuilder: (context, index) {
                          final icon = _sensorIcons[index];
                          final isSelected = icon == _selectedIcon;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIcon = icon;
                                _customImagePath = null; // Clear custom image
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected
                                    ? Colors.orange.shade100
                                    : Colors.grey.shade100,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.orange.shade400
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Display Configuration
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cấu hình hiển thị',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Display Type Selector
                      DropdownButtonFormField<DisplayType>(
                        value: _displayType,
                        decoration: const InputDecoration(
                          labelText: 'Kiểu hiển thị',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.visibility),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: DisplayType.boolean,
                            child: Text('Boolean (Có/Không)'),
                          ),
                          DropdownMenuItem(
                            value: DisplayType.pulse,
                            child: Text('Pulse (Đếm xung)'),
                          ),
                          DropdownMenuItem(
                            value: DisplayType.percentage,
                            child: Text('Percentage (Phần trăm)'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _displayType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Configuration fields based on display type
                      if (_displayType == DisplayType.boolean) ...[
                        TextFormField(
                          controller: _trueLabelController,
                          decoration: const InputDecoration(
                            labelText: 'Nhãn cho trạng thái True',
                            hintText: 'vd: Có, Bật, Mở...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _falseLabelController,
                          decoration: const InputDecoration(
                            labelText: 'Nhãn cho trạng thái False',
                            hintText: 'vd: Không, Tắt, Đóng...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

                      if (_displayType == DisplayType.percentage) ...[
                        TextFormField(
                          controller: _maxValueController,
                          decoration: const InputDecoration(
                            labelText: 'Giá trị tối đa',
                            hintText: 'Nhập giá trị analog tối đa',
                            border: OutlineInputBorder(),
                            suffixText: 'max',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final numValue = double.tryParse(value);
                              if (numValue == null || numValue <= 0) {
                                return 'Vui lòng nhập số dương';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateSensor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Đang cập nhật...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Cập nhật cảm biến',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa cảm biến'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa cảm biến "${widget.sensor.displayName}"? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final sensorProvider = Provider.of<SensorProvider>(
                context,
                listen: false,
              );
              await sensorProvider.deleteSensor(widget.sensor.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã xóa cảm biến "${widget.sensor.displayName}"',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop(); // Go back to previous screen
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
