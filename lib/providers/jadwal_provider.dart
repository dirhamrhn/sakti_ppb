import 'package:flutter/foundation.dart';
import '../models/jadwal_model.dart';
import '../models/kelas_model.dart';
import '../repositories/jadwal_repository.dart';

class JadwalProvider extends ChangeNotifier {
  final JadwalRepository _repository = JadwalRepository.instance;

  List<JadwalModel> _list = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<JadwalModel> get list => _list;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Hanya jadwal sesi teori
  List<JadwalModel> get listTeori =>
      _list.where((j) => j.jenisSesi == 'teori').toList();

  /// Hanya jadwal sesi praktikum
  List<JadwalModel> get listPraktikum =>
      _list.where((j) => j.jenisSesi == 'praktikum').toList();

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      _list = await _repository.getAll();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('JadwalProvider.loadAll: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Membuat jadwal baru + otomatis generate pertemuan.
  /// [kelas] diperlukan untuk mengisi data pertemuan.
  Future<bool> create(JadwalModel model, {KelasModel? kelas}) async {
    _setLoading(true);
    try {
      if (kelas != null) {
        await _repository.create(model, kelas);
      } else {
        await _repository.createSimple(model);
      }
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('JadwalProvider.create: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> update(JadwalModel model) async {
    _setLoading(true);
    try {
      await _repository.update(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('JadwalProvider.update: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Hapus jadwal dan semua pertemuan terkait (cascade delete)
  Future<bool> delete(String id) async {
    _setLoading(true);
    try {
      await _repository.delete(id);
      _list.removeWhere((j) => j.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('JadwalProvider.delete: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<JadwalModel> search(String query) {
    if (query.isEmpty) return _list;
    final q = query.toLowerCase();
    return _list.where((j) {
      return j.matakuliahNama.toLowerCase().contains(q) ||
          j.hari.toLowerCase().contains(q) ||
          j.ruanganNama.toLowerCase().contains(q) ||
          j.gedungNama.toLowerCase().contains(q) ||
          j.kelasNama.toLowerCase().contains(q);
    }).toList();
  }

  List<JadwalModel> filterByHari(String hari) {
    if (hari.isEmpty) return _list;
    return _list.where((j) => j.hari == hari).toList();
  }

  List<JadwalModel> filterByJenisSesi(String jenis) {
    if (jenis.isEmpty || jenis == 'semua') return _list;
    return _list.where((j) => j.jenisSesi == jenis).toList();
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
