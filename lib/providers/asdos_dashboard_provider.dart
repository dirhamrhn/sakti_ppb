import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/kelas_model.dart';
import '../models/jadwal_model.dart';
import '../models/pertemuan_model.dart';
import '../models/nilai_model.dart';
import '../models/tugas_model.dart';
import '../models/class_enrollment_model.dart';
import '../repositories/storage_repository.dart';

class AsdosDashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<KelasModel> _kelasList = [];
  List<JadwalModel> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<KelasModel> get kelasList => _kelasList;
  List<JadwalModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Home Stats
  int _totalKelas = 0;
  int _totalMahasiswa = 0;
  int _totalBelumDinilai = 0;

  int get totalKelas => _totalKelas;
  int get totalMahasiswa => _totalMahasiswa;
  int get totalBelumDinilai => _totalBelumDinilai;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Load all data relevant to Assistant Lecturer
  Future<void> loadAllData(String asdosUid) async {
    _setLoading(true);
    try {
      // 1. Load assisted classes
      final classesSnap = await _firestore
          .collection('kelas')
          .where('asdosIds', arrayContains: asdosUid)
          .get();

      _kelasList = classesSnap.docs
          .map((d) => KelasModel.fromMap(d.id, d.data()))
          .toList();

      _totalKelas = _kelasList.length;

      if (_kelasList.isNotEmpty) {
        final classIds = _kelasList.map((k) => k.id).toList();

        // 2. Load schedules
        final schedulesSnap = await _firestore
            .collection('jadwal')
            .where('kelasId', whereIn: classIds)
            .get();

        _schedules = schedulesSnap.docs
            .map((d) => JadwalModel.fromMap(d.id, d.data()))
            .toList();

        // 3. Load students count
        final enrollmentsSnap = await _firestore
            .collection('class_enrollments')
            .where('kelasId', whereIn: classIds)
            .get();
        
        final enrollments = enrollmentsSnap.docs
            .map((d) => ClassEnrollmentModel.fromMap(d.id, d.data()))
            .toList();
        
        final uniqueStudentIds = enrollments.map((e) => e.mahasiswaId).toSet();
        _totalMahasiswa = uniqueStudentIds.length;

        // 4. Load tasks & submissions to check for graded counts
        final tugasSnap = await _firestore
            .collection('tugas')
            .where('kelasId', whereIn: classIds)
            .get();
        
        final tasks = tugasSnap.docs
            .map((d) => TugasModel.fromMap(d.id, d.data()))
            .toList();

        if (tasks.isNotEmpty) {
          final taskIds = tasks.map((t) => t.id).toList();
          final submissionsSnap = await _firestore
              .collection('submissions')
              .where('tugasId', whereIn: taskIds)
              .where('isGraded', isEqualTo: false)
              .get();
          
          _totalBelumDinilai = submissionsSnap.docs.length;
        } else {
          _totalBelumDinilai = 0;
        }
      } else {
        _schedules = [];
        _totalMahasiswa = 0;
        _totalBelumDinilai = 0;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.loadAllData error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update schedule configuration
  Future<bool> updateJadwal(JadwalModel updated) async {
    try {
      await _firestore.collection('jadwal').doc(updated.id).update(updated.toMap());
      final idx = _schedules.indexWhere((s) => s.id == updated.id);
      if (idx != -1) {
        _schedules[idx] = updated;
        notifyListeners();
      }

      // Kirim notifikasi ke semua mahasiswa terdaftar di kelas
      try {
        final snap = await _firestore
            .collection('class_enrollments')
            .where('kelasId', isEqualTo: updated.kelasId)
            .get();
        final enrollments = snap.docs
            .map((d) => ClassEnrollmentModel.fromMap(d.id, d.data()))
            .toList();
            
        if (enrollments.isNotEmpty) {
          final batch = _firestore.batch();
          for (final enrollment in enrollments) {
            final notifRef = _firestore.collection('notifications').doc();
            final notif = NotifikasiModel(
              id: notifRef.id,
              userId: enrollment.mahasiswaId,
              judul: 'Perubahan Jadwal Kuliah',
              pesan: 'Jadwal kuliah ${updated.matakuliahNama} (${updated.jenisSesi == "praktikum" ? "Praktikum" : "Teori"}) diubah menjadi hari ${updated.hari}, pukul ${updated.jamMulai} - ${updated.jamSelesai}.',
              tipe: 'sistem',
              referenceId: updated.id,
              isRead: false,
              createdAt: Timestamp.now(),
            );
            batch.set(notifRef, notif.toMap());
          }
          await batch.commit();
          debugPrint('AsdosDashboardProvider: Berhasil mengirim notifikasi perubahan jadwal ke ${enrollments.length} mahasiswa.');
        }
      } catch (notifErr) {
        debugPrint('AsdosDashboardProvider: Gagal mengirim notifikasi perubahan jadwal: $notifErr');
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.updateJadwal error: $e');
      return false;
    }
  }

  /// Generate 8 meetings for a practical schedule
  Future<bool> generateMeetingsForJadwal(JadwalModel jadwal) async {
    _setLoading(true);
    try {
      final doc = await _firestore.collection('kelas').doc(jadwal.kelasId).get();
      if (!doc.exists) {
        throw Exception('Data kelas tidak ditemukan.');
      }
      final kelas = KelasModel.fromMap(doc.id, doc.data()!);

      // Check existing meetings first to prevent duplicates
      final existingSnap = await _firestore
          .collection('pertemuan')
          .where('jadwalId', isEqualTo: jadwal.id)
          .get();

      final existingPertemuanKe = existingSnap.docs
          .map((d) => d.data()['pertemuanKe'] as int?)
          .whereType<int>()
          .toSet();

      final batch = _firestore.batch();
      bool hasNew = false;

      for (int i = 1; i <= 8; i++) {
        if (!existingPertemuanKe.contains(i)) {
          final ref = _firestore.collection('pertemuan').doc();
          final pertemuan = PertemuanModel(
            id: ref.id,
            jadwalId: jadwal.id,
            kelasId: kelas.id,
            kelasNama: kelas.namaKelas,
            matakuliahId: kelas.matakuliahId,
            matakuliahNama: kelas.matakuliahNama,
            matakuliahKode: kelas.matakuliahKode,
            jenisSesi: 'praktikum',
            pertemuanKe: i,
            tanggal: '',
            topik: 'Praktikum Pertemuan $i',
            status: 'belum',
            qrCode: '',
            isAbsensiOpen: false,
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          );
          batch.set(ref, {
            ...pertemuan.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          hasNew = true;
        }
      }

      if (hasNew) {
        await batch.commit();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.generateMeetingsForJadwal error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Start a meeting/session and open attendance
  Future<bool> aktivasiPertemuan(String id, String topik) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await _firestore.collection('pertemuan').doc(id).update({
        'status': 'aktif',
        'isAbsensiOpen': true,
        'tanggal': dateStr,
        'topik': topik,
        'absensiOpenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.aktivasiPertemuan error: $e');
      return false;
    }
  }

  /// Close meeting/session
  Future<bool> selesaikanPertemuan(String id) async {
    try {
      await _firestore.collection('pertemuan').doc(id).update({
        'status': 'selesai',
        'isAbsensiOpen': false,
        'absensiCloseAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.selesaikanPertemuan error: $e');
      return false;
    }
  }

  /// Delete attendance record
  Future<bool> deleteAbsensiRecord(String id) async {
    try {
      await _firestore.collection('absensi').doc(id).delete();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.deleteAbsensiRecord error: $e');
      return false;
    }
  }

  /// Update attendance status manually
  Future<bool> updateAbsensiStatus(String id, String status, String keterangan) async {
    try {
      await _firestore.collection('absensi').doc(id).update({
        'status': status,
        'keterangan': keterangan,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.updateAbsensiStatus error: $e');
      return false;
    }
  }

  /// Add manual attendance record
  Future<bool> addAbsensiManual(Map<String, dynamic> data) async {
    try {
      final ref = _firestore.collection('absensi').doc();
      await ref.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.addAbsensiManual error: $e');
      return false;
    }
  }

  /// Remove student from class
  Future<bool> unenrollStudent(String enrollmentId, String kelasId) async {
    try {
      // Delete the class enrollment
      await _firestore.collection('class_enrollments').doc(enrollmentId).delete();

      // Decrement the student count in class
      await _firestore.collection('kelas').doc(kelasId).update({
        'jumlahMahasiswa': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.unenrollStudent error: $e');
      return false;
    }
  }

  /// Upload file modul praktikum
  Future<String> uploadModulFile(File file, String kelasId, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'materials/$kelasId/${timestamp}_$fileName';
    return await StorageRepository.instance.uploadFile(file: file, path: path);
  }

  /// Recalculate student grades for a class
  Future<void> recalculateStudentGrades({
    required String studentId,
    required String studentNama,
    required String studentNim,
    required KelasModel kelas,
  }) async {
    try {
      // 1. Calculate attendance percentage from meetings
      final meetingsSnap = await _firestore
          .collection('pertemuan')
          .where('kelasId', isEqualTo: kelas.id)
          .where('status', isEqualTo: 'selesai')
          .get();

      double attendancePct = 0.0;
      if (meetingsSnap.docs.isNotEmpty) {
        final meetingIds = meetingsSnap.docs.map((doc) => doc.id).toList();
        final absensiSnap = await _firestore
            .collection('absensi')
            .where('mahasiswaId', isEqualTo: studentId)
            .where('pertemuanId', whereIn: meetingIds)
            .get();

        int presentCount = 0;
        for (final doc in absensiSnap.docs) {
          final status = doc.data()['status'];
          if (status == 'hadir' || status == 'terlambat') {
            presentCount++;
          }
        }
        // Total meetings for practical is 8
        attendancePct = (presentCount / 8) * 100.0;
        if (attendancePct > 100.0) attendancePct = 100.0;
      }

      // 2. Fetch all assignments
      final tugasSnap = await _firestore
          .collection('tugas')
          .where('kelasId', isEqualTo: kelas.id)
          .get();
      final tasks = tugasSnap.docs.map((d) => TugasModel.fromMap(d.id, d.data())).toList();

      double totalLp = 0.0;
      int countLp = 0;
      double totalTp = 0.0;
      int countTp = 0;

      if (tasks.isNotEmpty) {
        final taskIds = tasks.map((t) => t.id).toList();
        final submissionsSnap = await _firestore
            .collection('submissions')
            .where('mahasiswaId', isEqualTo: studentId)
            .where('tugasId', whereIn: taskIds)
            .get();
        final submissions = submissionsSnap.docs.map((d) => SubmisiModel.fromMap(d.id, d.data())).toList();

        for (final t in tasks) {
          final subIdx = submissions.indexWhere((s) => s.tugasId == t.id);
          final sub = subIdx != -1 ? submissions[subIdx] : null;
          final double grade = (sub != null && sub.isGraded) ? (sub.nilai ?? 0.0) : 0.0;

          if (t.tipe == 'lp') {
            totalLp += grade;
            countLp++;
          } else if (t.tipe == 'tp') {
            totalTp += grade;
            countTp++;
          }
        }
      }

      final double avgLp = countLp > 0 ? totalLp / countLp : 0.0;
      final double avgTp = countTp > 0 ? totalTp / countTp : 0.0;

      // 3. Fetch existing Nilai doc
      final nilaiSnap = await _firestore
          .collection('nilai')
          .where('mahasiswaId', isEqualTo: studentId)
          .where('kelasId', isEqualTo: kelas.id)
          .limit(1)
          .get();

      bool isLpOverridden = false;
      bool isTpOverridden = false;
      bool isAbsensiOverridden = false;
      double lpManual = 0.0;
      double tpManual = 0.0;
      double absManual = 0.0;
      double nilaiQuiz = 0.0;
      double nilaiPraktikum = 0.0;
      double existingUts = 0.0;
      double existingUas = 0.0;
      double existingLain = 0.0;

      NilaiModel? existingNilai;
      String docId = _firestore.collection('nilai').doc().id;

      if (nilaiSnap.docs.isNotEmpty) {
        docId = nilaiSnap.docs.first.id;
        existingNilai = NilaiModel.fromMap(docId, nilaiSnap.docs.first.data());
        isLpOverridden = existingNilai.isLpOverridden;
        isTpOverridden = existingNilai.isTpOverridden;
        isAbsensiOverridden = existingNilai.isAbsensiOverridden;
        lpManual = existingNilai.nilaiLaporanManual;
        tpManual = existingNilai.nilaiTugasManual;
        absManual = existingNilai.nilaiAbsensiManual;
        nilaiQuiz = existingNilai.nilaiQuiz;
        nilaiPraktikum = existingNilai.nilaiPraktikum;
        existingUts = existingNilai.nilaiUTS;
        existingUas = existingNilai.nilaiUAS;
        existingLain = existingNilai.nilaiLain;
      }

      final double finalLp = isLpOverridden ? lpManual : avgLp;
      final double finalTp = isTpOverridden ? tpManual : avgTp;
      final double finalAbs = isAbsensiOverridden ? absManual : attendancePct;

      // Calculate final grade
      final double finalGrade = (finalAbs * (kelas.bobotAbsensi / 100.0)) +
          (finalLp * (kelas.bobotLaporan / 100.0)) +
          (finalTp * (kelas.bobotTugas / 100.0)) +
          (nilaiQuiz * (kelas.bobotQuiz / 100.0)) +
          (nilaiPraktikum * (kelas.bobotPraktikum / 100.0));

      final String gradeLetter = NilaiModel.bobotFromNilai(finalGrade);
      final double gradeBobot = NilaiModel.bobotFromHuruf(gradeLetter);

      final finalMap = {
        'kelasId': kelas.id,
        'matakuliahId': kelas.matakuliahId,
        'matakuliahNama': kelas.matakuliahNama,
        'matakuliahKode': kelas.matakuliahKode,
        'sks': 3,
        'mahasiswaId': studentId,
        'mahasiswaNama': studentNama,
        'semesterId': kelas.semesterId,
        'semesterNama': kelas.semesterNama,
        'nilaiTugas': finalTp, // mapped as TP in practical
        'nilaiLaporan': finalLp, // mapped as LP in practical
        'nilaiAbsensi': finalAbs,
        'nilaiQuiz': nilaiQuiz,
        'nilaiPraktikum': nilaiPraktikum,
        'nilaiUTS': existingUts,
        'nilaiUAS': existingUas,
        'nilaiLain': existingLain,
        'nilaiAkhir': finalGrade,
        'huruf': gradeLetter,
        'bobot': gradeBobot,
        'isLpOverridden': isLpOverridden,
        'isTpOverridden': isTpOverridden,
        'isAbsensiOverridden': isAbsensiOverridden,
        'nilaiLaporanManual': lpManual,
        'nilaiTugasManual': tpManual,
        'nilaiAbsensiManual': absManual,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('nilai').doc(docId).set(finalMap, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error recalculating student grades: $e');
    }
  }

  /// Grade a submission and trigger recalculation
  Future<bool> gradeSubmission({
    required String submissionId,
    required String studentId,
    required String studentNama,
    required String studentNim,
    required String kelasId,
    required String tugasId,
    required double nilai,
    required String feedback,
    required KelasModel kelas,
  }) async {
    try {
      await _firestore.collection('submissions').doc(submissionId).update({
        'nilai': nilai,
        'feedback': feedback,
        'isGraded': true,
        'gradedAt': FieldValue.serverTimestamp(),
      });

      await recalculateStudentGrades(
        studentId: studentId,
        studentNama: studentNama,
        studentNim: studentNim,
        kelas: kelas,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.gradeSubmission error: $e');
      return false;
    }
  }

  /// Update weights for a class or multiple classes
  Future<bool> updateKelasBobot({
    required String kelasId,
    required String asdosId,
    required String matakuliahKode,
    required int kehadiran,
    required int lp,
    required int tp,
    required int quiz,
    required int praktikum,
    required String scope, // 'kelas', 'matakuliah', 'semua'
  }) async {
    _setLoading(true);
    try {
      final batch = _firestore.batch();
      final updates = {
        'bobotAbsensi': kehadiran,
        'bobotLaporan': lp, // LP
        'bobotTugas': tp,   // TP
        'bobotQuiz': quiz,  // Keaktifan
        'bobotPraktikum': praktikum, // Final Praktikum
        // set other weights to 0 for practical
        'bobotUTS': 0,
        'bobotUAS': 0,
        'bobotLain': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (scope == 'kelas') {
        final ref = _firestore.collection('kelas').doc(kelasId);
        batch.update(ref, updates);
      } else if (scope == 'matakuliah') {
        final snap = await _firestore
            .collection('kelas')
            .where('asdosIds', arrayContains: asdosId)
            .where('matakuliahKode', isEqualTo: matakuliahKode)
            .get();
        for (final doc in snap.docs) {
          batch.update(doc.reference, updates);
        }
      } else {
        // semua kelas yang diampu asdos ini
        final snap = await _firestore
            .collection('kelas')
            .where('asdosIds', arrayContains: asdosId)
            .get();
        for (final doc in snap.docs) {
          batch.update(doc.reference, updates);
        }
      }

      await batch.commit();

      // Recalculate grades for all students in these classes to apply new weights
      if (scope == 'kelas') {
        await _recalculateAllStudentsInClass(kelasId);
      } else if (scope == 'matakuliah') {
        final snap = await _firestore
            .collection('kelas')
            .where('asdosIds', arrayContains: asdosId)
            .where('matakuliahKode', isEqualTo: matakuliahKode)
            .get();
        for (final doc in snap.docs) {
          await _recalculateAllStudentsInClass(doc.id);
        }
      } else {
        final snap = await _firestore
            .collection('kelas')
            .where('asdosIds', arrayContains: asdosId)
            .get();
        for (final doc in snap.docs) {
          await _recalculateAllStudentsInClass(doc.id);
        }
      }

      // Reload
      await loadAllData(asdosId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.updateKelasBobot error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _recalculateAllStudentsInClass(String kelasId) async {
    final kelasDoc = await _firestore.collection('kelas').doc(kelasId).get();
    if (!kelasDoc.exists) return;
    final kelas = KelasModel.fromMap(kelasDoc.id, kelasDoc.data()!);

    final enrollmentsSnap = await _firestore
        .collection('class_enrollments')
        .where('kelasId', isEqualTo: kelasId)
        .get();

    for (final doc in enrollmentsSnap.docs) {
      final enrollment = ClassEnrollmentModel.fromMap(doc.id, doc.data());
      await recalculateStudentGrades(
        studentId: enrollment.mahasiswaId,
        studentNama: enrollment.mahasiswaNama,
        studentNim: enrollment.mahasiswaNim,
        kelas: kelas,
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // ASDOS CRUD TUGAS (LP/TP) & MODUL
  // ─────────────────────────────────────────────────────────

  Future<bool> createTugas({
    required TugasModel tugas,
    File? file,
    String? fileName,
  }) async {
    _setLoading(true);
    try {
      String fileUrl = '';
      String finalFileName = '';

      if (file != null && fileName != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'tugas/${tugas.kelasId}/${timestamp}_$fileName';
        fileUrl = await StorageRepository.instance.uploadFile(file: file, path: path);
        finalFileName = fileName;
      }

      final ref = _firestore.collection('tugas').doc();
      final updatedTugas = tugas.copyWith(
        id: ref.id,
        fileUrl: fileUrl,
        fileName: finalFileName,
        fileSize: file != null ? file.lengthSync() : 0,
        fileType: file != null ? fileName!.split('.').last.toLowerCase() : '',
        uploadedAt: file != null ? Timestamp.now() : null,
        uploadedBy: file != null ? (FirebaseAuth.instance.currentUser?.uid ?? '') : '',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      await ref.set({
        ...updatedTugas.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.createTugas error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTugas(
    TugasModel tugas, {
    File? file,
    String? fileName,
    bool removeFile = false,
  }) async {
    _setLoading(true);
    try {
      TugasModel updatedTugas = tugas;

      if (removeFile) {
        updatedTugas = updatedTugas.copyWith(
          fileUrl: '',
          fileName: '',
          fileSize: 0,
          fileType: '',
          uploadedAt: null,
          uploadedBy: '',
        );
      } else if (file != null && fileName != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'tugas/${tugas.kelasId}/${timestamp}_$fileName';
        final fileUrl = await StorageRepository.instance.uploadFile(file: file, path: path);
        updatedTugas = updatedTugas.copyWith(
          fileUrl: fileUrl,
          fileName: fileName,
          fileSize: file.lengthSync(),
          fileType: fileName.split('.').last.toLowerCase(),
          uploadedAt: Timestamp.now(),
          uploadedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
        );
      }

      updatedTugas = updatedTugas.copyWith(updatedAt: Timestamp.now());
      await _firestore.collection('tugas').doc(tugas.id).update({
        ...updatedTugas.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.updateTugas error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTugas(String id) async {
    _setLoading(true);
    try {
      await _firestore.collection('tugas').doc(id).delete();
      // Remove related submissions
      final subSnap = await _firestore.collection('submissions').where('tugasId', isEqualTo: id).get();
      final batch = _firestore.batch();
      for (final doc in subSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.deleteTugas error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleTugasOpen(String id, bool isOpen) async {
    try {
      await _firestore.collection('tugas').doc(id).update({
        'isOpen': isOpen,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.toggleTugasOpen error: $e');
      return false;
    }
  }

  Future<bool> createModul({
    required String kelasId,
    required int modulKe,
    required String judul,
    required String deskripsi,
    required File file,
    required String fileName,
  }) async {
    _setLoading(true);
    try {
      final fileUrl = await uploadModulFile(file, kelasId, fileName);
      final ref = _firestore.collection('modul_praktikum').doc();
      await ref.set({
        'kelasId': kelasId,
        'modulKe': modulKe,
        'judul': judul,
        'deskripsi': deskripsi,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': file.lengthSync(),
        'fileType': fileName.split('.').last.toLowerCase(),
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.createModul error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateModul({
    required String id,
    required String kelasId,
    required String judul,
    required String deskripsi,
    File? file,
    String? fileName,
  }) async {
    _setLoading(true);
    try {
      final updates = <String, dynamic>{
        'judul': judul,
        'deskripsi': deskripsi,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (file != null && fileName != null) {
        final fileUrl = await uploadModulFile(file, kelasId, fileName);
        updates['fileUrl'] = fileUrl;
        updates['fileName'] = fileName;
        updates['fileSize'] = file.lengthSync();
        updates['fileType'] = fileName.split('.').last.toLowerCase();
        updates['uploadedAt'] = FieldValue.serverTimestamp();
        updates['uploadedBy'] = FirebaseAuth.instance.currentUser?.uid ?? '';
      }

      await _firestore.collection('modul_praktikum').doc(id).update(updates);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.updateModul error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteModul(String id) async {
    _setLoading(true);
    try {
      await _firestore.collection('modul_praktikum').doc(id).delete();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AsdosDashboardProvider.deleteModul error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
