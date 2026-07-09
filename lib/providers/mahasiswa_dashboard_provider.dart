import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

import '../models/absensi_model.dart';
import '../models/tugas_model.dart';
import '../models/nilai_model.dart';
import '../models/kelas_model.dart';
import '../models/jadwal_model.dart';
import '../models/class_enrollment_model.dart';
import '../repositories/nilai_repository.dart';
import '../repositories/kelas_repository.dart';
import '../repositories/jadwal_repository.dart';

/// Provider utama untuk semua data mahasiswa yang sedang login.
/// Semua query berdasarkan UID user yang sedang login.
class MahasiswaDashboardProvider extends ChangeNotifier {
  final MahasiswaDataRepository _repo = MahasiswaDataRepository.instance;
  final KelasRepository _kelasRepo = KelasRepository.instance;
  final JadwalRepository _jadwalRepo = JadwalRepository.instance;

  // ── State ─────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // ── Data ──────────────────────────────────────────────────
  List<ClassEnrollmentModel> _enrollments = [];
  List<KelasModel> _kelasList = [];
  List<JadwalModel> _jadwalList = [];
  List<AbsensiModel> _absensiList = [];
  List<TugasModel> _tugasList = [];
  List<SubmisiModel> _submisiList = [];
  List<NilaiModel> _nilaiList = [];
  List<PengumumanModel> _pengumumanList = [];
  List<NotifikasiModel> _notifikasiList = [];

  // ── Getters ───────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  List<ClassEnrollmentModel> get enrollments => _enrollments;
  List<KelasModel> get kelasList => _kelasList;
  List<JadwalModel> get jadwalList => _jadwalList;
  List<AbsensiModel> get absensiList => _absensiList;
  List<TugasModel> get tugasList => _tugasList;
  List<SubmisiModel> get submisiList => _submisiList;
  List<NilaiModel> get nilaiList => _nilaiList;
  List<PengumumanModel> get pengumumanList => _pengumumanList;
  List<NotifikasiModel> get notifikasiList => _notifikasiList;

  // ── Computed ──────────────────────────────────────────────

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// IDs kelas yang mahasiswa ikuti
  List<String> get kelasIds => _enrollments.map((e) => e.kelasId).toList();

  /// Jadwal hari ini
  List<JadwalModel> get jadwalHariIni {
    const hariMap = {
      DateTime.monday: 'Senin',
      DateTime.tuesday: 'Selasa',
      DateTime.wednesday: 'Rabu',
      DateTime.thursday: 'Kamis',
      DateTime.friday: 'Jumat',
      DateTime.saturday: 'Sabtu',
      DateTime.sunday: 'Minggu',
    };
    final hariIni = hariMap[DateTime.now().weekday] ?? '';
    return _jadwalList.where((j) => j.hari == hariIni).toList();
  }

  /// Tugas mendekati deadline (yang belum dikumpulkan, diurutkan dari yang paling dekat)
  List<TugasModel> get tugasDeadlineDekat {
    final now = DateTime.now();
    return _tugasList.where((t) {
      final dl = t.deadline.toDate();
      return dl.isAfter(now) && !hasSubmitted(t.id);
    }).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  /// Notifikasi belum dibaca
  int get unreadNotifCount => _notifikasiList.where((n) => !n.isRead).length;

  /// Pengumuman terbaru (max 5)
  List<PengumumanModel> get pengumumanTerbaru =>
      _pengumumanList.take(5).toList();

  /// Total SKS yang diambil
  int get totalSKS {
    if (_nilaiList.isNotEmpty) {
      return _nilaiList.fold(0, (total, n) => total + n.sks);
    }
    return _kelasList.length * 3; // estimasi 3 SKS per kelas
  }

  /// IP Semester
  double get ipSemester => _repo.hitungIPS(_nilaiList);

  /// IPK keseluruhan
  double get ipk => _repo.hitungIPK(_nilaiList);

  /// Progress semester (pertemuan rata-rata)
  double get progressSemester {
    if (_absensiList.isEmpty) return 0.0;
    final totalPertemuan = _absensiList.length;
    final hadir = _absensiList.where((a) => a.isHadir).length;
    return totalPertemuan > 0 ? hadir / totalPertemuan : 0.0;
  }

  // ─────────────────────────────────────────────────────────
  // INIT / LOAD ALL
  // ─────────────────────────────────────────────────────────

  final List<StreamSubscription> _subscriptions = [];
  final List<StreamSubscription> _subSubscriptions = [];

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _cancelSubSubscriptions();
  }

  void _cancelSubSubscriptions() {
    for (final sub in _subSubscriptions) {
      sub.cancel();
    }
    _subSubscriptions.clear();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  Future<void> syncDosenNames() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    try {
      final dosenSnap = await db.collection('users').where('role', isEqualTo: 'dosen').get();
      final batch = db.batch();
      bool hasChanges = false;

      for (final doc in dosenSnap.docs) {
        final dosenId = doc.id;
        final dosenNama = doc.data()['nama'] ?? '';
        if (dosenNama.isEmpty) continue;

        // Sync kelas
        final classesSnap = await db
            .collection('kelas')
            .where('dosenId', isEqualTo: dosenId)
            .get();
        for (final cDoc in classesSnap.docs) {
          if (cDoc.data()['dosenNama'] != dosenNama) {
            batch.update(cDoc.reference, {'dosenNama': dosenNama});
            hasChanges = true;
          }
        }

        // Sync jadwal
        final jadwalSnap = await db
            .collection('jadwal')
            .where('dosenId', isEqualTo: dosenId)
            .get();
        for (final jDoc in jadwalSnap.docs) {
          if (jDoc.data()['dosenNama'] != dosenNama) {
            batch.update(jDoc.reference, {'dosenNama': dosenNama});
            hasChanges = true;
          }
        }

        // Sync tugas
        final tugasSnap = await db
            .collection('tugas')
            .where('dosenId', isEqualTo: dosenId)
            .get();
        for (final tDoc in tugasSnap.docs) {
          if (tDoc.data()['dosenNama'] != dosenNama) {
            batch.update(tDoc.reference, {'dosenNama': dosenNama});
            hasChanges = true;
          }
        }
      }

      if (hasChanges) {
        await batch.commit();
        debugPrint('Dosen names synchronized successfully in database.');
      }
    } catch (e) {
      debugPrint('Error syncing dosen names: $e');
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    syncDosenNames(); // Heal database in background
    listenAll();
  }

  void listenAll() {
    final uid = _currentUid;
    if (uid == null) return;

    _cancelSubscriptions();
    _setLoading(true);

    final FirebaseFirestore db = FirebaseFirestore.instance;

    // 1. Listen to class_enrollments
    final enrollmentsSub = db
        .collection('class_enrollments')
        .where('mahasiswaId', isEqualTo: uid)
        .snapshots()
        .listen((enrollSnap) {
      _enrollments = enrollSnap.docs
          .map((d) => ClassEnrollmentModel.fromMap(d.id, d.data()))
          .toList();

      if (_enrollments.isEmpty) {
        _kelasList = [];
        _jadwalList = [];
        _tugasList = [];
        _pengumumanList = [];
        _isInitialized = true;
        _setLoading(false);
        notifyListeners();
        return;
      }

      final ids = kelasIds;

      _cancelSubSubscriptions();

      // 2. Listen to classes
      final classesSub = db
          .collection('kelas')
          .where(FieldPath.documentId, whereIn: ids)
          .snapshots()
          .listen((classesSnap) {
        _kelasList = classesSnap.docs
            .map((d) => KelasModel.fromMap(d.id, d.data()))
            .toList();
        notifyListeners();
      });
      _subSubscriptions.add(classesSub);

      // 3. Listen to schedules (jadwal)
      final jadwalSub = db
          .collection('jadwal')
          .where('kelasId', whereIn: ids)
          .snapshots()
          .listen((jadwalSnap) {
        final list = jadwalSnap.docs
            .map((d) => JadwalModel.fromMap(d.id, d.data()))
            .toList();
        const hariOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
        list.sort((a, b) {
          final hA = hariOrder.indexOf(a.hari);
          final hB = hariOrder.indexOf(b.hari);
          if (hA != hB) return hA.compareTo(hB);
          return a.jamMulai.compareTo(b.jamMulai);
        });
        _jadwalList = list;
        notifyListeners();
      });
      _subSubscriptions.add(jadwalSub);

      // 4. Listen to tugas
      final tugasSub = db
          .collection('tugas')
          .where('kelasId', whereIn: ids)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .listen((tugasSnap) {
        _tugasList = tugasSnap.docs
            .map((d) => TugasModel.fromMap(d.id, d.data()))
            .toList();
        notifyListeners();
      });
      _subSubscriptions.add(tugasSub);

      // 5. Listen to pengumuman
      final pengumumanSub = db
          .collection('announcements')
          .where('kelasId', whereIn: [''] + ids)
          .snapshots()
          .listen((annSnap) {
        final list = annSnap.docs
            .map((d) => PengumumanModel.fromMap(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _pengumumanList = list;
        notifyListeners();
      });
      _subSubscriptions.add(pengumumanSub);

      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
    });

    _subscriptions.add(enrollmentsSub);

    // 6. Listen to absensi
    final absensiSub = db
        .collection('absensi')
        .where('mahasiswaId', isEqualTo: uid)
        .snapshots()
        .listen((absSnap) {
      _absensiList = absSnap.docs
          .map((d) => AbsensiModel.fromMap(d.id, d.data()))
          .toList();
      notifyListeners();
    });
    _subscriptions.add(absensiSub);

    // 7. Listen to submissions
    final submisiSub = db
        .collection('submissions')
        .where('mahasiswaId', isEqualTo: uid)
        .snapshots()
        .listen((subSnap) {
      _submisiList = subSnap.docs
          .map((d) => SubmisiModel.fromMap(d.id, d.data()))
          .toList();
      notifyListeners();
    });
    _subscriptions.add(submisiSub);

    // 8. Listen to nilai
    final nilaiSub = db
        .collection('nilai')
        .where('mahasiswaId', isEqualTo: uid)
        .snapshots()
        .listen((nilaiSnap) {
      _nilaiList = nilaiSnap.docs
          .map((d) => NilaiModel.fromMap(d.id, d.data()))
          .toList();
      notifyListeners();
    });
    _subscriptions.add(nilaiSub);
  }

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      final uid = _currentUid;
      if (uid == null) return;

      // 1. Ambil enrollment
      _enrollments = await _kelasRepo.getEnrollmentsByMahasiswa(uid);

      if (_enrollments.isEmpty) {
        _isInitialized = true;
        _setLoading(false);
        return;
      }

      final ids = kelasIds;

      // 2. Load semua data secara parallel
      final results = await Future.wait([
        _loadKelas(ids),
        _loadJadwal(ids),
        _repo.getAbsensiByMahasiswa(),
        _repo.getTugasByKelasIds(ids),
        _repo.getAllSubmisiByMahasiswa(),
        _repo.getNilaiByMahasiswa(),
        _repo.getPengumumanByKelasIds(ids),
      ]);

      _kelasList = results[0] as List<KelasModel>;
      _jadwalList = results[1] as List<JadwalModel>;
      _absensiList = results[2] as List<AbsensiModel>;
      _tugasList = results[3] as List<TugasModel>;
      _submisiList = results[4] as List<SubmisiModel>;
      _nilaiList = results[5] as List<NilaiModel>;
      _pengumumanList = results[6] as List<PengumumanModel>;

      _errorMessage = null;
      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MahasiswaDashboardProvider.loadAll: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<KelasModel>> _loadKelas(List<String> ids) async {
    final list = <KelasModel>[];
    for (final id in ids) {
      final k = await _kelasRepo.getById(id);
      if (k != null) list.add(k);
    }
    return list;
  }

  Future<List<JadwalModel>> _loadJadwal(List<String> ids) async {
    final list = <JadwalModel>[];
    for (final id in ids) {
      final jadwals = await _jadwalRepo.getByKelas(id);
      list.addAll(jadwals);
    }
    const hariOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    list.sort((a, b) {
      final hA = hariOrder.indexOf(a.hari);
      final hB = hariOrder.indexOf(b.hari);
      if (hA != hB) return hA.compareTo(hB);
      return a.jamMulai.compareTo(b.jamMulai);
    });
    return list;
  }

  // ─────────────────────────────────────────────────────────
  // ABSENSI
  // ─────────────────────────────────────────────────────────

  Future<List<AbsensiModel>> getAbsensiByKelas(String kelasId) async {
    return _repo.getAbsensiByKelas(kelasId);
  }

  Future<bool> checkIn(String absensiId) async {
    try {
      await _repo.checkIn(absensiId);
      final idx = _absensiList.indexWhere((a) => a.id == absensiId);
      if (idx != -1) {
        _absensiList[idx] = _absensiList[idx].copyWith(
          isCheckedIn: true,
          status: 'hadir',
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

  // ─────────────────────────────────────────────────────────
  // TUGAS & SUBMISI
  // ─────────────────────────────────────────────────────────

  Future<List<TugasModel>> getTugasByKelas(String kelasId) async {
    return _repo.getTugasByKelas(kelasId);
  }

  Future<SubmisiModel?> getSubmisiByTugas(String tugasId) async {
    return _repo.getSubmisiByTugas(tugasId);
  }

  bool hasSubmitted(String tugasId) {
    return _submisiList.any((s) => s.tugasId == tugasId);
  }

  SubmisiModel? getSubmisiFor(String tugasId) {
    try {
      return _submisiList.firstWhere((s) => s.tugasId == tugasId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> submitTugas({
    required String tugasId,
    required String kelasId,
    required String mahasiswaNama,
    required File file,
    required String fileName,
    required String catatan,
  }) async {
    _setLoading(true);
    try {
      final fileUrl = await _repo.uploadFileTugas(file, tugasId);
      await _repo.submitTugas(
        tugasId: tugasId,
        kelasId: kelasId,
        mahasiswaNama: mahasiswaNama,
        fileUrl: fileUrl,
        fileName: fileName,
        file: file,
        catatan: catatan,
      );
      _submisiList = await _repo.getAllSubmisiByMahasiswa();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MahasiswaDashboardProvider.submitTugas: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // NILAI
  // ─────────────────────────────────────────────────────────

  List<NilaiModel> getNilaiBySemester(String semesterNama) {
    return _nilaiList.where((n) => n.semesterNama == semesterNama).toList();
  }

  /// Daftar nama semester unik
  List<String> get semesterList {
    final set = <String>{};
    for (final n in _nilaiList) {
      set.add(n.semesterNama);
    }
    final list = set.toList()..sort();
    return list;
  }

  double hitungIPS(List<NilaiModel> list) => _repo.hitungIPS(list);
  double hitungIPK(List<NilaiModel> list) => _repo.hitungIPK(list);

  // ─────────────────────────────────────────────────────────
  // MATERI
  // ─────────────────────────────────────────────────────────

  Future<List<MateriModel>> getMateriByKelas(String kelasId) async {
    return _repo.getMateriByKelas(kelasId);
  }

  // ─────────────────────────────────────────────────────────
  // NOTIFIKASI
  // ─────────────────────────────────────────────────────────

  void listenNotifikasi() {
    _repo.getNotifikasiStream().listen((list) {
      _notifikasiList = list;
      notifyListeners();
    });
  }

  Future<void> markRead(String id) async {
    await _repo.markNotifikasiRead(id);
    final idx = _notifikasiList.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final n = _notifikasiList[idx];
      _notifikasiList[idx] = NotifikasiModel(
        id: n.id,
        userId: n.userId,
        judul: n.judul,
        pesan: n.pesan,
        tipe: n.tipe,
        referenceId: n.referenceId,
        isRead: true,
        createdAt: n.createdAt,
      );
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _repo.markAllNotifikasiRead();
    _notifikasiList = _notifikasiList
        .map(
          (n) => NotifikasiModel(
            id: n.id,
            userId: n.userId,
            judul: n.judul,
            pesan: n.pesan,
            tipe: n.tipe,
            referenceId: n.referenceId,
            isRead: true,
            createdAt: n.createdAt,
          ),
        )
        .toList();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // PROFIL
  // ─────────────────────────────────────────────────────────

  Future<bool> updateProfil({
    required String nama,
    required String noHP,
    File? fotoFile,
    String? existingPhotoUrl,
  }) async {
    _setLoading(true);
    try {
      String? photoUrl = existingPhotoUrl;
      if (fotoFile != null) {
        photoUrl = await _repo.uploadFotoProfil(fotoFile);
      }
      await _repo.updateProfil(nama: nama, noHP: noHP, photoUrl: photoUrl);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MahasiswaDashboardProvider.updateProfil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _cancelSubscriptions();
    _isInitialized = false;
    _enrollments = [];
    _kelasList = [];
    _jadwalList = [];
    _absensiList = [];
    _tugasList = [];
    _submisiList = [];
    _nilaiList = [];
    _pengumumanList = [];
    _notifikasiList = [];
    notifyListeners();
  }
}
