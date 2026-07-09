import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk Kelas (instansi dari Mata Kuliah di semester tertentu).
/// Disimpan di collection 'classes'.
class KelasModel {
  final String id;
  final String namaKelas; // contoh: "A", "B", "Paralel 1"
  final String matakuliahId;
  final String matakuliahNama;
  final String matakuliahKode;
  final String dosenId;
  final String dosenNama;
  final List<String> asdosIds;
  final List<String> asdosNama;
  final String semesterId;
  final String semesterNama;
  final int kapasitas;
  final int jumlahMahasiswa;
  final bool status;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  // ── Field Akademik Baru ────────────────────────────────────────
  /// Tahun akademik, contoh: "2024/2025"
  final String tahunAkademik;

  /// Semester aktif: 1 (Ganjil) atau 2 (Genap)
  final int semesterAktif;

  // ── Konfigurasi Bobot Nilai ────────────────────────────────────
  /// Bobot komponen penilaian (total harus = 100).
  /// Dosen dapat mengubah bobot ini per kelas.
  final int bobotAbsensi; // default 10%
  final int bobotTugas; // default 20%
  final int bobotUTS; // default 30%
  final int bobotUAS; // default 40%
  final int bobotQuiz; // default 0%
  final int bobotPraktikum; // default 0%
  final int bobotLaporan; // default 0%
  final int bobotLain; // default 0%

  // ── Konfigurasi Fitur LMS ──────────────────────────────────────
  /// Toggle fitur yang tersedia untuk mahasiswa di kelas ini.
  final bool fiturMateri;
  final bool fiturTugas;
  final bool fiturQuiz;
  final bool fiturPengumuman;

  const KelasModel({
    required this.id,
    required this.namaKelas,
    required this.matakuliahId,
    required this.matakuliahNama,
    required this.matakuliahKode,
    required this.dosenId,
    required this.dosenNama,
    required this.asdosIds,
    required this.asdosNama,
    required this.semesterId,
    required this.semesterNama,
    required this.kapasitas,
    required this.jumlahMahasiswa,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.tahunAkademik = '',
    this.semesterAktif = 1,
    this.bobotAbsensi = 10,
    this.bobotTugas = 20,
    this.bobotUTS = 30,
    this.bobotUAS = 40,
    this.bobotQuiz = 0,
    this.bobotPraktikum = 0,
    this.bobotLaporan = 0,
    this.bobotLain = 0,
    this.fiturMateri = true,
    this.fiturTugas = true,
    this.fiturQuiz = false,
    this.fiturPengumuman = true,
  });

  /// Validasi total bobot harus 100%
  bool get isBobotValid =>
      bobotAbsensi + bobotTugas + bobotUTS + bobotUAS + bobotQuiz + bobotPraktikum + bobotLaporan + bobotLain == 100;

  /// Nama lengkap kelas untuk display: "MK101 - Kelas A | Ganjil 2024/2025"
  String get namaLengkap =>
      '$matakuliahKode - Kelas $namaKelas | $semesterNama $tahunAkademik'
          .trim();

  factory KelasModel.fromMap(String id, Map<String, dynamic> map) {
    return KelasModel(
      id: id,
      namaKelas: map['namaKelas'] ?? '',
      matakuliahId: map['matakuliahId'] ?? '',
      matakuliahNama: map['matakuliahNama'] ?? '',
      matakuliahKode: map['matakuliahKode'] ?? '',
      dosenId: map['dosenId'] ?? '',
      dosenNama: map['dosenNama'] ?? '',
      asdosIds: List<String>.from(map['asdosIds'] ?? []),
      asdosNama: List<String>.from(map['asdosNama'] ?? []),
      semesterId: map['semesterId'] ?? '',
      semesterNama: map['semesterNama'] ?? '',
      kapasitas: map['kapasitas'] ?? 40,
      jumlahMahasiswa: map['jumlahMahasiswa'] ?? 0,
      status: map['status'] ?? true,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
      tahunAkademik: map['tahunAkademik'] ?? '',
      semesterAktif: map['semesterAktif'] ?? 1,
      bobotAbsensi: map['bobotAbsensi'] ?? 10,
      bobotTugas: map['bobotTugas'] ?? 20,
      bobotUTS: map['bobotUTS'] ?? 30,
      bobotUAS: map['bobotUAS'] ?? 40,
      bobotQuiz: map['bobotQuiz'] ?? 0,
      bobotPraktikum: map['bobotPraktikum'] ?? 0,
      bobotLaporan: map['bobotLaporan'] ?? 0,
      bobotLain: map['bobotLain'] ?? 0,
      fiturMateri: map['fiturMateri'] ?? true,
      fiturTugas: map['fiturTugas'] ?? true,
      fiturQuiz: map['fiturQuiz'] ?? false,
      fiturPengumuman: map['fiturPengumuman'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaKelas': namaKelas,
      'matakuliahId': matakuliahId,
      'matakuliahNama': matakuliahNama,
      'matakuliahKode': matakuliahKode,
      'dosenId': dosenId,
      'dosenNama': dosenNama,
      'asdosIds': asdosIds,
      'asdosNama': asdosNama,
      'semesterId': semesterId,
      'semesterNama': semesterNama,
      'kapasitas': kapasitas,
      'jumlahMahasiswa': jumlahMahasiswa,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'tahunAkademik': tahunAkademik,
      'semesterAktif': semesterAktif,
      'bobotAbsensi': bobotAbsensi,
      'bobotTugas': bobotTugas,
      'bobotUTS': bobotUTS,
      'bobotUAS': bobotUAS,
      'bobotQuiz': bobotQuiz,
      'bobotPraktikum': bobotPraktikum,
      'bobotLaporan': bobotLaporan,
      'bobotLain': bobotLain,
      'fiturMateri': fiturMateri,
      'fiturTugas': fiturTugas,
      'fiturQuiz': fiturQuiz,
      'fiturPengumuman': fiturPengumuman,
    };
  }

  KelasModel copyWith({
    String? id,
    String? namaKelas,
    String? matakuliahId,
    String? matakuliahNama,
    String? matakuliahKode,
    String? dosenId,
    String? dosenNama,
    List<String>? asdosIds,
    List<String>? asdosNama,
    String? semesterId,
    String? semesterNama,
    int? kapasitas,
    int? jumlahMahasiswa,
    bool? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? tahunAkademik,
    int? semesterAktif,
    int? bobotAbsensi,
    int? bobotTugas,
    int? bobotUTS,
    int? bobotUAS,
    int? bobotQuiz,
    int? bobotPraktikum,
    int? bobotLaporan,
    int? bobotLain,
    bool? fiturMateri,
    bool? fiturTugas,
    bool? fiturQuiz,
    bool? fiturPengumuman,
  }) {
    return KelasModel(
      id: id ?? this.id,
      namaKelas: namaKelas ?? this.namaKelas,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      matakuliahNama: matakuliahNama ?? this.matakuliahNama,
      matakuliahKode: matakuliahKode ?? this.matakuliahKode,
      dosenId: dosenId ?? this.dosenId,
      dosenNama: dosenNama ?? this.dosenNama,
      asdosIds: asdosIds ?? this.asdosIds,
      asdosNama: asdosNama ?? this.asdosNama,
      semesterId: semesterId ?? this.semesterId,
      semesterNama: semesterNama ?? this.semesterNama,
      kapasitas: kapasitas ?? this.kapasitas,
      jumlahMahasiswa: jumlahMahasiswa ?? this.jumlahMahasiswa,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tahunAkademik: tahunAkademik ?? this.tahunAkademik,
      semesterAktif: semesterAktif ?? this.semesterAktif,
      bobotAbsensi: bobotAbsensi ?? this.bobotAbsensi,
      bobotTugas: bobotTugas ?? this.bobotTugas,
      bobotUTS: bobotUTS ?? this.bobotUTS,
      bobotUAS: bobotUAS ?? this.bobotUAS,
      bobotQuiz: bobotQuiz ?? this.bobotQuiz,
      bobotPraktikum: bobotPraktikum ?? this.bobotPraktikum,
      bobotLaporan: bobotLaporan ?? this.bobotLaporan,
      bobotLain: bobotLain ?? this.bobotLain,
      fiturMateri: fiturMateri ?? this.fiturMateri,
      fiturTugas: fiturTugas ?? this.fiturTugas,
      fiturQuiz: fiturQuiz ?? this.fiturQuiz,
      fiturPengumuman: fiturPengumuman ?? this.fiturPengumuman,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KelasModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
