import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/gedung_model.dart';

/// Repository untuk master data Gedung dan Ruangan.
/// Gedung: collection 'buildings'
/// Ruangan: collection 'rooms'
class GedungRepository {
  GedungRepository._();
  static final GedungRepository instance = GedungRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _buildingCollection = 'buildings';
  static const String _roomCollection = 'rooms';

  // ──────────────────────────────────────────────────────────────
  // GEDUNG
  // ──────────────────────────────────────────────────────────────

  Future<List<GedungModel>> getAllGedung() async {
    final snap = await _firestore
        .collection(_buildingCollection)
        .orderBy('nama')
        .get();
    return snap.docs.map((d) => GedungModel.fromMap(d.id, d.data())).toList();
  }

  Future<GedungModel?> getGedungById(String id) async {
    final doc = await _firestore.collection(_buildingCollection).doc(id).get();
    if (!doc.exists) return null;
    return GedungModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> createGedung(GedungModel model) async {
    final data = model.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection(_buildingCollection).add(data);
    return ref.id;
  }

  Future<void> updateGedung(GedungModel model) async {
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_buildingCollection).doc(model.id).update(data);
  }

  Future<void> toggleGedungStatus(String id, bool status) async {
    await _firestore.collection(_buildingCollection).doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGedung(String id) async {
    // Hapus semua ruangan terkait
    final rooms = await _firestore
        .collection(_roomCollection)
        .where('gedungId', isEqualTo: id)
        .get();
    final batch = _firestore.batch();
    for (final doc in rooms.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection(_buildingCollection).doc(id));
    await batch.commit();
  }

  // ──────────────────────────────────────────────────────────────
  // RUANGAN
  // ──────────────────────────────────────────────────────────────

  Future<List<RuanganModel>> getAllRuangan() async {
    final snap = await _firestore
        .collection(_roomCollection)
        .orderBy('gedungNama')
        .get();
    return snap.docs.map((d) => RuanganModel.fromMap(d.id, d.data())).toList();
  }

  Future<List<RuanganModel>> getRuanganByGedung(String gedungId) async {
    final snap = await _firestore
        .collection(_roomCollection)
        .where('gedungId', isEqualTo: gedungId)
        .where('status', isEqualTo: true)
        .get();
    final list = snap.docs.map((d) => RuanganModel.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => a.namaRuangan.compareTo(b.namaRuangan));
    return list;
  }

  Future<RuanganModel?> getRuanganById(String id) async {
    final doc = await _firestore.collection(_roomCollection).doc(id).get();
    if (!doc.exists) return null;
    return RuanganModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> createRuangan(RuanganModel model) async {
    final data = model.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection(_roomCollection).add(data);
    return ref.id;
  }

  Future<void> updateRuangan(RuanganModel model) async {
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_roomCollection).doc(model.id).update(data);
  }

  Future<void> toggleRuanganStatus(String id, bool status) async {
    await _firestore.collection(_roomCollection).doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRuangan(String id) async {
    await _firestore.collection(_roomCollection).doc(id).delete();
  }

  Future<int> getGedungCount() async {
    final snap = await _firestore.collection(_buildingCollection).count().get();
    return snap.count ?? 0;
  }
}
