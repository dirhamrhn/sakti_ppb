import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk Pertemuan (satu sesi tatap muka/online).
/// Disimpan di collection 'meetings'.
///
/// Pertemuan di-generate OTOMATIS oleh sistem saat Admin membuat Jadwal.
/// Jika jadwal memiliki [totalPertemuan] = 16, maka 16 dokumen pertemuan
/// akan dibuat dengan status 'belum'.
///
/// Dosen kemudian mengaktifkan setiap pertemuan saat kelas dimulai,
/// dan mahasiswa absen melalui pertemuan yang aktif.
class PertemuanModel {
  final String id;

  /// ID jadwal yang menghasilkan pertemuan ini
  final String jadwalId;

  final String kelasId;
  final String kelasNama;
  final String matakuliahId;
  final String matakuliahNama;
  final String matakuliahKode;

  /// Jenis sesi: 'teori' atau 'praktikum'
  final String jenisSesi;

  /// Nomor urut pertemuan dalam semester (1, 2, ..., totalPertemuan)
  final int pertemuanKe;

  /// Tanggal terjadwal pertemuan ini (format: "2025-01-15")
  final String tanggal;

  /// Topik bahasan pertemuan (diisi oleh Dosen/Asdos)
  final String topik;

  /// Status pertemuan:
  /// - 'belum': belum dimulai (default)
  /// - 'aktif': sedang berlangsung, absensi terbuka
  /// - 'selesai': pertemuan selesai, absensi ditutup
  final String status;

  /// QR Code string untuk metode absensi QR Code
  final String qrCode;

  /// Apakah absensi sedang terbuka untuk mahasiswa
  final bool isAbsensiOpen;

  final Timestamp? absensiOpenAt;
  final Timestamp? absensiCloseAt;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const PertemuanModel({
    required this.id,
    required this.jadwalId,
    required this.kelasId,
    required this.kelasNama,
    required this.matakuliahId,
    required this.matakuliahNama,
    required this.matakuliahKode,
    required this.jenisSesi,
    required this.pertemuanKe,
    required this.tanggal,
    required this.topik,
    required this.status,
    required this.qrCode,
    required this.isAbsensiOpen,
    this.absensiOpenAt,
    this.absensiCloseAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PertemuanModel.fromMap(String id, Map<String, dynamic> map) {
    return PertemuanModel(
      id: id,
      jadwalId: map['jadwalId'] ?? '',
      kelasId: map['kelasId'] ?? '',
      kelasNama: map['kelasNama'] ?? '',
      matakuliahId: map['matakuliahId'] ?? '',
      matakuliahNama: map['matakuliahNama'] ?? '',
      matakuliahKode: map['matakuliahKode'] ?? '',
      jenisSesi: map['jenisSesi'] ?? 'teori',
      pertemuanKe: map['pertemuanKe'] ?? 1,
      tanggal: map['tanggal'] ?? '',
      topik: map['topik'] ?? '',
      status: map['status'] ?? 'belum',
      qrCode: map['qrCode'] ?? '',
      isAbsensiOpen: map['isAbsensiOpen'] ?? false,
      absensiOpenAt: map['absensiOpenAt'],
      absensiCloseAt: map['absensiCloseAt'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jadwalId': jadwalId,
      'kelasId': kelasId,
      'kelasNama': kelasNama,
      'matakuliahId': matakuliahId,
      'matakuliahNama': matakuliahNama,
      'matakuliahKode': matakuliahKode,
      'jenisSesi': jenisSesi,
      'pertemuanKe': pertemuanKe,
      'tanggal': tanggal,
      'topik': topik,
      'status': status,
      'qrCode': qrCode,
      'isAbsensiOpen': isAbsensiOpen,
      'absensiOpenAt': absensiOpenAt,
      'absensiCloseAt': absensiCloseAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isBelum => status == 'belum';
  bool get isAktif => status == 'aktif';
  bool get isSelesai => status == 'selesai';
  bool get isPraktikum => jenisSesi == 'praktikum';

  PertemuanModel copyWith({
    String? id,
    String? jadwalId,
    String? kelasId,
    String? kelasNama,
    String? matakuliahId,
    String? matakuliahNama,
    String? matakuliahKode,
    String? jenisSesi,
    int? pertemuanKe,
    String? tanggal,
    String? topik,
    String? status,
    String? qrCode,
    bool? isAbsensiOpen,
    Timestamp? absensiOpenAt,
    Timestamp? absensiCloseAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return PertemuanModel(
      id: id ?? this.id,
      jadwalId: jadwalId ?? this.jadwalId,
      kelasId: kelasId ?? this.kelasId,
      kelasNama: kelasNama ?? this.kelasNama,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      matakuliahNama: matakuliahNama ?? this.matakuliahNama,
      matakuliahKode: matakuliahKode ?? this.matakuliahKode,
      jenisSesi: jenisSesi ?? this.jenisSesi,
      pertemuanKe: pertemuanKe ?? this.pertemuanKe,
      tanggal: tanggal ?? this.tanggal,
      topik: topik ?? this.topik,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      isAbsensiOpen: isAbsensiOpen ?? this.isAbsensiOpen,
      absensiOpenAt: absensiOpenAt ?? this.absensiOpenAt,
      absensiCloseAt: absensiCloseAt ?? this.absensiCloseAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
