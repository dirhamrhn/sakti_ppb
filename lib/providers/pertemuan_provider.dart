import 'package:flutter/foundation.dart';
import '../models/pertemuan_model.dart';
import '../repositories/pertemuan_repository.dart';

/// Provider untuk manajemen Pertemuan.
class PertemuanProvider extends ChangeNotifier {
  final PertemuanRepository _repository = PertemuanRepository.instance;

  List<PertemuanModel> _list = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PertemuanModel> get list => _list;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Semua pertemuan dengan status 'belum'
  List<PertemuanModel> get belum => _list.where((p) => p.isBelum).toList();

  /// Pertemuan yang sedang aktif
  List<PertemuanModel> get aktif => _list.where((p) => p.isAktif).toList();

  /// Pertemuan yang sudah selesai
  List<PertemuanModel> get selesai => _list.where((p) => p.isSelesai).toList();

  Future<void> loadByJadwal(String jadwalId) async {
    _setLoading(true);
    try {
      _list = await _repository.getByJadwal(jadwalId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('PertemuanProvider.loadByJadwal: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadByKelas(String kelasId) async {
    _setLoading(true);
    try {
      _list = await _repository.getByKelas(kelasId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('PertemuanProvider.loadByKelas: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadByKelasAndJenis(String kelasId, String jenisSesi) async {
    _setLoading(true);
    try {
      _list = await _repository.getByKelasAndJenis(kelasId, jenisSesi);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> update(PertemuanModel model) async {
    _setLoading(true);
    try {
      await _repository.update(model);
      final idx = _list.indexWhere((p) => p.id == model.id);
      if (idx != -1) _list[idx] = model;
      notifyListeners();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> aktivasi(String id, {String topik = ''}) async {
    try {
      await _repository.aktivasiPertemuan(id, topik: topik);
      final idx = _list.indexWhere((p) => p.id == id);
      if (idx != -1) {
        _list[idx] = _list[idx].copyWith(status: 'aktif', isAbsensiOpen: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> selesaikan(String id) async {
    try {
      await _repository.selesaikanPertemuan(id);
      final idx = _list.indexWhere((p) => p.id == id);
      if (idx != -1) {
        _list[idx] = _list[idx].copyWith(
          status: 'selesai',
          isAbsensiOpen: false,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
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
