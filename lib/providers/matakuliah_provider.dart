import 'package:flutter/foundation.dart';
import '../models/matakuliah_model.dart';
import '../repositories/matakuliah_repository.dart';

class MatakuliahProvider extends ChangeNotifier {
  final MatakuliahRepository _repository = MatakuliahRepository.instance;

  List<MatakuliahModel> _list = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MatakuliahModel> get list => _list;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Hanya mata kuliah teori
  List<MatakuliahModel> get listTeori =>
      _list.where((m) => m.jenisMatakuliah == 'teori').toList();

  /// Mata kuliah yang memiliki sesi praktikum
  List<MatakuliahModel> get listPraktikum =>
      _list.where((m) => m.jenisMatakuliah == 'teori_praktikum').toList();

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      _list = await _repository.getAllIncludingInactive();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MatakuliahProvider.loadAll: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> create(MatakuliahModel model) async {
    _setLoading(true);
    try {
      await _repository.create(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MatakuliahProvider.create: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> update(MatakuliahModel model) async {
    _setLoading(true);
    try {
      await _repository.update(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MatakuliahProvider.update: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleStatus(String id, bool currentStatus) async {
    try {
      await _repository.toggleStatus(id, !currentStatus);
      final index = _list.indexWhere((m) => m.id == id);
      if (index != -1) {
        _list[index] = _list[index].copyWith(status: !currentStatus);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    _setLoading(true);
    try {
      await _repository.delete(id);
      _list.removeWhere((m) => m.id == id);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MatakuliahProvider.delete: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Filter list berdasarkan jenis mata kuliah
  List<MatakuliahModel> filterByJenis(String jenis) {
    if (jenis.isEmpty || jenis == 'semua') return _list;
    return _list.where((m) => m.jenisMatakuliah == jenis).toList();
  }

  List<MatakuliahModel> search(String query) {
    if (query.isEmpty) return _list;
    final q = query.toLowerCase();
    return _list.where((m) {
      return m.nama.toLowerCase().contains(q) ||
          m.kode.toLowerCase().contains(q) ||
          m.dosenNama.toLowerCase().contains(q);
    }).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
