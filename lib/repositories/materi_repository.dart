import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nilai_model.dart'; // contains MateriModel
import 'storage_repository.dart';

class MateriRepository {
  MateriRepository._();
  static final MateriRepository instance = MateriRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ambil semua materi untuk kelas tertentu
  Future<List<MateriModel>> getByKelas(String kelasId) async {
    final snap = await _firestore
        .collection('materials')
        .where('kelasId', isEqualTo: kelasId)
        .get();
    
    final list = snap.docs
        .map((d) => MateriModel.fromMap(d.id, d.data()))
        .toList();
    
    // Sort by pertemuanKe ascending
    list.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
    return list;
  }

  /// Tambah materi baru ke Firestore
  Future<String> create(MateriModel model) async {
    final ref = _firestore.collection('materials').doc();
    final data = model.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  /// Upload file materi ke Supabase Storage
  Future<String> uploadFileMateri(File file, String kelasId, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'materials/$kelasId/${timestamp}_$fileName';
    return await StorageRepository.instance.uploadFile(file: file, path: path);
  }

  /// Hapus materi dari Firestore
  Future<void> delete(String id) async {
    await _firestore.collection('materials').doc(id).delete();
  }
}
