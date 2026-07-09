import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/jadwal_model.dart';
import '../models/kelas_model.dart';
import '../models/class_enrollment_model.dart';
import '../models/tugas_model.dart';
import '../models/nilai_model.dart';
import '../models/matakuliah_model.dart';
import '../repositories/tugas_repository.dart';
import '../repositories/jadwal_repository.dart';
import '../repositories/pertemuan_repository.dart';
import '../repositories/kelas_repository.dart';

class DosenDashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final JadwalRepository _jadwalRepo = JadwalRepository.instance;
  final PertemuanRepository _pertemuanRepo = PertemuanRepository.instance;
  final KelasRepository _kelasRepo = KelasRepository.instance;

  // ── State ─────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  List<JadwalModel> _schedules = [];
  List<KelasModel> _kelasList = [];
  Map<String, MatakuliahModel> _matakuliahMap = {};

  // ── Getters ───────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  List<JadwalModel> get schedules => _schedules;
  List<KelasModel> get kelasList => _kelasList;
  Map<String, MatakuliahModel> get matakuliahMap => _matakuliahMap;

  /// Jadwal mengajar Dosen untuk hari ini (Makassar Time)
  List<JadwalModel> get schedulesHariIni {
    final mTime = DateTime.now();
    const hariMap = {
      DateTime.monday: 'Senin',
      DateTime.tuesday: 'Selasa',
      DateTime.wednesday: 'Rabu',
      DateTime.thursday: 'Kamis',
      DateTime.friday: 'Jumat',
      DateTime.saturday: 'Sabtu',
      DateTime.sunday: 'Minggu',
    };
    final hariIni = hariMap[mTime.weekday] ?? '';
    return _schedules.where((j) => j.hari == hariIni).toList();
  }

  // ─────────────────────────────────────────────────────────
  // LOAD DATA
  // ─────────────────────────────────────────────────────────

  Future<void> loadSchedules(String dosenUid, String dosenNama) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ambil daftar kelas yang diampu dosen
      final classesSnap = await _firestore
          .collection('kelas')
          .where('dosenId', isEqualTo: dosenUid)
          .get();

      _kelasList = classesSnap.docs
          .map((d) => KelasModel.fromMap(d.id, d.data()))
          .toList();

      // Load data matakuliah untuk referensi jenis matakuliah (Teori vs Praktikum)
      // Mengambil seluruh matakuliah untuk pencocokan yang kokoh baik berdasarkan document ID maupun kode matakuliah
      _matakuliahMap = {};
      try {
        final mkSnap = await _firestore.collection('matakuliah').get();
        for (final doc in mkSnap.docs) {
          final mk = MatakuliahModel.fromMap(doc.id, doc.data());
          _matakuliahMap[doc.id] = mk;
          if (mk.kode.isNotEmpty) {
            _matakuliahMap[mk.kode] = mk;
          }
        }
      } catch (e) {
        debugPrint('DosenDashboardProvider.loadSchedules load matakuliah error: $e');
      }

      final list = <JadwalModel>[];

      if (_kelasList.isNotEmpty) {
        final classIds = _kelasList.map((k) => k.id).toList();

        // Load jadwal untuk kelas-kelas tersebut
        final schedulesSnap = await _firestore
            .collection('jadwal')
            .where('kelasId', whereIn: classIds)
            .get();

        list.addAll(schedulesSnap.docs
            .map((d) => JadwalModel.fromMap(d.id, d.data()))
            .toList());
      } else {
        // Fallback filter by name
        final schedulesSnap = await _firestore
            .collection('jadwal')
            .where('dosenNama', isEqualTo: dosenNama)
            .get();

        list.addAll(schedulesSnap.docs
            .map((d) => JadwalModel.fromMap(d.id, d.data()))
            .toList());
      }

      // Urutkan jadwal berdasarkan hari dan jam
      const hariOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      list.sort((a, b) {
        final hA = hariOrder.indexOf(a.hari);
        final hB = hariOrder.indexOf(b.hari);
        if (hA != hB) return hA.compareTo(hB);
        return a.jamMulai.compareTo(b.jamMulai);
      });

      _schedules = list;
      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.loadSchedules error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  // KELOLA JADWAL PERKULIAHAN
  // ─────────────────────────────────────────────────────────

  Future<bool> updateJadwal(JadwalModel updatedJadwal) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Simpan perubahan ke Firestore
      await _jadwalRepo.update(updatedJadwal);

      // 2. Perbarui local state
      final idx = _schedules.indexWhere((j) => j.id == updatedJadwal.id);
      if (idx != -1) {
        _schedules[idx] = updatedJadwal;
      }

      // 3. Kirim notifikasi ke semua mahasiswa terdaftar di kelas
      try {
        final enrollments = await getEnrollments(updatedJadwal.kelasId);
        if (enrollments.isNotEmpty) {
          final batch = _firestore.batch();
          for (final enrollment in enrollments) {
            final notifRef = _firestore.collection('notifications').doc();
            final notif = NotifikasiModel(
              id: notifRef.id,
              userId: enrollment.mahasiswaId,
              judul: 'Perubahan Jadwal Kuliah',
              pesan: 'Jadwal kuliah ${updatedJadwal.matakuliahNama} (${updatedJadwal.jenisSesi == "praktikum" ? "Praktikum" : "Teori"}) diubah menjadi hari ${updatedJadwal.hari}, pukul ${updatedJadwal.jamMulai} - ${updatedJadwal.jamSelesai}.',
              tipe: 'sistem',
              referenceId: updatedJadwal.id,
              isRead: false,
              createdAt: Timestamp.now(),
            );
            batch.set(notifRef, notif.toMap());
          }
          await batch.commit();
          debugPrint('DosenDashboardProvider: Berhasil mengirim notifikasi perubahan jadwal ke ${enrollments.length} mahasiswa.');
        }
      } catch (notifErr) {
        debugPrint('DosenDashboardProvider: Gagal mengirim notifikasi perubahan jadwal: $notifErr');
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.updateJadwal error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  // KELOLA SESI PERTEMUAN (AKTIVASI & SELESAI)
  // ─────────────────────────────────────────────────────────

  /// Buka absensi pertemuan dengan mengisi topik
  Future<bool> aktivasiPertemuan(String pertemuanId, String topik) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _pertemuanRepo.aktivasiPertemuan(pertemuanId, topik: topik);
      
      // Update tanggal pertemuan hari ini agar mahasiswa tahu tanggal presensi yang benar
      final mTime = DateTime.now();
      final tanggalStr = '${mTime.year}-${mTime.month.toString().padLeft(2, '0')}-${mTime.day.toString().padLeft(2, '0')}';
      
      await _firestore.collection('pertemuan').doc(pertemuanId).update({
        'tanggal': tanggalStr,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.aktivasiPertemuan error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tutup absensi/selesaikan pertemuan
  Future<bool> selesaikanPertemuan(String pertemuanId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _pertemuanRepo.selesaikanPertemuan(pertemuanId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.selesaikanPertemuan error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  // KELOLA ABSENSI MAHASISWA MANUAL / VALIDASI
  // ─────────────────────────────────────────────────────────

  /// Menambahkan absensi mahasiswa secara manual (jika belum check-in)
  Future<bool> addAbsensiManual(Map<String, dynamic> data) async {
    try {
      final ref = _firestore.collection('absensi').doc();
      final absensiData = Map<String, dynamic>.from(data);
      absensiData['createdAt'] = FieldValue.serverTimestamp();
      absensiData['updatedAt'] = FieldValue.serverTimestamp();
      absensiData['checkedInAt'] = FieldValue.serverTimestamp();
      absensiData['isCheckedIn'] = true;
      
      await ref.set(absensiData);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.addAbsensiManual error: $e');
      return false;
    }
  }

  /// Mengubah status kehadiran mahasiswa yang sudah melakukan absensi
  Future<bool> updateAbsensiStatus(String absensiId, String status, String keterangan) async {
    try {
      await _firestore.collection('absensi').doc(absensiId).update({
        'status': status,
        'keterangan': keterangan,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.updateAbsensiStatus error: $e');
      return false;
    }
  }

  /// Menghapus rekaman absensi agar status mahasiswa kembali menjadi 'Belum Absen' (Alpha)
  Future<bool> deleteAbsensiRecord(String absensiId) async {
    try {
      await _firestore.collection('absensi').doc(absensiId).delete();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.deleteAbsensiRecord error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // HELPER STREAMS
  // ─────────────────────────────────────────────────────────

  /// Dapatkan data realtime absensi untuk pertemuan tertentu
  Stream<QuerySnapshot<Map<String, dynamic>>> getAbsensiStream(String pertemuanId) {
    return _firestore
        .collection('absensi')
        .where('pertemuanId', isEqualTo: pertemuanId)
        .snapshots();
  }

  /// Dapatkan daftar mahasiswa terdaftar di suatu kelas
  Future<List<ClassEnrollmentModel>> getEnrollments(String kelasId) async {
    return _kelasRepo.getEnrollmentsByKelas(kelasId);
  }

  // ─── TUGAS & PENILAIAN ─────────────────────────────────────
  
  /// Membuat tugas baru untuk kelas
  Future<bool> createTugas(TugasModel model) async {
    try {
      await TugasRepository.instance.create(model);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.createTugas error: $e');
      return false;
    }
  }

  /// Menghapus tugas
  Future<bool> deleteTugas(String tugasId) async {
    try {
      await TugasRepository.instance.delete(tugasId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.deleteTugas error: $e');
      return false;
    }
  }

  /// Mengeluarkan mahasiswa dari kelas
  Future<bool> unenrollStudent(String enrollmentId, String kelasId) async {
    try {
      await _kelasRepo.unenrollMahasiswa(enrollmentId, kelasId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.unenrollStudent error: $e');
      return false;
    }
  }

  /// Menilai submisi tugas mahasiswa dan memperbarui data nilai akhir
  Future<bool> gradeSubmission({
    required String submissionId,
    required String studentId,
    required String studentNama,
    required String kelasId,
    required String tugasId,
    required double nilai,
    required String feedback,
    required KelasModel kelas,
  }) async {
    try {
      // 1. Perbarui submisi di koleksi 'submissions'
      await _firestore.collection('submissions').doc(submissionId).update({
        'nilai': nilai,
        'feedback': feedback,
        'isGraded': true,
        'gradedAt': FieldValue.serverTimestamp(),
      });

      // 2. Ambil semua tugas di kelas ini
      final assignmentsSnap = await _firestore
          .collection('tugas')
          .where('kelasId', isEqualTo: kelasId)
          .get();
      final assignmentIds = assignmentsSnap.docs.map((doc) => doc.id).toList();

      // 3. Hitung rata-rata nilai tugas & praktikum tergradasi siswa di kelas ini
      double totalTugas = 0.0;
      int countTugas = 0;
      double totalPraktikum = 0.0;
      int countPraktikum = 0;

      final assignments = assignmentsSnap.docs
          .map((d) => TugasModel.fromMap(d.id, d.data()))
          .toList();

      if (assignments.isNotEmpty) {
        final submissionsSnap = await _firestore
            .collection('submissions')
            .where('mahasiswaId', isEqualTo: studentId)
            .where('tugasId', whereIn: assignmentIds)
            .get();

        final submissions = submissionsSnap.docs
            .map((d) => SubmisiModel.fromMap(d.id, d.data()))
            .toList();

        for (final t in assignments) {
          final subIdx = submissions.indexWhere((s) => s.tugasId == t.id);
          final sub = subIdx != -1 ? submissions[subIdx] : null;
          final double grade = (sub != null && sub.isGraded) ? (sub.nilai ?? 0.0) : 0.0;

          final judulLower = t.judul.toLowerCase();
          final deskripsiLower = t.deskripsi.toLowerCase();

          // Klasifikasikan berdasarkan judul & deskripsi
          if (judulLower.contains('laporan') ||
              judulLower.contains('lp') ||
              deskripsiLower.contains('laporan') ||
              judulLower.contains('tp') ||
              judulLower.contains('praktikum')) {
            totalPraktikum += grade;
            countPraktikum++;
          } else {
            totalTugas += grade;
            countTugas++;
          }
        }
      }

      final double avgTugas = countTugas > 0 ? totalTugas / countTugas : nilai;
      final double avgPraktikum = countPraktikum > 0 ? totalPraktikum / countPraktikum : 0.0;

      // 4. Hitung persentase kehadiran mahasiswa di kelas ini
      final double attendancePct = await _calculateAttendancePercentage(studentId, kelasId);

      // 5. Cari rekap NilaiModel di koleksi 'nilai'
      final nilaiSnap = await _firestore
          .collection('nilai')
          .where('mahasiswaId', isEqualTo: studentId)
          .where('kelasId', isEqualTo: kelasId)
          .limit(1)
          .get();

      final double tugasWeight = kelas.bobotTugas / 100.0;
      final double utsWeight = kelas.bobotUTS / 100.0;
      final double uasWeight = kelas.bobotUAS / 100.0;
      final double absensiWeight = kelas.bobotAbsensi / 100.0;
      final double quizWeight = kelas.bobotQuiz / 100.0;
      final double praktikumWeight = kelas.bobotPraktikum / 100.0;
      final double laporanWeight = kelas.bobotLaporan / 100.0;
      final double lainWeight = kelas.bobotLain / 100.0;

      if (nilaiSnap.docs.isNotEmpty) {
        final docId = nilaiSnap.docs.first.id;
        final existingNilai = NilaiModel.fromMap(docId, nilaiSnap.docs.first.data());

        final double finalGrade = (attendancePct * absensiWeight) +
            (avgTugas * tugasWeight) +
            (existingNilai.nilaiUTS * utsWeight) +
            (existingNilai.nilaiUAS * uasWeight) +
            (existingNilai.nilaiQuiz * quizWeight) +
            (avgPraktikum * praktikumWeight) +
            (existingNilai.nilaiLaporan * laporanWeight) +
            (existingNilai.nilaiLain * lainWeight);

        final String gradeLetter = NilaiModel.bobotFromNilai(finalGrade);
        final double gradeBobot = NilaiModel.bobotFromHuruf(gradeLetter);

        await _firestore.collection('nilai').doc(docId).update({
          'nilaiTugas': avgTugas,
          'nilaiPraktikum': avgPraktikum,
          'nilaiAkhir': finalGrade,
          'huruf': gradeLetter,
          'bobot': gradeBobot,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Buat rekap nilai baru
        final ref = _firestore.collection('nilai').doc();
        
        final double finalGrade = (attendancePct * absensiWeight) +
            (avgTugas * tugasWeight) +
            (avgPraktikum * praktikumWeight);
        final String gradeLetter = NilaiModel.bobotFromNilai(finalGrade);
        final double gradeBobot = NilaiModel.bobotFromHuruf(gradeLetter);

        final newNilai = NilaiModel(
          id: ref.id,
          kelasId: kelasId,
          matakuliahId: kelas.matakuliahId,
          matakuliahNama: kelas.matakuliahNama,
          matakuliahKode: kelas.matakuliahKode,
          sks: 3, // Default SKS
          mahasiswaId: studentId,
          semesterId: kelas.semesterId,
          semesterNama: kelas.semesterNama,
          nilaiTugas: avgTugas,
          nilaiUTS: 0.0,
          nilaiUAS: 0.0,
          nilaiQuiz: 0.0,
          nilaiPraktikum: avgPraktikum,
          nilaiLaporan: 0.0,
          nilaiLain: 0.0,
          nilaiAbsensi: attendancePct,
          nilaiAkhir: finalGrade,
          huruf: gradeLetter,
          bobot: gradeBobot,
          updatedAt: Timestamp.now(),
        );
        await ref.set(newNilai.toMap());
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.gradeSubmission error: $e');
      return false;
    }
  }

  /// Hitung persentase kehadiran mahasiswa di suatu kelas
  Future<double> _calculateAttendancePercentage(String studentId, String kelasId) async {
    try {
      // 1. Tentukan target pertemuan berdasarkan jenis kelas (Teori: 16, Praktikum: 8)
      int totalTarget = 16;
      final kelasDoc = await _firestore.collection('kelas').doc(kelasId).get();
      if (kelasDoc.exists) {
        final data = kelasDoc.data()!;
        final asdosIds = List<String>.from(data['asdosIds'] ?? []);
        
        final schedulesSnap = await _firestore
            .collection('jadwal')
            .where('kelasId', isEqualTo: kelasId)
            .get();
        final schedules = schedulesSnap.docs.map((d) => d.data()['jenisSesi'] ?? '').toList();
        
        final isPraktikum = asdosIds.isNotEmpty || 
            schedules.any((jenis) => jenis.toString().toLowerCase().contains('prak'));
        
        totalTarget = isPraktikum ? 8 : 16;
      }

      // 2. Ambil pertemuan yang sudah selesai
      final meetingsSnap = await _firestore
          .collection('pertemuan')
          .where('kelasId', isEqualTo: kelasId)
          .where('status', isEqualTo: 'selesai')
          .get();
      
      if (meetingsSnap.docs.isEmpty) return 0.0;
      
      final meetingIds = meetingsSnap.docs.map((doc) => doc.id).toList();
      
      // 3. Ambil data absensi mahasiswa untuk pertemuan tersebut
      final attendancesSnap = await _firestore
          .collection('absensi')
          .where('mahasiswaId', isEqualTo: studentId)
          .where('pertemuanId', whereIn: meetingIds)
          .get();
          
      int presentCount = 0;
      for (final doc in attendancesSnap.docs) {
        final status = doc.data()['status'];
        if (status == 'hadir' || status == 'terlambat') {
          presentCount++;
        }
      }
      
      final double pct = (presentCount / totalTarget) * 100.0;
      return pct > 100.0 ? 100.0 : pct;
    } catch (e) {
      debugPrint('Error _calculateAttendancePercentage: $e');
      return 0.0;
    }
  }

  /// Wrapper publik untuk menghitung persentase kehadiran mahasiswa
  Future<double> calculateAttendancePercentage(String studentId, String kelasId) async {
    return _calculateAttendancePercentage(studentId, kelasId);
  }

  /// Menghitung nilai otomatis (Tugas, Laporan LP, Praktikum TP) dari data submisi di Firestore
  Future<Map<String, double>> calculateAutomaticGrades({
    required String studentId,
    required String kelasId,
  }) async {
    final Map<String, double> result = {
      'tugas': 0.0,
      'laporan': 0.0,
      'praktikum': 0.0,
    };

    try {
      // 1. Ambil semua tugas di kelas ini
      final tugasSnap = await _firestore
          .collection('tugas')
          .where('kelasId', isEqualTo: kelasId)
          .get();

      final assignments = tugasSnap.docs
          .map((d) => TugasModel.fromMap(d.id, d.data()))
          .toList();

      if (assignments.isEmpty) return result;

      final assignmentIds = assignments.map((t) => t.id).toList();

      // 2. Ambil seluruh submisi mahasiswa untuk tugas-tugas tersebut
      final submissionsSnap = await _firestore
          .collection('submissions')
          .where('mahasiswaId', isEqualTo: studentId)
          .where('tugasId', whereIn: assignmentIds)
          .get();

      final submissions = submissionsSnap.docs
          .map((d) => SubmisiModel.fromMap(d.id, d.data()))
          .toList();

      double totalTugas = 0.0;
      int countTugas = 0;

      double totalPraktikum = 0.0;
      int countPraktikum = 0;

      for (final t in assignments) {
        final subIdx = submissions.indexWhere((s) => s.tugasId == t.id);
        final sub = subIdx != -1 ? submissions[subIdx] : null;

        // Gunakan nilai jika tergradasi, default ke 0.0 jika tidak ada submisi/belum dinilai
        final double grade = (sub != null && sub.isGraded) ? (sub.nilai ?? 0.0) : 0.0;

        final judulLower = t.judul.toLowerCase();
        final deskripsiLower = t.deskripsi.toLowerCase();

        // Klasifikasikan berdasarkan judul & deskripsi
        if (judulLower.contains('laporan') ||
            judulLower.contains('lp') ||
            deskripsiLower.contains('laporan') ||
            judulLower.contains('tp') ||
            judulLower.contains('praktikum')) {
          totalPraktikum += grade;
          countPraktikum++;
        } else {
          totalTugas += grade;
          countTugas++;
        }
      }

      result['tugas'] = countTugas > 0 ? totalTugas / countTugas : 0.0;
      result['laporan'] = 0.0; // Digabung ke Praktikum
      result['praktikum'] = countPraktikum > 0 ? totalPraktikum / countPraktikum : 0.0;
    } catch (e) {
      debugPrint('Error calculateAutomaticGrades: $e');
    }

    return result;
  }

  /// Update bobot penilaian kelas berdasarkan scope
  Future<bool> updateKelasBobot({
    required String kelasId,
    required String dosenId,
    required String matakuliahKode,
    required int absensi,
    required int tugas,
    required int uts,
    required int uas,
    required int quiz,
    required int praktikum,
    required int laporan,
    required int lain,
    required String scope,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final updates = {
        'bobotAbsensi': absensi,
        'bobotTugas': tugas,
        'bobotUTS': uts,
        'bobotUAS': uas,
        'bobotQuiz': quiz,
        'bobotPraktikum': praktikum,
        'bobotLaporan': laporan,
        'bobotLain': lain,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (scope == 'kelas') {
        final ref = _firestore.collection('kelas').doc(kelasId);
        batch.update(ref, updates);
      } else if (scope == 'matakuliah') {
        final snap = await _firestore
            .collection('kelas')
            .where('dosenId', isEqualTo: dosenId)
            .where('matakuliahKode', isEqualTo: matakuliahKode)
            .get();
        for (final doc in snap.docs) {
          batch.update(doc.reference, updates);
        }
      } else if (scope == 'semua_teori') {
        final snap = await _firestore
            .collection('kelas')
            .where('dosenId', isEqualTo: dosenId)
            .get();
        for (final doc in snap.docs) {
          final hasP = _schedules.any((s) => s.kelasId == doc.id && s.jenisSesi == 'praktikum');
          if (!hasP) {
            batch.update(doc.reference, updates);
          }
        }
      } else if (scope == 'semua_praktikum') {
        final snap = await _firestore
            .collection('kelas')
            .where('dosenId', isEqualTo: dosenId)
            .get();
        for (final doc in snap.docs) {
          final hasP = _schedules.any((s) => s.kelasId == doc.id && s.jenisSesi == 'praktikum');
          if (hasP) {
            batch.update(doc.reference, updates);
          }
        }
      } else {
        final snap = await _firestore
            .collection('kelas')
            .where('dosenId', isEqualTo: dosenId)
            .get();
        for (final doc in snap.docs) {
          batch.update(doc.reference, updates);
        }
      }

      await batch.commit();

      // Reload data kelas setelah bobot diperbarui
      final authDosenNama = _kelasList.isNotEmpty ? _kelasList.first.dosenNama : '';
      await loadSchedules(dosenId, authDosenNama);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.updateKelasBobot error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menyimpan atau meng-update NilaiModel di Firestore
  Future<bool> saveNilai(NilaiModel nilai) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore.collection('nilai').doc(nilai.id).set(
            nilai.toMap(),
            SetOptions(merge: true),
          );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.saveNilai error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inisialisasi/generate pertemuan jika kosong disisi dosen
  Future<bool> generateMeetingsForJadwal(JadwalModel jadwal) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ambil Kelas dari database
      final doc = await _firestore.collection('kelas').doc(jadwal.kelasId).get();
      if (!doc.exists) {
        throw Exception('Data kelas untuk jadwal ini tidak ditemukan.');
      }
      final kelas = KelasModel.fromMap(doc.id, doc.data()!);

      // 2. Generate Pertemuan menggunakan PertemuanRepository
      await _pertemuanRepo.generatePertemuan(
        jadwalId: jadwal.id,
        kelas: kelas,
        jadwal: jadwal,
      );

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DosenDashboardProvider.generateMeetingsForJadwal error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
