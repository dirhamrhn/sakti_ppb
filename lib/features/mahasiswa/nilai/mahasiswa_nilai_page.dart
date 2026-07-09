import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/nilai_model.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class MahasiswaNilaiPage extends StatefulWidget {
  const MahasiswaNilaiPage({super.key});

  @override
  State<MahasiswaNilaiPage> createState() => _MahasiswaNilaiPageState();
}

class _MahasiswaNilaiPageState extends State<MahasiswaNilaiPage> {
  String? _selectedSemester;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaDashboardProvider>();
    final semesterList = provider.semesterList;

    // Set default semester
    if (_selectedSemester == null && semesterList.isNotEmpty) {
      _selectedSemester = semesterList.last;
    }

    final nilaiFiltered = _selectedSemester != null
        ? provider.getNilaiBySemester(_selectedSemester!)
        : provider.nilaiList;

    final ips = provider.hitungIPS(nilaiFiltered);
    final ipk = provider.hitungIPK(provider.nilaiList);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nilai Akademik'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: provider.nilaiList.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.grade_outlined,
              title: 'Belum Ada Nilai',
              description:
                  'Nilai akan muncul setelah dosen memasukkan penilaian.',
            )
          : Column(
              children: [
                // ─ IPS / IPK Header ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppColors.headerGradient,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _IPSCard(
                              label: 'IP Semester',
                              value: ips,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _IPSCard(
                              label: 'IPK Kumulatif',
                              value: ipk,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Semester filter
                      if (semesterList.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: semesterList.map((s) {
                              final isSelected = _selectedSemester == s;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedSemester = s),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    s,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                // ─ Nilai List ────────────────────────────────
                Expanded(
                  child: nilaiFiltered.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.grade_outlined,
                          title: 'Belum Ada Nilai',
                          description: 'Belum ada nilai untuk semester ini.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: nilaiFiltered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _NilaiCard(nilai: nilaiFiltered[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

class _IPSCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _IPSCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(2),
            style: AppTextStyles.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _NilaiCard extends StatelessWidget {
  final NilaiModel nilai;

  const _NilaiCard({required this.nilai});

  Color get _hurufColor {
    switch (nilai.huruf) {
      case 'A':
      case 'A-':
        return AppColors.success;
      case 'B+':
      case 'B':
      case 'B-':
        return AppColors.info;
      case 'C+':
      case 'C':
      case 'C-':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Huruf nilai
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _hurufColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _hurufColor.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                nilai.huruf.isNotEmpty ? nilai.huruf : '–',
                style: AppTextStyles.titleLarge.copyWith(
                  color: _hurufColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Mata kuliah info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nilai.matakuliahNama, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '${CourseFormatter.getAbbreviation(nilai.matakuliahNama, nilai.matakuliahKode)} • ${nilai.sks} SKS',
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniStat('Tugas', nilai.nilaiTugas),
                    const SizedBox(width: 8),
                    _MiniStat('UTS', nilai.nilaiUTS),
                    const SizedBox(width: 8),
                    _MiniStat('UAS', nilai.nilaiUAS),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Nilai akhir
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                nilai.nilaiAkhir.toStringAsFixed(1),
                style: AppTextStyles.titleMedium.copyWith(
                  color: _hurufColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Bobot ${nilai.bobot.toStringAsFixed(1)}',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}',
        style: AppTextStyles.labelSmall,
      ),
    );
  }
}
