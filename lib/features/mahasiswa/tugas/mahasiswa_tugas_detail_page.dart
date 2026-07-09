import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../models/tugas_model.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';
import '../../../../providers/auth_provider.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class MahasiswaTugasDetailPage extends StatefulWidget {
  final TugasModel tugas;
  final String kelasId;

  const MahasiswaTugasDetailPage({
    super.key,
    required this.tugas,
    required this.kelasId,
  });

  @override
  State<MahasiswaTugasDetailPage> createState() =>
      _MahasiswaTugasDetailPageState();
}

class _MahasiswaTugasDetailPageState extends State<MahasiswaTugasDetailPage> {
  final _catatanController = TextEditingController();
  File? _selectedFile;
  String _fileName = '';
  bool _isSubmitting = false;
  SubmisiModel? _existingSubmisi;
  bool _loadingSubmisi = true;

  @override
  void initState() {
    super.initState();
    _loadSubmisi();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmisi() async {
    final provider = context.read<MahasiswaDashboardProvider>();
    _existingSubmisi = await provider.getSubmisiByTugas(widget.tugas.id);
    if (mounted) setState(() => _loadingSubmisi = false);
  }

  Future<void> _pickFile() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Pilih Berkas', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Dari Galeri (Foto)'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(
                Icons.description_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Pilih Dokumen (PDF, ZIP, DOCX, dll.)'),
              onTap: () => Navigator.pop(context, 'document'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;

    if (result == 'gallery' || result == 'camera') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: result == 'gallery' ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() {
          _selectedFile = File(picked.path);
          _fileName = picked.name;
        });
      }
    } else if (result == 'document') {
      final pickerResult = await FilePicker.pickFiles(
        type: FileType.any,
      );
      if (pickerResult != null && pickerResult.files.single.path != null) {
        setState(() {
          _selectedFile = File(pickerResult.files.single.path!);
          _fileName = pickerResult.files.single.name;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null && _existingSubmisi == null) {
      AppSnackbar.warning(context, 'Pilih file terlebih dahulu.');
      return;
    }

    if (_selectedFile == null && _existingSubmisi != null) {
      AppSnackbar.info(context, 'Tugas sudah dikumpulkan sebelumnya.');
      return;
    }

    // TP must be PDF format
    if (widget.tugas.tipe == 'tp' && _selectedFile != null) {
      if (!_fileName.toLowerCase().endsWith('.pdf')) {
        AppSnackbar.error(
          context,
          'Tugas Pendahuluan (TP) wajib diunggah dalam format PDF (.pdf).',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final provider = context.read<MahasiswaDashboardProvider>();
    final mahasiswaNama = auth.user?.nama ?? '';

    final success = await provider.submitTugas(
      tugasId: widget.tugas.id,
      kelasId: widget.kelasId,
      mahasiswaNama: mahasiswaNama,
      file: _selectedFile!,
      fileName: _fileName,
      catatan: _catatanController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      AppSnackbar.success(context, 'Tugas berhasil dikumpulkan!');
      await _loadSubmisi();
    } else {
      AppSnackbar.error(
        context,
        provider.errorMessage ?? 'Gagal mengumpulkan tugas.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tugas = widget.tugas;
    final deadline = tugas.deadline.toDate();
    final isOverdue = deadline.isBefore(DateTime.now());
    final dayLeft = deadline.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Tugas Info Card ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B5BDB), Color(0xFF6741D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      CourseFormatter.getAbbreviation(tugas.matakuliahNama, tugas.matakuliahKode),
                      style: AppTextStyles.badge.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tugas.judul,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Oleh: ${tugas.dosenNama}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─ Deadline & Bobot ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Deadline',
                    value: DateFormat(
                      'd MMM yyyy\nHH:mm',
                      'id',
                    ).format(deadline),
                    color: isOverdue ? AppColors.error : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.star_rounded,
                    label: 'Bobot Nilai',
                    value: '${tugas.bobotNilai}%',
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: 'Sisa Waktu',
                    value: isOverdue
                        ? 'Terlambat'
                        : dayLeft == 0
                        ? 'Hari ini'
                        : '$dayLeft hari',
                    color: isOverdue
                        ? AppColors.error
                        : dayLeft <= 1
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ─ Deskripsi ────────────────────────────────────
            if (tugas.deskripsi.isNotEmpty || tugas.fileUrl.isNotEmpty) ...[
              Text('Instruksi Tugas', style: AppTextStyles.titleSmall),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tugas.deskripsi.isNotEmpty)
                      Text(tugas.deskripsi, style: AppTextStyles.bodyMedium),
                    if (tugas.deskripsi.isNotEmpty && tugas.fileUrl.isNotEmpty)
                      const Divider(height: 20),
                    if (tugas.fileUrl.isNotEmpty) ...[
                      const Text(
                        'Lampiran Instruksi:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          tugas.fileUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text(
                              'Format berkas lampiran tidak didukung untuk preview langsung.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'File: ${tugas.fileName}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─ Status Submisi ────────────────────────────────
            if (_loadingSubmisi)
              const Center(child: CircularProgressIndicator())
            else if (_existingSubmisi != null)
              _SubmisiStatusCard(submisi: _existingSubmisi!)
            else if (!tugas.isOpen) ...[
              Text('Kumpulkan Tugas', style: AppTextStyles.titleSmall),
              const SizedBox(height: 12),
              Card(
                color: AppColors.error.withOpacity(0.05),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.error.withOpacity(0.2)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, color: AppColors.error),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pengumpulan ditutup oleh Asisten Dosen.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const AppButton(
                label: 'Pengumpulan Ditutup',
                icon: Icons.lock_rounded,
                onPressed: null,
              ),
            ] else ...[
              Text('Kumpulkan Tugas', style: AppTextStyles.titleSmall),
              const SizedBox(height: 12),

              // File picker
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _selectedFile != null
                        ? AppColors.successLight
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedFile != null
                          ? AppColors.success
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.check_circle_rounded
                            : Icons.upload_file_rounded,
                        size: 40,
                        color: _selectedFile != null
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile != null
                            ? _fileName
                            : 'Tap untuk memilih file',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedFile != null
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: _selectedFile != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          tugas.tipe == 'tp' ? 'Wajib PDF' : 'Foto / Dokumen',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _fileName = '';
                      });
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                    label: const Text(
                      'Hapus Berkas',
                      style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Catatan
              AppTextField(
                controller: _catatanController,
                label: 'Catatan (Opsional)',
                hint: 'Tambahkan keterangan atau catatan...',
                prefixIcon: Icons.note_rounded,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 20),

              AppButton(
                label: 'Kumpulkan Tugas',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: isOverdue ? null : _submit,
              ),

              if (isOverdue) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Deadline telah lewat, tidak dapat mengumpulkan',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmisiStatusCard extends StatelessWidget {
  final SubmisiModel submisi;
  const _SubmisiStatusCard({required this.submisi});

  @override
  Widget build(BuildContext context) {
    final submittedAt = submisi.submittedAt.toDate();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Tugas Sudah Dikumpulkan',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row(
            Icons.schedule_rounded,
            'Dikumpulkan pada',
            DateFormat('d MMM yyyy, HH:mm', 'id').format(submittedAt),
          ),
          _Row(
            Icons.attach_file_rounded,
            'File',
            submisi.fileName.isNotEmpty ? submisi.fileName : '-',
          ),
          if (submisi.isGraded && submisi.nilai != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text('Hasil Penilaian', style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            _Row(
              Icons.grade_rounded,
              'Nilai',
              submisi.nilai!.toStringAsFixed(1),
            ),
            if (submisi.feedback.isNotEmpty)
              _Row(Icons.comment_rounded, 'Feedback', submisi.feedback),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  'Menunggu penilaian dari dosen',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
