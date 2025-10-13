import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/automation_service.dart';
import '../providers/automation_provider.dart';
import '../providers/device_provider.dart';
import '../providers/sensor_provider.dart';

/// Widget để khởi tạo và quản lý AutomationService
class AutomationInitializer extends StatefulWidget {
  final Widget child;

  const AutomationInitializer({Key? key, required this.child})
    : super(key: key);

  @override
  State<AutomationInitializer> createState() => _AutomationInitializerState();
}

class _AutomationInitializerState extends State<AutomationInitializer> {
  AutomationService? _automationService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_automationService == null) {
      final automationProvider = context.read<AutomationProvider>();
      final deviceProvider = context.read<DeviceProvider>();
      final sensorProvider = context.read<SensorProvider>();

      _automationService = AutomationService(
        automationProvider: automationProvider,
        deviceProvider: deviceProvider,
      );

      _automationService!.initialize();

      // Lắng nghe thay đổi sensor data
      sensorProvider.addListener(() {
        _automationService?.updateSensorData(sensorProvider.currentData);
      });
    }
  }

  @override
  void dispose() {
    _automationService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
