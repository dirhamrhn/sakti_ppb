import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/kelas_model.dart';
import '../../../../models/tugas_model.dart';
import '../../../../models/nilai_model.dart'; // contains MateriModel
import '../../../../models/pertemuan_model.dart';
import '../../../../models/class_enrollment_model.dart';
import '../../../../providers/dosen_dashboard_provider.dart';
import '../../../../repositories/kelas_repository.dart';
import '../../../../repositories/materi_repository.dart';
import '../../../../repositories/tugas_repository.dart';
import 'dosen_tugas_detail_page.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class DosenKelasDetailPage extends StatefulWidget {
  final String kelasId;
  const DosenKelasDetailPage({super.key, required this.kelasId});

  @override
  State<DosenKelasDetailPage> createState() => _DosenKelasDetailPageState();
}

class _DosenKelasDetailPageState extends State<DosenKelasDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  KelasModel? _kelas;
  bool _isLoadingKelas = true;

  // Data state
  List<MateriModel> _materiList = [];
  List<TugasModel> _tugasList = [];
  List<PertemuanModel> _pertemuanList = [];
  List<ClassEnrollmentModel> _enrollments = [];

  bool _isLoadingMateri = false;
  bool _isLoadingTugas = false;
  bool _isLoadingAbsensi = false;
  bool _isLoadingMahasiswa = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadKelasData().then((_) {
      _loadMateri();
      _loadTugas();
      _loadAbsensi();
      _loadMahasiswa();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadKelasData() async {
    setState(() => _isLoadingKelas = true);
    try {
      final k = await KelasRepository.instance.getById(widget.kelasId);
      setState(() {
        _kelas = k;
        _isLoadingKelas = false;
      });
    } catch (e) {
      debugPrint('Error load kelas: $e');
      if (mounted) AppSnackbar.error(context, 'Gagal memuat data kelas.');
      setState(() => _isLoadingKelas = false);
    }
  }

  Future<void> _loadMateri() async {
    setState(() => _isLoadingMateri = true);
    try {
      final list = await MateriRepository.instance.getByKelas(widget.kelasId);
      setState(() {
        _materiList = list;
        _isLoadingMateri = false;
      });
    } catch (e) {
      debugPrint('Error load materi: $e');
      setState(() => _isLoadingMateri = false);
    }
  }

  Future<void> _loadTugas() async {
    setState(() => _isLoadingTugas = true);
    try {
      // Query tugas
      final snap = await FirebaseFirestore.instance
          .collection('tugas')
          .where('kelasId', isEqualTo: widget.kelasId)
          .get();
      final list = snap.docs
          .map((d) => TugasModel.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.deadline.compareTo(b.deadline));
      setState(() {
        _tugasList = list;
        _isLoadingTugas = false;
      });
    } catch (e) {
      debugPrint('Error load tugas: $e');
      setState(() => _isLoadingTugas = false);
    }
  }

  Future<void> _loadAbsensi() async {
    setState(() => _isLoadingAbsensi = true);
    try {
      // Query all 16 pertemuan
      final snap = await FirebaseFirestore.instance
          .collection('pertemuan')
          .where('kelasId', isEqualTo: widget.kelasId)
          .get();
      final list = snap.docs
          .map((d) => PertemuanModel.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
      setState(() {
        _pertemuanList = list;
        _isLoadingAbsensi = false;
      });
    } catch (e) {
      debugPrint('Error load absensi: $e');
      setState(() => _isLoadingAbsensi = false);
    }
  }

  Future<void> _loadMahasiswa() async {
    setState(() => _isLoadingMahasiswa = true);
    try {
      final list = await context.read<DosenDashboardProvider>().getEnrollments(widget.kelasId);
      setState(() {
        _enrollments = list;
        _isLoadingMahasiswa = false;
      });
    } catch (e) {
      debugPrint('Error load mahasiswa: $e');
      setState(() => _isLoadingMahasiswa = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingKelas) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_kelas == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kelas')),
        body: const Center(child: Text('Kelas tidak ditemukan.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_kelas!.matakuliahNama} - ${ClassNameFormatter.format(_kelas!.namaKelas)}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Materi'),
            Tab(text: 'Tugas'),
            Tab(text: 'Absensi'),
            Tab(text: 'Mahasiswa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMateriTab(),
          _buildTugasTab(),
          _buildAbsensiTab(),
          _buildMahasiswaTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 1: MATERI
  // ─────────────────────────────────────────────────────────────
  Widget _buildMateriTab() {
    if (_isLoadingMateri) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showTambahMateriDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _materiList.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.menu_book_rounded,
              title: 'Materi Belum Tersedia',
              description: 'Klik tombol + di bawah untuk mengunggah materi perkuliahan baru.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _materiList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final mat = _materiList[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'P${mat.pertemuanKe}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mat.topik,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mat.deskripsi,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (mat.fileName.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.attach_file_rounded,
                                      size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      mat.fileName,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error),
                        onPressed: () => _handleDeleteMateri(mat.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showTambahMateriDialog() {
    final pertemuanController = TextEditingController(text: '1');
    final topikController = TextEditingController();
    final deskripsiController = TextEditingController();
    File? selectedFile;
    String selectedFileName = '';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Materi Kuliah'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: int.tryParse(pertemuanController.text) ?? 1,
                      decoration: const InputDecoration(labelText: 'Pertemuan Ke'),
                      items: List.generate(16, (index) => index + 1)
                          .map((val) => DropdownMenuItem<int>(
                                value: val,
                                child: Text('Pertemuan $val'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          pertemuanController.text = val.toString();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: topikController,
                      label: 'Topik Pembahasan',
                      hint: 'Isi judul topik materi...',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: deskripsiController,
                      label: 'Deskripsi Singkat',
                      hint: 'Isi deskripsi atau panduan...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // File selector UI
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedFileName.isEmpty
                                ? 'Belum ada berkas dilampirkan.'
                                : selectedFileName,
                            style: TextStyle(
                              color: selectedFileName.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                              fontSize: 12,
                              fontWeight: selectedFileName.isEmpty
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final pickerResult = await FilePicker.pickFiles(
                              type: FileType.any,
                            );
                            if (pickerResult != null && pickerResult.files.single.path != null) {
                              setDialogState(() {
                                selectedFile = File(pickerResult.files.single.path!);
                                selectedFileName = pickerResult.files.single.name;
                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file_rounded, size: 18),
                          label: const Text('Pilih Berkas'),
                        ),
                        if (selectedFileName.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedFile = null;
                                selectedFileName = '';
                              });
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            tooltip: 'Hapus berkas',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final topik = topikController.text.trim();
                          final deskripsi = deskripsiController.text.trim();
                          if (topik.isEmpty) {
                            AppSnackbar.error(context, 'Topik materi wajib diisi.');
                            return;
                          }

                          setDialogState(() => isUploading = true);
                          try {
                            String fileUrl = '';
                            if (selectedFile != null) {
                              fileUrl = await MateriRepository.instance
                                  .uploadFileMateri(selectedFile!, widget.kelasId, selectedFileName);
                            }

                            final newMateri = MateriModel(
                              id: '',
                              kelasId: widget.kelasId,
                              matakuliahNama: _kelas!.matakuliahNama,
                              pertemuanKe: int.tryParse(pertemuanController.text) ?? 1,
                              topik: topik,
                              deskripsi: deskripsi,
                              fileUrl: fileUrl,
                              fileName: selectedFileName,
                              fileSize: selectedFile != null ? selectedFile!.lengthSync() : 0,
                              fileType: selectedFile != null ? selectedFileName.split('.').last.toLowerCase() : '',
                              uploadedAt: selectedFile != null ? Timestamp.now() : null,
                              uploadedBy: _kelas!.dosenId,
                              tanggal: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                              createdAt: Timestamp.now(),
                            );

                            await MateriRepository.instance.create(newMateri);
                            if (context.mounted) {
                              Navigator.pop(context);
                              AppSnackbar.success(context, 'Materi kuliah berhasil diunggah.');
                              _loadMateri();
                            }
                          } catch (e) {
                            debugPrint('Error upload materi: $e');
                            if (context.mounted) {
                              AppSnackbar.error(context, 'Gagal mengunggah materi.');
                            }
                          } finally {
                            setDialogState(() => isUploading = false);
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleDeleteMateri(String id) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Materi',
      message: 'Apakah Anda yakin ingin menghapus materi kuliah ini?',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        try {
          await MateriRepository.instance.delete(id);
          if (mounted) AppSnackbar.success(context, 'Materi berhasil dihapus.');
          _loadMateri();
        } catch (e) {
          if (mounted) AppSnackbar.error(context, 'Gagal menghapus materi.');
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 2: TUGAS
  // ─────────────────────────────────────────────────────────────
  Widget _buildTugasTab() {
    if (_isLoadingTugas) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showTambahTugasDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _tugasList.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.task_rounded,
              title: 'Belum Ada Tugas',
              description: 'Klik tombol + di bawah untuk membuat tugas mahasiswa baru.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _tugasList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tugas = _tugasList[index];
                final deadlineDate = tugas.deadline.toDate();
                final formattedDeadline = DateFormat('dd MMM yyyy, HH:mm').format(deadlineDate);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assignment_turned_in_outlined,
                            color: Colors.orange, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DosenTugasDetailPage(
                                  tugas: tugas,
                                  kelas: _kelas!,
                                ),
                              ),
                            ).then((_) => _loadTugas());
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tugas.judul,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Deadline: $formattedDeadline',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bobot: ${tugas.bobotNilai}%',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (tugas.fileName.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.attach_file_rounded,
                                        size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        tugas.fileName,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error),
                        onPressed: () => _handleDeleteTugas(tugas.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showTambahTugasDialog() {
    final judulController = TextEditingController();
    final deskripsiController = TextEditingController();
    final bobotController = TextEditingController(text: '20');
    DateTime selectedDeadlineDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedDeadlineTime = const TimeOfDay(hour: 23, minute: 59);
    File? selectedFile;
    String selectedFileName = '';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Buat Tugas Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      controller: judulController,
                      label: 'Judul Tugas',
                      hint: 'Isi judul tugas...',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: deskripsiController,
                      label: 'Deskripsi Instruksi',
                      hint: 'Isi instruksi pengerjaan tugas...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: bobotController,
                      label: 'Bobot Nilai (%)',
                      hint: 'Contoh: 20',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    // Date & Time selection
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDeadlineDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 120)),
                              );
                              if (pickedDate != null) {
                                setDialogState(() => selectedDeadlineDate = pickedDate);
                              }
                            },
                            icon: const Icon(Icons.date_range_rounded, size: 18),
                            label: Text(
                              DateFormat('dd MMM yyyy').format(selectedDeadlineDate),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: selectedDeadlineTime,
                              );
                              if (pickedTime != null) {
                                setDialogState(() => selectedDeadlineTime = pickedTime);
                              }
                            },
                            icon: const Icon(Icons.access_time_rounded, size: 18),
                            label: Text(selectedDeadlineTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedFileName.isEmpty
                                ? 'Belum ada berkas instruksi.'
                                : selectedFileName,
                            style: TextStyle(
                              color: selectedFileName.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                              fontSize: 12,
                              fontWeight: selectedFileName.isEmpty
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final pickerResult = await FilePicker.pickFiles(
                              type: FileType.any,
                            );
                            if (pickerResult != null && pickerResult.files.single.path != null) {
                              setDialogState(() {
                                selectedFile = File(pickerResult.files.single.path!);
                                selectedFileName = pickerResult.files.single.name;
                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file_rounded, size: 18),
                          label: const Text('Pilih Berkas'),
                        ),
                        if (selectedFileName.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedFile = null;
                                selectedFileName = '';
                              });
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            tooltip: 'Hapus berkas',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final judul = judulController.text.trim();
                          final deskripsi = deskripsiController.text.trim();
                          final bobotStr = bobotController.text.trim();

                          if (judul.isEmpty || deskripsi.isEmpty) {
                            AppSnackbar.error(context, 'Harap isi semua formulir.');
                            return;
                          }

                          final bobot = int.tryParse(bobotStr) ?? 20;

                          setDialogState(() => isSaving = true);
                          try {
                            String fileUrl = '';
                            if (selectedFile != null) {
                              fileUrl = await TugasRepository.instance
                                  .uploadFileTugas(selectedFile!, widget.kelasId, selectedFileName);
                            }

                            final deadlineDateTime = DateTime(
                              selectedDeadlineDate.year,
                              selectedDeadlineDate.month,
                              selectedDeadlineDate.day,
                              selectedDeadlineTime.hour,
                              selectedDeadlineTime.minute,
                            );

                            final newTugas = TugasModel(
                              id: '',
                              kelasId: widget.kelasId,
                              kelasNama: _kelas!.namaKelas,
                              matakuliahNama: _kelas!.matakuliahNama,
                              matakuliahKode: _kelas!.matakuliahKode,
                              dosenId: _kelas!.dosenId,
                              dosenNama: _kelas!.dosenNama,
                              judul: judul,
                              deskripsi: deskripsi,
                              deadline: Timestamp.fromDate(deadlineDateTime),
                              bobotNilai: bobot,
                              isActive: true,
                              fileUrl: fileUrl,
                              fileName: selectedFileName,
                              fileSize: selectedFile != null ? selectedFile!.lengthSync() : 0,
                              fileType: selectedFile != null ? selectedFileName.split('.').last.toLowerCase() : '',
                              uploadedAt: selectedFile != null ? Timestamp.now() : null,
                              uploadedBy: _kelas!.dosenId,
                              createdAt: Timestamp.now(),
                              updatedAt: Timestamp.now(),
                            );

                            await context.read<DosenDashboardProvider>().createTugas(newTugas);
                            if (context.mounted) {
                              Navigator.pop(context);
                              AppSnackbar.success(context, 'Tugas baru berhasil diterbitkan.');
                              _loadTugas();
                            }
                          } catch (e) {
                            debugPrint('Error create tugas: $e');
                            if (context.mounted) {
                              AppSnackbar.error(context, 'Gagal menerbitkan tugas.');
                            }
                          } finally {
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleDeleteTugas(String id) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Tugas',
      message: 'Apakah Anda yakin ingin menghapus tugas ini?',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final success = await context.read<DosenDashboardProvider>().deleteTugas(id);
        if (success && mounted) {
          AppSnackbar.success(context, 'Tugas berhasil dihapus.');
          _loadTugas();
        } else if (mounted) {
          AppSnackbar.error(context, 'Gagal menghapus tugas.');
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 3: ABSENSI HISTORIS (PERTEMUAN 1 - 16)
  // ─────────────────────────────────────────────────────────────
  Widget _buildAbsensiTab() {
    if (_isLoadingAbsensi) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pertemuanList.isEmpty) {
      return const Center(
        child: Text('Pertemuan kelas belum dibuat atau tidak ditemukan.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _pertemuanList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = _pertemuanList[index];
        final isBelumStr = p.status == 'belum';
        final isAktifStr = p.status == 'aktif';

        Color statusColor = AppColors.textSecondary;
        String statusLabel = 'Nanti';
        if (p.status == 'selesai') {
          statusColor = AppColors.success;
          statusLabel = 'Selesai';
        } else if (p.status == 'aktif') {
          statusColor = AppColors.primary;
          statusLabel = 'Aktif';
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.08),
              child: Text(
                '${p.pertemuanKe}',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              p.topik.isEmpty ? 'Pertemuan ${p.pertemuanKe}' : p.topik,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              p.tanggal.isEmpty ? 'Tanggal belum ditentukan' : p.tanggal,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            onTap: isBelumStr
                ? () {
                    AppSnackbar.info(
                      context,
                      'Pertemuan ini belum dimulai. Buka absensi via Dashboard/Absensi utama.',
                    );
                  }
                : () => _showAbsensiPertemuanDetailDialog(p),
          ),
        );
      },
    );
  }

  void _showAbsensiPertemuanDetailDialog(PertemuanModel pertemuan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Absensi Pertemuan ${pertemuan.pertemuanKe}',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          pertemuan.topik,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Student attendances stream
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: context.read<DosenDashboardProvider>().getAbsensiStream(pertemuan.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final listAbsen = snapshot.data?.docs ?? [];
                    final Map<String, Map<String, dynamic>> absensiMap = {};
                    for (final doc in listAbsen) {
                      final data = doc.data();
                      absensiMap[data['mahasiswaId']] = {
                        'id': doc.id,
                        'status': data['status'],
                        'keterangan': data['keterangan'] ?? '',
                        'jam': data['waktuAbsen'] != null
                            ? DateFormat('HH:mm').format((data['waktuAbsen'] as Timestamp).toDate())
                            : '',
                      };
                    }

                    // Render list
                    return ListView.separated(
                      itemCount: _enrollments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final e = _enrollments[index];
                        final abs = absensiMap[e.mahasiswaId];
                        final String status = abs?['status'] ?? 'alpha';
                        final String keterangan = abs?['keterangan'] ?? '';
                        final String jam = abs?['jam'] ?? '';

                        Color badgeColor = AppColors.error;
                        String statusLabel = 'Alpha';

                        if (status == 'hadir') {
                          badgeColor = AppColors.success;
                          statusLabel = 'Hadir';
                        } else if (status == 'terlambat') {
                          badgeColor = Colors.orange;
                          statusLabel = 'Terlambat';
                        } else if (status == 'izin' || status == 'sakit') {
                          badgeColor = Colors.blue;
                          statusLabel = status.toUpperCase();
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.mahasiswaNama,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'NIM: ${e.mahasiswaNim} ${jam.isNotEmpty ? " •  $jam WITA" : ""}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                    if (keterangan.isNotEmpty)
                                      Text(
                                        'Ket: $keterangan',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => _editStatusAbsensiDialog(
                                  context,
                                  pertemuan,
                                  e.mahasiswaId,
                                  e.mahasiswaNama,
                                  e.mahasiswaNim,
                                  abs?['id'],
                                  status,
                                  keterangan,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: badgeColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editStatusAbsensiDialog(
    BuildContext context,
    PertemuanModel pertemuan,
    String mahasiswaId,
    String mahasiswaNama,
    String mahasiswaNim,
    String? absensiId,
    String statusSkrg,
    String keteranganSkrg,
  ) {
    String selectedStatus = statusSkrg;
    final ketController = TextEditingController(text: keteranganSkrg);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Absen: $mahasiswaNama'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status Kehadiran'),
                    items: const [
                      DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                      DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                      DropdownMenuItem(value: 'izin', child: Text('Izin')),
                      DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                      DropdownMenuItem(value: 'alpha', child: Text('Alpha / Belum Absen')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedStatus = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: ketController,
                    label: 'Keterangan Tambahan',
                    hint: 'Contoh: Izin kegiatan mahasiswa...',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final provider = context.read<DosenDashboardProvider>();
                    bool success = false;

                    if (selectedStatus == 'alpha') {
                      if (absensiId != null) {
                        // Delete record to make it Alpha
                        success = await provider.deleteAbsensiRecord(absensiId);
                      } else {
                        success = true;
                      }
                    } else {
                      if (absensiId != null) {
                        // Update existing record
                        success = await provider.updateAbsensiStatus(
                          absensiId,
                          selectedStatus,
                          ketController.text.trim(),
                        );
                      } else {
                        // Create manual attendance record
                        final Map<String, dynamic> data = {
                          'mahasiswaId': mahasiswaId,
                          'mahasiswaNama': mahasiswaNama,
                          'mahasiswaNim': mahasiswaNim,
                          'kelasId': widget.kelasId,
                          'kelasNama': _kelas!.namaKelas,
                          'jadwalId': '',
                          'matakuliahId': _kelas!.matakuliahId,
                          'matakuliahNama': _kelas!.matakuliahNama,
                          'matakuliahKode': _kelas!.matakuliahKode,
                          'pertemuanKe': pertemuan.pertemuanKe,
                          'pertemuanId': pertemuan.id,
                          'jenisSesi': pertemuan.jenisSesi,
                          'tanggal': pertemuan.tanggal,
                          'jamAbsensi': DateFormat('HH:mm').format(DateTime.now()),
                          'status': selectedStatus,
                          'keterangan': ketController.text.trim().isEmpty ? 'Absensi manual oleh Dosen' : ketController.text.trim(),
                          'isCheckedIn': true,
                          'latitude': 0.0,
                          'longitude': 0.0,
                          'jarak': 0.0,
                          'metodeAbsensi': 'manual',
                          'selfieUrl': '',
                        };
                        success = await provider.addAbsensiManual(data);
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      if (success) {
                        AppSnackbar.success(context, 'Status absensi berhasil diperbarui.');
                      } else {
                        AppSnackbar.error(context, 'Gagal memperbarui status absensi.');
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 4: MAHASISWA
  // ─────────────────────────────────────────────────────────────
  Widget _buildMahasiswaTab() {
    if (_isLoadingMahasiswa) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _enrollments.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: 'Tidak Ada Mahasiswa',
              description: 'Belum ada mahasiswa terdaftar di kelas ini.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _enrollments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final enroll = _enrollments[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enroll.mahasiswaNama,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'NIM: ${enroll.mahasiswaNim}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_remove_outlined,
                            color: AppColors.error),
                        onPressed: () => _handleUnenrollStudent(enroll.id, enroll.mahasiswaNama),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _handleUnenrollStudent(String id, String nama) {
    ConfirmDialog.show(
      context,
      title: 'Keluarkan Mahasiswa',
      message: 'Apakah Anda yakin ingin mengeluarkan $nama dari kelas ini?',
      confirmLabel: 'Keluarkan',
      isDanger: true,
      onConfirm: () async {
        final success = await context
            .read<DosenDashboardProvider>()
            .unenrollStudent(id, widget.kelasId);
        if (success && mounted) {
          AppSnackbar.success(context, '$nama berhasil dikeluarkan dari kelas.');
          _loadMahasiswa();
        } else if (mounted) {
          AppSnackbar.error(context, 'Gagal mengeluarkan mahasiswa.');
        }
      },
    );
  }
}
