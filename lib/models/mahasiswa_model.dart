import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk user dengan role 'mahasiswa'.
/// Disimpan di collection 'users'.
class MahasiswaModel {
  final String uid;
  final String nama;
  final String email;
  final String nim; // Nomor Induk Mahasiswa
  final String programStudiId;
  final String programStudiNama;
  final String angkatan; // contoh: "2021"
  final String photoUrl;
  final bool status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  /// Semester aktif mahasiswa saat ini (1-8).
  /// Digunakan untuk filter konten LMS sesuai semester.
  final int semester;

  const MahasiswaModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.nim,
    required this.programStudiId,
    required this.programStudiNama,
    required this.angkatan,
    required this.photoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.semester = 1,
  });

  factory MahasiswaModel.fromMap(Map<String, dynamic> map) {
    return MahasiswaModel(
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      nim: map['nomorInduk'] ?? '',
      programStudiId: map['programStudiId'] ?? '',
      programStudiNama: map['programStudiNama'] ?? '',
      angkatan: map['angkatan'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      status: map['status'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
      semester: map['semester'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'nomorInduk': nim,
      'role': 'mahasiswa',
      'programStudiId': programStudiId,
      'programStudiNama': programStudiNama,
      'angkatan': angkatan,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'semester': semester,
    };
  }

  MahasiswaModel copyWith({
    String? uid,
    String? nama,
    String? email,
    String? nim,
    String? programStudiId,
    String? programStudiNama,
    String? angkatan,
    String? photoUrl,
    bool? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? semester,
  }) {
    return MahasiswaModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      programStudiId: programStudiId ?? this.programStudiId,
      programStudiNama: programStudiNama ?? this.programStudiNama,
      angkatan: angkatan ?? this.angkatan,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      semester: semester ?? this.semester,
    );
  }
}
