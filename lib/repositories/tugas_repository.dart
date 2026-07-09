import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tugas_model.dart';
import '../models/nilai_model.dart';
import '../models/absensi_model.dart';
import 'storage_repository.dart';

/// Repository khusus untuk data tugas mahasiswa
class TugasRepository {
  TugasRepository._();
  static final TugasRepository instance = TugasRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload file tugas ke Supabase Storage
  Future<String> uploadFileTugas(File file, String kelasId, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'assignments/$kelasId/${timestamp}_$fileName';
    return await StorageRepository.instance.uploadFile(file: file, path: path);
  }

  Future<List<TugasModel>> getByKelas(String kelasId) async {
    final snap = await _firestore
        .collection('tugas')
        .where('kelasId', isEqualTo: kelasId)
        .get();
    final list = snap.docs
        .map((d) => TugasModel.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  Future<TugasModel?> getById(String id) async {
    final doc = await _firestore.collection('tugas').doc(id).get();
    if (!doc.exists) return null;
    return TugasModel.fromMap(doc.id, doc.data()!);
  }

  Future<String> create(TugasModel model) async {
    final data = model.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection('tugas').add(data);
    return ref.id;
  }

  Future<void> update(TugasModel model) async {
    final data = model.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('tugas').doc(model.id).update(data);
  }

  Future<void> delete(String id) async {
    await _firestore.collection('tugas').doc(id).delete();
  }
}
