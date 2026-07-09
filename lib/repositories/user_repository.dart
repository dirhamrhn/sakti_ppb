import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mahasiswa_model.dart';
import '../models/dosen_model.dart';
import '../models/asdos_model.dart';
import '../services/auth/auth_service.dart';

/// Repository untuk operasi CRUD user berdasarkan role.
/// Semua user (mahasiswa, dosen, asdos) disimpan di collection 'users'.
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  // ────────────────────────────────────────────────────────────
  // MAHASISWA
  // ────────────────────────────────────────────────────────────

  Future<List<MahasiswaModel>> getMahasiswaList() async {
    final snap = await _firestore
        .collection(_collection)
        .where('role', isEqualTo: 'mahasiswa')
        .get();
    final list = snap.docs
        .map((d) => MahasiswaModel.fromMap(d.data()))
        .toList();
    list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return list;
  }

  Future<MahasiswaModel?> getMahasiswaById(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return MahasiswaModel.fromMap(doc.data()!);
  }

  /// Membuat akun Firebase Auth + menyimpan data Firestore.
  Future<void> createMahasiswa(MahasiswaModel model) async {
    // 1. Buat akun Firebase Auth tanpa mengubah sesi admin
    final credential = await AuthService.instance.createUserWithoutSignIn(
      email: model.email,
      password: 'Sakti@2025',
    );

    // 2. Simpan data ke Firestore dengan UID dari Auth
    final uid = credential.user!.uid;
    final data = model.copyWith(uid: uid).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection(_collection).doc(uid).set(data);
  }

  Future<void> updateMahasiswa(MahasiswaModel model) async {
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(model.uid).update(data);
  }

  Future<void> toggleStatusMahasiswa(String uid, bool status) async {
    await _firestore.collection(_collection).doc(uid).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMahasiswa(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  // ────────────────────────────────────────────────────────────
  // DOSEN
  // ────────────────────────────────────────────────────────────

  Future<List<DosenModel>> getDosenList() async {
    final snap = await _firestore
        .collection(_collection)
        .where('role', isEqualTo: 'dosen')
        .get();
    final list = snap.docs.map((d) => DosenModel.fromMap(d.data())).toList();
    list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return list;
  }

  Future<DosenModel?> getDosenById(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return DosenModel.fromMap(doc.data()!);
  }

  Future<void> createDosen(DosenModel model) async {
    final credential = await AuthService.instance.createUserWithoutSignIn(
      email: model.email,
      password: 'Sakti@2025',
    );

    final uid = credential.user!.uid;
    final data = model.copyWith(uid: uid).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection(_collection).doc(uid).set(data);
  }

  Future<void> updateDosen(DosenModel model) async {
    final batch = _firestore.batch();
    
    // 1. Update user
    final userRef = _firestore.collection(_collection).doc(model.uid);
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    batch.update(userRef, data);

    // 2. Cascade update to 'classes' collection
    final classesSnap = await _firestore
        .collection('classes')
        .where('dosenId', isEqualTo: model.uid)
        .get();
    for (final doc in classesSnap.docs) {
      batch.update(doc.reference, {
        'dosenNama': model.nama,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Cascade update to 'jadwal' collection
    final jadwalSnap = await _firestore
        .collection('jadwal')
        .where('dosenId', isEqualTo: model.uid)
        .get();
    for (final doc in jadwalSnap.docs) {
      batch.update(doc.reference, {
        'dosenNama': model.nama,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 4. Cascade update to 'tugas' collection
    final tugasSnap = await _firestore
        .collection('tugas')
        .where('dosenId', isEqualTo: model.uid)
        .get();
    for (final doc in tugasSnap.docs) {
      batch.update(doc.reference, {
        'dosenNama': model.nama,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> toggleStatusDosen(String uid, bool status) async {
    await _firestore.collection(_collection).doc(uid).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDosen(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  // ────────────────────────────────────────────────────────────
  // ASDOS
  // ────────────────────────────────────────────────────────────

  Future<List<AsdosModel>> getAsdosList() async {
    final snap = await _firestore
        .collection(_collection)
        .where('role', isEqualTo: 'asdos')
        .get();
    final list = snap.docs.map((d) => AsdosModel.fromMap(d.data())).toList();
    list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return list;
  }

  Future<AsdosModel?> getAsdosById(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return AsdosModel.fromMap(doc.data()!);
  }

  Future<void> createAsdos(AsdosModel model) async {
    final credential = await AuthService.instance.createUserWithoutSignIn(
      email: model.email,
      password: 'Sakti@2025',
    );

    final uid = credential.user!.uid;
    final data = model.copyWith(uid: uid).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection(_collection).doc(uid).set(data);
  }

  Future<void> updateAsdos(AsdosModel model) async {
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(model.uid).update(data);
  }

  Future<void> toggleStatusAsdos(String uid, bool status) async {
    await _firestore.collection(_collection).doc(uid).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAsdos(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  // ────────────────────────────────────────────────────────────
  // STATS
  // ────────────────────────────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    final futures = await Future.wait([
      _firestore
          .collection(_collection)
          .where('role', isEqualTo: 'mahasiswa')
          .count()
          .get(),
      _firestore
          .collection(_collection)
          .where('role', isEqualTo: 'dosen')
          .count()
          .get(),
      _firestore
          .collection(_collection)
          .where('role', isEqualTo: 'asdos')
          .count()
          .get(),
    ]);

    return {
      'mahasiswa': futures[0].count ?? 0,
      'dosen': futures[1].count ?? 0,
      'asdos': futures[2].count ?? 0,
    };
  }
}
