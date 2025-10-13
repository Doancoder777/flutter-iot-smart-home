class DustRecord {
  final int value;
  final DateTime timestamp;
  final String? note;

  DustRecord({required this.value, required this.timestamp, this.note});

  factory DustRecord.fromJson(Map<String, dynamic> json) {
    return DustRecord(
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  bool isHighLevel(int threshold) {
    return value > threshold;
  }

  String getLevel(int threshold) {
    if (value < threshold * 0.5) {
      return 'Tốt';
    } else if (value < threshold * 0.75) {
      return 'Trung bình';
    } else if (value < threshold) {
      return 'Xấu';
    } else {
      return 'Rất xấu';
    }
  }
}
