class User {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      displayName: json['displayName'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      isActive: json['isActive'] ?? true,
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'avatarUrl': avatarUrl,
    };
  }

  User copyWith({
    String? username,
    String? email,
    String? displayName,
    DateTime? lastLoginAt,
    bool? isActive,
    String? avatarUrl,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class UserDevice {
  final String id;
  final String userId;
  final String deviceId;
  final String name;
  final String type; // relay, servo, sensor
  final String? description;
  final Map<String, dynamic>? config; // Custom configuration
  final DateTime createdAt;
  final bool isShared; // true = shared device, false = personal device

  UserDevice({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.name,
    required this.type,
    this.description,
    this.config,
    required this.createdAt,
    this.isShared = false,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'],
      userId: json['userId'],
      deviceId: json['deviceId'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      config: json['config'],
      createdAt: DateTime.parse(json['createdAt']),
      isShared: json['isShared'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'name': name,
      'type': type,
      'description': description,
      'config': config,
      'createdAt': createdAt.toIso8601String(),
      'isShared': isShared,
    };
  }
}
