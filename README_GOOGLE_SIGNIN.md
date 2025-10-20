# Hướng dẫn tích hợp Đăng nhập Google với Firebase cho Flutter

> ⚠️ **LƯU Ý QUAN TRỌNG**: File này chỉ hướng dẫn cơ bản cho Android.  
> Để xem **hướng dẫn đầy đủ cho Android, iOS, Web** và cách khắc phục các lỗi phổ biến, xem file:  
> 👉 **[GOOGLE_SIGNIN_SETUP.md](./GOOGLE_SIGNIN_SETUP.md)**

## 1. Tạo Project Firebase
- Truy cập https://console.firebase.google.com
- Tạo project mới hoặc chọn project đã có

## 2. Thêm ứng dụng Android vào Firebase
- Thêm package name: `com.example.doan_2280600686`
- Tải file `google-services.json` về

## 3. Thêm SHA-1 vào Firebase
- Mở terminal và chạy:
  ```powershell
  cd "C:\Program Files\Android\Android Studio\jbr\bin"
  .\keytool.exe -list -v -keystore C:\Users\sigma\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android | Select-String -Pattern "SHA1|SHA-1"
  ```
- Copy SHA-1 và thêm vào Project Settings > Your apps > Android app

## 4. Bật Google Sign-In trong Firebase
- Vào **Authentication** > **Sign-in method**
- Bật **Google**
- Chọn email hỗ trợ và lưu

## 5. Tải lại file `google-services.json`
- Vào Project Settings > Your apps > Android app
- Tải lại file `google-services.json` mới
- Copy vào thư mục: `android/app/google-services.json`

## 6. Thêm dependencies vào `pubspec.yaml`
```yaml
dependencies:
  firebase_core: ^4.2.0
  firebase_auth: ^6.1.1
  cloud_firestore: ^6.0.3
  google_sign_in: ^6.1.0
```

## 7. Khởi tạo Firebase trong `main.dart`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

## 8. Thêm code đăng nhập Google
Tạo file `lib/services/auth_service.dart`:
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    await _googleSignIn.signOut();
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    await _saveUserToFirestore(userCredential.user!);
    return userCredential;
  }

  Future<void> _saveUserToFirestore(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userRef.get();
    if (!docSnapshot.exists) {
      await userRef.set({
        'uid': user.uid,
        'username': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'email': user.email,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'provider': 'google',
      });
    } else {
      await userRef.update({'lastSeen': FieldValue.serverTimestamp()});
    }
  }
}
```

## 9. Thêm nút đăng nhập Google vào UI
Ví dụ trong `auth_screen.dart`:
```dart
ElevatedButton(
  onPressed: () async {
    await AuthService().signInWithGoogle();
  },
  child: Text('Đăng nhập với Google'),
)
```

## 10. Clean và build lại app
```powershell
flutter clean
flutter pub get
flutter run
```

---
**Lưu ý:**
- Đảm bảo file `google-services.json` đúng project và package name
- Đã bật Google Sign-In trong Firebase Authentication
- Đã thêm SHA-1 vào Firebase

Nếu gặp lỗi, kiểm tra lại các bước trên hoặc liên hệ trợ giúp!
