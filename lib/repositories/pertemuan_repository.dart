import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pertemuan_model.dart';
import '../models/jadwal_model.dart';
import '../models/kelas_model.dart';

/// Repository untuk manajemen Pertemuan.
/// Disimpan di collection 'meetings'.
///
/// Pertemuan di-generate otomatis oleh [JadwalRepository.create()]
/// berdasarkan [JadwalModel.totalPertemuan].
class PertemuanRepository {
  PertemuanRepository._();
  static final PertemuanRepository instance = PertemuanRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'pertemuan';

  // ──────────────────────────────────────────────────────────────
  // GENERATE OTOMATIS
  // ──────────────────────────────────────────────────────────────

  /// Generate N pertemuan untuk jadwal yang baru dibuat.
  /// Dipanggil oleh JadwalRepository.create() via batch write.
  ///
  /// Setiap pertemuan dibuat dengan status 'belum' dan tanggal kosong
  /// (Dosen akan mengisi topik dan mengaktifkan saat kelas dimulai).
  Future<void> generatePertemuan({
    required String jadwalId,
    required KelasModel kelas,
    required JadwalModel jadwal,
  }) async {
    final batch = _firestore.batch();
    final total = jadwal.totalPertemuan;

    for (int i = 1; i <= total; i++) {
      final ref = _firestore.collection(_collection).doc();
      final pertemuan = PertemuanModel(
        id: ref.id,
        jadwalId: jadwalId,
        kelasId: kelas.id,
        kelasNama: kelas.namaKelas,
        matakuliahId: kelas.matakuliahId,
        matakuliahNama: kelas.matakuliahNama,
        matakuliahKode: kelas.matakuliahKode,
        jenisSesi: jadwal.jenisSesi,
        pertemuanKe: i,
        tanggal: '',
        topik: 'Pertemuan $i',
        status: 'belum',
        qrCode: '',
        isAbsensiOpen: false,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      final data = pertemuan.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(ref, data);
    }

    await batch.commit();
  }

  // ──────────────────────────────────────────────────────────────
  // QUERY
  // ──────────────────────────────────────────────────────────────

  Future<List<PertemuanModel>> getByJadwal(String jadwalId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('jadwalId', isEqualTo: jadwalId)
        .get();
    final list = snap.docs
        .map((d) => PertemuanModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
    return list;
  }

  Future<List<PertemuanModel>> getByKelas(String kelasId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('kelasId', isEqualTo: kelasId)
        .get();
    final list = snap.docs
        .map((d) => PertemuanModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
    return list;
  }

  Future<List<PertemuanModel>> getByKelasAndJenis(
    String kelasId,
    String jenisSesi,
  ) async {
    final snap = await _firestore
        .collection(_collection)
        .where('kelasId', isEqualTo: kelasId)
        .where('jenisSesi', isEqualTo: jenisSesi)
        .get();
    final list = snap.docs
        .map((d) => PertemuanModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
    return list;
  }

  Future<PertemuanModel?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return PertemuanModel.fromMap(doc.id, doc.data()!);
  }

  // ──────────────────────────────────────────────────────────────
  // CRUD
  // ──────────────────────────────────────────────────────────────

  Future<void> update(PertemuanModel model) async {
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(model.id).update(data);
  }

  /// Aktifkan pertemuan dan buka absensi
  Future<void> aktivasiPertemuan(String id, {String topik = ''}) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': 'aktif',
      'isAbsensiOpen': true,
      'absensiOpenAt': FieldValue.serverTimestamp(),
      if (topik.isNotEmpty) 'topik': topik,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tutup absensi dan selesaikan pertemuan
  Future<void> selesaikanPertemuan(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': 'selesai',
      'isAbsensiOpen': false,
      'absensiCloseAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hapus semua pertemuan dari jadwal tertentu (saat jadwal dihapus)
  Future<void> deleteByJadwal(String jadwalId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('jadwalId', isEqualTo: jadwalId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
