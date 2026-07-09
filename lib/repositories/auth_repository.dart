import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth/auth_service.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Login kemudian mengambil data user dari Firestore
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Login ke Firebase Authentication
    final UserCredential credential = await AuthService.instance.login(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Ambil document user
    final snapshot = await _firestore.collection('users').doc(uid).get();

    if (!snapshot.exists) {
      await AuthService.instance.logout();
      throw Exception("Data user tidak ditemukan.");
    }
    final user = UserModel.fromMap(snapshot.data()!);
    if (!user.status) {
      await AuthService.instance.logout();
      throw Exception('Akun dinonaktifkan. Hubungi administrator.');
    }
    return user;
  }

  /// Logout
  Future<void> logout() async {
    await AuthService.instance.logout();
  }

  /// User yang sedang login
  User? get currentUser => AuthService.instance.currentUser;

  /// UID user saat ini
  String? get currentUid => currentUser?.uid;

  /// Ambil profile user
  Future<UserModel?> getCurrentUserProfile() async {
    if (currentUid == null) return null;

    final snapshot = await _firestore.collection('users').doc(currentUid).get();

    if (!snapshot.exists) return null;

    final user = UserModel.fromMap(snapshot.data()!);
    if (!user.status) {
      await AuthService.instance.logout();
      return null;
    }
    return user;
  }
}
