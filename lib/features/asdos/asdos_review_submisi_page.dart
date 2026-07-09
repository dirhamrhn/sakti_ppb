import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../models/kelas_model.dart';
import '../../models/tugas_model.dart';
import '../../providers/asdos_dashboard_provider.dart';

class AsdosReviewSubmisiPage extends StatefulWidget {
  final SubmisiModel submission;
  final KelasModel kelas;
  final TugasModel tugas;
  final String mahasiswaNim;

  const AsdosReviewSubmisiPage({
    super.key,
    required this.submission,
    required this.kelas,
    required this.tugas,
    required this.mahasiswaNim,
  });

  @override
  State<AsdosReviewSubmisiPage> createState() => _AsdosReviewSubmisiPageState();
}

class _AsdosReviewSubmisiPageState extends State<AsdosReviewSubmisiPage> {
  final _nilaiController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.submission.isGraded) {
      _nilaiController.text = widget.submission.nilai?.toString() ?? '';
      _feedbackController.text = widget.submission.feedback;
    }
  }

  @override
  void dispose() {
    _nilaiController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _saveGrading() async {
    final gradeText = _nilaiController.text.trim();
    if (gradeText.isEmpty) {
      AppSnackbar.warning(context, 'Harap isi nilai.');
      return;
    }

    final double? gradeVal = double.tryParse(gradeText);
    if (gradeVal == null || gradeVal < 0 || gradeVal > 100) {
      AppSnackbar.error(context, 'Nilai harus berupa angka antara 0 s.d 100.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final provider = context.read<AsdosDashboardProvider>();
      final success = await provider.gradeSubmission(
        submissionId: widget.submission.id,
        studentId: widget.submission.mahasiswaId,
        studentNama: widget.submission.mahasiswaNama,
        studentNim: widget.mahasiswaNim,
        kelasId: widget.kelas.id,
        tugasId: widget.tugas.id,
        nilai: gradeVal,
        feedback: _feedbackController.text.trim(),
        kelas: widget.kelas,
      );

      if (success && mounted) {
        AppSnackbar.success(context, 'Submisi berhasil dinilai.');
        Navigator.pop(context, true);
      } else if (mounted) {
        AppSnackbar.error(context, provider.errorMessage ?? 'Gagal menyimpan penilaian.');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFile = widget.submission.fileUrl.isNotEmpty;
    final bool isPdf = widget.submission.fileName.toLowerCase().endsWith('.pdf');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.submission.mahasiswaNama,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            Text(
              'NIM. ${widget.mahasiswaNim}  •  ${widget.tugas.judul}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0.5,
      ),
      body: Row(
        children: [
          // Left: PDF Viewer (or File Status placeholder)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey.shade100,
              child: !hasFile
                  ? const Center(
                      child: Text('Mahasiswa mengumpulkan tanpa berkas.'),
                    )
                  : (isPdf
                      ? SfPdfViewer.network(
                          widget.submission.fileUrl,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.insert_drive_file_rounded, size: 72, color: AppColors.primary),
                              const SizedBox(height: 12),
                              Text('File: ${widget.submission.fileName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('Hanya berkas format PDF yang didukung untuk preview langsung.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        )),
            ),
          ),
          const VerticalDivider(width: 1),

          // Right: Grading Side Panel
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penilaian Submisi', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _nilaiController,
                      label: 'Nilai (0 - 100)',
                      hint: 'Masukkan angka...',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.grade_rounded,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _feedbackController,
                      label: 'Catatan / Feedback',
                      hint: 'Tulis umpan balik untuk mahasiswa...',
                      prefixIcon: Icons.feedback_rounded,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    if (widget.submission.catatan.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Catatan Mahasiswa:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.submission.catatan,
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24),
                    ],

                    AppButton(
                      label: 'Simpan Penilaian',
                      icon: Icons.save_rounded,
                      isLoading: _isSaving,
                      onPressed: _saveGrading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
