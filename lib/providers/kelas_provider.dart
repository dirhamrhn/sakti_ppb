import 'package:flutter/foundation.dart';
import '../models/kelas_model.dart';
import '../models/class_enrollment_model.dart';
import '../models/mahasiswa_model.dart';
import '../repositories/kelas_repository.dart';

class KelasProvider extends ChangeNotifier {
  final KelasRepository _repository = KelasRepository.instance;

  List<KelasModel> _list = [];
  List<ClassEnrollmentModel> _enrollments = [];
  bool _isLoading = false;
  bool _isEnrollmentLoading = false;
  String? _errorMessage;

  List<KelasModel> get list => _list;
  List<ClassEnrollmentModel> get enrollments => _enrollments;
  bool get isLoading => _isLoading;
  bool get isEnrollmentLoading => _isEnrollmentLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      _list = await _repository.getAll();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('KelasProvider.loadAll: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEnrollments(String kelasId) async {
    _isEnrollmentLoading = true;
    notifyListeners();
    try {
      _enrollments = await _repository.getEnrollmentsByKelas(kelasId);
    } catch (e) {
      debugPrint('KelasProvider.loadEnrollments: $e');
    } finally {
      _isEnrollmentLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(KelasModel model) async {
    _setLoading(true);
    try {
      await _repository.create(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('KelasProvider.create: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> update(KelasModel model) async {
    _setLoading(true);
    try {
      await _repository.update(model);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('KelasProvider.update: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> delete(String id) async {
    _setLoading(true);
    try {
      await _repository.delete(id);
      _list.removeWhere((k) => k.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('KelasProvider.delete: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> enrollMahasiswa(
    MahasiswaModel mahasiswa,
    KelasModel kelas,
  ) async {
    _isEnrollmentLoading = true;
    notifyListeners();
    try {
      await _repository.enrollMahasiswa(mahasiswa, kelas);
      await loadEnrollments(kelas.id);
      await loadAll();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      debugPrint('KelasProvider.enrollMahasiswa: $e');
      return false;
    } finally {
      _isEnrollmentLoading = false;
      notifyListeners();
    }
  }

  Future<bool> unenrollMahasiswa(String enrollmentId, String kelasId) async {
    _isEnrollmentLoading = true;
    notifyListeners();
    try {
      await _repository.unenrollMahasiswa(enrollmentId, kelasId);
      _enrollments.removeWhere((e) => e.id == enrollmentId);
      await loadAll();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isEnrollmentLoading = false;
      notifyListeners();
    }
  }

  List<KelasModel> search(String query) {
    if (query.isEmpty) return _list;
    final q = query.toLowerCase();
    return _list.where((k) {
      return k.matakuliahNama.toLowerCase().contains(q) ||
          k.namaKelas.toLowerCase().contains(q) ||
          k.dosenNama.toLowerCase().contains(q);
    }).toList();
  }

  /// Update bobot komponen penilaian per kelas.
  /// Total bobotAbsensi + bobotTugas + bobotUTS + bobotUAS harus = 100.
  Future<bool> updateBobotNilai(
    String kelasId, {
    required int bobotAbsensi,
    required int bobotTugas,
    required int bobotUTS,
    required int bobotUAS,
  }) async {
    try {
      if (bobotAbsensi + bobotTugas + bobotUTS + bobotUAS != 100) {
        _errorMessage = 'Total bobot harus 100%';
        notifyListeners();
        return false;
      }
      await _repository.updateBobotNilai(
        kelasId,
        bobotAbsensi: bobotAbsensi,
        bobotTugas: bobotTugas,
        bobotUTS: bobotUTS,
        bobotUAS: bobotUAS,
      );
      // Update local state
      final idx = _list.indexWhere((k) => k.id == kelasId);
      if (idx != -1) {
        _list[idx] = _list[idx].copyWith(
          bobotAbsensi: bobotAbsensi,
          bobotTugas: bobotTugas,
          bobotUTS: bobotUTS,
          bobotUAS: bobotUAS,
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

  /// Toggle fitur LMS yang tersedia untuk mahasiswa di kelas ini.
  Future<bool> updateFitur(
    String kelasId, {
    required bool fiturMateri,
    required bool fiturTugas,
    required bool fiturQuiz,
    required bool fiturPengumuman,
  }) async {
    try {
      await _repository.updateFitur(
        kelasId,
        fiturMateri: fiturMateri,
        fiturTugas: fiturTugas,
        fiturQuiz: fiturQuiz,
        fiturPengumuman: fiturPengumuman,
      );
      final idx = _list.indexWhere((k) => k.id == kelasId);
      if (idx != -1) {
        _list[idx] = _list[idx].copyWith(
          fiturMateri: fiturMateri,
          fiturTugas: fiturTugas,
          fiturQuiz: fiturQuiz,
          fiturPengumuman: fiturPengumuman,
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
