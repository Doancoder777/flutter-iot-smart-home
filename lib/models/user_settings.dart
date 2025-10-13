class UserSettings {
  final bool darkMode;
  final bool notificationsEnabled;
  final bool gasAlertEnabled;
  final bool rainAlertEnabled;
  final bool soilAlertEnabled;
  final bool dustAlertEnabled;
  final bool motionAlertEnabled;
  final int gasThreshold;
  final int dustThreshold;
  final double soilThreshold;
  final String language;

  UserSettings({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.gasAlertEnabled = true,
    this.rainAlertEnabled = true,
    this.soilAlertEnabled = true,
    this.dustAlertEnabled = true,
    this.motionAlertEnabled = true,
    this.gasThreshold = 1500,
    this.dustThreshold = 150,
    this.soilThreshold = 30.0,
    this.language = 'vi',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      darkMode: json['darkMode'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      gasAlertEnabled: json['gasAlertEnabled'] ?? true,
      rainAlertEnabled: json['rainAlertEnabled'] ?? true,
      soilAlertEnabled: json['soilAlertEnabled'] ?? true,
      dustAlertEnabled: json['dustAlertEnabled'] ?? true,
      motionAlertEnabled: json['motionAlertEnabled'] ?? true,
      gasThreshold: json['gasThreshold'] ?? 1500,
      dustThreshold: json['dustThreshold'] ?? 150,
      soilThreshold: (json['soilThreshold'] ?? 30.0).toDouble(),
      language: json['language'] ?? 'vi',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'gasAlertEnabled': gasAlertEnabled,
      'rainAlertEnabled': rainAlertEnabled,
      'soilAlertEnabled': soilAlertEnabled,
      'dustAlertEnabled': dustAlertEnabled,
      'motionAlertEnabled': motionAlertEnabled,
      'gasThreshold': gasThreshold,
      'dustThreshold': dustThreshold,
      'soilThreshold': soilThreshold,
      'language': language,
    };
  }

  UserSettings copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    bool? gasAlertEnabled,
    bool? rainAlertEnabled,
    bool? soilAlertEnabled,
    bool? dustAlertEnabled,
    bool? motionAlertEnabled,
    int? gasThreshold,
    int? dustThreshold,
    double? soilThreshold,
    String? language,
  }) {
    return UserSettings(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      gasAlertEnabled: gasAlertEnabled ?? this.gasAlertEnabled,
      rainAlertEnabled: rainAlertEnabled ?? this.rainAlertEnabled,
      soilAlertEnabled: soilAlertEnabled ?? this.soilAlertEnabled,
      dustAlertEnabled: dustAlertEnabled ?? this.dustAlertEnabled,
      motionAlertEnabled: motionAlertEnabled ?? this.motionAlertEnabled,
      gasThreshold: gasThreshold ?? this.gasThreshold,
      dustThreshold: dustThreshold ?? this.dustThreshold,
      soilThreshold: soilThreshold ?? this.soilThreshold,
      language: language ?? this.language,
    );
  }
}
