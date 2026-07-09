import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../models/kelas_model.dart';
import '../../../../models/tugas_model.dart';
import '../../../../models/class_enrollment_model.dart';
import '../../../../providers/dosen_dashboard_provider.dart';
import 'dosen_review_submisi_page.dart';

class DosenTugasDetailPage extends StatefulWidget {
  final TugasModel tugas;
  final KelasModel kelas;

  const DosenTugasDetailPage({
    super.key,
    required this.tugas,
    required this.kelas,
  });

  @override
  State<DosenTugasDetailPage> createState() => _DosenTugasDetailPageState();
}

class _DosenTugasDetailPageState extends State<DosenTugasDetailPage> {
  List<ClassEnrollmentModel> _enrollments = [];
  Map<String, SubmisiModel> _submissionsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<DosenDashboardProvider>();
      
      // 1. Fetch enrollments
      final enrolls = await provider.getEnrollments(widget.kelas.id);
      
      // 2. Fetch submissions
      final subSnap = await FirebaseFirestore.instance
          .collection('submissions')
          .where('tugasId', isEqualTo: widget.tugas.id)
          .get();
          
      final Map<String, SubmisiModel> subMap = {};
      for (final doc in subSnap.docs) {
        final sub = SubmisiModel.fromMap(doc.id, doc.data());
        subMap[sub.mahasiswaId] = sub;
      }

      setState(() {
        _enrollments = enrolls;
        _submissionsMap = subMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error load submissions: $e');
      if (mounted) AppSnackbar.error(context, 'Gagal memuat data submisi.');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadlineDate = widget.tugas.deadline.toDate();
    final formattedDeadline = DateFormat('dd MMM yyyy, HH:mm').format(deadlineDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Tugas & Submisi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Info Tugas Card
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Bobot: ${widget.tugas.bobotNilai}%',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                widget.tugas.isActive ? 'Aktif' : 'Nonaktif',
                                style: TextStyle(
                                  color: widget.tugas.isActive ? AppColors.success : AppColors.textDisabled,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.tugas.judul,
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Deadline: $formattedDeadline',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const Divider(height: 24),
                          const Text(
                            'Instruksi Tugas:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.tugas.deskripsi,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Daftar Submisi Mahasiswa
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Mahasiswa & Submisi',
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_submissionsMap.length} / ${_enrollments.length} Mengumpulkan',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_enrollments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text('Tidak ada mahasiswa terdaftar di kelas ini.'),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _enrollments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final e = _enrollments[index];
                            final sub = _submissionsMap[e.mahasiswaId];
                            final bool sudahKumpul = sub != null;

                            Color statusColor = AppColors.textDisabled;
                            String statusText = 'Belum Kumpul';

                            if (sudahKumpul) {
                              if (sub.isGraded) {
                                statusColor = AppColors.success;
                                statusText = 'Nilai: ${sub.nilai?.toStringAsFixed(0)}';
                              } else {
                                statusColor = Colors.orange;
                                statusText = 'Belum Diperiksa';
                              }
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: (sudahKumpul ? AppColors.primary : AppColors.textDisabled).withOpacity(0.08),
                                    radius: 18,
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: sudahKumpul ? AppColors.primary : AppColors.textDisabled,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.mahasiswaNama,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          'NIM: ${e.mahasiswaNim}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: sudahKumpul
                                        ? () async {
                                            final rated = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => DosenReviewSubmisiPage(
                                                  submission: sub,
                                                  kelas: widget.kelas,
                                                  tugas: widget.tugas,
                                                  mahasiswaNim: e.mahasiswaNim,
                                                ),
                                              ),
                                            );
                                            if (rated == true) {
                                              _loadSubmissions();
                                            }
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (sudahKumpul) ...[
                                            const SizedBox(width: 4),
                                            Icon(Icons.edit_note_rounded, size: 14, color: statusColor),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  void _showPenilaianDialog(SubmisiModel sub) {
    final nilaiController = TextEditingController(text: sub.nilai?.toStringAsFixed(0) ?? '');
    final feedbackController = TextEditingController(text: sub.feedback);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Periksa: ${sub.mahasiswaNama}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Catatan Mahasiswa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(
                      sub.catatan.isEmpty ? 'Tidak ada catatan.' : sub.catatan,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    const Text('File Submisi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    if (sub.fileUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            sub.fileUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('Format file tidak didukung / gagal memuat gambar', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ),
                      )
                    else
                      const Text('Tidak ada berkas terlampir.', style: TextStyle(fontSize: 12, color: AppColors.textDisabled)),
                    const Divider(height: 24),
                    AppTextField(
                      controller: nilaiController,
                      label: 'Nilai (0 - 100)',
                      hint: 'Masukkan angka nilai...',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: feedbackController,
                      label: 'Catatan Umpan Balik (Feedback)',
                      hint: 'Berikan saran / masukan...',
                      maxLines: 3,
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
                          final nilaiStr = nilaiController.text.trim();
                          if (nilaiStr.isEmpty) {
                            AppSnackbar.error(context, 'Nilai harus diisi.');
                            return;
                          }

                          final double? nilai = double.tryParse(nilaiStr);
                          if (nilai == null || nilai < 0 || nilai > 100) {
                            AppSnackbar.error(context, 'Nilai harus berkisar antara 0 - 100.');
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            final success = await context.read<DosenDashboardProvider>().gradeSubmission(
                                  submissionId: sub.id,
                                  studentId: sub.mahasiswaId,
                                  studentNama: sub.mahasiswaNama,
                                  kelasId: widget.kelas.id,
                                  tugasId: widget.tugas.id,
                                  nilai: nilai,
                                  feedback: feedbackController.text.trim(),
                                  kelas: widget.kelas,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                AppSnackbar.success(context, 'Nilai berhasil disimpan!');
                                _loadSubmissions();
                              } else {
                                AppSnackbar.error(context, 'Gagal menyimpan nilai.');
                              }
                            }
                          } catch (e) {
                            debugPrint('Error grading submission: $e');
                            if (context.mounted) {
                              AppSnackbar.error(context, 'Gagal menyimpan nilai.');
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
}
