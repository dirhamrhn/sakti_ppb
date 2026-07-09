import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk Nilai Mahasiswa per Mata Kuliah per Semester.
/// Disimpan di collection 'grades'.
class NilaiModel {
  final String id;
  final String kelasId;
  final String matakuliahId;
  final String matakuliahNama;
  final String matakuliahKode;
  final int sks;
  final String mahasiswaId;
  final String semesterId;
  final String semesterNama;
  final double nilaiTugas; // 0-100
  final double nilaiUTS; // 0-100
  final double nilaiUAS; // 0-100
  final double nilaiQuiz; // 0-100
  final double nilaiPraktikum; // 0-100
  final double nilaiLaporan; // 0-100
  final double nilaiLain; // 0-100
  final double nilaiAbsensi; // 0-100
  final double nilaiAkhir; // weighted average
  final String huruf; // A, B+, B, C+, C, D, E
  final double bobot; // 4.0, 3.5, 3.0, ...
  final bool isOverridden;
  final double nilaiAkhirCalculated;
  final String overrideReason;
  final String mahasiswaNama;
  final Timestamp? updatedAt;

  // Override components fields
  final bool isLpOverridden;
  final bool isTpOverridden;
  final bool isAbsensiOverridden;
  final double nilaiLaporanManual;
  final double nilaiTugasManual;
  final double nilaiAbsensiManual;

  const NilaiModel({
    required this.id,
    required this.kelasId,
    required this.matakuliahId,
    required this.matakuliahNama,
    required this.matakuliahKode,
    required this.sks,
    required this.mahasiswaId,
    required this.semesterId,
    required this.semesterNama,
    required this.nilaiTugas,
    required this.nilaiUTS,
    required this.nilaiUAS,
    this.nilaiQuiz = 0.0,
    this.nilaiPraktikum = 0.0,
    this.nilaiLaporan = 0.0,
    this.nilaiLain = 0.0,
    this.nilaiAbsensi = 0.0,
    required this.nilaiAkhir,
    required this.huruf,
    required this.bobot,
    this.isOverridden = false,
    this.nilaiAkhirCalculated = 0.0,
    this.overrideReason = '',
    this.mahasiswaNama = '',
    this.updatedAt,
    this.isLpOverridden = false,
    this.isTpOverridden = false,
    this.isAbsensiOverridden = false,
    this.nilaiLaporanManual = 0.0,
    this.nilaiTugasManual = 0.0,
    this.nilaiAbsensiManual = 0.0,
  });

  factory NilaiModel.fromMap(String id, Map<String, dynamic> map) {
    return NilaiModel(
      id: id,
      kelasId: map['kelasId'] ?? '',
      matakuliahId: map['matakuliahId'] ?? '',
      matakuliahNama: map['matakuliahNama'] ?? '',
      matakuliahKode: map['matakuliahKode'] ?? '',
      sks: map['sks'] ?? 3,
      mahasiswaId: map['mahasiswaId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      semesterNama: map['semesterNama'] ?? '',
      nilaiTugas: (map['nilaiTugas'] as num?)?.toDouble() ?? 0.0,
      nilaiUTS: (map['nilaiUTS'] as num?)?.toDouble() ?? 0.0,
      nilaiUAS: (map['nilaiUAS'] as num?)?.toDouble() ?? 0.0,
      nilaiQuiz: (map['nilaiQuiz'] as num?)?.toDouble() ?? 0.0,
      nilaiPraktikum: (map['nilaiPraktikum'] as num?)?.toDouble() ?? 0.0,
      nilaiLaporan: (map['nilaiLaporan'] as num?)?.toDouble() ?? 0.0,
      nilaiLain: (map['nilaiLain'] as num?)?.toDouble() ?? 0.0,
      nilaiAbsensi: (map['nilaiAbsensi'] as num?)?.toDouble() ?? 0.0,
      nilaiAkhir: (map['nilaiAkhir'] as num?)?.toDouble() ?? 0.0,
      huruf: map['huruf'] ?? '',
      bobot: (map['bobot'] as num?)?.toDouble() ?? 0.0,
      isOverridden: map['isOverridden'] ?? false,
      nilaiAkhirCalculated: (map['nilaiAkhirCalculated'] as num?)?.toDouble() ?? 0.0,
      overrideReason: map['overrideReason'] ?? '',
      mahasiswaNama: map['mahasiswaNama'] ?? '',
      updatedAt: map['updatedAt'],
      isLpOverridden: map['isLpOverridden'] ?? false,
      isTpOverridden: map['isTpOverridden'] ?? false,
      isAbsensiOverridden: map['isAbsensiOverridden'] ?? false,
      nilaiLaporanManual: (map['nilaiLaporanManual'] as num?)?.toDouble() ?? 0.0,
      nilaiTugasManual: (map['nilaiTugasManual'] as num?)?.toDouble() ?? 0.0,
      nilaiAbsensiManual: (map['nilaiAbsensiManual'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kelasId': kelasId,
      'matakuliahId': matakuliahId,
      'matakuliahNama': matakuliahNama,
      'matakuliahKode': matakuliahKode,
      'sks': sks,
      'mahasiswaId': mahasiswaId,
      'semesterId': semesterId,
      'semesterNama': semesterNama,
      'nilaiTugas': nilaiTugas,
      'nilaiUTS': nilaiUTS,
      'nilaiUAS': nilaiUAS,
      'nilaiQuiz': nilaiQuiz,
      'nilaiPraktikum': nilaiPraktikum,
      'nilaiLaporan': nilaiLaporan,
      'nilaiLain': nilaiLain,
      'nilaiAbsensi': nilaiAbsensi,
      'nilaiAkhir': nilaiAkhir,
      'huruf': huruf,
      'bobot': bobot,
      'isOverridden': isOverridden,
      'nilaiAkhirCalculated': nilaiAkhirCalculated,
      'overrideReason': overrideReason,
      'mahasiswaNama': mahasiswaNama,
      'updatedAt': updatedAt,
      'isLpOverridden': isLpOverridden,
      'isTpOverridden': isTpOverridden,
      'isAbsensiOverridden': isAbsensiOverridden,
      'nilaiLaporanManual': nilaiLaporanManual,
      'nilaiTugasManual': nilaiTugasManual,
      'nilaiAbsensiManual': nilaiAbsensiManual,
    };
  }

  /// Hitung mutu (SKS × bobot)
  double get mutu => sks * bobot;

  /// Warna berdasarkan huruf
  static String bobotFromNilai(double nilai) {
    if (nilai >= 85) return 'A';
    if (nilai >= 80) return 'A-';
    if (nilai >= 75) return 'B+';
    if (nilai >= 70) return 'B';
    if (nilai >= 65) return 'B-';
    if (nilai >= 60) return 'C+';
    if (nilai >= 55) return 'C';
    if (nilai >= 50) return 'C-';
    if (nilai >= 40) return 'D';
    return 'E';
  }

  static double bobotFromHuruf(String huruf) {
    switch (huruf) {
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.5;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.5;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D':
        return 1.0;
      default:
        return 0.0;
    }
  }

  NilaiModel copyWith({
    String? id,
    String? kelasId,
    String? matakuliahId,
    String? matakuliahNama,
    String? matakuliahKode,
    int? sks,
    String? mahasiswaId,
    String? semesterId,
    String? semesterNama,
    double? nilaiTugas,
    double? nilaiUTS,
    double? nilaiUAS,
    double? nilaiQuiz,
    double? nilaiPraktikum,
    double? nilaiLaporan,
    double? nilaiLain,
    double? nilaiAbsensi,
    double? nilaiAkhir,
    String? huruf,
    double? bobot,
    bool? isOverridden,
    double? nilaiAkhirCalculated,
    String? overrideReason,
    String? mahasiswaNama,
    Timestamp? updatedAt,
    bool? isLpOverridden,
    bool? isTpOverridden,
    bool? isAbsensiOverridden,
    double? nilaiLaporanManual,
    double? nilaiTugasManual,
    double? nilaiAbsensiManual,
  }) {
    return NilaiModel(
      id: id ?? this.id,
      kelasId: kelasId ?? this.kelasId,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      matakuliahNama: matakuliahNama ?? this.matakuliahNama,
      matakuliahKode: matakuliahKode ?? this.matakuliahKode,
      sks: sks ?? this.sks,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      semesterId: semesterId ?? this.semesterId,
      semesterNama: semesterNama ?? this.semesterNama,
      nilaiTugas: nilaiTugas ?? this.nilaiTugas,
      nilaiUTS: nilaiUTS ?? this.nilaiUTS,
      nilaiUAS: nilaiUAS ?? this.nilaiUAS,
      nilaiQuiz: nilaiQuiz ?? this.nilaiQuiz,
      nilaiPraktikum: nilaiPraktikum ?? this.nilaiPraktikum,
      nilaiLaporan: nilaiLaporan ?? this.nilaiLaporan,
      nilaiLain: nilaiLain ?? this.nilaiLain,
      nilaiAbsensi: nilaiAbsensi ?? this.nilaiAbsensi,
      nilaiAkhir: nilaiAkhir ?? this.nilaiAkhir,
      huruf: huruf ?? this.huruf,
      bobot: bobot ?? this.bobot,
      isOverridden: isOverridden ?? this.isOverridden,
      nilaiAkhirCalculated: nilaiAkhirCalculated ?? this.nilaiAkhirCalculated,
      overrideReason: overrideReason ?? this.overrideReason,
      mahasiswaNama: mahasiswaNama ?? this.mahasiswaNama,
      updatedAt: updatedAt ?? this.updatedAt,
      isLpOverridden: isLpOverridden ?? this.isLpOverridden,
      isTpOverridden: isTpOverridden ?? this.isTpOverridden,
      isAbsensiOverridden: isAbsensiOverridden ?? this.isAbsensiOverridden,
      nilaiLaporanManual: nilaiLaporanManual ?? this.nilaiLaporanManual,
      nilaiTugasManual: nilaiTugasManual ?? this.nilaiTugasManual,
      nilaiAbsensiManual: nilaiAbsensiManual ?? this.nilaiAbsensiManual,
    );
  }
}

/// Model untuk Pengumuman.
/// Disimpan di collection 'announcements'.
class PengumumanModel {
  final String id;
  final String judul;
  final String konten;
  final String kelasId; // kosong jika untuk semua
  final String dosenNama;
  final String kategori; // 'umum', 'tugas', 'ujian', 'lainnya'
  final bool isImportant;
  final Timestamp createdAt;

  const PengumumanModel({
    required this.id,
    required this.judul,
    required this.konten,
    required this.kelasId,
    required this.dosenNama,
    required this.kategori,
    required this.isImportant,
    required this.createdAt,
  });

  factory PengumumanModel.fromMap(String id, Map<String, dynamic> map) {
    return PengumumanModel(
      id: id,
      judul: map['judul'] ?? '',
      konten: map['konten'] ?? '',
      kelasId: map['kelasId'] ?? '',
      dosenNama: map['dosenNama'] ?? '',
      kategori: map['kategori'] ?? 'umum',
      isImportant: map['isImportant'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'konten': konten,
      'kelasId': kelasId,
      'dosenNama': dosenNama,
      'kategori': kategori,
      'isImportant': isImportant,
      'createdAt': createdAt,
    };
  }
}

/// Model untuk Notifikasi User.
/// Disimpan di collection 'notifications'.
class NotifikasiModel {
  final String id;
  final String userId;
  final String judul;
  final String pesan;
  final String tipe; // 'tugas', 'nilai', 'absensi', 'pengumuman', 'sistem'
  final String referenceId; // ID tugas/nilai/dll
  final bool isRead;
  final Timestamp createdAt;

  const NotifikasiModel({
    required this.id,
    required this.userId,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotifikasiModel.fromMap(String id, Map<String, dynamic> map) {
    return NotifikasiModel(
      id: id,
      userId: map['userId'] ?? '',
      judul: map['judul'] ?? '',
      pesan: map['pesan'] ?? '',
      tipe: map['tipe'] ?? 'sistem',
      referenceId: map['referenceId'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'judul': judul,
      'pesan': pesan,
      'tipe': tipe,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
}

class MateriModel {
  final String id;
  final String kelasId;
  final String matakuliahNama;
  final int pertemuanKe;
  final String topik;
  final String deskripsi;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String fileType;
  final Timestamp? uploadedAt;
  final String uploadedBy;
  final String tanggal; // "2025-01-15"
  final Timestamp createdAt;

  const MateriModel({
    required this.id,
    required this.kelasId,
    required this.matakuliahNama,
    required this.pertemuanKe,
    required this.topik,
    required this.deskripsi,
    required this.fileUrl,
    required this.fileName,
    this.fileSize = 0,
    this.fileType = '',
    this.uploadedAt,
    this.uploadedBy = '',
    required this.tanggal,
    required this.createdAt,
  });

  factory MateriModel.fromMap(String id, Map<String, dynamic> map) {
    return MateriModel(
      id: id,
      kelasId: map['kelasId'] ?? '',
      matakuliahNama: map['matakuliahNama'] ?? '',
      pertemuanKe: map['pertemuanKe'] ?? 1,
      topik: map['topik'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      fileType: map['fileType'] ?? '',
      uploadedAt: map['uploadedAt'],
      uploadedBy: map['uploadedBy'] ?? '',
      tanggal: map['tanggal'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kelasId': kelasId,
      'matakuliahNama': matakuliahNama,
      'pertemuanKe': pertemuanKe,
      'topik': topik,
      'deskripsi': deskripsi,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileType': fileType,
      'uploadedAt': uploadedAt,
      'uploadedBy': uploadedBy,
      'tanggal': tanggal,
      'createdAt': createdAt,
    };
  }
}
