class AlertModel {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final AlertLevel level;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.level,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'],
      type: AlertType.values.firstWhere(
        (e) => e.toString() == 'AlertType.${json['type']}',
      ),
      title: json['title'],
      message: json['message'],
      level: AlertLevel.values.firstWhere(
        (e) => e.toString() == 'AlertLevel.${json['level']}',
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'level': level.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  AlertModel copyWith({
    String? id,
    AlertType? type,
    String? title,
    String? message,
    AlertLevel? level,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

enum AlertType { gas, rain, soil, dust, motion, temperature, system }

enum AlertLevel { info, warning, critical }
