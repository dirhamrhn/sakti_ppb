import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/jadwal_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dosen_dashboard_provider.dart';
import 'dosen_absensi_bottom_sheet.dart';

class DosenAbsensiPage extends StatefulWidget {
  const DosenAbsensiPage({super.key});

  @override
  State<DosenAbsensiPage> createState() => _DosenAbsensiPageState();
}

class _DosenAbsensiPageState extends State<DosenAbsensiPage> {
  DateTime getMakassarTime() {
    return DateTime.now();
  }

  String getMakassarDateString() {
    final mTime = getMakassarTime();
    final year = mTime.year;
    final month = mTime.month.toString().padLeft(2, '0');
    final day = mTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String getMakassarDayName(DateTime dateTime) {
    const hariMap = {
      DateTime.monday: 'Senin',
      DateTime.tuesday: 'Selasa',
      DateTime.wednesday: 'Rabu',
      DateTime.thursday: 'Kamis',
      DateTime.friday: 'Jumat',
      DateTime.saturday: 'Sabtu',
      DateTime.sunday: 'Minggu',
    };
    return hariMap[dateTime.weekday] ?? '';
  }

  Future<void> _refreshData() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      await context.read<DosenDashboardProvider>().loadSchedules(
            auth.user!.uid,
            auth.user!.nama,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenDashboardProvider>();
    final auth = context.watch<AuthProvider>();
    
    final mTime = getMakassarTime();
    final hariIni = getMakassarDayName(mTime);
    final todayString = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(mTime);

    // Filter jadwal dosen hanya untuk hari ini
    final todaySchedules = provider.schedules
        .where((j) => j.hari == hariIni)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Absensi Hari Ini'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Jadwal',
            onPressed: _refreshData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: provider.isLoading && !provider.isInitialized
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  // Hari & Tanggal Header
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        todayString,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (todaySchedules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: EmptyStateWidget(
                        icon: Icons.event_busy_rounded,
                        title: 'Tidak Ada Kelas Hari Ini',
                        description: 'Anda tidak memiliki jadwal mengajar pada hari ini.',
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todaySchedules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final jadwal = todaySchedules[index];
                        return _DosenJadwalCard(
                          jadwal: jadwal,
                          todayDateStr: getMakassarDateString(),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => DosenAbsensiBottomSheet(jadwal: jadwal),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }
}

class _DosenJadwalCard extends StatelessWidget {
  final JadwalModel jadwal;
  final String todayDateStr;
  final VoidCallback onTap;

  const _DosenJadwalCard({
    required this.jadwal,
    required this.todayDateStr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = jadwal.jenisSesi == 'praktikum' ? 'Praktikum' : 'Teori';
    final typeColor = jadwal.jenisSesi == 'praktikum' ? Colors.indigo : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                jadwal.jenisSesi == 'praktikum' ? Icons.science_rounded : Icons.menu_book_rounded,
                color: typeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal.matakuliahNama,
                    style: AppTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelas ${jadwal.kelasNama}  •  $typeLabel',
                    style: AppTextStyles.cardSubtitle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        jadwal.isOnline ? Icons.videocam_rounded : Icons.room_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          jadwal.isOnline ? 'Kelas Online (${jadwal.platformMeet.toUpperCase()})' : '${jadwal.gedungNama} - ${jadwal.ruanganNama}',
                          style: AppTextStyles.cardSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${jadwal.jamMulai} - ${jadwal.jamSelesai}',
                        style: AppTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Status Badge (Realtime via Stream)
            _JadwalStatusBadge(jadwal: jadwal, todayDateStr: todayDateStr),
          ],
        ),
      ),
    );
  }
}

class _JadwalStatusBadge extends StatelessWidget {
  final JadwalModel jadwal;
  final String todayDateStr;

  const _JadwalStatusBadge({
    required this.jadwal,
    required this.todayDateStr,
  });

  @override
  Widget build(BuildContext context) {
    if (!jadwal.status) {
      return _buildBadge(AppColors.error, 'Batal');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('pertemuan')
          .where('jadwalId', isEqualTo: jadwal.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildBadge(Colors.grey, '...');
        }

        final docs = snapshot.data!.docs;
        final hasActive = docs.any((d) => d.data()['status'] == 'aktif');
        if (hasActive) {
          return _buildBadge(AppColors.success, 'Aktif');
        }

        final hasFinishedToday = docs.any((d) =>
            d.data()['status'] == 'selesai' &&
            d.data()['tanggal'] == todayDateStr);
        if (hasFinishedToday) {
          return _buildBadge(AppColors.info, 'Selesai');
        }

        return _buildBadge(AppColors.warning, 'Nanti');
      },
    );
  }

  Widget _buildBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
