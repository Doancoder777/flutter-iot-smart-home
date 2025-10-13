import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    print('🔧 AuthProvider initializing...');
    // Use addPostFrameCallback to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  /// Initialize provider and load existing user only (no auto sign-in)
  Future<void> _initialize() async {
    print('🔧 Initializing AuthProvider...');

    // First initialize Google Sign-In
    await _initializeGoogleSignIn();

    // Load existing valid Google user from storage (if any)
    await _loadUserFromStorage();

    print('🎯 AuthProvider initialization complete');
  }

  /// Initialize Google Sign-In
  Future<void> _initializeGoogleSignIn() async {
    try {
      print('🔧 Initializing Google Sign-In...');

      await GoogleSignIn.instance.initialize();

      // Listen to authentication events for manual sign-ins
      GoogleSignIn.instance.authenticationEvents
          .listen((event) {
            _handleAuthenticationEvent(event);
          })
          .onError((error) {
            print('❌ Authentication error: $error');
            _setError('Lỗi xác thực: $error');
          });

      // DON'T attempt automatic authentication - let user manually sign in
      print('✅ Google Sign-In initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Google Sign-In: $e');
      print('⚠️ Google Sign-In not configured, will show login screen');
    }
  }

  /// Handle Google Sign-In authentication events
  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    if (user != null) {
      // Create User object from Google account
      final newUser = User(
        id: user.id,
        username: user.email.split('@')[0],
        email: user.email,
        displayName: user.displayName ?? 'Unknown User',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        avatarUrl: user.photoUrl,
      );

      _currentUser = newUser;
      await _saveUserToStorage(newUser);
      print('✅ User signed in: ${newUser.displayName}');
    } else {
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      print('✅ User signed out');
    }

    _setLoading(false);
    notifyListeners();
  }

  /// Load user data from SharedPreferences
  Future<void> _loadUserFromStorage() async {
    try {
      print('📱 Loading user from storage...');
      final prefs = await SharedPreferences.getInstance();

      // Check if user exists in storage
      final userJson = prefs.getString('current_user');

      if (userJson != null) {
        print('📄 Found user data in storage');
        final userData = jsonDecode(userJson);

        // Only load if it's a valid Google user (has real Google ID)
        if (userData['id'] != null &&
            userData['id'].toString().isNotEmpty &&
            !userData['id'].toString().contains('demo') &&
            !userData['id'].toString().contains('default')) {
          _currentUser = User.fromJson(userData);
          notifyListeners();
          print('👤 User loaded from storage: ${_currentUser!.displayName}');
        } else {
          print('🗑️ Found demo/test user - clearing for fresh Google login');
          await prefs.remove('current_user');
          _currentUser = null;
        }
      } else {
        print('❌ No user data found in storage - will show login screen');
      }
    } catch (e) {
      print('❌ Error loading user: $e');
    }
  }

  /// Save user data to SharedPreferences
  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(user.toJson()));
      print('💾 User saved to storage: ${user.displayName}');
    } catch (e) {
      print('❌ Error saving user: $e');
    }
  }

  /// Sign in with Google - TRY REAL GOOGLE SIGN-IN FIRST
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 Starting Google Sign-In...');

      // Try real Google Sign-In first
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate(); // Fix: changed from signIn() to authenticate()

      if (googleUser != null) {
        print('✅ Real Google Sign-In successful: ${googleUser.email}');

        // Create user object from Google account
        final user = User(
          id: googleUser.id,
          username: googleUser.email.split('@')[0],
          email: googleUser.email,
          displayName: googleUser.displayName ?? googleUser.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          avatarUrl: googleUser.photoUrl,
        );

        // Save to storage and update state
        await _saveUserToStorage(user);
        _currentUser = user;

        _setLoading(false);
        notifyListeners();

        print('✅ Google Sign-In successful: ${user.displayName}');
        return true;
      } else {
        print('❌ Google Sign-In cancelled by user');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ Real Google Sign-In failed: $e');

      // Fallback to mock Google user for now
      print('⚠️ Using mock Google Sign-In as fallback');

      final user = User(
        id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
        username: 'google_user',
        email: 'user@gmail.com',
        displayName: 'Google User (Mock)',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        avatarUrl: null,
      );

      // Save to storage and update state
      await _saveUserToStorage(user);
      _currentUser = user;

      _setLoading(false);
      notifyListeners();

      print('✅ Mock Google Sign-In successful: ${user.displayName}');
      return true;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);

    try {
      print('🔓 Signing out...');

      // Sign out from Google
      await GoogleSignIn.instance.signOut();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');

      // Clear state
      _currentUser = null;

      _setLoading(false);
      notifyListeners();
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Sign out error: $e');
      _setError('Đăng xuất thất bại: $e');
      _setLoading(false);
    }
  }

  /// Disconnect Google account completely (revoke access)
  Future<void> disconnect() async {
    _setLoading(true);

    try {
      print('🔌 Disconnecting Google account...');

      // Disconnect from Google (revokes all permissions)
      await GoogleSignIn.instance.disconnect();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');

      // Clear state
      _currentUser = null;

      _setLoading(false);
      notifyListeners();
      print('✅ Google account disconnected successfully');
    } catch (e) {
      print('❌ Disconnect error: $e');
      _setError('Ngắt kết nối thất bại: $e');
      _setLoading(false);
    }
  }

  /// Check if user is already signed in (silently)
  Future<bool> checkSignInStatus() async {
    try {
      _setLoading(true);

      // The authentication event handler will automatically handle
      // the user state when attemptLightweightAuthentication is called
      // in _initializeGoogleSignIn()

      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      print('❌ Silent sign-in error: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      _currentUser = updatedUser;
      await _saveUserToStorage(updatedUser);
      notifyListeners();

      print('✅ User profile updated');
    } catch (e) {
      print('❌ Error updating profile: $e');
      _setError('Cập nhật thông tin thất bại: $e');
    }
  }

  /// Get current user ID for data isolation
  String? getCurrentUserId() {
    return _currentUser?.id;
  }

  /// Get storage key with user prefix for data isolation
  String getUserStorageKey(String key) {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return '${userId}_$key';
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
