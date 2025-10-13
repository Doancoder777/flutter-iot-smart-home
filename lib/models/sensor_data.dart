class SensorData {
  final double temperature;
  final double humidity;
  final int rain;
  final int light;
  final int soilMoisture;
  final int gas;
  final int dust;
  final bool motionDetected;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.rain,
    required this.light,
    required this.soilMoisture,
    required this.gas,
    required this.dust,
    required this.motionDetected,
    required this.timestamp,
  });

  factory SensorData.empty() {
    return SensorData(
      temperature: 0.0,
      humidity: 0.0,
      rain: 0,
      light: 0,
      soilMoisture: 0,
      gas: 0,
      dust: 0,
      motionDetected: false,
      timestamp: DateTime.now(),
    );
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      rain: json['rain'] ?? 0,
      light: json['light'] ?? 0,
      soilMoisture: json['soilMoisture'] ?? 0,
      gas: json['gas'] ?? 0,
      dust: json['dust'] ?? 0,
      motionDetected: json['motionDetected'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'rain': rain,
      'light': light,
      'soilMoisture': soilMoisture,
      'gas': gas,
      'dust': dust,
      'motionDetected': motionDetected,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  SensorData copyWith({
    double? temperature,
    double? humidity,
    int? rain,
    int? light,
    int? soilMoisture,
    int? gas,
    int? dust,
    bool? motionDetected,
    DateTime? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      rain: rain ?? this.rain,
      light: light ?? this.light,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      gas: gas ?? this.gas,
      dust: dust ?? this.dust,
      motionDetected: motionDetected ?? this.motionDetected,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
