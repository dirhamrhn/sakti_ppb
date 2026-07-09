import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String nomorInduk;
  final String role;
  final String photoUrl;
  final bool status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.nomorInduk,
    required this.role,
    required this.photoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore ke Model
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      nomorInduk: map['nomorInduk'] ?? '',
      role: map['role'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      status: map['status'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// Model ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'nomorInduk': nomorInduk,
      'role': role,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Copy object
  UserModel copyWith({
    String? uid,
    String? nama,
    String? email,
    String? nomorInduk,
    String? role,
    String? photoUrl,
    bool? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nomorInduk: nomorInduk ?? this.nomorInduk,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return '''
UserModel(
  uid: $uid,
  nama: $nama,
  email: $email,
  nomorInduk: $nomorInduk,
  role: $role,
  status: $status
)
''';
  }
}
