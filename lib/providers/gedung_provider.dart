import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gedung_model.dart';
import '../repositories/gedung_repository.dart';

/// Provider untuk master data Gedung dan Ruangan.
class GedungProvider extends ChangeNotifier {
  final GedungRepository _repository = GedungRepository.instance;

  // ── Gedung ─────────────────────────────────────────────────────
  List<GedungModel> _gedungList = [];
  bool _isLoadingGedung = false;
  String? _errorMessage;

  List<GedungModel> get gedungList => _gedungList;
  bool get isLoadingGedung => _isLoadingGedung;
  String? get errorMessage => _errorMessage;

  // ── Ruangan ────────────────────────────────────────────────────
  List<RuanganModel> _ruanganList = [];
  bool _isLoadingRuangan = false;

  List<RuanganModel> get ruanganList => _ruanganList;
  bool get isLoadingRuangan => _isLoadingRuangan;

  // ──────────────────────────────────────────────────────────────
  // GEDUNG ACTIONS
  // ──────────────────────────────────────────────────────────────

  Future<void> loadAllGedung() async {
    _isLoadingGedung = true;
    notifyListeners();
    try {
      _gedungList = await _repository.getAllGedung();
      
      // Auto seed Gedung E, Gedung D, and Gedung C if they don't exist
      bool hasE = _gedungList.any((g) => g.kode.toUpperCase() == 'E');
      bool hasD = _gedungList.any((g) => g.kode.toUpperCase() == 'D');
      bool hasC = _gedungList.any((g) => g.kode.toUpperCase() == 'C');
      bool seeded = false;

      if (!hasE) {
        final eId = await _repository.createGedung(GedungModel(
          id: '',
          kode: 'E',
          nama: 'Gedung E',
          alamat: 'Kampus 2 UINAM Samata',
          latitude: -5.2030,
          longitude: 119.4972,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        
        await _repository.createRuangan(RuanganModel(
          id: '',
          gedungId: eId,
          gedungNama: 'Gedung E',
          namaRuangan: '102',
          kodeRuangan: 'E 102',
          kapasitas: 40,
          tipe: 'kelas',
          latitude: -5.2030,
          longitude: 119.4972,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        await _repository.createRuangan(RuanganModel(
          id: '',
          gedungId: eId,
          gedungNama: 'Gedung E',
          namaRuangan: '202',
          kodeRuangan: 'E 202',
          kapasitas: 40,
          tipe: 'kelas',
          latitude: -5.2031,
          longitude: 119.4973,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        await _repository.createRuangan(RuanganModel(
          id: '',
          gedungId: eId,
          gedungNama: 'Gedung E',
          namaRuangan: '302',
          kodeRuangan: 'E 302',
          kapasitas: 40,
          tipe: 'kelas',
          latitude: -5.2032,
          longitude: 119.4974,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        seeded = true;
      }

      if (!hasD) {
        final dId = await _repository.createGedung(GedungModel(
          id: '',
          kode: 'D',
          nama: 'Gedung D',
          alamat: 'Kampus 2 UINAM Samata',
          latitude: -5.2045,
          longitude: 119.4975,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        
        await _repository.createRuangan(RuanganModel(
          id: '',
          gedungId: dId,
          gedungNama: 'Gedung D',
          namaRuangan: '404',
          kodeRuangan: 'D 404',
          kapasitas: 40,
          tipe: 'kelas',
          latitude: -5.2045,
          longitude: 119.4975,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        await _repository.createRuangan(RuanganModel(
          id: '',
          gedungId: dId,
          gedungNama: 'Gedung D',
          namaRuangan: '405',
          kodeRuangan: 'D 405',
          kapasitas: 40,
          tipe: 'kelas',
          latitude: -5.2046,
          longitude: 119.4976,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        await _repository.createRuangan(RuanganModel(
          id: '',
          gedungId: dId,
          gedungNama: 'Gedung D',
          namaRuangan: '406',
          kodeRuangan: 'D 406',
          kapasitas: 40,
          tipe: 'kelas',
          latitude: -5.2047,
          longitude: 119.4977,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        seeded = true;
      }

      if (!hasC) {
        final cId = await _repository.createGedung(GedungModel(
          id: '',
          kode: 'C',
          nama: 'Gedung C',
          alamat: 'Kampus 2 UINAM Samata',
          latitude: -5.2038,
          longitude: 119.4980,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        
        await _repository.createRuangan(RuanganModel(
          id: '',
          gedungId: cId,
          gedungNama: 'Gedung C',
          namaRuangan: '102',
          kodeRuangan: 'C 102',
          kapasitas: 40,
          tipe: 'kelas',
          latitude: -5.2038,
          longitude: 119.4980,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        await _repository.createRuangan(RuanganModel(
          id: '',
          gedungId: cId,
          gedungNama: 'Gedung C',
          namaRuangan: '103',
          kodeRuangan: 'C 103',
          kapasitas: 40,
          tipe: 'kelas',
          latitude: -5.2039,
          longitude: 119.4981,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        await _repository.createRuangan(RuanganModel(
          id: '',
          gedungId: cId,
          gedungNama: 'Gedung C',
          namaRuangan: '104',
          kodeRuangan: 'C 104',
          kapasitas: 40,
          tipe: 'kelas',
          latitude: -5.2040,
          longitude: 119.4982,
          status: true,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        ));
        seeded = true;
      }

      if (seeded) {
        _gedungList = await _repository.getAllGedung();
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('GedungProvider.loadAllGedung: $e');
    } finally {
      _isLoadingGedung = false;
      notifyListeners();
    }
  }

  Future<bool> createGedung(GedungModel model) async {
    _isLoadingGedung = true;
    notifyListeners();
    try {
      await _repository.createGedung(model);
      await loadAllGedung();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('GedungProvider.createGedung: $e');
      return false;
    } finally {
      _isLoadingGedung = false;
      notifyListeners();
    }
  }

  Future<bool> updateGedung(GedungModel model) async {
    _isLoadingGedung = true;
    notifyListeners();
    try {
      await _repository.updateGedung(model);
      await loadAllGedung();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoadingGedung = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGedung(String id) async {
    try {
      await _repository.deleteGedung(id);
      _gedungList.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // RUANGAN ACTIONS
  // ──────────────────────────────────────────────────────────────

  Future<void> loadRuanganByGedung(String gedungId) async {
    _isLoadingRuangan = true;
    notifyListeners();
    try {
      _ruanganList = await _repository.getRuanganByGedung(gedungId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('GedungProvider.loadRuanganByGedung: $e');
    } finally {
      _isLoadingRuangan = false;
      notifyListeners();
    }
  }

  Future<bool> createRuangan(RuanganModel model) async {
    _isLoadingRuangan = true;
    notifyListeners();
    try {
      await _repository.createRuangan(model);
      await loadRuanganByGedung(model.gedungId);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoadingRuangan = false;
      notifyListeners();
    }
  }

  Future<bool> updateRuangan(RuanganModel model) async {
    _isLoadingRuangan = true;
    notifyListeners();
    try {
      await _repository.updateRuangan(model);
      await loadRuanganByGedung(model.gedungId);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoadingRuangan = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRuangan(String id, String gedungId) async {
    try {
      await _repository.deleteRuangan(id);
      _ruanganList.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<GedungModel> searchGedung(String query) {
    if (query.isEmpty) return _gedungList;
    final q = query.toLowerCase();
    return _gedungList
        .where(
          (g) =>
              g.nama.toLowerCase().contains(q) ||
              g.kode.toLowerCase().contains(q),
        )
        .toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
