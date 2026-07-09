import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/nilai_model.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';

class MahasiswaNotifikasiPage extends StatelessWidget {
  const MahasiswaNotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaDashboardProvider>();
    final notifList = provider.notifikasiList;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          if (provider.unreadNotifCount > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: Text(
                'Baca Semua',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
        ],
      ),
      body: notifList.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'Belum Ada Notifikasi',
              description: 'Notifikasi akan muncul di sini.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final notif = notifList[i];
                return _NotifCard(
                  notif: notif,
                  onTap: () => provider.markRead(notif.id),
                );
              },
            ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotifikasiModel notif;
  final VoidCallback onTap;

  const _NotifCard({required this.notif, required this.onTap});

  IconData get _icon {
    switch (notif.tipe) {
      case 'tugas':
        return Icons.assignment_rounded;
      case 'nilai':
        return Icons.grade_rounded;
      case 'absensi':
        return Icons.how_to_reg_rounded;
      case 'pengumuman':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _color {
    switch (notif.tipe) {
      case 'tugas':
        return AppColors.warning;
      case 'nilai':
        return AppColors.success;
      case 'absensi':
        return AppColors.info;
      case 'pengumuman':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanggal = DateFormat(
      'd MMM, HH:mm',
      'id',
    ).format(notif.createdAt.toDate());

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.surface
              : AppColors.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : AppColors.primary.withOpacity(0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.judul,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(tanggal, style: AppTextStyles.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.pesan,
                    style: AppTextStyles.cardSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
