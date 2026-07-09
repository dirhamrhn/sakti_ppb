import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk user dengan role 'asdos'.
/// Disimpan di collection 'users'.
class AsdosModel {
  final String uid;
  final String nama;
  final String email;
  final String nim; // NIM Asisten Dosen
  final String programStudiId;
  final String programStudiNama;
  final String angkatan;
  final String photoUrl;
  final bool status;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final List<String> praktikumIds;
  final List<String> praktikumNama;

  const AsdosModel({
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
    this.praktikumIds = const [],
    this.praktikumNama = const [],
  });

  factory AsdosModel.fromMap(Map<String, dynamic> map) {
    return AsdosModel(
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
      praktikumIds: List<String>.from(map['praktikumIds'] ?? const []),
      praktikumNama: List<String>.from(map['praktikumNama'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'nomorInduk': nim,
      'role': 'asdos',
      'programStudiId': programStudiId,
      'programStudiNama': programStudiNama,
      'angkatan': angkatan,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'praktikumIds': praktikumIds,
      'praktikumNama': praktikumNama,
    };
  }

  AsdosModel copyWith({
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
    List<String>? praktikumIds,
    List<String>? praktikumNama,
  }) {
    return AsdosModel(
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
      praktikumIds: praktikumIds ?? this.praktikumIds,
      praktikumNama: praktikumNama ?? this.praktikumNama,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AsdosModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
