import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository.instance;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // GETTER
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage;

  // LOGIN
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _repository.login(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'Email belum terdaftar.';
          break;
        case 'wrong-password':
          _errorMessage = 'Password salah.';
          break;
        case 'invalid-email':
          _errorMessage = 'Format email tidak valid.';
          break;
        case 'invalid-credential':
          _errorMessage = 'Email atau password salah.';
          break;
        case 'too-many-requests':
          _errorMessage =
              'Terlalu banyak percobaan login. Silakan coba beberapa saat lagi.';
          break;
        case 'network-request-failed':
          _errorMessage = 'Tidak dapat terhubung ke internet.';
          break;
        default:
          _errorMessage = e.message ?? 'Terjadi kesalahan saat login.';
      }
      debugPrint("FirebaseAuthException : ${e.code}\n${e.message}");
      return false;
    } catch (e) {
      _errorMessage = "Terjadi kesalahan yang tidak diketahui.";
      debugPrint(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await _repository.logout();
      _user = null;
      _errorMessage = null;
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      notifyListeners();
    }
  }

  // LOAD CURRENT USER
  Future<void> loadCurrentUser() async {
    try {
      _user = await _repository.getCurrentUserProfile();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      notifyListeners();
    }
  }

  // CLEAR ERROR
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
