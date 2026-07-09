import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/jadwal_model.dart';
import '../models/kelas_model.dart';
import 'pertemuan_repository.dart';

class JadwalRepository {
  JadwalRepository._();
  static final JadwalRepository instance = JadwalRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'jadwal';

  static const List<String> hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  Future<List<JadwalModel>> getAll() async {
    final snap = await _firestore.collection(_collection).orderBy('hari').get();
    final list = snap.docs
        .map((d) => JadwalModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) {
      final hariA = hariList.indexOf(a.hari);
      final hariB = hariList.indexOf(b.hari);
      if (hariA != hariB) return hariA.compareTo(hariB);
      return a.jamMulai.compareTo(b.jamMulai);
    });
    return list;
  }

  Future<List<JadwalModel>> getByKelas(String kelasId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('kelasId', isEqualTo: kelasId)
        .get();
    return snap.docs.map((d) => JadwalModel.fromMap(d.id, d.data())).toList();
  }

  /// Filter jadwal berdasarkan jenis sesi: 'teori' atau 'praktikum'
  Future<List<JadwalModel>> getByJenisSesi(String jenisSesi) async {
    final snap = await _firestore
        .collection(_collection)
        .where('jenisSesi', isEqualTo: jenisSesi)
        .get();
    return snap.docs.map((d) => JadwalModel.fromMap(d.id, d.data())).toList();
  }

  Future<List<JadwalModel>> getByKelasAndJenis(
    String kelasId,
    String jenisSesi,
  ) async {
    final snap = await _firestore
        .collection(_collection)
        .where('kelasId', isEqualTo: kelasId)
        .where('jenisSesi', isEqualTo: jenisSesi)
        .get();
    return snap.docs.map((d) => JadwalModel.fromMap(d.id, d.data())).toList();
  }

  Future<JadwalModel?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return JadwalModel.fromMap(doc.id, doc.data()!);
  }

  /// Membuat jadwal baru DAN otomatis men-generate [JadwalModel.totalPertemuan]
  /// dokumen pertemuan di collection 'meetings'.
  Future<String> create(JadwalModel model, KelasModel kelas) async {
    final data = model.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    // 1. Simpan jadwal
    final ref = await _firestore.collection(_collection).add(data);
    final jadwalId = ref.id;

    // 2. Auto-generate pertemuan
    await PertemuanRepository.instance.generatePertemuan(
      jadwalId: jadwalId,
      kelas: kelas,
      jadwal: model,
    );

    return jadwalId;
  }

  /// Create jadwal tanpa kelas (backward compat / simple case)
  Future<String> createSimple(JadwalModel model) async {
    final data = model.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection(_collection).add(data);
    return ref.id;
  }

  Future<void> update(JadwalModel model) async {
    final batch = _firestore.batch();
    
    // 1. Update jadwal
    final scheduleRef = _firestore.collection(_collection).doc(model.id);
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    batch.update(scheduleRef, data);

    // 2. Cascade ke Pertemuan (collection: 'pertemuan')
    final meetingsSnap = await _firestore
        .collection('pertemuan')
        .where('jadwalId', isEqualTo: model.id)
        .get();
    for (final doc in meetingsSnap.docs) {
      batch.update(doc.reference, {
        'kelasId': model.kelasId,
        'kelasNama': model.kelasNama,
        'matakuliahId': model.matakuliahId,
        'matakuliahNama': model.matakuliahNama,
        'matakuliahKode': model.matakuliahKode,
        'jenisSesi': model.jenisSesi,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Hapus jadwal dan semua pertemuan terkait
  Future<void> delete(String id) async {
    await PertemuanRepository.instance.deleteByJadwal(id);
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<int> getCount() async {
    final snap = await _firestore.collection(_collection).count().get();
    return snap.count ?? 0;
  }
}
