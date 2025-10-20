import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/automation_provider.dart';
import '../providers/mqtt_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  String? _lastInitializedUserId;

  @override
  void initState() {
    super.initState();
    print('🔧 AuthWrapper: initState called');
    // Delay the auth check to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔧 AuthWrapper: Post frame callback executing');
      _checkAuthStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for auth provider changes
    final authProvider = Provider.of<AuthProvider>(context);

    print(
      '🔧 AuthWrapper.didChangeDependencies: isLoggedIn=${authProvider.isLoggedIn}, _lastInitializedUserId=$_lastInitializedUserId',
    );

    if (authProvider.isLoggedIn) {
      final userId = authProvider.currentUser?.id ?? 'default_user';
      print('🔧 AuthWrapper.didChangeDependencies: current userId=$userId');
      if (_lastInitializedUserId != userId) {
        print(
          '🔧 AuthWrapper.didChangeDependencies: userId changed, scheduling initialization...',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeDevicesIfNeeded(authProvider);
        });
      }
    } else {
      // 🔓 USER LOGGED OUT - CLEAR ALL DATA
      if (_lastInitializedUserId != null) {
        print(
          '🔧 AuthWrapper.didChangeDependencies: User logged out, scheduling data clear...',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _clearAllUserData();
        });
      }
    }
  }

  Future<void> _checkAuthStatus() async {
    print('🔧 AuthWrapper: Checking auth status...');
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkSignInStatus();

    print(
      '🔧 AuthWrapper: Auth check complete. IsLoggedIn: ${authProvider.isLoggedIn}',
    );

    // Khởi tạo providers cho user hiện tại
    if (authProvider.isLoggedIn) {
      final deviceProvider = context.read<DeviceProvider>();
      final sensorProvider = context.read<SensorProvider>();
      final automationProvider = context.read<AutomationProvider>();
      final mqttProvider = context.read<MqttProvider>();
      final userId = authProvider.currentUser?.id ?? 'default_user';

      print('🔧 AuthWrapper: Setting current user to all providers: $userId');
      await deviceProvider.setCurrentUser(userId);
      await sensorProvider.setCurrentUser(userId);
      await automationProvider.setCurrentUser(userId);
      await mqttProvider.setCurrentUser(userId);

      // Connect MQTT message handler to SensorProvider
      mqttProvider.setMessageHandler(sensorProvider.handleMqttMessage);
      print('🔗 AuthWrapper: Connected MQTT message handler to SensorProvider');

      print('✅ AuthWrapper: All providers initialization complete');
    } else {
      print(
        '🔧 AuthWrapper: User not logged in, skipping provider initialization',
      );
    }
    if (mounted) {
      print('🔧 AuthWrapper: Setting initialized to true');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Re-initialize devices when auth state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeDevicesIfNeeded(authProvider);
        });

        if (authProvider.isLoggedIn) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }

  Future<void> _initializeDevicesIfNeeded(AuthProvider authProvider) async {
    if (authProvider.isLoggedIn) {
      final deviceProvider = context.read<DeviceProvider>();
      final sensorProvider = context.read<SensorProvider>();
      final automationProvider = context.read<AutomationProvider>();
      final mqttProvider = context.read<MqttProvider>();
      final userId = authProvider.currentUser?.id ?? 'default_user';

      // Only initialize if not already set for this user
      if (deviceProvider.currentUserId != userId) {
        print(
          '🔧 AuthWrapper: User state changed, setting current user to all providers: $userId',
        );

        // Initialize all providers with current user
        await deviceProvider.setCurrentUser(userId);
        await sensorProvider.setCurrentUser(userId);
        await automationProvider.setCurrentUser(userId);
        await mqttProvider.setCurrentUser(userId);

        // Connect MQTT message handler to SensorProvider
        mqttProvider.setMessageHandler(sensorProvider.handleMqttMessage);
        print(
          '🔗 AuthWrapper: Connected MQTT message handler to SensorProvider',
        );

        _lastInitializedUserId = userId;
        print(
          '✅ AuthWrapper: All providers initialization complete for user: $userId',
        );
      }
    }
  } // 🗑️ CLEAR ALL USER DATA ON LOGOUT

  Future<void> _clearAllUserData() async {
    print('🗑️ AuthWrapper: Clearing all user data...');

    try {
      // Clear all provider data
      final deviceProvider = context.read<DeviceProvider>();
      final sensorProvider = context.read<SensorProvider>();
      final automationProvider = context.read<AutomationProvider>();

      await deviceProvider.clearUserData();
      sensorProvider.clearUserData();
      automationProvider.clearUserData();

      // Reset initialization state with setState to rebuild UI
      if (mounted) {
        setState(() {
          _lastInitializedUserId = null;
          _isInitialized = true; // Keep initialized=true so LoginScreen shows
        });
      }

      print('✅ AuthWrapper: All user data cleared');
    } catch (e) {
      print('❌ AuthWrapper: Error clearing user data: $e');
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade600, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(Icons.home_filled, size: 50, color: Colors.white),
              ),

              SizedBox(height: 24),

              Text(
                'Smart Home',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 40),

              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),

              SizedBox(height: 16),

              Text(
                'Đang khởi tạo...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
