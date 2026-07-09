import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk user dengan role 'dosen'.
/// Disimpan di collection 'users'.
class DosenModel {
  final String uid;
  final String nama;
  final String email;
  final String nidn; // Nomor Induk Dosen Nasional
  final String programStudiId;
  final String programStudiNama;
  final String jabatan; // Asisten Ahli, Lektor, dll
  final String bidangKeahlian;
  final String photoUrl;
  final bool status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const DosenModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.nidn,
    required this.programStudiId,
    required this.programStudiNama,
    required this.jabatan,
    required this.bidangKeahlian,
    required this.photoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DosenModel.fromMap(Map<String, dynamic> map) {
    return DosenModel(
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      nidn: map['nomorInduk'] ?? '',
      programStudiId: map['programStudiId'] ?? '',
      programStudiNama: map['programStudiNama'] ?? '',
      jabatan: map['jabatan'] ?? '',
      bidangKeahlian: map['bidangKeahlian'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      status: map['status'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'nomorInduk': nidn,
      'role': 'dosen',
      'programStudiId': programStudiId,
      'programStudiNama': programStudiNama,
      'jabatan': jabatan,
      'bidangKeahlian': bidangKeahlian,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  DosenModel copyWith({
    String? uid,
    String? nama,
    String? email,
    String? nidn,
    String? programStudiId,
    String? programStudiNama,
    String? jabatan,
    String? bidangKeahlian,
    String? photoUrl,
    bool? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return DosenModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nidn: nidn ?? this.nidn,
      programStudiId: programStudiId ?? this.programStudiId,
      programStudiNama: programStudiNama ?? this.programStudiNama,
      jabatan: jabatan ?? this.jabatan,
      bidangKeahlian: bidangKeahlian ?? this.bidangKeahlian,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DosenModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
