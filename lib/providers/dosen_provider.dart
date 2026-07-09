import 'package:flutter/foundation.dart';
import '../models/dosen_model.dart';
import '../repositories/user_repository.dart';

class DosenProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository.instance;

  List<DosenModel> _list = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DosenModel> get list => _list;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      _list = await _repository.getDosenList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenProvider.loadAll: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> create(DosenModel model) async {
    _setLoading(true);
    try {
      await _repository.createDosen(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('DosenProvider.create: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> update(DosenModel model) async {
    _setLoading(true);
    try {
      await _repository.updateDosen(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('DosenProvider.update: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleStatus(String uid, bool currentStatus) async {
    try {
      await _repository.toggleStatusDosen(uid, !currentStatus);
      final index = _list.indexWhere((d) => d.uid == uid);
      if (index != -1) {
        _list[index] = _list[index].copyWith(status: !currentStatus);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    }
  }

  Future<bool> delete(String uid) async {
    _setLoading(true);
    try {
      await _repository.deleteDosen(uid);
      _list.removeWhere((d) => d.uid == uid);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('DosenProvider.delete: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<DosenModel> search(String query) {
    if (query.isEmpty) return _list;
    final q = query.toLowerCase();
    return _list.where((d) {
      return d.nama.toLowerCase().contains(q) ||
          d.nidn.toLowerCase().contains(q) ||
          d.email.toLowerCase().contains(q);
    }).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) return 'Email sudah digunakan.';
    if (msg.contains('network')) return 'Tidak dapat terhubung ke internet.';
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
