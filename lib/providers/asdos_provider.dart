import 'package:flutter/foundation.dart';
import '../models/asdos_model.dart';
import '../repositories/user_repository.dart';

class AsdosProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository.instance;

  List<AsdosModel> _list = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AsdosModel> get list => _list;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      _list = await _repository.getAsdosList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosProvider.loadAll: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> create(AsdosModel model) async {
    _setLoading(true);
    try {
      await _repository.createAsdos(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('AsdosProvider.create: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> update(AsdosModel model) async {
    _setLoading(true);
    try {
      await _repository.updateAsdos(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('AsdosProvider.update: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleStatus(String uid, bool currentStatus) async {
    try {
      await _repository.toggleStatusAsdos(uid, !currentStatus);
      final index = _list.indexWhere((a) => a.uid == uid);
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
      await _repository.deleteAsdos(uid);
      _list.removeWhere((a) => a.uid == uid);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      debugPrint('AsdosProvider.delete: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<AsdosModel> search(String query) {
    if (query.isEmpty) return _list;
    final q = query.toLowerCase();
    return _list.where((a) {
      return a.nama.toLowerCase().contains(q) ||
          a.nim.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q);
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
