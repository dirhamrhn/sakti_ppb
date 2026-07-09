import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk relasi Mahasiswa → Kelas.
/// Disimpan di collection 'class_enrollments'.
class ClassEnrollmentModel {
  final String id;
  final String kelasId;
  final String kelasNama;
  final String matakuliahNama;
  final String mahasiswaId;
  final String mahasiswaNama;
  final String mahasiswaNim;
  final Timestamp enrolledAt;

  const ClassEnrollmentModel({
    required this.id,
    required this.kelasId,
    required this.kelasNama,
    required this.matakuliahNama,
    required this.mahasiswaId,
    required this.mahasiswaNama,
    required this.mahasiswaNim,
    required this.enrolledAt,
  });

  factory ClassEnrollmentModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassEnrollmentModel(
      id: id,
      kelasId: map['kelasId'] ?? '',
      kelasNama: map['kelasNama'] ?? '',
      matakuliahNama: map['matakuliahNama'] ?? '',
      mahasiswaId: map['mahasiswaId'] ?? '',
      mahasiswaNama: map['mahasiswaNama'] ?? '',
      mahasiswaNim: map['mahasiswaNim'] ?? '',
      enrolledAt: map['enrolledAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kelasId': kelasId,
      'kelasNama': kelasNama,
      'matakuliahNama': matakuliahNama,
      'mahasiswaId': mahasiswaId,
      'mahasiswaNama': mahasiswaNama,
      'mahasiswaNim': mahasiswaNim,
      'enrolledAt': enrolledAt,
    };
  }
}
