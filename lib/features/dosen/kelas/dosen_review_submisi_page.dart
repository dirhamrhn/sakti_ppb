import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../models/kelas_model.dart';
import '../../../../models/tugas_model.dart';
import '../../../../providers/dosen_dashboard_provider.dart';

class DosenReviewSubmisiPage extends StatefulWidget {
  final SubmisiModel submission;
  final KelasModel kelas;
  final TugasModel tugas;
  final String mahasiswaNim;

  const DosenReviewSubmisiPage({
    super.key,
    required this.submission,
    required this.kelas,
    required this.tugas,
    required this.mahasiswaNim,
  });

  @override
  State<DosenReviewSubmisiPage> createState() => _DosenReviewSubmisiPageState();
}

class _DosenReviewSubmisiPageState extends State<DosenReviewSubmisiPage> {
  late TextEditingController _nilaiController;
  late TextEditingController _feedbackController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nilaiController = TextEditingController(
        text: widget.submission.nilai?.toStringAsFixed(0) ?? '');
    _feedbackController = TextEditingController(text: widget.submission.feedback);
  }

  @override
  void dispose() {
    _nilaiController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = widget.submission.fileUrl.split('?').first.toLowerCase();
    final isPdf = cleanUrl.endsWith('.pdf');
    final isImage = cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.webp') ||
        cleanUrl.endsWith('.gif');

    final submittedDate = widget.submission.submittedAt.toDate();
    final formattedSubmitted =
        DateFormat('dd MMM yyyy, HH:mm').format(submittedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Review: ${widget.submission.mahasiswaNama}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. File Preview Section (Expanded)
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: widget.submission.fileUrl.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada berkas terlampir.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : isPdf
                      ? SfPdfViewer.network(
                          widget.submission.fileUrl,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                        )
                      : isImage
                          ? InteractiveViewer(
                              child: Image.network(
                                widget.submission.fileUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Text('Gagal memuat gambar preview.'),
                                ),
                              ),
                            )
                          : Center(
                              child: Card(
                                margin: const EdgeInsets.all(24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file_outlined,
                                        size: 72,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        widget.submission.fileName.isNotEmpty
                                            ? widget.submission.fileName
                                            : 'Berkas Tugas',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Format file tidak didukung untuk preview langsung.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
            ),
          ),

          // 2. Grading Panel (Bottom Sheet style container)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Student Details Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.submission.mahasiswaNama,
                              style: AppTextStyles.titleMedium
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'NIM: ${widget.mahasiswaNim} • Dikirim: $formattedSubmitted',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (widget.submission.isGraded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Sudah Dinilai',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.submission.catatan.isNotEmpty) ...[
                    const Text(
                      'Catatan Mahasiswa:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.submission.catatan,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Divider(height: 16),
                  
                  // Scoring Inputs
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: AppTextField(
                          controller: _nilaiController,
                          label: 'Nilai (0-100)',
                          hint: 'Nilai...',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _feedbackController,
                          label: 'Komentar / Umpan Balik',
                          hint: 'Tulis saran atau masukan...',
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Save Button
                  AppButton(
                    label: _isSaving ? 'Menyimpan...' : 'Simpan Penilaian',
                    onPressed: _isSaving ? null : _savePenilaian,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePenilaian() async {
    final nilaiStr = _nilaiController.text.trim();
    if (nilaiStr.isEmpty) {
      AppSnackbar.error(context, 'Nilai harus diisi.');
      return;
    }

    final double? nilai = double.tryParse(nilaiStr);
    if (nilai == null || nilai < 0 || nilai > 100) {
      AppSnackbar.error(context, 'Nilai harus berkisar antara 0 - 100.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await context.read<DosenDashboardProvider>().gradeSubmission(
            submissionId: widget.submission.id,
            studentId: widget.submission.mahasiswaId,
            studentNama: widget.submission.mahasiswaNama,
            kelasId: widget.kelas.id,
            tugasId: widget.tugas.id,
            nilai: nilai,
            feedback: _feedbackController.text.trim(),
            kelas: widget.kelas,
          );

      if (mounted) {
        if (success) {
          AppSnackbar.success(context, 'Penilaian berhasil disimpan!');
          Navigator.pop(context, true); // Return true to trigger reload in parent
        } else {
          AppSnackbar.error(context, 'Gagal menyimpan penilaian.');
        }
      }
    } catch (e) {
      debugPrint('Error grading submission page: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Gagal menyimpan penilaian.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
