import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk Absensi Mahasiswa per Pertemuan.
/// Disimpan di collection 'attendance'.
///
/// Mendukung:
/// - Absensi GPS (koordinat mahasiswa vs koordinat ruangan)
/// - Absensi QR Code
/// - Absensi Manual oleh Dosen/Asdos
/// - Tracking untuk sesi Teori DAN Praktikum
/// - Status Terlambat berdasarkan toleransi waktu di JadwalModel
class AbsensiModel {
  final String id;
  final String kelasId;
  final String kelasNama;
  final String matakuliahNama;
  final String matakuliahKode;
  final String mahasiswaId;
  final String mahasiswaNama;
  final String mahasiswaNim;
  final int pertemuanKe;
  final String tanggal; // Format: "2025-01-15"

  /// Status kehadiran:
  /// - 'hadir': tepat waktu
  /// - 'terlambat': check-in melewati toleransi waktu
  /// - 'izin': tidak hadir dengan izin
  /// - 'sakit': tidak hadir karena sakit
  /// - 'alpha': tidak hadir tanpa keterangan
  final String status;
  final String keterangan;
  final bool isCheckedIn;
  final Timestamp? checkedInAt;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  // ── Field baru ─────────────────────────────────────────────────

  /// ID pertemuan yang diabsensi (referensi ke collection 'meetings')
  final String pertemuanId;

  /// Jenis sesi: 'teori' atau 'praktikum'
  final String jenisSesi;

  /// Koordinat GPS mahasiswa saat melakukan absensi
  final double latitude;
  final double longitude;

  /// URL foto selfie mahasiswa (jika selfieWajib = true)
  final String selfieUrl;

  /// Metode absensi yang digunakan: 'gps', 'qrcode', 'manual'
  final String metodeAbsensi;

  /// ID jadwal yang menghasilkan pertemuan/absensi ini
  final String jadwalId;

  /// ID mata kuliah
  final String matakuliahId;

  /// Jarak dari lokasi kelas (dalam meter) saat mahasiswa melakukan absensi
  final double jarak;

  /// Jam absensi (format: "HH:mm") saat mahasiswa melakukan absensi
  final String jamAbsensi;

  const AbsensiModel({
    required this.id,
    required this.kelasId,
    required this.kelasNama,
    required this.matakuliahNama,
    required this.matakuliahKode,
    required this.mahasiswaId,
    required this.mahasiswaNama,
    required this.mahasiswaNim,
    required this.pertemuanKe,
    required this.tanggal,
    required this.status,
    required this.keterangan,
    required this.isCheckedIn,
    this.checkedInAt,
    required this.createdAt,
    required this.updatedAt,
    this.pertemuanId = '',
    this.jenisSesi = 'teori',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.selfieUrl = '',
    this.metodeAbsensi = 'gps',
    this.jadwalId = '',
    this.matakuliahId = '',
    this.jarak = 0.0,
    this.jamAbsensi = '',
  });

  factory AbsensiModel.fromMap(String id, Map<String, dynamic> map) {
    return AbsensiModel(
      id: id,
      kelasId: map['kelasId'] ?? '',
      kelasNama: map['kelasNama'] ?? '',
      matakuliahNama: map['matakuliahNama'] ?? '',
      matakuliahKode: map['matakuliahKode'] ?? '',
      mahasiswaId: map['mahasiswaId'] ?? '',
      mahasiswaNama: map['mahasiswaNama'] ?? '',
      mahasiswaNim: map['mahasiswaNim'] ?? '',
      pertemuanKe: map['pertemuanKe'] ?? 1,
      tanggal: map['tanggal'] ?? '',
      status: map['status'] ?? 'hadir',
      keterangan: map['keterangan'] ?? '',
      isCheckedIn: map['isCheckedIn'] ?? false,
      checkedInAt: map['checkedInAt'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
      pertemuanId: map['pertemuanId'] ?? '',
      jenisSesi: map['jenisSesi'] ?? 'teori',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      selfieUrl: map['selfieUrl'] ?? '',
      metodeAbsensi: map['metodeAbsensi'] ?? 'gps',
      jadwalId: map['jadwalId'] ?? '',
      matakuliahId: map['matakuliahId'] ?? '',
      jarak: (map['jarak'] as num?)?.toDouble() ?? 0.0,
      jamAbsensi: map['jamAbsensi'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kelasId': kelasId,
      'kelasNama': kelasNama,
      'matakuliahNama': matakuliahNama,
      'matakuliahKode': matakuliahKode,
      'mahasiswaId': mahasiswaId,
      'mahasiswaNama': mahasiswaNama,
      'mahasiswaNim': mahasiswaNim,
      'pertemuanKe': pertemuanKe,
      'tanggal': tanggal,
      'status': status,
      'keterangan': keterangan,
      'isCheckedIn': isCheckedIn,
      'checkedInAt': checkedInAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'pertemuanId': pertemuanId,
      'jenisSesi': jenisSesi,
      'latitude': latitude,
      'longitude': longitude,
      'selfieUrl': selfieUrl,
      'metodeAbsensi': metodeAbsensi,
      'jadwalId': jadwalId,
      'matakuliahId': matakuliahId,
      'jarak': jarak,
      'jamAbsensi': jamAbsensi,
    };
  }

  AbsensiModel copyWith({
    String? id,
    String? kelasId,
    String? kelasNama,
    String? matakuliahNama,
    String? matakuliahKode,
    String? mahasiswaId,
    String? mahasiswaNama,
    String? mahasiswaNim,
    int? pertemuanKe,
    String? tanggal,
    String? status,
    String? keterangan,
    bool? isCheckedIn,
    Timestamp? checkedInAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? pertemuanId,
    String? jenisSesi,
    double? latitude,
    double? longitude,
    String? selfieUrl,
    String? metodeAbsensi,
    String? jadwalId,
    String? matakuliahId,
    double? jarak,
    String? jamAbsensi,
  }) {
    return AbsensiModel(
      id: id ?? this.id,
      kelasId: kelasId ?? this.kelasId,
      kelasNama: kelasNama ?? this.kelasNama,
      matakuliahNama: matakuliahNama ?? this.matakuliahNama,
      matakuliahKode: matakuliahKode ?? this.matakuliahKode,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      mahasiswaNama: mahasiswaNama ?? this.mahasiswaNama,
      mahasiswaNim: mahasiswaNim ?? this.mahasiswaNim,
      pertemuanKe: pertemuanKe ?? this.pertemuanKe,
      tanggal: tanggal ?? this.tanggal,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pertemuanId: pertemuanId ?? this.pertemuanId,
      jenisSesi: jenisSesi ?? this.jenisSesi,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      metodeAbsensi: metodeAbsensi ?? this.metodeAbsensi,
      jadwalId: jadwalId ?? this.jadwalId,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      jarak: jarak ?? this.jarak,
      jamAbsensi: jamAbsensi ?? this.jamAbsensi,
    );
  }

  bool get isHadir => status == 'hadir' || status == 'terlambat';
  bool get isTerlambat => status == 'terlambat';
  bool get isIzin => status == 'izin';
  bool get isSakit => status == 'sakit';
  bool get isAlpha => status == 'alpha';
  bool get isPraktikum => jenisSesi == 'praktikum';
  bool get hasGpsData => latitude != 0.0 && longitude != 0.0;
}
