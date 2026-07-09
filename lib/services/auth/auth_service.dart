import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// User yang sedang login
  User? get currentUser => _auth.currentUser;

  /// Apakah user sudah login?
  bool get isLoggedIn => currentUser != null;

  /// Login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Buat user baru TANPA mengubah sesi admin yang sedang aktif.
  /// Menggunakan secondary Firebase App instance.
  Future<UserCredential> createUserWithoutSignIn({
    required String email,
    required String password,
  }) async {
    // Inisialisasi app kedua dengan nama unik
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Sign out dari secondary app setelah user dibuat
      await secondaryAuth.signOut();
      return credential;
    } finally {
      // Selalu hapus secondary app untuk membersihkan resource
      await secondaryApp.delete();
    }
  }

  /// Reset Password via email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Reload User
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }
}
