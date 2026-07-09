import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../models/absensi_model.dart';
import '../models/tugas_model.dart';
import '../models/nilai_model.dart';
import 'storage_repository.dart';

/// Repository untuk semua operasi data Mahasiswa.
/// Semua query berdasarkan UID mahasiswa yang sedang login.
class MahasiswaDataRepository {
  MahasiswaDataRepository._();
  static final MahasiswaDataRepository instance = MahasiswaDataRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  // ────────────────────────────────────────────────────────────
  // ABSENSI
  // ────────────────────────────────────────────────────────────

  /// Ambil semua absensi mahasiswa yang sedang login
  Future<List<AbsensiModel>> getAbsensiByMahasiswa() async {
    if (_currentUid == null) return [];
    final snap = await _firestore
        .collection('absensi')
        .where('mahasiswaId', isEqualTo: _currentUid)
        .get();
    final list = snap.docs
        .map((d) => AbsensiModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
    return list;
  }

  /// Ambil absensi berdasarkan kelas
  Future<List<AbsensiModel>> getAbsensiByKelas(String kelasId) async {
    if (_currentUid == null) return [];
    final snap = await _firestore
        .collection('absensi')
        .where('mahasiswaId', isEqualTo: _currentUid)
        .where('kelasId', isEqualTo: kelasId)
        .get();
    final list = snap.docs
        .map((d) => AbsensiModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
    return list;
  }

  /// Check-in absensi
  Future<void> checkIn(String absensiId) async {
    await _firestore.collection('absensi').doc(absensiId).update({
      'isCheckedIn': true,
      'status': 'hadir',
      'checkedInAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hitung persentase kehadiran untuk sebuah kelas
  Future<double> getPersentaseKehadiran(String kelasId) async {
    final list = await getAbsensiByKelas(kelasId);
    if (list.isEmpty) return 0.0;
    final hadir = list.where((a) => a.isHadir).length;
    return (hadir / list.length) * 100;
  }

  // ────────────────────────────────────────────────────────────
  // TUGAS
  // ────────────────────────────────────────────────────────────

  /// Ambil semua tugas dari kelas-kelas yang mahasiswa ikuti
  Future<List<TugasModel>> getTugasByKelasIds(List<String> kelasIds) async {
    if (kelasIds.isEmpty) return [];
    final snap = await _firestore
        .collection('tugas')
        .where('kelasId', whereIn: kelasIds)
        .where('isActive', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => TugasModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  /// Ambil tugas berdasarkan kelas
  Future<List<TugasModel>> getTugasByKelas(String kelasId) async {
    final snap = await _firestore
        .collection('tugas')
        .where('kelasId', isEqualTo: kelasId)
        .where('isActive', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => TugasModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  /// Ambil submisi mahasiswa untuk tugas tertentu
  Future<SubmisiModel?> getSubmisiByTugas(String tugasId) async {
    if (_currentUid == null) return null;
    final snap = await _firestore
        .collection('submissions')
        .where('tugasId', isEqualTo: tugasId)
        .where('mahasiswaId', isEqualTo: _currentUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SubmisiModel.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// Ambil semua submisi mahasiswa
  Future<List<SubmisiModel>> getAllSubmisiByMahasiswa() async {
    if (_currentUid == null) return [];
    final snap = await _firestore
        .collection('submissions')
        .where('mahasiswaId', isEqualTo: _currentUid)
        .get();
    final list = snap.docs
        .map((d) => SubmisiModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  /// Upload file tugas ke Supabase Storage
  Future<String> uploadFileTugas(File file, String tugasId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User tidak terautentikasi.');
    final fileName = file.path.split('/').last.split('\\').last;
    final path = 'assignments/$tugasId/${uid}_$fileName';
    return await StorageRepository.instance.uploadFile(file: file, path: path);
  }

  /// Submit tugas mahasiswa
  Future<void> submitTugas({
    required String tugasId,
    required String kelasId,
    required String mahasiswaNama,
    required String fileUrl,
    required String fileName,
    required File file,
    required String catatan,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User tidak terautentikasi.');

    // Cek apakah sudah submit
    final existing = await _firestore
        .collection('submissions')
        .where('tugasId', isEqualTo: tugasId)
        .where('mahasiswaId', isEqualTo: uid)
        .get();

    final submisiRef = existing.docs.isNotEmpty
        ? _firestore.collection('submissions').doc(existing.docs.first.id)
        : _firestore.collection('submissions').doc();

    await submisiRef.set({
      'tugasId': tugasId,
      'kelasId': kelasId,
      'mahasiswaId': uid,
      'mahasiswaNama': mahasiswaNama,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': file.lengthSync(),
      'fileType': fileName.split('.').last.toLowerCase(),
      'uploadedAt': FieldValue.serverTimestamp(),
      'uploadedBy': uid,
      'catatan': catatan,
      'nilai': null,
      'feedback': '',
      'isGraded': false,
      'submittedAt': FieldValue.serverTimestamp(),
      'gradedAt': null,
    });
  }

  // ────────────────────────────────────────────────────────────
  // NILAI
  // ────────────────────────────────────────────────────────────

  /// Ambil semua nilai mahasiswa
  Future<List<NilaiModel>> getNilaiByMahasiswa() async {
    if (_currentUid == null) return [];
    final snap = await _firestore
        .collection('nilai')
        .where('mahasiswaId', isEqualTo: _currentUid)
        .get();
    final list = snap.docs
        .map((d) => NilaiModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.semesterNama.compareTo(b.semesterNama));
    return list;
  }

  /// Ambil nilai berdasarkan semester
  Future<List<NilaiModel>> getNilaiBySemester(String semesterId) async {
    if (_currentUid == null) return [];
    final snap = await _firestore
        .collection('nilai')
        .where('mahasiswaId', isEqualTo: _currentUid)
        .where('semesterId', isEqualTo: semesterId)
        .get();
    return snap.docs.map((d) => NilaiModel.fromMap(d.id, d.data())).toList();
  }

  /// Hitung IP Semester
  double hitungIPS(List<NilaiModel> nilaiList) {
    if (nilaiList.isEmpty) return 0.0;
    final totalMutu = nilaiList.fold(0.0, (sum, n) => sum + n.mutu);
    final totalSks = nilaiList.fold(0, (sum, n) => sum + n.sks);
    if (totalSks == 0) return 0.0;
    return totalMutu / totalSks;
  }

  /// Hitung IPK dari semua semester
  double hitungIPK(List<NilaiModel> allNilai) {
    if (allNilai.isEmpty) return 0.0;
    final totalMutu = allNilai.fold(0.0, (sum, n) => sum + n.mutu);
    final totalSks = allNilai.fold(0, (sum, n) => sum + n.sks);
    if (totalSks == 0) return 0.0;
    return totalMutu / totalSks;
  }

  // ────────────────────────────────────────────────────────────
  // PENGUMUMAN
  // ────────────────────────────────────────────────────────────

  /// Ambil pengumuman untuk kelas-kelas yang mahasiswa ikuti + pengumuman umum
  Future<List<PengumumanModel>> getPengumumanByKelasIds(
    List<String> kelasIds,
  ) async {
    final List<PengumumanModel> result = [];

    // Pengumuman umum (kelasId kosong)
    final globalSnap = await _firestore
        .collection('pengumuman')
        .where('kelasId', isEqualTo: '')
        .get();
    final globalList = globalSnap.docs
        .map((d) => PengumumanModel.fromMap(d.id, d.data()))
        .toList();
    globalList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    result.addAll(globalList.take(20));

    // Pengumuman per kelas (max 10 kelas untuk whereIn)
    if (kelasIds.isNotEmpty) {
      final chunks = <List<String>>[];
      for (var i = 0; i < kelasIds.length; i += 10) {
        chunks.add(
          kelasIds.sublist(
            i,
            i + 10 > kelasIds.length ? kelasIds.length : i + 10,
          ),
        );
      }
      for (final chunk in chunks) {
        final snap = await _firestore
            .collection('pengumuman')
            .where('kelasId', whereIn: chunk)
            .get();
        result.addAll(
          snap.docs.map((d) => PengumumanModel.fromMap(d.id, d.data())),
        );
      }
    }

    // Sort by createdAt descending
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Deduplicate
    final seen = <String>{};
    return result.where((p) => seen.add(p.id)).toList();
  }

  // ────────────────────────────────────────────────────────────
  // NOTIFIKASI
  // ────────────────────────────────────────────────────────────

  /// Ambil notifikasi mahasiswa
  Stream<List<NotifikasiModel>> getNotifikasiStream() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => NotifikasiModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Tandai notifikasi sudah dibaca
  Future<void> markNotifikasiRead(String notifId) async {
    await _firestore.collection('notifications').doc(notifId).update({
      'isRead': true,
    });
  }

  /// Tandai semua notifikasi sudah dibaca
  Future<void> markAllNotifikasiRead() async {
    final uid = _currentUid;
    if (uid == null) return;
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ────────────────────────────────────────────────────────────
  // MATERI
  // ────────────────────────────────────────────────────────────

  /// Ambil materi berdasarkan kelas
  Future<List<MateriModel>> getMateriByKelas(String kelasId) async {
    final snap = await _firestore
        .collection('materials')
        .where('kelasId', isEqualTo: kelasId)
        .get();
    final list = snap.docs
        .map((d) => MateriModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
    return list;
  }

  // ────────────────────────────────────────────────────────────
  // PROFIL MAHASISWA
  // ────────────────────────────────────────────────────────────

  /// Update profil mahasiswa (nama, noHP, photoUrl)
  Future<void> updateProfil({
    required String nama,
    required String noHP,
    String? photoUrl,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User tidak terautentikasi.');
    final data = <String, dynamic>{
      'nama': nama,
      'noHP': noHP,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// Upload foto profil ke Supabase Storage
  Future<String> uploadFotoProfil(File file) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('User tidak terautentikasi.');
    final ext = file.path.split('.').last;
    final path = 'profile_photos/$uid.$ext';
    return await StorageRepository.instance.uploadFile(file: file, path: path);
  }

  // ────────────────────────────────────────────────────────────
  // JADWAL MAHASISWA
  // ────────────────────────────────────────────────────────────

  /// Ambil jadwal berdasarkan kelasIds yang mahasiswa ikuti
  Future<List<dynamic>> getJadwalByKelasIds(List<String> kelasIds) async {
    if (kelasIds.isEmpty) return [];
    final List<dynamic> result = [];

    final chunks = <List<String>>[];
    for (var i = 0; i < kelasIds.length; i += 10) {
      chunks.add(
        kelasIds.sublist(
          i,
          i + 10 > kelasIds.length ? kelasIds.length : i + 10,
        ),
      );
    }

    for (final chunk in chunks) {
      final snap = await _firestore
          .collection('jadwal')
          .where('kelasId', whereIn: chunk)
          .where('status', isEqualTo: true)
          .get();
      result.addAll(snap.docs.map((d) => {'id': d.id, ...d.data()}));
    }
    return result;
  }
}
