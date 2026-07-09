import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/kelas_model.dart';
import '../models/class_enrollment_model.dart';
import '../models/mahasiswa_model.dart';

class KelasRepository {
  KelasRepository._();
  static final KelasRepository instance = KelasRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'kelas';
  static const String _enrollmentCollection = 'class_enrollments';

  // ────────────────────────────────────────────────────────────
  // KELAS CRUD
  // ────────────────────────────────────────────────────────────

  Future<List<KelasModel>> getAll() async {
    final snap = await _firestore
        .collection(_collection)
        .orderBy('matakuliahNama')
        .get();
    return snap.docs.map((d) => KelasModel.fromMap(d.id, d.data())).toList();
  }

  Future<KelasModel?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return KelasModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> create(KelasModel model) async {
    final data = model.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection(_collection).add(data);
    return ref.id;
  }

  Future<void> update(KelasModel model) async {
    final batch = _firestore.batch();
    
    // 1. Update kelas
    final classRef = _firestore.collection(_collection).doc(model.id);
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    batch.update(classRef, data);

    // 2. Cascade ke Jadwal (collection: 'jadwal')
    final schedulesSnap = await _firestore
        .collection('jadwal')
        .where('kelasId', isEqualTo: model.id)
        .get();
    for (final doc in schedulesSnap.docs) {
      batch.update(doc.reference, {
        'kelasNama': model.namaKelas,
        'matakuliahId': model.matakuliahId,
        'matakuliahNama': model.matakuliahNama,
        'matakuliahKode': model.matakuliahKode,
        'dosenNama': model.dosenNama,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Cascade ke Pertemuan (collection: 'pertemuan')
    final meetingsSnap = await _firestore
        .collection('pertemuan')
        .where('kelasId', isEqualTo: model.id)
        .get();
    for (final doc in meetingsSnap.docs) {
      batch.update(doc.reference, {
        'kelasNama': model.namaKelas,
        'matakuliahId': model.matakuliahId,
        'matakuliahNama': model.matakuliahNama,
        'matakuliahKode': model.matakuliahKode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 4. Cascade ke Enrollments (collection: 'class_enrollments')
    final enrollmentsSnap = await _firestore
        .collection(_enrollmentCollection)
        .where('kelasId', isEqualTo: model.id)
        .get();
    for (final doc in enrollmentsSnap.docs) {
      batch.update(doc.reference, {
        'kelasNama': model.namaKelas,
        'matakuliahNama': model.matakuliahNama,
      });
    }

    await batch.commit();
  }

  Future<void> toggleStatus(String id, bool status) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    // Hapus juga semua enrollment yang terkait
    final enrollments = await _firestore
        .collection(_enrollmentCollection)
        .where('kelasId', isEqualTo: id)
        .get();

    final batch = _firestore.batch();
    for (final doc in enrollments.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection(_collection).doc(id));
    await batch.commit();
  }

  // ────────────────────────────────────────────────────────────
  // ASSIGN DOSEN
  // ────────────────────────────────────────────────────────────

  Future<void> assignDosen(
    String kelasId,
    String dosenId,
    String dosenNama,
  ) async {
    await _firestore.collection(_collection).doc(kelasId).update({
      'dosenId': dosenId,
      'dosenNama': dosenNama,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ────────────────────────────────────────────────────────────
  // ASSIGN ASDOS
  // ────────────────────────────────────────────────────────────

  Future<void> addAsdos(
    String kelasId,
    String asdosId,
    String asdosNama,
  ) async {
    await _firestore.collection(_collection).doc(kelasId).update({
      'asdosIds': FieldValue.arrayUnion([asdosId]),
      'asdosNama': FieldValue.arrayUnion([asdosNama]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAsdos(
    String kelasId,
    String asdosId,
    String asdosNama,
  ) async {
    await _firestore.collection(_collection).doc(kelasId).update({
      'asdosIds': FieldValue.arrayRemove([asdosId]),
      'asdosNama': FieldValue.arrayRemove([asdosNama]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ────────────────────────────────────────────────────────────
  // ENROLLMENT MAHASISWA
  // ────────────────────────────────────────────────────────────

  Future<List<ClassEnrollmentModel>> getEnrollmentsByKelas(
    String kelasId,
  ) async {
    final snap = await _firestore
        .collection(_enrollmentCollection)
        .where('kelasId', isEqualTo: kelasId)
        .get();
    final list = snap.docs
        .map((d) => ClassEnrollmentModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.mahasiswaNama.toLowerCase().compareTo(b.mahasiswaNama.toLowerCase()));
    return list;
  }

  Future<List<ClassEnrollmentModel>> getEnrollmentsByMahasiswa(
    String mahasiswaId,
  ) async {
    final snap = await _firestore
        .collection(_enrollmentCollection)
        .where('mahasiswaId', isEqualTo: mahasiswaId)
        .get();
    return snap.docs
        .map((d) => ClassEnrollmentModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> enrollMahasiswa(
    MahasiswaModel mahasiswa,
    KelasModel kelas,
  ) async {
    // Cek apakah sudah enrolled
    final existing = await _firestore
        .collection(_enrollmentCollection)
        .where('kelasId', isEqualTo: kelas.id)
        .where('mahasiswaId', isEqualTo: mahasiswa.uid)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Mahasiswa sudah terdaftar di kelas ini.');
    }

    final batch = _firestore.batch();

    // Tambah enrollment
    final enrollRef = _firestore.collection(_enrollmentCollection).doc();
    batch.set(
      enrollRef,
      ClassEnrollmentModel(
        id: enrollRef.id,
        kelasId: kelas.id,
        kelasNama: kelas.namaKelas,
        matakuliahNama: kelas.matakuliahNama,
        mahasiswaId: mahasiswa.uid,
        mahasiswaNama: mahasiswa.nama,
        mahasiswaNim: mahasiswa.nim,
        enrolledAt: Timestamp.now(),
      ).toMap(),
    );

    // Update jumlah mahasiswa di kelas
    batch.update(_firestore.collection(_collection).doc(kelas.id), {
      'jumlahMahasiswa': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> unenrollMahasiswa(String enrollmentId, String kelasId) async {
    final batch = _firestore.batch();

    batch.delete(
      _firestore.collection(_enrollmentCollection).doc(enrollmentId),
    );

    batch.update(_firestore.collection(_collection).doc(kelasId), {
      'jumlahMahasiswa': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<int> getCount() async {
    final snap = await _firestore.collection(_collection).count().get();
    return snap.count ?? 0;
  }

  // ──────────────────────────────────────────────────────────────
  // BOBOT NILAI & FITUR LMS
  // ──────────────────────────────────────────────────────────────

  /// Update konfigurasi bobot penilaian.
  /// Total bobotAbsensi + bobotTugas + bobotUTS + bobotUAS harus = 100.
  Future<void> updateBobotNilai(
    String kelasId, {
    required int bobotAbsensi,
    required int bobotTugas,
    required int bobotUTS,
    required int bobotUAS,
  }) async {
    assert(
      bobotAbsensi + bobotTugas + bobotUTS + bobotUAS == 100,
      'Total bobot harus 100%',
    );
    await _firestore.collection(_collection).doc(kelasId).update({
      'bobotAbsensi': bobotAbsensi,
      'bobotTugas': bobotTugas,
      'bobotUTS': bobotUTS,
      'bobotUAS': bobotUAS,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle fitur LMS yang tersedia untuk mahasiswa di kelas ini.
  Future<void> updateFitur(
    String kelasId, {
    required bool fiturMateri,
    required bool fiturTugas,
    required bool fiturQuiz,
    required bool fiturPengumuman,
  }) async {
    await _firestore.collection(_collection).doc(kelasId).update({
      'fiturMateri': fiturMateri,
      'fiturTugas': fiturTugas,
      'fiturQuiz': fiturQuiz,
      'fiturPengumuman': fiturPengumuman,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
