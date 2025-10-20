import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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

    // Load existing valid Google user from storage (if any)
    await _loadUserFromStorage();

    print('🎯 AuthProvider initialization complete');
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
            !userData['id'].toString().contains('default') &&
            !userData['id'].toString().contains('google_user') &&
            !userData['displayName'].toString().contains('Mock')) {
          _currentUser = User.fromJson(userData);
          notifyListeners();
          print('👤 User loaded from storage: ${_currentUser!.displayName}');
        } else {
          print(
            '🗑️ Found demo/test/mock user - clearing for fresh Google login',
          );
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

  /// Sign in with Google using Firebase Auth
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 Bắt đầu đăng nhập Google...');

      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Xóa cache để user có thể chọn tài khoản
      await googleSignIn.signOut();

      // Hiển thị màn hình chọn tài khoản Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Người dùng hủy đăng nhập');
        _setError('Đăng nhập bị hủy. Vui lòng thử lại.');
        _setLoading(false);
        return false;
      }

      print('✅ Đã chọn tài khoản: ${googleUser.email}');

      // Lấy authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Tạo credential cho Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase
      final firebase_auth.UserCredential userCredential = await firebase_auth
          .FirebaseAuth
          .instance
          .signInWithCredential(credential);

      print('✅ Đăng nhập Firebase thành công');

      // 5. Get Firebase user
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print('❌ Firebase user is null');
        _setError('Đăng nhập thất bại. Vui lòng thử lại.');
        _setLoading(false);
        return false;
      }

      print('👤 Firebase User: ${firebaseUser.email}');

      // 6. Create our User object from Firebase user
      final user = User(
        id: firebaseUser.uid, // ✅ Use Firebase UID instead of Google ID
        username: firebaseUser.email?.split('@')[0] ?? 'user',
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        avatarUrl: firebaseUser.photoURL,
      );

      // 7. Save to local storage and update state
      await _saveUserToStorage(user);
      _currentUser = user;

      _setLoading(false);
      notifyListeners();

      print('✅ Google Sign-In thành công!');
      print('   Email: ${user.email}');
      print('   Name: ${user.displayName}');
      print('   UID: ${user.id}');
      return true;
    } catch (e) {
      print('❌ Lỗi đăng nhập Google: $e');
      _setError('Đăng nhập thất bại: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);

    try {
      print('🔓 Signing out...');

      // Sign out from Firebase Auth
      await firebase_auth.FirebaseAuth.instance.signOut();
      print('✅ Signed out from Firebase Auth');

      // Sign out from Google
      await GoogleSignIn().signOut();
      print('✅ Đã đăng xuất Google');

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
      await GoogleSignIn().disconnect();

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

  /// Clear all user data (for testing)
  Future<void> clearUserData() async {
    try {
      print('🗑️ Clearing all user data...');

      // Clear from Google Sign-In
      await GoogleSignIn().signOut();
      await GoogleSignIn().disconnect();

      // Clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear state
      _currentUser = null;

      notifyListeners();
      print('✅ All user data cleared');
    } catch (e) {
      print('❌ Error clearing user data: $e');
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
