import 'package:flutter/foundation.dart';
import '../models/mahasiswa_model.dart';
import '../repositories/user_repository.dart';

class MahasiswaProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository.instance;

  List<MahasiswaModel> _list = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MahasiswaModel> get list => _list;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Load ──────────────────────────────────────────────────

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      _list = await _repository.getMahasiswaList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MahasiswaProvider.loadAll: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─── Create ────────────────────────────────────────────────

  Future<bool> create(MahasiswaModel model) async {
    _setLoading(true);
    try {
      await _repository.createMahasiswa(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('MahasiswaProvider.create: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Update ────────────────────────────────────────────────

  Future<bool> update(MahasiswaModel model) async {
    _setLoading(true);
    try {
      await _repository.updateMahasiswa(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('MahasiswaProvider.update: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Toggle Status ─────────────────────────────────────────

  Future<bool> toggleStatus(String uid, bool currentStatus) async {
    try {
      await _repository.toggleStatusMahasiswa(uid, !currentStatus);
      final index = _list.indexWhere((m) => m.uid == uid);
      if (index != -1) {
        _list[index] = _list[index].copyWith(status: !currentStatus);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('MahasiswaProvider.toggleStatus: $e');
      return false;
    }
  }

  // ─── Delete ────────────────────────────────────────────────

  Future<bool> delete(String uid) async {
    _setLoading(true);
    try {
      await _repository.deleteMahasiswa(uid);
      _list.removeWhere((m) => m.uid == uid);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('MahasiswaProvider.delete: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Search ────────────────────────────────────────────────

  List<MahasiswaModel> search(String query) {
    if (query.isEmpty) return _list;
    final q = query.toLowerCase();
    return _list.where((m) {
      return m.nama.toLowerCase().contains(q) ||
          m.nim.toLowerCase().contains(q) ||
          m.email.toLowerCase().contains(q);
    }).toList();
  }

  // ─── Helpers ───────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) {
      return 'Email sudah digunakan oleh akun lain.';
    }
    if (msg.contains('network')) {
      return 'Tidak dapat terhubung ke internet.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
