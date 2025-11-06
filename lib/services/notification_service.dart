import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔔 Background message handler (PHẢI Ở TOP-LEVEL)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      // Initialize local notifications
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Request local notification permissions
      await _requestPermissions();

      // 🔔 Initialize Firebase Cloud Messaging
      await _initializeFCM();

      _initialized = true;
      print('✅ NotificationService: Initialized (Local + FCM)');
    } catch (e) {
      print('❌ NotificationService Init Error: $e');
      _initialized = false;
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    try {
      // Request FCM permissions
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ FCM provisional permission granted');
      } else {
        print('❌ FCM permission denied');
        return;
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');
        // TODO: Update token in Firestore
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📨 Foreground message: ${message.notification?.title}');

        if (message.notification != null) {
          showNotification(
            title: message.notification!.title ?? 'Thông báo',
            body: message.notification!.body ?? '',
            payload: message.data.toString(),
          );
        }
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔔 Notification opened app: ${message.notification?.title}');
        // TODO: Navigate to specific screen based on message data
      });

      // Check if app was opened from a terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        print(
          '🚀 App opened from notification: ${initialMessage.notification?.title}',
        );
        // TODO: Handle initial message
      }
    } catch (e) {
      print('❌ FCM initialization error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android notifications don't have a unified requestPermissions API in
      // flutter_local_notifications. On Android 13+ (SDK 33) the
      // POST_NOTIFICATIONS runtime permission is required. Handle that with
      // permission_handler or platform code if you need to request it.
      print(
        'Android platform detected — ensure POST_NOTIFICATIONS permission on Android 13+ if needed',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        try {
          final bool? granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          print('iOS notification permission: $granted');
        } catch (e) {
          print('⚠️ iOS notification permission error: $e');
        }
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // Handle notification tap here
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    if (!_initialized) {
      print('⚠️ NotificationService not initialized');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'smart_home_channel',
        'Smart Home Alerts',
        channelDescription: 'Notifications for smart home events',
        importance: _getAndroidImportance(priority),
        priority: _getAndroidPriority(priority),
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use a larger, more unique id for notifications
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _notifications.show(id, title, body, details, payload: payload);

      print('🔔 Notification sent: $title');
    } catch (e) {
      print('❌ Notification Error: $e');
    }
  }

  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.max:
        return Importance.max;
    }
  }

  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }

  /// Save FCM token to Firestore for remote notifications
  Future<void> saveFcmTokenToFirestore(String userId) async {
    if (_fcmToken == null) {
      print('⚠️ No FCM token to save');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': _fcmToken,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ FCM token saved to Firestore');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // ============================================
  // Sensor-Specific Alert Methods
  // ============================================

  Future<void> showGasAlert(int gasValue) async {
    await showNotification(
      title: '⚠️ Cảnh báo Gas nguy hiểm!',
      body: 'Phát hiện nồng độ gas cao: $gasValue ppm. Hãy kiểm tra ngay!',
      payload: 'gas_alert',
      priority: NotificationPriority.max,
    );
  }

  Future<void> showHighTemperatureAlert(double temperature) async {
    await showNotification(
      title: '🔥 Cảnh báo nhiệt độ cao!',
      body:
          'Nhiệt độ quá cao: ${temperature.toStringAsFixed(1)}°C. Hãy bật quạt hoặc điều hòa!',
      payload: 'high_temp_alert',
      priority: NotificationPriority.high,
    );
  }

  Future<void> showLowTemperatureAlert(double temperature) async {
    await showNotification(
      title: '❄️ Cảnh báo nhiệt độ thấp!',
      body:
          'Nhiệt độ quá thấp: ${temperature.toStringAsFixed(1)}°C. Giữ ấm cơ thể!',
      payload: 'low_temp_alert',
      priority: NotificationPriority.high,
    );
  }

  Future<void> showRainAlert() async {
    await showNotification(
      title: '🌧️ Cảnh báo mưa lớn!',
      body: 'Đang có mưa, cửa trần đã tự động đóng để bảo vệ nhà',
      payload: 'rain_alert',
      priority: NotificationPriority.high,
    );
  }

  Future<void> showLowSoilMoistureAlert() async {
    await showNotification(
      title: '🌱 Cảnh báo độ ẩm đất',
      body: 'Độ ẩm đất thấp, cây cần được tưới nước',
      payload: 'soil_alert',
      priority: NotificationPriority.normal,
    );
  }

  Future<void> showHighDustAlert(int dustValue) async {
    await showNotification(
      title: '🫁 Cảnh báo bụi mịn cao!',
      body:
          'Nồng độ bụi: $dustValue µg/m³. Không khí độc hại, hạn chế ra ngoài!',
      payload: 'dust_alert',
      priority: NotificationPriority.max,
    );
  }

  Future<void> showMotionDetectedAlert() async {
    await showNotification(
      title: '🚶 Phát hiện chuyển động',
      body: 'Có người di chuyển trong khu vực giám sát',
      payload: 'motion_alert',
      priority: NotificationPriority.normal,
    );
  }

  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      print('🔕 All notifications cancelled');
    } catch (e) {
      print('❌ Cancel notifications error: $e');
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id);
      print('🔕 Notification $id cancelled');
    } catch (e) {
      print('❌ Cancel notification error: $e');
    }
  }
}

enum NotificationPriority { low, normal, high, max }
