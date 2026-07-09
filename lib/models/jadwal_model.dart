import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipe lokasi pertemuan
enum LokasiType {
  offline,
  online;

  String get value => name;
  String get label => this == offline ? 'Offline' : 'Online';

  static LokasiType fromString(String? value) {
    if (value == 'online') return LokasiType.online;
    return LokasiType.offline;
  }
}

/// Metode absensi yang digunakan
enum MetodeAbsensi {
  gps,
  qrcode,
  manual;

  String get value => name;
  String get label {
    switch (this) {
      case gps:
        return 'GPS';
      case qrcode:
        return 'QR Code';
      case manual:
        return 'Manual';
    }
  }

  static MetodeAbsensi fromString(String? value) {
    switch (value) {
      case 'qrcode':
        return MetodeAbsensi.qrcode;
      case 'manual':
        return MetodeAbsensi.manual;
      default:
        return MetodeAbsensi.gps;
    }
  }
}

/// Platform online meeting
enum PlatformMeet {
  meet,
  zoom;

  String get value => name;
  String get label => this == meet ? 'Google Meet' : 'Zoom';

  static PlatformMeet fromString(String? value) {
    if (value == 'zoom') return PlatformMeet.zoom;
    return PlatformMeet.meet;
  }
}

/// Model untuk Jadwal Kelas.
/// Disimpan di collection 'schedules'.
///
/// Mendukung:
/// - Lokasi Offline (gedung, ruangan, koordinat GPS untuk absensi)
/// - Lokasi Online (Google Meet / Zoom)
/// - Konfigurasi absensi (radius, toleransi keterlambatan, metode)
/// - Otomatis membuat [totalPertemuan] dokumen di collection 'meetings'
class JadwalModel {
  final String id;
  final String kelasId;
  final String kelasNama;
  final String matakuliahId;
  final String matakuliahNama;
  final String matakuliahKode;
  final String dosenNama;
  final String hari; // Senin - Sabtu

  /// Jenis sesi: 'teori' atau 'praktikum'
  final String jenisSesi;

  final String jamMulai; // "08:00"
  final String jamSelesai; // "10:00"

  // ── Lokasi ─────────────────────────────────────────────────────
  /// 'offline' atau 'online'
  final String lokasiType;

  // Offline fields
  final String gedungNama;
  final String ruanganNama;
  final double latitude;
  final double longitude;

  // Online fields
  final String linkMeet;

  /// 'meet' atau 'zoom'
  final String platformMeet;

  // ── Konfigurasi Absensi ────────────────────────────────────────
  /// Radius absensi GPS dalam meter (50, 100, atau 150)
  final int radiusAbsensi;

  /// Toleransi keterlambatan dalam menit (15, 30, atau 45).
  /// Mahasiswa yang check-in melebihi waktu ini = Terlambat.
  final int toleransiMenit;

  /// Metode absensi: 'gps', 'qrcode', atau 'manual'
  final String metodeAbsensi;

  /// Apakah mahasiswa wajib berada dalam radius GPS untuk absen
  final bool lokasiWajib;

  /// Apakah mahasiswa wajib upload selfie saat absen
  final bool selfieWajib;

  // ── Pertemuan ─────────────────────────────────────────────────
  /// Total pertemuan dalam satu semester (8 atau 16).
  /// Praktikum selalu 8 pertemuan.
  final int totalPertemuan;

  final bool status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  /// Field lama untuk backward compatibility
  String get ruangan => ruanganNama.isNotEmpty
      ? ruanganNama
      : (gedungNama.isNotEmpty ? '$gedungNama' : '');

  const JadwalModel({
    required this.id,
    required this.kelasId,
    required this.kelasNama,
    this.matakuliahId = '',
    required this.matakuliahNama,
    required this.matakuliahKode,
    required this.dosenNama,
    required this.hari,
    this.jenisSesi = 'teori',
    required this.jamMulai,
    required this.jamSelesai,
    this.lokasiType = 'offline',
    this.gedungNama = '',
    this.ruanganNama = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.linkMeet = '',
    this.platformMeet = 'meet',
    this.radiusAbsensi = 100,
    this.toleransiMenit = 15,
    this.metodeAbsensi = 'gps',
    this.lokasiWajib = true,
    this.selfieWajib = false,
    this.totalPertemuan = 16,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JadwalModel.fromMap(String id, Map<String, dynamic> map) {
    return JadwalModel(
      id: id,
      kelasId: map['kelasId'] ?? '',
      kelasNama: map['kelasNama'] ?? '',
      matakuliahId: map['matakuliahId'] ?? '',
      matakuliahNama: map['matakuliahNama'] ?? '',
      matakuliahKode: map['matakuliahKode'] ?? '',
      dosenNama: map['dosenNama'] ?? '',
      hari: map['hari'] ?? '',
      jenisSesi: map['jenisSesi'] ?? 'teori',
      jamMulai: map['jamMulai'] ?? '',
      jamSelesai: map['jamSelesai'] ?? '',
      lokasiType: map['lokasiType'] ?? 'offline',
      gedungNama: map['gedungNama'] ?? '',
      // Backward compat: baca 'ruangan' jika 'ruanganNama' belum ada
      ruanganNama: map['ruanganNama'] ?? map['ruangan'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      linkMeet: map['linkMeet'] ?? '',
      platformMeet: map['platformMeet'] ?? 'meet',
      radiusAbsensi: map['radiusAbsensi'] ?? 100,
      toleransiMenit: map['toleransiMenit'] ?? 15,
      metodeAbsensi: map['metodeAbsensi'] ?? 'gps',
      lokasiWajib: map['lokasiWajib'] ?? true,
      selfieWajib: map['selfieWajib'] ?? false,
      totalPertemuan: map['totalPertemuan'] ?? 16,
      status: map['status'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kelasId': kelasId,
      'kelasNama': kelasNama,
      'matakuliahId': matakuliahId,
      'matakuliahNama': matakuliahNama,
      'matakuliahKode': matakuliahKode,
      'dosenNama': dosenNama,
      'hari': hari,
      'jenisSesi': jenisSesi,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
      'lokasiType': lokasiType,
      'gedungNama': gedungNama,
      'ruanganNama': ruanganNama,
      // Simpan juga 'ruangan' untuk backward compatibility
      'ruangan': ruanganNama.isNotEmpty
          ? '$gedungNama - $ruanganNama'.trim()
          : gedungNama,
      'latitude': latitude,
      'longitude': longitude,
      'linkMeet': linkMeet,
      'platformMeet': platformMeet,
      'radiusAbsensi': radiusAbsensi,
      'toleransiMenit': toleransiMenit,
      'metodeAbsensi': metodeAbsensi,
      'lokasiWajib': lokasiWajib,
      'selfieWajib': selfieWajib,
      'totalPertemuan': totalPertemuan,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isOnline => lokasiType == 'online';
  bool get isOffline => lokasiType == 'offline';
  bool get isPraktikum => jenisSesi == 'praktikum';
  bool get hasGpsLocation => latitude != 0.0 && longitude != 0.0;

  JadwalModel copyWith({
    String? id,
    String? kelasId,
    String? kelasNama,
    String? matakuliahId,
    String? matakuliahNama,
    String? matakuliahKode,
    String? dosenNama,
    String? hari,
    String? jenisSesi,
    String? jamMulai,
    String? jamSelesai,
    String? lokasiType,
    String? gedungNama,
    String? ruanganNama,
    double? latitude,
    double? longitude,
    String? linkMeet,
    String? platformMeet,
    int? radiusAbsensi,
    int? toleransiMenit,
    String? metodeAbsensi,
    bool? lokasiWajib,
    bool? selfieWajib,
    int? totalPertemuan,
    bool? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return JadwalModel(
      id: id ?? this.id,
      kelasId: kelasId ?? this.kelasId,
      kelasNama: kelasNama ?? this.kelasNama,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      matakuliahNama: matakuliahNama ?? this.matakuliahNama,
      matakuliahKode: matakuliahKode ?? this.matakuliahKode,
      dosenNama: dosenNama ?? this.dosenNama,
      hari: hari ?? this.hari,
      jenisSesi: jenisSesi ?? this.jenisSesi,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      lokasiType: lokasiType ?? this.lokasiType,
      gedungNama: gedungNama ?? this.gedungNama,
      ruanganNama: ruanganNama ?? this.ruanganNama,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      linkMeet: linkMeet ?? this.linkMeet,
      platformMeet: platformMeet ?? this.platformMeet,
      radiusAbsensi: radiusAbsensi ?? this.radiusAbsensi,
      toleransiMenit: toleransiMenit ?? this.toleransiMenit,
      metodeAbsensi: metodeAbsensi ?? this.metodeAbsensi,
      lokasiWajib: lokasiWajib ?? this.lokasiWajib,
      selfieWajib: selfieWajib ?? this.selfieWajib,
      totalPertemuan: totalPertemuan ?? this.totalPertemuan,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
