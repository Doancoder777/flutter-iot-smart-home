import 'dart:async';
import '../providers/automation_provider.dart';
import '../providers/device_provider.dart';
import '../providers/sensor_provider.dart';

/// Service để xử lý logic automation
class AutomationService {
  final AutomationProvider automationProvider;
  final DeviceProvider deviceProvider;
  final SensorProvider sensorProvider; // ✅ Thêm SensorProvider

  Timer? _evaluationTimer;
  final Map<String, bool> _ruleActiveState =
      {}; // Track rule đang active hay không

  AutomationService({
    required this.automationProvider,
    required this.deviceProvider,
    required this.sensorProvider, // ✅ Thêm parameter
  });

  void initialize() {
    // Đánh giá quy tắc mỗi 5 giây
    _evaluationTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _evaluateRules();
    });

    // ✅ Lắng nghe thay đổi sensor data
    sensorProvider.addListener(_evaluateRules);

    print('✅ AutomationService: Initialized');
  }

  void _evaluateRules() {
    // ✅ BUILD SENSOR MAP từ SensorProvider với REAL sensor IDs
    final sensorDataMap = <String, dynamic>{};

    for (var sensor in sensorProvider.userSensors) {
      if (sensor.isActive && sensor.lastValue != null) {
        // Dùng sensor ID làm key (VD: "sensor_1762005354206")
        sensorDataMap[sensor.id] = sensor.lastValue;
      }
    }

    // Debug log (uncomment để debug)
    // print('📊 Automation: ${sensorDataMap.length} sensors available');
    // sensorDataMap.forEach((id, value) {
    //   print('   - $id: $value');
    // });

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
        print('═══════════════════════════════════════════════════');
        print('🟢 AUTOMATION TRIGGERED: "${rule.name}"');
        print(
          '📋 Conditions met, executing ${rule.startActions.length} actions...',
        );
        for (var action in rule.startActions) {
          _executeAction(action.deviceId, action);
        }
        _ruleActiveState[ruleId] = true;
        print('═══════════════════════════════════════════════════');
      } else if (!isTriggered && wasActive) {
        // Rule vừa inactive → Có thể tắt thiết bị (tùy logic)
        print('🔴 AUTOMATION DEACTIVATED: "${rule.name}"');
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
    sensorProvider.removeListener(_evaluateRules); // ✅ Remove listener
    print('🛑 AutomationService: Disposed');
  }
}
