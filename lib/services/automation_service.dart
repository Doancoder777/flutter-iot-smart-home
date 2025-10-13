import 'dart:async';
import '../providers/automation_provider.dart';
import '../providers/device_provider.dart';
import '../models/sensor_data.dart';
import '../models/device_model.dart';

/// Service để xử lý logic automation
class AutomationService {
  final AutomationProvider automationProvider;
  final DeviceProvider deviceProvider;

  Timer? _evaluationTimer;
  SensorData? _lastSensorData;
  // final Map<String, DateTime> _lastExecutionTime = {}; // Unused - removed
  final Map<String, bool> _ruleActiveState =
      {}; // Track rule đang active hay không
  // final Duration _cooldownDuration = Duration(seconds: 30); // Unused - removed

  AutomationService({
    required this.automationProvider,
    required this.deviceProvider,
  });

  void initialize() {
    // Đánh giá quy tắc mỗi 5 giây
    _evaluationTimer = Timer.periodic(Duration(seconds: 5), (_) {
      print('⏰ Timer tick - evaluating rules...');
      _evaluateRules();
    });
    print('✅ AutomationService: Initialized');
  }

  void updateSensorData(SensorData data) {
    _lastSensorData = data;
    // Đánh giá ngay khi có dữ liệu mới
    _evaluateRules();
  }

  void _evaluateRules() {
    // Tạo sensor data map, dùng giá trị mặc định nếu chưa có dữ liệu
    final sensorDataMap = _lastSensorData != null
        ? {
            'temperature': _lastSensorData!.temperature,
            'humidity': _lastSensorData!.humidity,
            'gas': _lastSensorData!.gas,
            'dust': _lastSensorData!.dust,
            'light': _lastSensorData!.light,
            'soil': _lastSensorData!.soilMoisture,
            'rain': _lastSensorData!.rain,
          }
        : <String, dynamic>{}; // Empty map cho quy tắc chỉ dựa vào thời gian

    // Lấy danh sách rules được trigger
    final triggeredRules = automationProvider.getTriggeredRules(sensorDataMap);

    // Kiểm tra từng rule xem có thay đổi trạng thái không
    for (var rule in automationProvider.rules) {
      final ruleId = rule.id;
      final isTriggered = triggeredRules.any((r) => r.id == ruleId);
      final wasActive = _ruleActiveState[ruleId] ?? false;

      // Chỉ thực thi khi CHUYỂN TRẠNG THÁI
      if (isTriggered && !wasActive) {
        // Rule vừa active → Thực thi ON actions
        print('🟢 Rule "${rule.name}" activated');
        for (var action in rule.actions) {
          _executeAction(action.deviceId, action);
        }
        _ruleActiveState[ruleId] = true;
      } else if (!isTriggered && wasActive) {
        // Rule vừa inactive → Thực thi END actions
        print('🔴 Rule "${rule.name}" deactivated - executing end actions');
        for (var action in rule.actions) {
          _executeEndAction(action.deviceId, action);
        }
        _ruleActiveState[ruleId] = false;
      }
    }
  }

  void _executeAction(String deviceId, dynamic action) {
    try {
      final device = deviceProvider.getDeviceById(deviceId);
      if (device == null) {
        print('❌ Device not found: $deviceId');
        return;
      }

      // Dispatch based on actual device type
      if (device.isFan) {
        // Fan actions: support presets (action.action = 'low'/'medium'/'high'/'off')
        // or numeric value in percent (0-100) or raw PWM (0-255)
        if (action.action == 'off' || action.action == 'turn_off') {
          deviceProvider.setFanSpeed(deviceId, 0);
          print('🎬 Automation: Fan $deviceId -> OFF');
        } else if (action.action == 'low' || action.action == 'low_speed') {
          deviceProvider.setFanSpeed(deviceId, Device.fanSpeedLow);
          print('🎬 Automation: Fan $deviceId -> LOW');
        } else if (action.action == 'medium' ||
            action.action == 'medium_speed') {
          deviceProvider.setFanSpeed(deviceId, Device.fanSpeedMedium);
          print('🎬 Automation: Fan $deviceId -> MEDIUM');
        } else if (action.action == 'high' || action.action == 'high_speed') {
          deviceProvider.setFanSpeed(deviceId, Device.fanSpeedHigh);
          print('🎬 Automation: Fan $deviceId -> HIGH');
        } else if (action.value != null) {
          final raw = action.value as int;
          int pwm;
          if (raw >= 0 && raw <= 100) {
            // value is percent -> map to 0-255
            pwm = ((raw / 100.0) * 255).round();
          } else {
            // assume already PWM 0-255
            pwm = raw.clamp(0, 255);
          }
          deviceProvider.setFanSpeed(deviceId, pwm);
          print(
            '🎬 Automation: Fan $deviceId -> PWM $pwm (from ${action.value})',
          );
        }
      } else if (device.isServo) {
        // Servo expects an integer angle
        if (action.value != null) {
          deviceProvider.updateServoValue(deviceId, action.value as int);
          print('🎬 Automation: Set $deviceId to angle ${action.value}°');
        } else {
          print('⚠️ Automation: No value provided for servo $deviceId');
        }
      } else {
        // Fallback/relay: interpret action.action
        final isOn =
            (action.action == 'on' ||
            action.action == 'turn_on' ||
            action.action == '1');
        deviceProvider.updateDeviceState(deviceId, isOn);
        print('🎬 Automation: Turn ${isOn ? 'ON' : 'OFF'} $deviceId');
      }
    } catch (e) {
      print('❌ Error executing action: $e');
    }
  }

  void _executeEndAction(String deviceId, dynamic action) {
    try {
      final device = deviceProvider.getDeviceById(deviceId);
      if (device == null) {
        print('❌ Device not found: $deviceId');
        return;
      }

      // Nếu có endAction được định nghĩa, thực thi nó
      if (action.endAction != null && action.endAction.isNotEmpty) {
        print('🎬 Executing END action for $deviceId: ${action.endAction}');

        if (device.isFan) {
          // Fan end actions: presets hoặc off
          if (action.endAction == 'off' || action.endAction == 'turn_off') {
            deviceProvider.setFanSpeed(deviceId, 0);
          } else if (action.endAction == 'low') {
            deviceProvider.setFanSpeed(deviceId, Device.fanSpeedLow);
          } else if (action.endAction == 'medium') {
            deviceProvider.setFanSpeed(deviceId, Device.fanSpeedMedium);
          } else if (action.endAction == 'high') {
            deviceProvider.setFanSpeed(deviceId, Device.fanSpeedHigh);
          }
          print('🎬 Automation END: Fan $deviceId -> ${action.endAction}');
        } else if (device.isServo) {
          // Servo end action: set angle
          final angle = action.endValue ?? 0;
          deviceProvider.updateServoValue(deviceId, angle);
          print('🎬 Automation END: Servo $deviceId -> ${angle}°');
        } else {
          // Relay end action: on/off
          final isOn =
              (action.endAction == 'on' || action.endAction == 'turn_on');
          deviceProvider.updateDeviceState(deviceId, isOn);
          print('🎬 Automation END: Turn ${isOn ? 'ON' : 'OFF'} $deviceId');
        }
      } else {
        // Không có endAction → Tắt thiết bị (default behavior)
        print('🎬 No END action defined, turning OFF $deviceId');
        if (device.isFan) {
          deviceProvider.setFanSpeed(deviceId, 0);
        } else if (device.isServo) {
          deviceProvider.updateServoValue(deviceId, 0);
        } else {
          deviceProvider.updateDeviceState(deviceId, false);
        }
      }
    } catch (e) {
      print('❌ Error executing END action: $e');
    }
  }

  void dispose() {
    _evaluationTimer?.cancel();
    print('🛑 AutomationService: Disposed');
  }
}
