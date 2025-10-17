import 'dart:async';
import '../providers/automation_provider.dart';
import '../providers/device_provider.dart';
import '../models/sensor_data.dart';

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
      // print('⏰ Timer tick - evaluating rules...');
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
        for (var action in rule.startActions) {
          _executeAction(action.deviceId, action);
        }
        _ruleActiveState[ruleId] = true;
      } else if (!isTriggered && wasActive) {
        // Rule vừa inactive → Có thể tắt thiết bị (tùy logic)
        print('🔴 Rule "${rule.name}" deactivated');
        // Nếu muốn tự động tắt khi hết time:
        for (var action in rule.startActions) {
          _executeOffAction(action.deviceId, action);
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

      // Xác định loại action dựa trên action.action
      if (action.action == 'set_angle' && action.value != null) {
        // Servo device (góc)
        deviceProvider.updateServoValue(deviceId, action.value as int);
        print('🎬 Automation: Set $deviceId to angle ${action.value}°');
      } else if (action.action == 'set_speed' && action.speed != null) {
        // Fan device (tốc độ)
        deviceProvider.updateServoValue(deviceId, action.speed as int);
        print('🎬 Automation: Set $deviceId to speed ${action.speed}');
      } else {
        // Relay device (on/off)
        final isOn = action.action == 'on' || action.action == 'turn_on';
        deviceProvider.updateDeviceState(deviceId, isOn);
        print('🎬 Automation: Turn ${isOn ? 'ON' : 'OFF'} $deviceId');
      }
    } catch (e) {
      print('❌ Error executing action: $e');
    }
  }

  void _executeOffAction(String deviceId, dynamic action) {
    try {
      final device = deviceProvider.getDeviceById(deviceId);
      if (device == null) {
        print('❌ Device not found: $deviceId');
        return;
      }

      // Tắt thiết bị khi rule kết thúc
      if (action.action == 'set_angle') {
        // Servo device - trở về góc 0 hoặc góc được chỉ định trong end action
        final endAngle = action.value ?? 0;
        deviceProvider.updateServoValue(deviceId, endAngle);
        print('🎬 Automation: Reset $deviceId to ${endAngle}° (rule ended)');
      } else if (action.action == 'set_speed') {
        // Fan device - tắt hoặc tốc độ được chỉ định trong end action
        final endSpeed = action.speed ?? 0;
        deviceProvider.updateServoValue(deviceId, endSpeed);
        print('🎬 Automation: Set $deviceId to speed ${endSpeed} (rule ended)');
      } else {
        // Relay device - tắt
        deviceProvider.updateDeviceState(deviceId, false);
        print('🎬 Automation: Turn OFF $deviceId (rule ended)');
      }
    } catch (e) {
      print('❌ Error executing OFF action: $e');
    }
  }

  void dispose() {
    _evaluationTimer?.cancel();
    print('🛑 AutomationService: Disposed');
  }
}
