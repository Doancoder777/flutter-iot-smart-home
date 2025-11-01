class AutomationRule {
  final String id;
  final String name;
  final bool enabled;
  final List<Condition> conditions;
  final List<Action> startActions; // Hành động khi điều kiện được thỏa mãn
  final List<Action>
  endActions; // Hành động khi điều kiện không còn thỏa mãn (mặc định tắt)
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final String? startTime; // Format: "HH:mm"
  final String? endTime; // Format: "HH:mm"
  final bool hasEndActions; // Cho phép tùy chỉnh end actions

  AutomationRule({
    required this.id,
    required this.name,
    required this.enabled,
    required this.conditions,
    required this.startActions,
    List<Action>? endActions,
    required this.createdAt,
    this.lastTriggered,
    this.startTime,
    this.endTime,
    this.hasEndActions = false, // Mặc định không có end actions tùy chỉnh
  }) : endActions = endActions ?? []; // Mặc định tắt nếu không có end actions

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'],
      name: json['name'],
      enabled: json['enabled'],
      conditions: (json['conditions'] as List)
          .map((e) => Condition.fromJson(e))
          .toList(),
      startActions:
          (json['startActions'] as List?)
              ?.map((e) => Action.fromJson(e))
              .toList() ??
          (json['actions'] as List) // Backward compatibility
              .map((e) => Action.fromJson(e))
              .toList(),
      endActions: (json['endActions'] as List?)
          ?.map((e) => Action.fromJson(e))
          .toList(),
      hasEndActions: json['hasEndActions'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastTriggered: json['lastTriggered'] != null
          ? DateTime.parse(json['lastTriggered'])
          : null,
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'conditions': conditions.map((e) => e.toJson()).toList(),
      'startActions': startActions.map((e) => e.toJson()).toList(),
      'endActions': endActions.map((e) => e.toJson()).toList(),
      'hasEndActions': hasEndActions,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  AutomationRule copyWith({
    String? id,
    String? name,
    bool? enabled,
    List<Condition>? conditions,
    List<Action>? startActions,
    List<Action>? endActions,
    DateTime? createdAt,
    DateTime? lastTriggered,
    String? startTime,
    String? endTime,
    bool? hasEndActions,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      conditions: conditions ?? this.conditions,
      startActions: startActions ?? this.startActions,
      endActions: endActions ?? this.endActions,
      hasEndActions: hasEndActions ?? this.hasEndActions,
      createdAt: createdAt ?? this.createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  // Tạo default end actions (tắt tất cả thiết bị trong start actions)
  List<Action> getDefaultEndActions() {
    return startActions
        .map(
          (startAction) => Action(
            deviceId: startAction.deviceId,
            deviceCode: startAction.deviceCode,
            action: 'turn_off',
            value: null,
            speed: null,
            mode: null,
          ),
        )
        .toList();
  }

  // Lấy end actions (tùy chỉnh hoặc mặc định)
  List<Action> getEffectiveEndActions() {
    if (hasEndActions && endActions.isNotEmpty) {
      return endActions;
    }
    return getDefaultEndActions();
  }
}

class Condition {
  final String sensorId; // 🔄 THAY ĐỔI TỪ sensorType THÀNH sensorId
  final String operator; // '>', '<', '==', '>=', '<='
  final dynamic value;

  Condition({
    required this.sensorId, // 🔄 THAY ĐỔI TỪ sensorType THÀNH sensorId
    required this.operator,
    required this.value,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      sensorId:
          json['sensorId'] ?? json['sensorType'], // 🔄 BACKWARD COMPATIBILITY
      operator: json['operator'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sensorId': sensorId,
      'operator': operator,
      'value': value,
    }; // 🔄 THAY ĐỔI
  }

  bool evaluate(dynamic currentValue) {
    try {
      // ✅ XỬ LÝ BOOLEAN (PIR motion, door sensor, etc.)
      if (currentValue is bool) {
        final boolValue = currentValue;
        final expectedValue = _parseBool(value);
        
        switch (operator) {
          case '==':
            return boolValue == expectedValue;
          case '!=':
            return boolValue != expectedValue;
          default:
            // Boolean không hỗ trợ >, <, >=, <=
            return false;
        }
      }
      
      // ✅ XỬ LÝ NUMERIC (temperature, humidity, light, gas, etc.)
      final numericValue = _toNumeric(currentValue);
      final expectedNumeric = _toNumeric(value);
      
      if (numericValue == null || expectedNumeric == null) {
        return false; // Không thể so sánh
      }
      
      switch (operator) {
        case '>':
          return numericValue > expectedNumeric;
        case '<':
          return numericValue < expectedNumeric;
        case '==':
          return numericValue == expectedNumeric;
        case '>=':
          return numericValue >= expectedNumeric;
        case '<=':
          return numericValue <= expectedNumeric;
        case '!=':
          return numericValue != expectedNumeric;
        default:
          return false;
      }
    } catch (e) {
      print('❌ Error evaluating condition: $e');
      return false;
    }
  }
  
  // Helper: Parse bool từ nhiều format (true, false, 1, 0, "1", "0")
  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'on';
    }
    return false;
  }
  
  // Helper: Convert to numeric (int/double)
  num? _toNumeric(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    if (value is bool) return value ? 1 : 0; // Convert bool to 0/1
    return null;
  }
}

class Action {
  final String deviceId; // 🔄 GIỮ NGUYÊN để tìm device
  final String deviceCode; // 🔄 THÊM deviceCode để gửi MQTT
  final String action; // 'turn_on', 'turn_off', 'set_value', 'set_speed'
  final dynamic value; // For servo angle, PWM duty cycle
  final int? speed; // For fan speed (0-100)
  final String? mode; // For fan mode (auto, manual, sleep)

  Action({
    required this.deviceId,
    required this.deviceCode, // 🔄 THÊM deviceCode
    required this.action,
    this.value,
    this.speed,
    this.mode,
  });

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      deviceId: json['deviceId'],
      deviceCode: json['deviceCode'] ?? json['deviceId'], // 🔄 FALLBACK
      action: json['action'],
      value: json['value'],
      speed: json['speed'],
      mode: json['mode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceCode': deviceCode, // 🔄 THÊM deviceCode
      'action': action,
      'value': value,
      'speed': speed,
      'mode': mode,
    };
  }
}
