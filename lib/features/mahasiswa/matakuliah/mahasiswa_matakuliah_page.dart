import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/kelas_model.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';
import 'mahasiswa_matakuliah_detail_page.dart';

class MahasiswaMatakuliahPage extends StatelessWidget {
  const MahasiswaMatakuliahPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaDashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mata Kuliah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: provider.isLoading && !provider.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : provider.kelasList.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.book_outlined,
              title: 'Belum Ada Mata Kuliah',
              description: 'Anda belum terdaftar di kelas manapun.',
            )
          : RefreshIndicator(
              onRefresh: provider.loadAll,
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: provider.kelasList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final kelas = provider.kelasList[i];
                  return _MatakuliahCard(
                    kelas: kelas,
                    provider: provider,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MahasiswaMatakuliahDetailPage(kelasId: kelas.id),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _MatakuliahCard extends StatelessWidget {
  final KelasModel kelas;
  final MahasiswaDashboardProvider provider;
  final VoidCallback onTap;

  const _MatakuliahCard({
    required this.kelas,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Hitung absensi untuk kelas ini
    final absensiKelas = provider.absensiList
        .where((a) => a.kelasId == kelas.id)
        .toList();
    final totalPertemuan = absensiKelas.length;
    final hadirCount = absensiKelas.where((a) => a.isHadir).length;
    final progress = totalPertemuan > 0 ? hadirCount / totalPertemuan : 0.0;

    // Hitung tugas
    final tugasKelas = provider.tugasList
        .where((t) => t.kelasId == kelas.id)
        .toList();
    final tugasSelesai = tugasKelas
        .where((t) => provider.hasSubmitted(t.id))
        .length;

    final gradients = _getGradient(kelas.matakuliahKode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Gradient Header ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradients,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.book_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kelas.matakuliahNama,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kelas.matakuliahKode,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kelas.status ? 'Aktif' : 'Nonaktif',
                      style: AppTextStyles.badge.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info & Progress ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          kelas.dosenNama.isNotEmpty
                              ? kelas.dosenNama
                              : 'Belum ada dosen',
                          style: AppTextStyles.cardSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.assignment_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$tugasSelesai/${tugasKelas.length} Tugas',
                        style: AppTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kehadiran',
                                  style: AppTextStyles.labelSmall,
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  gradients.first,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$hadirCount dari $totalPertemuan pertemuan',
                              style: AppTextStyles.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradient(String kode) {
    final gradients = [
      [const Color(0xFF3B5BDB), const Color(0xFF748FFC)],
      [const Color(0xFF6741D9), const Color(0xFF9775FA)],
      [const Color(0xFF2F9E44), const Color(0xFF69DB7C)],
      [const Color(0xFFF08C00), const Color(0xFFFFD43B)],
      [const Color(0xFF1971C2), const Color(0xFF74C0FC)],
      [const Color(0xFFE03131), const Color(0xFFFF8787)],
    ];
    final index = kode.hashCode.abs() % gradients.length;
    return gradients[index];
  }
}
