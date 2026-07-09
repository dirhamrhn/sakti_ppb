import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk Master Data Gedung.
/// Disimpan di collection 'buildings'.
///
/// Admin mengelola daftar gedung beserta koordinat GPS-nya.
/// Koordinat ini digunakan sebagai referensi untuk absensi offline.
class GedungModel {
  final String id;

  /// Kode gedung untuk identifikasi cepat, contoh: "GDA", "LAB"
  final String kode;

  /// Nama lengkap gedung, contoh: "Gedung A", "Laboratorium Komputer"
  final String nama;

  final String alamat;

  /// Koordinat GPS gedung (pusat gedung)
  final double latitude;
  final double longitude;

  final bool status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const GedungModel({
    required this.id,
    required this.kode,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GedungModel.fromMap(String id, Map<String, dynamic> map) {
    return GedungModel(
      id: id,
      kode: map['kode'] ?? '',
      nama: map['nama'] ?? '',
      alamat: map['alamat'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kode': kode,
      'nama': nama,
      'alamat': alamat,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get hasGpsLocation => latitude != 0.0 && longitude != 0.0;

  GedungModel copyWith({
    String? id,
    String? kode,
    String? nama,
    String? alamat,
    double? latitude,
    double? longitude,
    bool? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return GedungModel(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      nama: nama ?? this.nama,
      alamat: alamat ?? this.alamat,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GedungModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model untuk Master Data Ruangan dalam sebuah Gedung.
/// Disimpan di collection 'rooms'.
///
/// Setiap ruangan memiliki koordinat GPS sendiri (bisa berbeda dari gedung
/// untuk gedung multi-lantai, atau sama dengan gedung untuk gedung kecil).
class RuanganModel {
  final String id;

  /// ID gedung induk
  final String gedungId;

  /// Nama gedung induk (denormalized)
  final String gedungNama;

  /// Nama ruangan, contoh: "Lab Komputer 1", "Ruang 301"
  final String namaRuangan;

  /// Kode ruangan singkat, contoh: "LK1", "R301"
  final String kodeRuangan;

  final int kapasitas;

  /// Tipe ruangan: 'kelas', 'lab', 'aula', 'seminar'
  final String tipe;

  /// Koordinat GPS ruangan spesifik.
  /// Jika tidak diisi, fallback ke koordinat gedung.
  final double latitude;
  final double longitude;

  final bool status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const RuanganModel({
    required this.id,
    required this.gedungId,
    required this.gedungNama,
    required this.namaRuangan,
    required this.kodeRuangan,
    required this.kapasitas,
    required this.tipe,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RuanganModel.fromMap(String id, Map<String, dynamic> map) {
    return RuanganModel(
      id: id,
      gedungId: map['gedungId'] ?? '',
      gedungNama: map['gedungNama'] ?? '',
      namaRuangan: map['namaRuangan'] ?? '',
      kodeRuangan: map['kodeRuangan'] ?? '',
      kapasitas: map['kapasitas'] ?? 40,
      tipe: map['tipe'] ?? 'kelas',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gedungId': gedungId,
      'gedungNama': gedungNama,
      'namaRuangan': namaRuangan,
      'kodeRuangan': kodeRuangan,
      'kapasitas': kapasitas,
      'tipe': tipe,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get hasGpsLocation => latitude != 0.0 && longitude != 0.0;

  /// Nama lengkap untuk display: "Gedung A — Lab Komputer 1"
  String get namaLengkap => '$gedungNama — $namaRuangan';

  RuanganModel copyWith({
    String? id,
    String? gedungId,
    String? gedungNama,
    String? namaRuangan,
    String? kodeRuangan,
    int? kapasitas,
    String? tipe,
    double? latitude,
    double? longitude,
    bool? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return RuanganModel(
      id: id ?? this.id,
      gedungId: gedungId ?? this.gedungId,
      gedungNama: gedungNama ?? this.gedungNama,
      namaRuangan: namaRuangan ?? this.namaRuangan,
      kodeRuangan: kodeRuangan ?? this.kodeRuangan,
      kapasitas: kapasitas ?? this.kapasitas,
      tipe: tipe ?? this.tipe,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RuanganModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
