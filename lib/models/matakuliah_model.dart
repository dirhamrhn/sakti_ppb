import 'package:cloud_firestore/cloud_firestore.dart';

/// Jenis Mata Kuliah: hanya teori, atau teori + praktikum.
/// Jika 'teori_praktikum', sistem otomatis mendukung pertemuan,
/// materi, tugas, absensi, dan nilai untuk KEDUA sesi.
enum JenisMatakuliah {
  teori,
  teoriPraktikum;

  String get value => this == teori ? 'teori' : 'teori_praktikum';
  String get label => this == teori ? 'Hanya Teori' : 'Teori + Praktikum';

  static JenisMatakuliah fromString(String? value) {
    if (value == 'teori_praktikum') return JenisMatakuliah.teoriPraktikum;
    return JenisMatakuliah.teori;
  }
}

/// Model untuk Mata Kuliah.
/// Disimpan di collection 'courses'.
class MatakuliahModel {
  final String id;
  final String kode; // Kode mata kuliah, contoh: "CS101"
  final String nama;
  final int sks;
  final String semester; // "1" - "8"
  final String programStudiId;
  final String programStudiNama;
  final String deskripsi;
  final bool status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  // ── Field baru untuk mendukung LMS Teori & Praktikum ──────────
  /// Jenis mata kuliah: 'teori' atau 'teori_praktikum'.
  /// Menentukan apakah sistem menyediakan sesi praktikum.
  final String jenisMatakuliah;

  /// ID dosen pengampu mata kuliah ini.
  final String dosenId;

  /// Nama dosen pengampu (denormalized untuk query efisien).
  final String dosenNama;

  const MatakuliahModel({
    required this.id,
    required this.kode,
    required this.nama,
    required this.sks,
    required this.semester,
    required this.programStudiId,
    required this.programStudiNama,
    required this.deskripsi,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.jenisMatakuliah = 'teori',
    this.dosenId = '',
    this.dosenNama = '',
  });

  /// true jika mata kuliah ini memiliki sesi praktikum
  bool get hasPraktikum => jenisMatakuliah.toLowerCase().contains('prak');

  factory MatakuliahModel.fromMap(String id, Map<String, dynamic> map) {
    return MatakuliahModel(
      id: id,
      kode: map['kode'] ?? '',
      nama: map['nama'] ?? '',
      sks: map['sks'] ?? 0,
      semester: map['semester'] ?? '',
      programStudiId: map['programStudiId'] ?? '',
      programStudiNama: map['programStudiNama'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      status: map['status'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
      jenisMatakuliah: map['jenisMatakuliah'] ?? 'teori',
      dosenId: map['dosenId'] ?? '',
      dosenNama: map['dosenNama'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kode': kode,
      'nama': nama,
      'sks': sks,
      'semester': semester,
      'programStudiId': programStudiId,
      'programStudiNama': programStudiNama,
      'deskripsi': deskripsi,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'jenisMatakuliah': jenisMatakuliah,
      'hasPraktikum': hasPraktikum,
      'dosenId': dosenId,
      'dosenNama': dosenNama,
    };
  }

  MatakuliahModel copyWith({
    String? id,
    String? kode,
    String? nama,
    int? sks,
    String? semester,
    String? programStudiId,
    String? programStudiNama,
    String? deskripsi,
    bool? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? jenisMatakuliah,
    String? dosenId,
    String? dosenNama,
  }) {
    return MatakuliahModel(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      nama: nama ?? this.nama,
      sks: sks ?? this.sks,
      semester: semester ?? this.semester,
      programStudiId: programStudiId ?? this.programStudiId,
      programStudiNama: programStudiNama ?? this.programStudiNama,
      deskripsi: deskripsi ?? this.deskripsi,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      jenisMatakuliah: jenisMatakuliah ?? this.jenisMatakuliah,
      dosenId: dosenId ?? this.dosenId,
      dosenNama: dosenNama ?? this.dosenNama,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatakuliahModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
