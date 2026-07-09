import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/jadwal_model.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class MahasiswaJadwalPage extends StatelessWidget {
  const MahasiswaJadwalPage({super.key});

  static const _hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  static const _hariMap = {
    DateTime.monday: 'Senin',
    DateTime.tuesday: 'Selasa',
    DateTime.wednesday: 'Rabu',
    DateTime.thursday: 'Kamis',
    DateTime.friday: 'Jumat',
    DateTime.saturday: 'Sabtu',
    DateTime.sunday: 'Minggu',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaDashboardProvider>();
    final hariIni = _hariMap[DateTime.now().weekday] ?? '';

    return DefaultTabController(
      length: _hariList.length,
      initialIndex: _hariList.indexOf(hariIni).clamp(0, _hariList.length - 1),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Jadwal'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _hariList.map((h) => Tab(text: h)).toList(),
          ),
        ),
        body: provider.isLoading && !provider.isInitialized
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: _hariList.map((hari) {
                  final jadwals = provider.jadwalList
                      .where((j) => j.hari == hari)
                      .toList();
                  return _JadwalDayView(
                    hari: hari,
                    jadwals: jadwals,
                    isToday: hari == hariIni,
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _JadwalDayView extends StatelessWidget {
  final String hari;
  final List<JadwalModel> jadwals;
  final bool isToday;

  const _JadwalDayView({
    required this.hari,
    required this.jadwals,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    if (jadwals.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_available_rounded,
        title: 'Tidak ada jadwal',
        description: 'Tidak ada jadwal kuliah pada hari $hari',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (isToday)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.today_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Jadwal Hari Ini • ${jadwals.length} kelas',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ...jadwals.asMap().entries.map((e) {
          final i = e.key;
          final jadwal = e.value;
          return _JadwalCard(jadwal: jadwal, index: i, isToday: isToday);
        }),
      ],
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final JadwalModel jadwal;
  final int index;
  final bool isToday;

  const _JadwalCard({
    required this.jadwal,
    required this.index,
    required this.isToday,
  });

  Color get _color {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored bar
          Container(
            width: 6,
            height: 80,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Jam
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                jadwal.jamMulai,
                style: AppTextStyles.titleSmall.copyWith(color: _color),
              ),
              const SizedBox(height: 2),
              Icon(Icons.more_vert, size: 14, color: AppColors.textDisabled),
              const SizedBox(height: 2),
              Text(
                jadwal.jamSelesai,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),
          const VerticalDivider(width: 1, thickness: 1),
          const SizedBox(width: 14),

          // Mata kuliah info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jadwal.matakuliahNama,
                  style: AppTextStyles.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.room_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(jadwal.ruangan, style: AppTextStyles.cardSubtitle),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        jadwal.dosenNama,
                        style: AppTextStyles.cardSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              CourseFormatter.getAbbreviation(jadwal.matakuliahNama, jadwal.matakuliahKode),
              style: AppTextStyles.badge.copyWith(color: _color),
            ),
          ),
        ],
      ),
    );
  }
}
