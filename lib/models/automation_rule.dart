class AutomationRule {
  final String id;
  final String name;
  final bool enabled;
  final List<Condition> conditions;
  final List<Action> actions;
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final String? startTime; // Format: "HH:mm"
  final String? endTime; // Format: "HH:mm"

  AutomationRule({
    required this.id,
    required this.name,
    required this.enabled,
    required this.conditions,
    required this.actions,
    required this.createdAt,
    this.lastTriggered,
    this.startTime,
    this.endTime,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'],
      name: json['name'],
      enabled: json['enabled'],
      conditions: (json['conditions'] as List)
          .map((e) => Condition.fromJson(e))
          .toList(),
      actions: (json['actions'] as List)
          .map((e) => Action.fromJson(e))
          .toList(),
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
      'actions': actions.map((e) => e.toJson()).toList(),
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
    List<Action>? actions,
    DateTime? createdAt,
    DateTime? lastTriggered,
    String? startTime,
    String? endTime,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class Condition {
  final String sensorType;
  final String operator; // '>', '<', '==', '>=', '<='
  final dynamic value;

  Condition({
    required this.sensorType,
    required this.operator,
    required this.value,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      sensorType: json['sensorType'],
      operator: json['operator'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'sensorType': sensorType, 'operator': operator, 'value': value};
  }

  bool evaluate(dynamic currentValue) {
    switch (operator) {
      case '>':
        return currentValue > value;
      case '<':
        return currentValue < value;
      case '==':
        return currentValue == value;
      case '>=':
        return currentValue >= value;
      case '<=':
        return currentValue <= value;
      default:
        return false;
    }
  }
}

class Action {
  final String deviceId;
  final String
  action; // 'turn_on', 'turn_off', 'set_value', 'low', 'medium', 'high', 'off'
  final dynamic value;
  final String? endAction; // Hành động khi kết thúc rule (optional)
  final dynamic endValue; // Giá trị khi kết thúc rule (optional)

  Action({
    required this.deviceId,
    required this.action,
    this.value,
    this.endAction,
    this.endValue,
  });

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      deviceId: json['deviceId'],
      action: json['action'],
      value: json['value'],
      endAction: json['endAction'],
      endValue: json['endValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'action': action,
      'value': value,
      'endAction': endAction,
      'endValue': endValue,
    };
  }
}
