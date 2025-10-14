import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/device_model.dart';
import '../../providers/device_provider.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();
  DeviceType _selectedType = DeviceType.relay;
  String? _selectedIcon;
  String? _customImagePath;
  double _servoValue = 0.0;
  double _fanSpeed = 0.0; // 🌪️ THÊM FAN SPEED
  bool _isLoading = false;

  // 📡 MQTT Configuration
  final _mqttBrokerController = TextEditingController();
  final _mqttPortController = TextEditingController(text: '1883');
  final _mqttUsernameController = TextEditingController();
  final _mqttPasswordController = TextEditingController();
  bool _mqttUseSsl = false;
  bool _showMqttPassword = false;

  // 🔑 ESP32 Device ID
  final _deviceIdController = TextEditingController();

  // 🎚️ Servo range settings (hỗ trợ 360°)
  double _servoMinAngle = 0.0;
  double _servoMaxAngle = 360.0; // Mặc định 360° cho servo liên tục
  double _servoOffValue = 0.0; // Giá trị khi "tắt" servo
  bool _isServo360 = true; // Chế độ servo 360 độ
  bool _servoEnabled = false; // Trạng thái bật/tắt servo

  // Device type and room options
  // 📋 Sử dụng extension từ DeviceType thay vì hardcode
  // final Map<DeviceType, String> _deviceTypeLabels = {
  //   DeviceType.relay: 'Relay (Đèn/Thiết bị)',
  //   DeviceType.servo: 'Servo Motor',
  //   DeviceType.fan: 'Quạt (Fan)', // 🌪️ THÊM LOẠI QUẠT
  // };

  final Map<DeviceType, List<String>> _deviceTypeIcons = {
    DeviceType.relay: [
      '💡',
      '🔆',
      '💥',
      '⭐',
      '🌟',
      '',
      '🚪',
      '🔐',
      '🔑',
      '🏠',
      '🔒',
    ],
    DeviceType.servo: [
      '⚙️',
      '🔧',
      '🛠️',
      '🔩',
      '⚡',
      '🎚️',
      '📐',
      '↗️',
      '🔄',
      '🎮',
    ],
    DeviceType.fan: [
      '🌀',
      '💨',
      '🌪️',
      '❄️',
      '🎐',
      '🌬️',
      '💨',
      '🌀',
      '🔄',
    ], // 🌪️ ICONS CHO QUẠT
  };

  @override
  void initState() {
    super.initState();
    _selectedIcon = _deviceTypeIcons[_selectedType]?.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    _mqttBrokerController.dispose();
    _mqttPortController.dispose();
    _mqttUsernameController.dispose();
    _mqttPasswordController.dispose();
    _deviceIdController.dispose();
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
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String deviceImagesDir = path.join(appDir.path, 'device_images');
        await Directory(deviceImagesDir).create(recursive: true);

        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String newPath = path.join(deviceImagesDir, fileName);

        await File(image.path).copy(newPath);

        setState(() {
          _customImagePath = newPath;
          _selectedIcon = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _customImagePath = null;
      _selectedIcon = _deviceTypeIcons[_selectedType]?.first;
    });
  }

  // 🧪 Test MQTT Connection - Ping-Pong với Global Connection
  Future<void> _testMqttConnection() async {
    // Validate inputs
    if (_mqttBrokerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vui lòng nhập MQTT Broker'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_deviceIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vui lòng nhập Device ID (ESP32) để test'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final deviceId = _deviceIdController.text.trim();
    final deviceName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'test_device';

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('');
      debugPrint('═══════════════════════════════════════');
      debugPrint('🧪 TEST CONNECTION - Using Global MQTT');
      debugPrint('═══════════════════════════════════════');

      final deviceProvider = Provider.of<DeviceProvider>(
        context,
        listen: false,
      );

      // Check if global MQTT is connected
      if (deviceProvider.mqttProvider == null ||
          !deviceProvider.mqttProvider!.isConnected) {
        throw Exception('MQTT chưa kết nối. Vui lòng đợi app khởi động xong.');
      }

      debugPrint('✅ Using global MQTT connection');

      // Topics for ping-pong
      final checkTopic = 'smart_home/devices/$deviceId/$deviceName/ping';
      final statusTopic = 'smart_home/devices/$deviceId/$deviceName/state';

      debugPrint('📤 Ping topic: $checkTopic');
      debugPrint('📥 Status topic: $statusTopic');

      bool receivedResponse = false;

      // Subscribe to status topic
      debugPrint('📡 Subscribing to status topic...');
      deviceProvider.mqttProvider!.subscribe(statusTopic, (topic, message) {
        debugPrint('📩 Received: $topic = $message');
        if (message == '1' || message == 'online' || message == 'pong') {
          receivedResponse = true;
          debugPrint('✅ ESP32 responded!');
        }
      });

      // Wait for subscribe to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Send ping
      debugPrint('📤 Sending ping...');
      deviceProvider.mqttProvider!.publish(checkTopic, 'ping');
      debugPrint('✅ Ping sent, waiting for response (3 seconds)...');

      // Wait for response
      await Future.delayed(const Duration(seconds: 3));

      // Unsubscribe
      deviceProvider.mqttProvider!.unsubscribe(statusTopic);

      debugPrint('');
      debugPrint('═══════════════════════════════════════');
      debugPrint(
        '🧪 RESULT: ${receivedResponse ? "✅ SUCCESS" : "❌ NO RESPONSE"}',
      );
      debugPrint('═══════════════════════════════════════');
      debugPrint('');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (receivedResponse) {
          // ✅ SUCCESS - ESP32 responded
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '✅ Test kết nối thành công!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('📡 Broker: ${_mqttBrokerController.text.trim()}'),
                  Text('🆔 Device ID: $deviceId'),
                  Text('📱 Device: $deviceName'),
                  const Divider(color: Colors.white30, height: 12),
                  const Text(
                    '🎉 ESP32 đã phản hồi! Sẵn sàng thêm thiết bị.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          // ⚠️ NO RESPONSE - ESP32 not responding
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ ESP32 không phản hồi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('� Kiểm tra:'),
                  const Text('• ESP32 đã bật và kết nối WiFi chưa?'),
                  Text('• Device ID đúng chưa? ($deviceId)'),
                  const Text('• ESP32 đã subscribe topic ping chưa?'),
                  const Divider(color: Colors.white30, height: 12),
                  Text(
                    '📤 Ping: $checkTopic',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    '� Status: $statusTopic',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Test error: $e');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIcon == null && _customImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn biểu tượng hoặc ảnh cho thiết bị'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceProvider = Provider.of<DeviceProvider>(
        context,
        listen: false,
      );

      final success = await deviceProvider.addDevice(
        name: _nameController.text.trim(),
        type: _selectedType,
        room: _roomController.text.trim(),
        icon: _selectedIcon,
        initialValue: _selectedType == DeviceType.servo
            ? _servoValue.round()
            : _selectedType == DeviceType.fan
            ? _fanSpeed
                  .round() // 🌪️ FAN SPEED
            : null,
        // 📡 MQTT config
        mqttBroker: _mqttBrokerController.text.trim().isNotEmpty
            ? _mqttBrokerController.text.trim()
            : null,
        mqttPort: _mqttPortController.text.trim().isNotEmpty
            ? int.tryParse(_mqttPortController.text.trim())
            : null,
        mqttUsername: _mqttUsernameController.text.trim().isNotEmpty
            ? _mqttUsernameController.text.trim()
            : null,
        mqttPassword: _mqttPasswordController.text.trim().isNotEmpty
            ? _mqttPasswordController.text.trim()
            : null,
        mqttUseSsl: _mqttUseSsl,
        // 🔑 ESP32 Device ID
        esp32DeviceId: _deviceIdController.text.trim().isNotEmpty
            ? _deviceIdController.text.trim()
            : null,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã thêm thiết bị "${_nameController.text.trim()}" thành công',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể thêm thiết bị. Vui lòng thử lại.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
        title: const Text('Thêm thiết bị mới'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Preview
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Xem trước thiết bị',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
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
                                  _selectedIcon ?? '💡',
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nameController.text.isEmpty
                            ? 'Tên thiết bị'
                            : _nameController.text,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _selectedType.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _roomController.text.isEmpty
                            ? 'Chưa chọn phòng'
                            : _roomController.text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      if (_selectedType == DeviceType.servo)
                        Text(
                          'Giá trị: ${_servoValue.round()}°',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      if (_selectedType == DeviceType.fan) // 🌪️ FAN PREVIEW
                        Text(
                          'Tốc độ: ${_fanSpeed == 0 ? "Tắt" : "${((_fanSpeed / 255) * 100).round()}%"}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Device Name
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên thiết bị',
                      hintText: 'Nhập tên cho thiết bị',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên thiết bị';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Device Type and Room
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<DeviceType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Loại thiết bị',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: DeviceType.values.map((type) {
                          return DropdownMenuItem<DeviceType>(
                            value: type,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  type.icon,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    type.displayName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _showDeviceTypeInfo(type),
                                  child: const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (DeviceType? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedType = newValue;
                              _selectedIcon = _deviceTypeIcons[newValue]?.first;
                              _customImagePath = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _roomController,
                        decoration: const InputDecoration(
                          labelText: 'Phòng',
                          hintText:
                              'Nhập tên phòng (vd: Phòng khách, Phòng ngủ)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.room),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên phòng';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // Refresh preview
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Servo Settings
              if (_selectedType == DeviceType.servo)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cài đặt Servo Motor',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Chọn loại servo và nút Tắt/Mở
                        Row(
                          children: [
                            Text(
                              'Loại: ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            ChoiceChip(
                              label: const Text('180°'),
                              selected: !_isServo360,
                              onSelected: (selected) {
                                setState(() {
                                  _isServo360 = false;
                                  _servoMaxAngle = 180.0;
                                  if (_servoValue > 180) _servoValue = 180;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('360°'),
                              selected: _isServo360,
                              onSelected: (selected) {
                                setState(() {
                                  _isServo360 = true;
                                  _servoMaxAngle = 360.0;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Nút Tắt/Mở Servo
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _servoEnabled = false;
                                    _servoValue = _servoOffValue;
                                  });
                                },
                                icon: const Icon(Icons.power_off, size: 18),
                                label: const Text('TẮT'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _servoEnabled
                                      ? Colors.red.shade100
                                      : Colors.red.shade300,
                                  foregroundColor: Colors.red.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _servoEnabled = true;
                                    _servoValue = _isServo360 ? 90 : 90;
                                  });
                                },
                                icon: const Icon(Icons.power, size: 18),
                                label: const Text('MỞ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _servoEnabled
                                      ? Colors.green.shade300
                                      : Colors.green.shade100,
                                  foregroundColor: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Dải góc điều chỉnh (chỉ hiện với servo 180°)
                        if (!_isServo360) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Góc tối thiểu: ${_servoMinAngle.round()}°',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Slider(
                                      value: _servoMinAngle,
                                      min: 0,
                                      max: (_isServo360 ? 360 : 180) - 10,
                                      divisions: 17,
                                      label: '${_servoMinAngle.round()}°',
                                      onChanged: (double value) {
                                        setState(() {
                                          _servoMinAngle = value;
                                          if (_servoValue < value)
                                            _servoValue = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Góc tối đa: ${_servoMaxAngle.round()}°',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Slider(
                                      value: _servoMaxAngle,
                                      min: _servoMinAngle + 10,
                                      max: _isServo360 ? 360 : 180,
                                      divisions: 17,
                                      label: '${_servoMaxAngle.round()}°',
                                      onChanged: (double value) {
                                        setState(() {
                                          _servoMaxAngle = value;
                                          if (_servoValue > value)
                                            _servoValue = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ), // Đóng Row

                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                        ], // Đóng if (!_isServo360)
                        // Góc hiện tại
                        Text(
                          _servoEnabled
                              ? 'Góc hiện tại: ${_servoValue.round()}°'
                              : 'Servo: TẮT (${_servoOffValue.round()}°)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _servoEnabled
                                    ? Colors.blue.shade700
                                    : Colors.red.shade700,
                              ),
                        ),
                        Slider(
                          value: _servoValue,
                          min: _servoMinAngle,
                          max: _servoMaxAngle,
                          divisions: (_servoMaxAngle - _servoMinAngle).round(),
                          label: '${_servoValue.round()}°',
                          onChanged: _servoEnabled
                              ? (double value) {
                                  setState(() {
                                    _servoValue = value;
                                  });
                                }
                              : null,
                        ),

                        const SizedBox(height: 8),

                        // Giá trị tắt tùy chỉnh
                        Row(
                          children: [
                            Text(
                              'Giá trị "Tắt": ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: _servoOffValue.round().toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  suffixText: '°',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed != null &&
                                      parsed >= 0 &&
                                      parsed <= 180) {
                                    setState(() {
                                      _servoOffValue = parsed;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _servoValue = _servoOffValue;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade100,
                                foregroundColor: Colors.red.shade700,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Tắt'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Preset buttons
                        Text(
                          'Vị trí nhanh:',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _isServo360
                              ? [
                                  // Servo 360° - các vị trí đặc biệt
                                  _servoAngleButton('Dừng', 90),
                                  _servoAngleButton('Chậm thuận', 100),
                                  _servoAngleButton('Trung bình', 120),
                                  _servoAngleButton('Nhanh thuận', 180),
                                  _servoAngleButton('Chậm nghịch', 80),
                                  _servoAngleButton('Nhanh nghịch', 0),
                                ]
                              : [
                                  // Servo 180° - các góc cụ thể
                                  _servoAngleButton(
                                    'Tối thiểu',
                                    _servoMinAngle,
                                  ),
                                  _servoAngleButton(
                                    'Giữa',
                                    (_servoMinAngle + _servoMaxAngle) / 2,
                                  ),
                                  _servoAngleButton('Tối đa', _servoMaxAngle),
                                  _servoAngleButton('45°', 45),
                                  _servoAngleButton('90°', 90),
                                  _servoAngleButton('135°', 135),
                                ].where((btn) {
                                  // Chỉ hiện button nếu giá trị nằm trong dải
                                  if (btn == _servoAngleButton('45°', 45))
                                    return 45 >= _servoMinAngle &&
                                        45 <= _servoMaxAngle;
                                  if (btn == _servoAngleButton('90°', 90))
                                    return 90 >= _servoMinAngle &&
                                        90 <= _servoMaxAngle;
                                  if (btn == _servoAngleButton('135°', 135))
                                    return 135 >= _servoMinAngle &&
                                        135 <= _servoMaxAngle;
                                  return true;
                                }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              // 🌪️ Fan Settings
              if (_selectedType == DeviceType.fan)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cài đặt Quạt (PWM)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Nút điều khiển nhanh cho Fan
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _fanSpeed = 0;
                                  });
                                },
                                icon: const Icon(Icons.power_off, size: 18),
                                label: const Text('TẮT'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _fanSpeed == 0
                                      ? Colors.red.shade300
                                      : Colors.red.shade100,
                                  foregroundColor: Colors.red.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _fanSpeed = 128; // ~50% tốc độ
                                  });
                                },
                                icon: const Icon(Icons.air, size: 18),
                                label: const Text('MỞ VỪA'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (_fanSpeed > 80 && _fanSpeed < 180)
                                      ? Colors.orange.shade300
                                      : Colors.orange.shade100,
                                  foregroundColor: Colors.orange.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _fanSpeed = 255; // 100% tốc độ
                                  });
                                },
                                icon: const Icon(Icons.wind_power, size: 18),
                                label: const Text('MỞ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _fanSpeed > 200
                                      ? Colors.green.shade300
                                      : Colors.green.shade100,
                                  foregroundColor: Colors.green.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Tốc độ ban đầu: ${_getFanSpeedLabel(_fanSpeed)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Slider(
                          value: _fanSpeed,
                          min: 0,
                          max: 255,
                          divisions: 25,
                          label: _getFanSpeedLabel(_fanSpeed),
                          onChanged: (double value) {
                            setState(() {
                              _fanSpeed = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _fanSpeedButton('Tắt', 0, Colors.red),
                            _fanSpeedButton('Nhẹ', 85, Colors.green),
                            _fanSpeedButton('Khá', 170, Colors.orange),
                            _fanSpeedButton('Mạnh', 255, Colors.blue),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildFanInfoItem('Tắt', '0%', Colors.red),
                              _buildFanInfoItem('Nhẹ', '33%', Colors.green),
                              _buildFanInfoItem('Khá', '67%', Colors.orange),
                              _buildFanInfoItem('Mạnh', '100%', Colors.blue),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Icon Selector
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
                            'Biểu tượng thiết bị',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_customImagePath != null)
                            TextButton.icon(
                              onPressed: _clearImage,
                              icon: const Icon(Icons.clear, size: 18),
                              label: const Text('Xóa ảnh'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            _customImagePath != null
                                ? 'Thay đổi ảnh'
                                : 'Chọn ảnh từ thư viện',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _customImagePath != null
                                ? Colors.green
                                : Colors.blue,
                            side: BorderSide(
                              color: _customImagePath != null
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      if (_customImagePath == null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Hoặc chọn biểu tượng có sẵn:',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _deviceTypeIcons[_selectedType]?.map((icon) {
                                final isSelected = _selectedIcon == icon;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedIcon = icon;
                                    });
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade100,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
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
                              }).toList() ??
                              [],
                        ),
                      ], // <- Closing bracket for if (_customImagePath == null) ...[
                    ], // <- Closing bracket for Column children in Icon Selector Card
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 📡 MQTT Configuration Section
              _buildMqttConfigSection(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _addDevice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Thêm thiết bị',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  // 🌪️ FAN SPEED BUTTON HELPER WITH COLOR
  Widget _fanSpeedButton(String label, double speed, Color color) {
    final isSelected = _fanSpeed == speed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _fanSpeed = speed;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  // 🌪️ FAN INFO ITEM HELPER
  Widget _buildFanInfoItem(String label, String percent, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(percent, style: const TextStyle(fontSize: 9)),
      ],
    );
  }

  // 🌪️ GET FAN SPEED LABEL
  String _getFanSpeedLabel(double speed) {
    if (speed == 0) return 'Tắt (0%)';
    if (speed <= 85) return 'Nhẹ (${((speed / 255) * 100).round()}%)';
    if (speed <= 170) return 'Khá (${((speed / 255) * 100).round()}%)';
    return 'Mạnh (${((speed / 255) * 100).round()}%)';
  }

  // 🎚️ SERVO ANGLE BUTTON HELPER
  Widget _servoAngleButton(String label, double angle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _servoValue = angle;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _servoValue == angle
              ? Theme.of(context).primaryColor
              : Colors.grey[300],
          foregroundColor: _servoValue == angle ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _showDeviceTypeInfo(DeviceType type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(type.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Text(type.displayName)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Text(
                'Thông số kỹ thuật:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Giá trị: ${type.minValue} - ${type.maxValue}${type.unit}',
              ),
              if (type.presets.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Các chế độ thông dụng:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                ...type.presets.map(
                  (preset) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text('• ${preset.name}'),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  /// 📡 MQTT Configuration Section
  Widget _buildMqttConfigSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Cấu hình MQTT',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.help_outline, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('📡 MQTT là gì?'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'MQTT là giao thức truyền thông cho IoT.\n\n'
                            'Mỗi thiết bị cần có thông tin MQTT để kết nối đến vi điều khiển (ESP32, Arduino, ...).\n\n'
                            '• Broker: Địa chỉ máy chủ MQTT (VD: 192.168.1.100)\n'
                            '• Port: Cổng kết nối (mặc định 1883)\n'
                            '• Username/Password: Thông tin đăng nhập (nếu có)\n'
                            '• SSL: Mã hóa kết nối (nên bật nếu có hỗ trợ)',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🔑 ESP32 Device ID
            TextFormField(
              controller: _deviceIdController,
              decoration: InputDecoration(
                labelText: 'ESP32 Device ID (Không bắt buộc)',
                hintText: 'VD: ESP32_A4CF12B23D5E',
                helperText:
                    'Tìm trên nhãn dán của thiết bị ESP32. Để trống nếu không có.',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.fingerprint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!value.startsWith('ESP32_')) {
                    return 'Device ID phải bắt đầu bằng ESP32_';
                  }
                  if (value.length < 10) {
                    return 'Device ID quá ngắn (tối thiểu 10 ký tự)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // MQTT Broker
            TextFormField(
              controller: _mqttBrokerController,
              decoration: InputDecoration(
                labelText: 'MQTT Broker *',
                hintText: 'VD: 192.168.1.100 hoặc broker.hivemq.com',
                prefixIcon: const Icon(Icons.dns),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // Auto-detect HiveMQ Cloud và suggest SSL
                if (value.toLowerCase().contains('hivemq.cloud')) {
                  setState(() {
                    if (!_mqttUseSsl) {
                      _mqttUseSsl = true;
                      _mqttPortController.text = '8883';
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '💡 HiveMQ Cloud phát hiện! Auto-enable SSL/TLS',
                          ),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  });
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa chỉ MQTT broker';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // MQTT Port
            TextFormField(
              controller: _mqttPortController,
              decoration: InputDecoration(
                labelText: 'MQTT Port',
                hintText: '1883',
                prefixIcon: const Icon(Icons.settings_ethernet),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Port phải từ 1-65535';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // MQTT Username
            TextFormField(
              controller: _mqttUsernameController,
              decoration: InputDecoration(
                labelText: 'Username (tùy chọn)',
                hintText: 'Để trống nếu không cần',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // MQTT Password
            TextFormField(
              controller: _mqttPasswordController,
              decoration: InputDecoration(
                labelText: 'Password (tùy chọn)',
                hintText: 'Để trống nếu không cần',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showMqttPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showMqttPassword = !_showMqttPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: !_showMqttPassword,
            ),
            const SizedBox(height: 16),

            // SSL Toggle
            SwitchListTile(
              title: const Text('Sử dụng SSL/TLS'),
              subtitle: const Text('Mã hóa kết nối (port 8883)'),
              value: _mqttUseSsl,
              onChanged: (value) {
                setState(() {
                  _mqttUseSsl = value;
                  if (value) {
                    _mqttPortController.text = '8883';
                  } else {
                    _mqttPortController.text = '1883';
                  }
                });
              },
              secondary: const Icon(Icons.security),
            ),

            // Info box về HiveMQ Cloud
            if (_mqttBrokerController.text.toLowerCase().contains('hivemq'))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HiveMQ Cloud yêu cầu SSL/TLS và credentials',
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),

            // Test Connection Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _testMqttConnection,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Test kết nối MQTT'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.blue[600]!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
