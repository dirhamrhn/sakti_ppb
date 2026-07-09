import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/matakuliah_model.dart';

class MatakuliahRepository {
  MatakuliahRepository._();
  static final MatakuliahRepository instance = MatakuliahRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'mata_kuliah';

  Future<List<MatakuliahModel>> getAll() async {
    final snap = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => MatakuliahModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return list;
  }

  Future<List<MatakuliahModel>> getAllIncludingInactive() async {
    final snap = await _firestore.collection(_collection).get();
    final list = snap.docs
        .map((d) => MatakuliahModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return list;
  }

  /// Filter berdasarkan jenis: 'teori' atau 'teori_praktikum'
  Future<List<MatakuliahModel>> getByJenis(String jenisMatakuliah) async {
    final snap = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: true)
        .where('jenisMatakuliah', isEqualTo: jenisMatakuliah)
        .get();
    final list = snap.docs
        .map((d) => MatakuliahModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return list;
  }

  Future<MatakuliahModel?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return MatakuliahModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> create(MatakuliahModel model) async {
    final data = model.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection(_collection).add(data);
    return ref.id;
  }

  Future<void> update(MatakuliahModel model) async {
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(model.id).update(data);
  }

  Future<void> toggleStatus(String id, bool status) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<int> getCount() async {
    final snap = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: true)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Hitung berdasarkan jenis untuk dashboard stats
  Future<Map<String, int>> countByJenis() async {
    final results = await Future.wait([
      _firestore
          .collection(_collection)
          .where('status', isEqualTo: true)
          .where('jenisMatakuliah', isEqualTo: 'teori')
          .count()
          .get(),
      _firestore
          .collection(_collection)
          .where('status', isEqualTo: true)
          .where('jenisMatakuliah', isEqualTo: 'teori_praktikum')
          .count()
          .get(),
    ]);
    return {
      'teori': results[0].count ?? 0,
      'teoriPraktikum': results[1].count ?? 0,
    };
  }
}
