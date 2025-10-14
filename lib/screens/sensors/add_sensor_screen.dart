import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sensor_type.dart';
import '../../providers/sensor_provider.dart';
import '../../config/app_colors.dart';

class AddSensorScreen extends StatefulWidget {
  const AddSensorScreen({Key? key}) : super(key: key);

  @override
  State<AddSensorScreen> createState() => _AddSensorScreenState();
}

class _AddSensorScreenState extends State<AddSensorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _mqttTopicController = TextEditingController();
  final _maxValueController = TextEditingController();
  final _trueLabelController = TextEditingController();
  final _falseLabelController = TextEditingController();

  // 📡 MQTT Config Controllers
  final _sensorIdController = TextEditingController();
  final _mqttBrokerController = TextEditingController();
  final _mqttPortController = TextEditingController(text: '8883');
  final _mqttUsernameController = TextEditingController();
  final _mqttPasswordController = TextEditingController();
  bool _mqttUseSsl = true;
  bool _showMqttPassword = false;

  SensorType? _selectedSensorType;
  String? _selectedIcon;
  DisplayType _displayType = DisplayType.percentage;
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _mqttTopicController.dispose();
    _maxValueController.dispose();
    _trueLabelController.dispose();
    _falseLabelController.dispose();
    // MQTT controllers
    _sensorIdController.dispose();
    _mqttBrokerController.dispose();
    _mqttPortController.dispose();
    _mqttUsernameController.dispose();
    _mqttPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm cảm biến'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sensor Type Selection
            _buildSensorTypeSection(),
            const SizedBox(height: 24),

            // Display Name
            _buildDisplayNameField(),
            const SizedBox(height: 16),

            // MQTT Topic
            _buildMqttTopicField(),
            const SizedBox(height: 24),

            // Display Configuration
            _buildDisplayConfigSection(),
            const SizedBox(height: 24),

            // Sensor Type Info
            if (_selectedSensorType != null) _buildSensorInfo(),
            const SizedBox(height: 24),

            // MQTT Configuration
            _buildMqttConfigSection(),
            const SizedBox(height: 32),

            // Add Button
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại cảm biến',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: AvailableSensorTypes.all.length,
          itemBuilder: (context, index) {
            final sensorType = AvailableSensorTypes.all[index];
            final isSelected = _selectedSensorType?.id == sensorType.id;

            return InkWell(
              onTap: () => _selectSensorType(sensorType),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Text(sensorType.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sensorType.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? AppColors.primary : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDisplayNameField() {
    return TextFormField(
      controller: _displayNameController,
      decoration: const InputDecoration(
        labelText: 'Tên hiển thị *',
        hintText: 'VD: Nhiệt độ phòng khách',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập tên hiển thị';
        }
        return null;
      },
    );
  }

  Widget _buildMqttTopicField() {
    return TextFormField(
      controller: _mqttTopicController,
      decoration: InputDecoration(
        labelText: 'MQTT Topic',
        hintText:
            _selectedSensorType?.defaultMqttTopic ?? 'smart_home/sensors/...',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.auto_fix_high),
          onPressed: _generateMqttTopic,
          tooltip: 'Tự động tạo topic',
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập MQTT topic';
        }
        if (!value.contains('/')) {
          return 'Topic phải có định dạng: prefix/sensor_name';
        }
        return null;
      },
    );
  }

  Widget _buildSensorInfo() {
    final sensorType = _selectedSensorType!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(sensorType.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sensorType.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sensorType.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  'Đơn vị',
                  sensorType.unit.isEmpty ? 'Không có' : sensorType.unit,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  'Kiểu dữ liệu',
                  _getDataTypeText(sensorType.dataType),
                ),
              ],
            ),
            if (sensorType.minValue != null && sensorType.maxValue != null) ...[
              const SizedBox(height: 8),
              _buildInfoChip(
                'Phạm vi',
                '${sensorType.minValue} - ${sensorType.maxValue}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildDisplayConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cấu hình hiển thị',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Display Type Selection
            DropdownButtonFormField<DisplayType>(
              value: _displayType,
              decoration: const InputDecoration(
                labelText: 'Kiểu hiển thị',
                border: OutlineInputBorder(),
              ),
              items: DisplayType.values.map((type) {
                String label;
                switch (type) {
                  case DisplayType.boolean:
                    label = 'Có/Không (On/Off)';
                    break;
                  case DisplayType.pulse:
                    label = 'Xung (Pulse)';
                    break;
                  case DisplayType.percentage:
                    label = 'Phần trăm (%)';
                    break;
                }
                return DropdownMenuItem(value: type, child: Text(label));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _displayType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Conditional configuration based on display type
            if (_displayType == DisplayType.boolean) ...[
              TextFormField(
                controller: _trueLabelController,
                decoration: const InputDecoration(
                  labelText: 'Nhãn khi TRUE',
                  hintText: 'Bật, Có, On...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _falseLabelController,
                decoration: const InputDecoration(
                  labelText: 'Nhãn khi FALSE',
                  hintText: 'Tắt, Không, Off...',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else if (_displayType == DisplayType.percentage) ...[
              TextFormField(
                controller: _maxValueController,
                decoration: const InputDecoration(
                  labelText: 'Giá trị tối đa (100%)',
                  hintText: 'Ví dụ: 1024 cho analog',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_displayType == DisplayType.percentage &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập giá trị tối đa';
                  }
                  if (value != null && value.isNotEmpty) {
                    final number = double.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Vui lòng nhập số dương';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            // Icon Selection
            Text(
              'Icon tùy chỉnh (tùy chọn)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showIconPicker,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedIcon ?? (_selectedSensorType?.icon ?? '📊'),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedIcon != null
                          ? 'Icon tùy chỉnh'
                          : 'Dùng icon mặc định',
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _addSensor,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
            : const Text('Thêm cảm biến'),
      ),
    );
  }

  void _selectSensorType(SensorType sensorType) {
    setState(() {
      _selectedSensorType = sensorType;

      // Auto-fill tên hiển thị nếu chưa có
      if (_displayNameController.text.isEmpty) {
        _displayNameController.text = sensorType.name;
      }

      // Auto-generate MQTT topic nếu chưa có
      if (_mqttTopicController.text.isEmpty) {
        _generateMqttTopic();
      }
    });
  }

  void _generateMqttTopic() {
    if (_selectedSensorType == null) return;

    final sensorProvider = Provider.of<SensorProvider>(context, listen: false);
    final existingSensors = sensorProvider.userSensors;

    // Generate unique topic
    var counter = 1;
    String topic;

    do {
      if (counter == 1) {
        topic = '${_selectedSensorType!.defaultMqttTopic}/user';
      } else {
        topic = '${_selectedSensorType!.defaultMqttTopic}/user/$counter';
      }
      counter++;
    } while (existingSensors.any((s) => s.mqttTopic == topic));

    _mqttTopicController.text = topic;
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn Icon'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
            ),
            itemCount: _commonIcons.length,
            itemBuilder: (context, index) {
              final icon = _commonIcons[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedIcon == icon
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedIcon = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Dùng mặc định'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  static const List<String> _commonIcons = [
    '🌡️',
    '💧',
    '💨',
    '💡',
    '🔥',
    '⚡',
    '📊',
    '📈',
    '🔔',
    '🚨',
    '⚠️',
    '✅',
    '❌',
    '🟢',
    '🔴',
    '🟡',
    '🔵',
    '⚪',
    '🌪️',
    '🌊',
    '🔋',
    '⚙️',
    '🎛️',
    '📡',
    '🏠',
    '🚪',
    '🪟',
    '🛡️',
    '🔒',
    '🔓',
    '📱',
    '💻',
    '⌚',
    '🎯',
    '📍',
    '🔍',
  ];

  String _getDataTypeText(SensorDataType dataType) {
    switch (dataType) {
      case SensorDataType.double:
        return 'Số thực';
      case SensorDataType.int:
        return 'Số nguyên';
      case SensorDataType.bool:
        return 'True/False';
    }
  }

  Future<void> _addSensor() async {
    if (!_formKey.currentState!.validate() || _selectedSensorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sensorProvider = Provider.of<SensorProvider>(
        context,
        listen: false,
      );

      // Tạo DisplayConfig từ form
      DisplayConfig? displayConfig;
      switch (_displayType) {
        case DisplayType.boolean:
          displayConfig = DisplayConfig(
            type: DisplayType.boolean,
            trueLabel: _trueLabelController.text.trim().isNotEmpty
                ? _trueLabelController.text.trim()
                : null,
            falseLabel: _falseLabelController.text.trim().isNotEmpty
                ? _falseLabelController.text.trim()
                : null,
          );
          break;
        case DisplayType.percentage:
          final maxValue = double.tryParse(_maxValueController.text.trim());
          if (maxValue != null && maxValue > 0) {
            displayConfig = DisplayConfig(
              type: DisplayType.percentage,
              maxValue: maxValue,
            );
          }
          break;
        case DisplayType.pulse:
          displayConfig = DisplayConfig(type: DisplayType.pulse);
          break;
      }

      // Tạo configuration map
      final configuration = <String, dynamic>{};
      if (displayConfig != null) {
        configuration['displayConfig'] = displayConfig.toJson();
      }
      if (_selectedIcon != null) {
        configuration['customIcon'] = _selectedIcon;
      }

      await sensorProvider.addSensor(
        sensorTypeId: _selectedSensorType!.id,
        displayName: _displayNameController.text.trim(),
        customMqttTopic: _mqttTopicController.text.trim(),
        configuration: configuration,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Đã thêm cảm biến "${_displayNameController.text}"',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true để báo đã thêm sensor
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
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
                            'Mỗi cảm biến cần có thông tin MQTT để kết nối đến vi điều khiển (ESP32, Arduino, ...).\n\n'
                            '• Sensor ID: Mã định danh cảm biến trên ESP32\n'
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

            // 🔑 ESP32 Sensor ID
            TextFormField(
              controller: _sensorIdController,
              decoration: InputDecoration(
                labelText: 'ESP32 Sensor ID (Không bắt buộc)',
                hintText: 'VD: DHT22_01',
                helperText:
                    'Mã định danh của cảm biến trên ESP32. Để trống nếu không có.',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.fingerprint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                // Validate không có http:// prefix
                if (value.trim().startsWith('http://') ||
                    value.trim().startsWith('https://')) {
                  return 'Broker không cần http:// hoặc https://';
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
                hintText: '8883',
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
                  // Warning cho SSL port
                  if (_mqttUseSsl && port != 8883) {
                    return 'SSL/TLS thường dùng port 8883';
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

  Future<void> _testMqttConnection() async {
    // Validate required fields
    if (_mqttBrokerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vui lòng nhập MQTT Broker'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate broker format
    final broker = _mqttBrokerController.text.trim();
    if (broker.startsWith('http://') || broker.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Broker không cần http:// hoặc https://'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate port
    final port = int.tryParse(_mqttPortController.text.trim());
    if (port == null || port < 1 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Port phải từ 1-65535'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sensorProvider = context.read<SensorProvider>();

      print('🔍 DEBUG: mqttProvider = ${sensorProvider.mqttProvider}');
      print(
        '🔍 DEBUG: isConnected = ${sensorProvider.mqttProvider?.isConnected}',
      );

      // Kiểm tra MQTT đã connected chưa
      if (sensorProvider.mqttProvider == null ||
          !sensorProvider.mqttProvider!.isConnected) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ MQTT chưa kết nối.\n'
                'mqttProvider: ${sensorProvider.mqttProvider}\n'
                'isConnected: ${sensorProvider.mqttProvider?.isConnected}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Sử dụng sensor ID hoặc tên hiển thị làm fallback
      final sensorId = _sensorIdController.text.trim().isNotEmpty
          ? _sensorIdController.text.trim()
          : _displayNameController.text.trim().replaceAll(' ', '_');

      if (sensorId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Vui lòng nhập Sensor ID hoặc Tên hiển thị'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final sensorName = _displayNameController.text.trim().isNotEmpty
          ? _displayNameController.text.trim()
          : 'sensor';

      // Topic format: smart_home/sensors/{sensorId}/{sensorName}/state
      final stateTopic =
          'smart_home/sensors/$sensorId/${sensorName.replaceAll(' ', '_')}/state';
      final pingTopic =
          'smart_home/sensors/$sensorId/${sensorName.replaceAll(' ', '_')}/ping';

      print('🔔 Testing sensor connection...');
      print('📤 Subscribe to: $stateTopic');
      print('📤 Will publish to: $pingTopic');

      bool receivedResponse = false;

      // Subscribe to state topic
      sensorProvider.mqttProvider!.subscribe(stateTopic, (topic, message) {
        print('📥 Received on $topic: $message');
        if (message == '1' ||
            message.toLowerCase() == 'online' ||
            message.toLowerCase() == 'pong') {
          receivedResponse = true;
        }
      });

      // Publish ping
      sensorProvider.mqttProvider!.publish(pingTopic, 'ping');
      print('📤 Published ping to $pingTopic');

      // Wait 3 seconds for response
      await Future.delayed(const Duration(seconds: 3));

      // Unsubscribe
      sensorProvider.mqttProvider!.unsubscribe(stateTopic);

      if (context.mounted) {
        if (receivedResponse) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  Expanded(child: const Text('✅ Kết nối thành công')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cảm biến đã phản hồi!\n'),
                  Text('📡 Broker: $broker:$port'),
                  Text('🔐 SSL: ${_mqttUseSsl ? "Bật" : "Tắt"}'),
                  if (_mqttUsernameController.text.isNotEmpty)
                    Text('👤 Username: ${_mqttUsernameController.text}'),
                  Text('\n✅ Cảm biến đang online và sẵn sàng!'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: const Text('⚠️ Không nhận được phản hồi')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Không nhận được phản hồi từ cảm biến trong 3 giây.\n',
                  ),
                  Text('📡 Broker: $broker:$port'),
                  Text('🔐 SSL: ${_mqttUseSsl ? "Bật" : "Tắt"}'),
                  const Text('\n💡 Nguyên nhân có thể:'),
                  const Text('• ESP32 chưa được lập trình'),
                  const Text('• Cảm biến đang offline'),
                  const Text('• Cấu hình MQTT không khớp với ESP32'),
                  const Text('• Topic format không đúng'),
                  const Text('\n⚙️ Bạn vẫn có thể thêm cảm biến này.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Test connection error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi kết nối: $e'),
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
}
