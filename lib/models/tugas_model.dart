import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk Tugas Mahasiswa.
/// Disimpan di collection 'assignments'.
class TugasModel {
  final String id;
  final String kelasId;
  final String kelasNama;
  final String matakuliahNama;
  final String matakuliahKode;
  final String dosenId;
  final String dosenNama;
  final String judul;
  final String deskripsi;
  final Timestamp deadline;
  final int bobotNilai; // 0-100
  final bool isActive;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String fileType;
  final Timestamp? uploadedAt;
  final String uploadedBy;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String tipe; // 'tugas', 'lp', 'tp'
  final bool isOpen;

  const TugasModel({
    required this.id,
    required this.kelasId,
    required this.kelasNama,
    required this.matakuliahNama,
    required this.matakuliahKode,
    required this.dosenId,
    required this.dosenNama,
    required this.judul,
    required this.deskripsi,
    required this.deadline,
    required this.bobotNilai,
    required this.isActive,
    this.fileUrl = '',
    this.fileName = '',
    this.fileSize = 0,
    this.fileType = '',
    this.uploadedAt,
    this.uploadedBy = '',
    required this.createdAt,
    required this.updatedAt,
    this.tipe = 'tugas',
    this.isOpen = true,
  });

  factory TugasModel.fromMap(String id, Map<String, dynamic> map) {
    return TugasModel(
      id: id,
      kelasId: map['kelasId'] ?? '',
      kelasNama: map['kelasNama'] ?? '',
      matakuliahNama: map['matakuliahNama'] ?? '',
      matakuliahKode: map['matakuliahKode'] ?? '',
      dosenId: map['dosenId'] ?? '',
      dosenNama: map['dosenNama'] ?? '',
      judul: map['judul'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      deadline: map['deadline'] ?? Timestamp.now(),
      bobotNilai: map['bobotNilai'] ?? 0,
      isActive: map['isActive'] ?? true,
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      fileType: map['fileType'] ?? '',
      uploadedAt: map['uploadedAt'],
      uploadedBy: map['uploadedBy'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
      tipe: map['tipe'] ?? 'tugas',
      isOpen: map['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kelasId': kelasId,
      'kelasNama': kelasNama,
      'matakuliahNama': matakuliahNama,
      'matakuliahKode': matakuliahKode,
      'dosenId': dosenId,
      'dosenNama': dosenNama,
      'judul': judul,
      'deskripsi': deskripsi,
      'deadline': deadline,
      'bobotNilai': bobotNilai,
      'isActive': isActive,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileType': fileType,
      'uploadedAt': uploadedAt,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'tipe': tipe,
      'isOpen': isOpen,
    };
  }

  bool get isOverdue => deadline.toDate().isBefore(DateTime.now());

  TugasModel copyWith({
    String? id,
    String? kelasId,
    String? kelasNama,
    String? matakuliahNama,
    String? matakuliahKode,
    String? dosenId,
    String? dosenNama,
    String? judul,
    String? deskripsi,
    Timestamp? deadline,
    int? bobotNilai,
    bool? isActive,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    Timestamp? uploadedAt,
    String? uploadedBy,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? tipe,
    bool? isOpen,
  }) {
    return TugasModel(
      id: id ?? this.id,
      kelasId: kelasId ?? this.kelasId,
      kelasNama: kelasNama ?? this.kelasNama,
      matakuliahNama: matakuliahNama ?? this.matakuliahNama,
      matakuliahKode: matakuliahKode ?? this.matakuliahKode,
      dosenId: dosenId ?? this.dosenId,
      dosenNama: dosenNama ?? this.dosenNama,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      deadline: deadline ?? this.deadline,
      bobotNilai: bobotNilai ?? this.bobotNilai,
      isActive: isActive ?? this.isActive,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tipe: tipe ?? this.tipe,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

/// Model untuk Pengumpulan Tugas Mahasiswa.
/// Disimpan di collection 'submissions'.
class SubmisiModel {
  final String id;
  final String tugasId;
  final String kelasId;
  final String mahasiswaId;
  final String mahasiswaNama;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String fileType;
  final Timestamp? uploadedAt;
  final String uploadedBy;
  final String catatan;
  final double? nilai;
  final String feedback;
  final bool isGraded;
  final Timestamp submittedAt;
  final Timestamp? gradedAt;

  const SubmisiModel({
    required this.id,
    required this.tugasId,
    required this.kelasId,
    required this.mahasiswaId,
    required this.mahasiswaNama,
    required this.fileUrl,
    required this.fileName,
    this.fileSize = 0,
    this.fileType = '',
    this.uploadedAt,
    this.uploadedBy = '',
    required this.catatan,
    this.nilai,
    required this.feedback,
    required this.isGraded,
    required this.submittedAt,
    this.gradedAt,
  });

  factory SubmisiModel.fromMap(String id, Map<String, dynamic> map) {
    return SubmisiModel(
      id: id,
      tugasId: map['tugasId'] ?? '',
      kelasId: map['kelasId'] ?? '',
      mahasiswaId: map['mahasiswaId'] ?? '',
      mahasiswaNama: map['mahasiswaNama'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      fileType: map['fileType'] ?? '',
      uploadedAt: map['uploadedAt'],
      uploadedBy: map['uploadedBy'] ?? '',
      catatan: map['catatan'] ?? '',
      nilai: (map['nilai'] as num?)?.toDouble(),
      feedback: map['feedback'] ?? '',
      isGraded: map['isGraded'] ?? false,
      submittedAt: map['submittedAt'] ?? Timestamp.now(),
      gradedAt: map['gradedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tugasId': tugasId,
      'kelasId': kelasId,
      'mahasiswaId': mahasiswaId,
      'mahasiswaNama': mahasiswaNama,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileType': fileType,
      'uploadedAt': uploadedAt,
      'uploadedBy': uploadedBy,
      'catatan': catatan,
      'nilai': nilai,
      'feedback': feedback,
      'isGraded': isGraded,
      'submittedAt': submittedAt,
      'gradedAt': gradedAt,
    };
  }
}
