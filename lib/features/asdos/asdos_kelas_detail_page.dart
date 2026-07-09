import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/sakti_pdf_viewer_page.dart';
import '../../models/kelas_model.dart';
import '../../models/tugas_model.dart';
import '../../models/pertemuan_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/absensi_model.dart';
import '../../models/class_enrollment_model.dart';
import '../../providers/asdos_dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import 'asdos_review_submisi_page.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class AsdosKelasDetailPage extends StatefulWidget {
  final KelasModel kelas;

  const AsdosKelasDetailPage({
    super.key,
    required this.kelas,
  });

  @override
  State<AsdosKelasDetailPage> createState() => _AsdosKelasDetailPageState();
}

class _AsdosKelasDetailPageState extends State<AsdosKelasDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late KelasModel _kelas;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _kelas = widget.kelas;
    _reloadKelas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reloadKelas() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('kelas').doc(widget.kelas.id).get();
      if (doc.exists && mounted) {
        setState(() {
          _kelas = KelasModel.fromMap(doc.id, doc.data()!);
        });
      }
    } catch (e) {
      debugPrint('Error reloading kelas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _kelas.matakuliahNama,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            Text(
              'Kelas ${_kelas.namaKelas}  •  Sisi Asisten Dosen',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Materi'),
            Tab(text: 'LP (Laporan)'),
            Tab(text: 'TP (Pendahuluan)'),
            Tab(text: 'Pertemuan'),
            Tab(text: 'Mahasiswa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AsdosMateriTab(kelas: _kelas),
          _AsdosTugasTab(kelas: _kelas, tipe: 'lp'),
          _AsdosTugasTab(kelas: _kelas, tipe: 'tp'),
          _AsdosPertemuanTab(kelas: _kelas),
          _AsdosMahasiswaTab(kelas: _kelas, onUnenroll: _reloadKelas),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUB-TAB 1: MATERI PRAKTIKUM (MODUL 1-8)
// ─────────────────────────────────────────────────────────────
class _AsdosMateriTab extends StatefulWidget {
  final KelasModel kelas;

  const _AsdosMateriTab({required this.kelas});

  @override
  State<_AsdosMateriTab> createState() => _AsdosMateriTabState();
}

class _AsdosMateriTabState extends State<_AsdosMateriTab> {
  List<Map<String, dynamic>> _modulList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModul();
  }

  Future<void> _loadModul() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('modul_praktikum')
          .where('kelasId', isEqualTo: widget.kelas.id)
          .get();

      final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      if (mounted) {
        setState(() {
          _modulList = list;
        });
      }
    } catch (e) {
      debugPrint('Error load modul: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditModulDialog({Map<String, dynamic>? modul, required int modulKe}) {
    final titleController = TextEditingController(text: modul != null ? modul['judul'] : '');
    final descController = TextEditingController(text: modul != null ? modul['deskripsi'] : '');
    File? selectedFile;
    String selectedFileName = modul != null ? modul['fileName'] ?? '' : '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(modul == null ? 'Unggah Modul Praktikum $modulKe' : 'Edit Modul Praktikum $modulKe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: titleController,
                  label: 'Judul Modul',
                  hint: 'Contoh: Pengenalan Sintaks Kotlin',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: descController,
                  label: 'Deskripsi',
                  hint: 'Tulis ringkasan isi modul...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
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
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedFile != null ? AppColors.successLight : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedFile != null ? AppColors.success : AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          selectedFile != null ? Icons.check_circle_rounded : Icons.picture_as_pdf_rounded,
                          color: selectedFile != null ? AppColors.success : AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedFileName.isNotEmpty ? selectedFileName : 'Pilih Berkas PDF Modul',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selectedFile != null ? AppColors.success : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final judul = titleController.text.trim();
                final deskripsi = descController.text.trim();

                if (judul.isEmpty) {
                  AppSnackbar.error(context, 'Judul modul wajib diisi.');
                  return;
                }

                if (modul == null && selectedFile == null) {
                  AppSnackbar.error(context, 'Harap pilih file PDF modul.');
                  return;
                }

                if (selectedFileName.isNotEmpty && !selectedFileName.toLowerCase().endsWith('.pdf')) {
                  AppSnackbar.error(context, 'Modul harus berupa berkas PDF.');
                  return;
                }

                Navigator.pop(context);
                final provider = context.read<AsdosDashboardProvider>();
                bool success = false;

                if (modul == null) {
                  success = await provider.createModul(
                    kelasId: widget.kelas.id,
                    modulKe: modulKe,
                    judul: judul,
                    deskripsi: deskripsi,
                    file: selectedFile!,
                    fileName: selectedFileName,
                  );
                } else {
                  success = await provider.updateModul(
                    id: modul['id'],
                    kelasId: widget.kelas.id,
                    judul: judul,
                    deskripsi: deskripsi,
                    file: selectedFile,
                    fileName: selectedFile != null ? selectedFileName : null,
                  );
                }

                if (success) {
                  if (mounted) AppSnackbar.success(context, 'Modul praktikum berhasil disimpan.');
                  _loadModul();
                } else {
                  if (mounted) AppSnackbar.error(context, provider.errorMessage ?? 'Gagal menyimpan modul.');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteModul(String id) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Modul',
      message: 'Apakah Anda yakin ingin menghapus modul praktikum ini?',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final provider = context.read<AsdosDashboardProvider>();
        final success = await provider.deleteModul(id);
        if (success) {
          if (mounted) AppSnackbar.success(context, 'Modul praktikum berhasil dihapus.');
          _loadModul();
        } else {
          if (mounted) AppSnackbar.error(context, provider.errorMessage ?? 'Gagal menghapus modul.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final modulKe = index + 1;
        Map<String, dynamic>? currentModul;
        for (final m in _modulList) {
          if (m['modulKe'] == modulKe) {
            currentModul = m;
            break;
          }
        }

        final bool hasFile = currentModul != null && (currentModul['fileUrl'] ?? '').toString().isNotEmpty;

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (hasFile ? AppColors.primaryContainer : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: (hasFile ? AppColors.primary : Colors.grey),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modul Praktikum $modulKe',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentModul != null ? currentModul['judul'] : 'Belum Diunggah',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: currentModul != null ? AppColors.textPrimary : AppColors.textDisabled,
                      ),
                    ),
                    if (currentModul != null && (currentModul['deskripsi'] ?? '').toString().isNotEmpty)
                      Text(
                        currentModul['deskripsi'],
                        style: AppTextStyles.cardSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  if (hasFile) ...[
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.blue),
                      tooltip: 'Lihat Modul PDF',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SaktiPdfViewerPage(
                              title: 'Modul $modulKe: ${currentModul!['judul']}',
                              pdfUrl: currentModul['fileUrl'],
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppColors.warning, size: 20),
                          tooltip: 'Edit Modul',
                          onPressed: () => _showAddEditModulDialog(modul: currentModul, modulKe: modulKe),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          tooltip: 'Hapus Modul',
                          onPressed: () => _deleteModul(currentModul!['id']),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditModulDialog(modulKe: modulKe),
                      icon: const Icon(Icons.upload_file_rounded, size: 14),
                      label: const Text('Unggah', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUB-TAB 2 & 3: LP (LAPORAN PRAKTIKUM) & TP (TUGAS PENDAHULUAN)
// ─────────────────────────────────────────────────────────────
class _AsdosTugasTab extends StatefulWidget {
  final KelasModel kelas;
  final String tipe; // 'lp' atau 'tp'

  const _AsdosTugasTab({
    required this.kelas,
    required this.tipe,
  });

  @override
  State<_AsdosTugasTab> createState() => _AsdosTugasTabState();
}

class _AsdosTugasTabState extends State<_AsdosTugasTab> {
  List<TugasModel> _tugasList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTugas();
  }

  Future<void> _loadTugas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tugas')
          .where('kelasId', isEqualTo: widget.kelas.id)
          .where('tipe', isEqualTo: widget.tipe)
          .get();

      final list = snap.docs.map((d) => TugasModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (mounted) {
        setState(() {
          _tugasList = list;
        });
      }
    } catch (e) {
      debugPrint('Error load tugas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditTugasDialog({TugasModel? tugas}) {
    final titleController = TextEditingController(text: tugas?.judul ?? '');
    final descController = TextEditingController(text: tugas?.deskripsi ?? '');
    final bobotController = TextEditingController(text: tugas != null ? tugas.bobotNilai.toString() : '10');
    DateTime selectedDeadline = tugas?.deadline.toDate() ?? DateTime.now().add(const Duration(days: 7));
    File? selectedFile;
    String selectedFileName = tugas?.fileName ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(tugas == null 
                ? 'Buat Soal ${widget.tipe.toUpperCase()}' 
                : 'Edit Soal ${widget.tipe.toUpperCase()}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: titleController,
                    label: 'Judul Tugas',
                    hint: 'Contoh: ${widget.tipe.toUpperCase()} 1: Dasar Dart',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: descController,
                    label: 'Deskripsi / Instruksi',
                    hint: 'Tulis soal atau instruksi pengerjaan...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: bobotController,
                    label: 'Bobot Nilai (%)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Deadline Pengumpulan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      DateFormat('d MMM yyyy, HH:mm', 'id').format(selectedDeadline),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDeadline,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDeadline),
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedDeadline = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
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
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedFile != null ? AppColors.successLight : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selectedFile != null ? AppColors.success : AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selectedFile != null ? Icons.check_circle_rounded : Icons.attach_file_rounded,
                            color: selectedFile != null ? AppColors.success : AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedFileName.isNotEmpty ? selectedFileName : 'Unggah File Lampiran Soal (Opsional)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selectedFile != null ? AppColors.success : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final judul = titleController.text.trim();
                  final deskripsi = descController.text.trim();
                  final bobotVal = int.tryParse(bobotController.text) ?? 10;

                  if (judul.isEmpty) {
                    AppSnackbar.error(context, 'Judul tugas wajib diisi.');
                    return;
                  }

                  Navigator.pop(context);
                  final provider = context.read<AsdosDashboardProvider>();
                  final user = context.read<AuthProvider>().user;
                  bool success = false;

                  if (tugas == null) {
                    final newTugas = TugasModel(
                      id: '',
                      kelasId: widget.kelas.id,
                      kelasNama: widget.kelas.namaKelas,
                      matakuliahNama: widget.kelas.matakuliahNama,
                      matakuliahKode: widget.kelas.matakuliahKode,
                      dosenId: user?.uid ?? '',
                      dosenNama: user?.nama ?? 'Asisten Dosen',
                      judul: judul,
                      deskripsi: deskripsi,
                      deadline: Timestamp.fromDate(selectedDeadline),
                      bobotNilai: bobotVal,
                      isActive: true,
                      tipe: widget.tipe,
                      isOpen: true,
                      createdAt: Timestamp.now(),
                      updatedAt: Timestamp.now(),
                    );
                    success = await provider.createTugas(
                      tugas: newTugas,
                      file: selectedFile,
                      fileName: selectedFile != null ? selectedFileName : null,
                    );
                  } else {
                    final updatedTugas = tugas.copyWith(
                      judul: judul,
                      deskripsi: deskripsi,
                      bobotNilai: bobotVal,
                      deadline: Timestamp.fromDate(selectedDeadline),
                    );
                    success = await provider.updateTugas(
                      updatedTugas,
                      file: selectedFile,
                      fileName: selectedFile != null ? selectedFileName : null,
                    );
                  }

                  if (success) {
                    if (mounted) AppSnackbar.success(context, 'Tugas berhasil disimpan.');
                    _loadTugas();
                  } else {
                    if (mounted) AppSnackbar.error(context, provider.errorMessage ?? 'Gagal menyimpan tugas.');
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteTugas(String id) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Tugas',
      message: 'Apakah Anda yakin ingin menghapus tugas/LP/TP ini beserta seluruh submisinya?',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final provider = context.read<AsdosDashboardProvider>();
        final success = await provider.deleteTugas(id);
        if (success) {
          if (mounted) AppSnackbar.success(context, 'Tugas berhasil dihapus.');
          _loadTugas();
        } else {
          if (mounted) AppSnackbar.error(context, provider.errorMessage ?? 'Gagal menghapus tugas.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: AppButton(
            label: 'Buat Soal ${widget.tipe.toUpperCase()} Baru',
            icon: Icons.add_rounded,
            onPressed: () => _showAddEditTugasDialog(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _tugasList.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.task_rounded,
                  title: 'Belum Ada Soal ${widget.tipe.toUpperCase()}',
                  description: 'Silakan buat soal praktikum pertama Anda menggunakan tombol di atas.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tugasList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final t = _tugasList[idx];
                    return _TugasCard(
                      tugas: t,
                      kelas: widget.kelas,
                      onEdit: () => _showAddEditTugasDialog(tugas: t),
                      onDelete: () => _deleteTugas(t.id),
                      onRefresh: _loadTugas,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TugasCard extends StatefulWidget {
  final TugasModel tugas;
  final KelasModel kelas;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const _TugasCard({
    required this.tugas,
    required this.kelas,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<_TugasCard> createState() => _TugasCardState();
}

class _TugasCardState extends State<_TugasCard> {
  bool _isExpanded = false;
  List<ClassEnrollmentModel> _enrollments = [];
  List<SubmisiModel> _submissions = [];
  bool _isLoadingSubmisi = false;

  Future<void> _loadSubmissions() async {
    setState(() => _isLoadingSubmisi = true);
    try {
      final db = FirebaseFirestore.instance;
      final enrollSnap = await db
          .collection('class_enrollments')
          .where('kelasId', isEqualTo: widget.kelas.id)
          .get();

      _enrollments = enrollSnap.docs
          .map((d) => ClassEnrollmentModel.fromMap(d.id, d.data()))
          .toList();
      _enrollments.sort((a, b) => a.mahasiswaNama.toLowerCase().compareTo(b.mahasiswaNama.toLowerCase()));

      final subSnap = await db
          .collection('submissions')
          .where('tugasId', isEqualTo: widget.tugas.id)
          .get();

      _submissions = subSnap.docs
          .map((d) => SubmisiModel.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      debugPrint('Error load submisinya: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSubmisi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tugas;
    final dlDate = t.deadline.toDate();
    final bool isOverdue = dlDate.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(t.judul, style: AppTextStyles.cardTitle),
            subtitle: Text(
              'Deadline: ${DateFormat('d MMM yyyy, HH:mm', 'id').format(dlDate)} (${isOverdue ? "Lewat" : "Aktif"})',
              style: TextStyle(
                color: isOverdue ? AppColors.error : AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.warning, size: 20),
                  onPressed: widget.onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: widget.onDelete,
                ),
                Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              ],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              if (_isExpanded) {
                _loadSubmissions();
              }
            },
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status Penerimaan Tugas:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Row(
                        children: [
                          Text(
                            t.isOpen ? 'Buka Pengumpulan' : 'Tutup Pengumpulan',
                            style: TextStyle(
                              color: t.isOpen ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Switch(
                            value: t.isOpen,
                            activeColor: AppColors.success,
                            onChanged: (val) async {
                              final success = await context.read<AsdosDashboardProvider>().toggleTugasOpen(t.id, val);
                              if (success) {
                                widget.onRefresh();
                                _loadSubmissions();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingSubmisi)
                    const Center(child: CircularProgressIndicator())
                  else if (_enrollments.isEmpty)
                    const Text('Belum ada mahasiswa terdaftar di kelas ini.')
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _enrollments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final student = _enrollments[index];
                        final subIdx = _submissions.indexWhere((s) => s.mahasiswaId == student.mahasiswaId);
                        final sub = subIdx != -1 ? _submissions[subIdx] : null;

                        String statusLabel = 'Belum Mengumpulkan';
                        Color badgeColor = Colors.grey;

                        if (sub != null) {
                          final subTime = sub.submittedAt.toDate();
                          final bool isLate = subTime.isAfter(dlDate);
                          if (isLate) {
                            statusLabel = sub.isGraded ? 'Sudah Mengumpulkan (Terlambat - Dinilai)' : 'Sudah Mengumpulkan (Terlambat)';
                            badgeColor = AppColors.warning;
                          } else {
                            statusLabel = sub.isGraded ? 'Sudah Mengumpulkan (Dinilai)' : 'Sudah Mengumpulkan';
                            badgeColor = AppColors.success;
                          }
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student.mahasiswaNama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('NIM. ${student.mahasiswaNim}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (sub != null && sub.isGraded)
                                      Text(
                                        'Nilai: ${sub.nilai?.toStringAsFixed(1) ?? "-"}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                  ],
                                ),
                              ),
                              if (sub != null)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AsdosReviewSubmisiPage(
                                          submission: sub,
                                          kelas: widget.kelas,
                                          tugas: widget.tugas,
                                          mahasiswaNim: student.mahasiswaNim,
                                        ),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        _loadSubmissions();
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    backgroundColor: sub.isGraded ? Colors.grey.shade400 : AppColors.primary,
                                  ),
                                  child: Text(
                                    sub.isGraded ? 'Ubah Nilai' : 'Buka & Nilai',
                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUB-TAB 4: ABSENSI PERTEMUAN (PRAKTIKUM 1-8)
// ─────────────────────────────────────────────────────────────
class _AsdosPertemuanTab extends StatefulWidget {
  final KelasModel kelas;

  const _AsdosPertemuanTab({required this.kelas});

  @override
  State<_AsdosPertemuanTab> createState() => _AsdosPertemuanTabState();
}

class _AsdosPertemuanTabState extends State<_AsdosPertemuanTab> {
  List<PertemuanModel> _pertemuanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPertemuan();
  }

  Future<void> _loadPertemuan() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pertemuan')
          .where('kelasId', isEqualTo: widget.kelas.id)
          .where('jenisSesi', isEqualTo: 'praktikum')
          .get();

      final list = snap.docs.map((d) => PertemuanModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
      
      if (mounted) {
        setState(() {
          _pertemuanList = list;
        });
      }
    } catch (e) {
      debugPrint('Error load pertemuan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAsdosAbsensiDetailSheet(BuildContext context, PertemuanModel pertemuan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AsdosPertemuanAbsensiSheet(pertemuan: pertemuan),
    ).then((_) => _loadPertemuan());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pertemuanList.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.event_busy_rounded,
          title: 'Belum Ada Pertemuan',
          description: 'Pertemuan praktikum (8 pertemuan) untuk kelas ini belum diinisialisasi.',
          actionLabel: 'Generate 8 Pertemuan',
          onAction: () async {
            setState(() => _isLoading = true);
            try {
              final schedSnap = await FirebaseFirestore.instance
                  .collection('jadwal')
                  .where('kelasId', isEqualTo: widget.kelas.id)
                  .where('jenisSesi', isEqualTo: 'praktikum')
                  .get();

              if (schedSnap.docs.isEmpty) {
                AppSnackbar.error(context, 'Jadwal praktikum tidak ditemukan untuk kelas ini.');
                return;
              }

              final jadwal = JadwalModel.fromMap(schedSnap.docs.first.id, schedSnap.docs.first.data());
              final provider = context.read<AsdosDashboardProvider>();
              final success = await provider.generateMeetingsForJadwal(jadwal);
              if (success) {
                AppSnackbar.success(context, 'Berhasil menginisialisasi 8 pertemuan praktikum.');
                _loadPertemuan();
              } else {
                AppSnackbar.error(context, provider.errorMessage ?? 'Gagal menginisialisasi pertemuan.');
              }
            } catch (e) {
              AppSnackbar.error(context, 'Terjadi kesalahan: $e');
            } finally {
              setState(() => _isLoading = false);
            }
          },
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pertemuanList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final p = _pertemuanList[idx];
        final isBelumStr = p.status == 'belum';

        Color statusColor = Colors.grey;
        String statusLabel = 'Belum Mulai';
        if (p.status == 'selesai') {
          statusColor = Colors.indigo;
          statusLabel = 'Selesai';
        } else if (p.status == 'aktif') {
          statusColor = AppColors.success;
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
                      'Pertemuan ini belum dimulai. Buka absensi via Beranda/Absensi utama.',
                    );
                  }
                : () {
                    _showAsdosAbsensiDetailSheet(context, p);
                  },
          ),
        );
      },
    );
  }
}

class _AsdosPertemuanAbsensiSheet extends StatefulWidget {
  final PertemuanModel pertemuan;
  const _AsdosPertemuanAbsensiSheet({required this.pertemuan});

  @override
  State<_AsdosPertemuanAbsensiSheet> createState() => _AsdosPertemuanAbsensiSheetState();
}

class _AsdosPertemuanAbsensiSheetState extends State<_AsdosPertemuanAbsensiSheet> {
  List<ClassEnrollmentModel> _students = [];
  List<AbsensiModel> _attendances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;

      final studentsSnap = await db
          .collection('class_enrollments')
          .where('kelasId', isEqualTo: widget.pertemuan.kelasId)
          .get();

      _students = studentsSnap.docs
          .map((d) => ClassEnrollmentModel.fromMap(d.id, d.data()))
          .toList();
      _students.sort((a, b) => a.mahasiswaNama.toLowerCase().compareTo(b.mahasiswaNama.toLowerCase()));

      final attendanceSnap = await db
          .collection('absensi')
          .where('pertemuanId', isEqualTo: widget.pertemuan.id)
          .get();

      _attendances = attendanceSnap.docs
          .map((d) => AbsensiModel.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading attendance list: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStudentStatus(String mahasiswaId, String mahasiswaNama, String status) async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      final provider = context.read<AsdosDashboardProvider>();
      final existingIdx = _attendances.indexWhere((a) => a.mahasiswaId == mahasiswaId);
      final student = _students.firstWhere((s) => s.mahasiswaId == mahasiswaId);

      if (existingIdx != -1) {
        final record = _attendances[existingIdx];
        await db.collection('absensi').doc(record.id).update({
          'status': status,
          'isCheckedIn': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final ref = db.collection('absensi').doc();
        final newRecord = AbsensiModel(
          id: ref.id,
          pertemuanId: widget.pertemuan.id,
          pertemuanKe: widget.pertemuan.pertemuanKe,
          kelasId: widget.pertemuan.kelasId,
          kelasNama: widget.pertemuan.kelasNama,
          matakuliahNama: widget.pertemuan.matakuliahNama,
          matakuliahKode: widget.pertemuan.matakuliahKode,
          mahasiswaId: mahasiswaId,
          mahasiswaNama: mahasiswaNama,
          mahasiswaNim: student.mahasiswaNim,
          tanggal: widget.pertemuan.tanggal,
          status: status,
          isCheckedIn: true,
          keterangan: 'Absen manual oleh Asdos',
          checkedInAt: Timestamp.now(),
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          jadwalId: widget.pertemuan.jadwalId,
          matakuliahId: widget.pertemuan.matakuliahId,
          jenisSesi: widget.pertemuan.jenisSesi,
        );

        await ref.set(newRecord.toMap());
      }
      
      final classDoc = await db.collection('kelas').doc(widget.pertemuan.kelasId).get();
      if (classDoc.exists) {
        final kelas = KelasModel.fromMap(classDoc.id, classDoc.data()!);
        await provider.recalculateStudentGrades(
          studentId: mahasiswaId,
          studentNama: mahasiswaNama,
          studentNim: student.mahasiswaNim,
          kelas: kelas,
        );
      }

      _loadData();
      if (mounted) AppSnackbar.success(context, 'Presensi mahasiswa berhasil diubah.');
    } catch (e) {
      debugPrint('Error updating attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Presensi Pertemuan ${widget.pertemuan.pertemuanKe}',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(child: Text('Belum ada mahasiswa terdaftar.'))
                    : ListView.separated(
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final attIdx = _attendances.indexWhere((a) => a.mahasiswaId == student.mahasiswaId);
                          final att = attIdx != -1 ? _attendances[attIdx] : null;

                          String currentStatus = att?.status ?? 'alpha';
                          Color statusColor = AppColors.error;
                          String statusLabel = 'Alpha';

                          if (currentStatus == 'hadir') {
                            statusColor = AppColors.success;
                            statusLabel = 'Hadir';
                          } else if (currentStatus == 'sakit') {
                            statusColor = Colors.orange;
                            statusLabel = 'Sakit';
                          } else if (currentStatus == 'izin') {
                            statusColor = Colors.blue;
                            statusLabel = 'Izin';
                          } else if (currentStatus == 'terlambat') {
                            statusColor = Colors.amber;
                            statusLabel = 'Terlambat';
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(student.mahasiswaNama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'NIM. ${student.mahasiswaNim}  •  Status: $statusLabel',
                                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 22),
                                  onSelected: (status) => _updateStudentStatus(
                                    student.mahasiswaId,
                                    student.mahasiswaNama,
                                    status,
                                  ),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'hadir', child: Text('Hadir')),
                                    PopupMenuItem(value: 'izin', child: Text('Izin')),
                                    PopupMenuItem(value: 'sakit', child: Text('Sakit')),
                                    PopupMenuItem(value: 'alpha', child: Text('Alpha')),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUB-TAB 5: DAFTAR MAHASISWA
// ─────────────────────────────────────────────────────────────
class _AsdosMahasiswaTab extends StatefulWidget {
  final KelasModel kelas;
  final VoidCallback onUnenroll;

  const _AsdosMahasiswaTab({
    required this.kelas,
    required this.onUnenroll,
  });

  @override
  State<_AsdosMahasiswaTab> createState() => _AsdosMahasiswaTabState();
}

class _AsdosMahasiswaTabState extends State<_AsdosMahasiswaTab> {
  List<ClassEnrollmentModel> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('class_enrollments')
          .where('kelasId', isEqualTo: widget.kelas.id)
          .get();

      final list = snap.docs.map((d) => ClassEnrollmentModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.mahasiswaNama.toLowerCase().compareTo(b.mahasiswaNama.toLowerCase()));
      
      if (mounted) {
        setState(() {
          _students = list;
        });
      }
    } catch (e) {
      debugPrint('Error load students: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _unenrollStudent(ClassEnrollmentModel student) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Mahasiswa',
      message: 'Apakah Anda yakin ingin menghapus ${student.mahasiswaNama} dari kelas praktikum ini? Nilai dan riwayat presensi siswa pada kelas ini akan tetap tersimpan di database.',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final provider = context.read<AsdosDashboardProvider>();
        final success = await provider.unenrollStudent(student.id, widget.kelas.id);
        if (success) {
          if (mounted) AppSnackbar.success(context, '${student.mahasiswaNama} berhasil dihapus dari kelas.');
          widget.onUnenroll();
          _loadStudents();
        } else {
          if (mounted) AppSnackbar.error(context, provider.errorMessage ?? 'Gagal menghapus mahasiswa.');
        }
      },
    );
  }

  void _showStudentProfileDialog(ClassEnrollmentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: Icon(Icons.person_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.mahasiswaNama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('NIM. ${student.mahasiswaNim}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _buildProfileRow('Kelas', widget.kelas.namaKelas),
            _buildProfileRow('Mata Kuliah', widget.kelas.matakuliahNama),
            _buildProfileRow('Kode MK', CourseFormatter.getAbbreviation(widget.kelas.matakuliahNama, widget.kelas.matakuliahKode)),
            _buildProfileRow('Terdaftar pada', student.enrolledAt != null 
                ? DateFormat('d MMMM yyyy', 'id').format(student.enrolledAt!.toDate())
                : '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_students.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_rounded,
        title: 'Tidak Ada Mahasiswa',
        description: 'Belum ada mahasiswa yang terdaftar di kelas praktikum ini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final s = _students[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryContainer,
                child: Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.mahasiswaNama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('NIM. ${s.mahasiswaNim}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                tooltip: 'Detail Profil',
                onPressed: () => _showStudentProfileDialog(s),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_rounded, color: AppColors.error),
                tooltip: 'Hapus dari Kelas',
                onPressed: () => _unenrollStudent(s),
              ),
            ],
          ),
        );
      },
    );
  }
}
