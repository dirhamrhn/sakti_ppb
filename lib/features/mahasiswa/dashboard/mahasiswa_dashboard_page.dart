import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../models/jadwal_model.dart';
import '../../../../models/tugas_model.dart';
import '../matakuliah/mahasiswa_matakuliah_page.dart';

class MahasiswaDashboardPage extends StatelessWidget {
  const MahasiswaDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<MahasiswaDashboardProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => provider.loadAll(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ─── Header ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              floating: false,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              title: Text('SAKTI', style: AppTextStyles.appBarTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () => ConfirmDialog.show(
                    context,
                    title: 'Logout',
                    message: 'Apakah Anda yakin ingin keluar?',
                    confirmLabel: 'Logout',
                    isDanger: true,
                    onConfirm: () async {
                      provider.reset();
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          RouteName.login,
                        );
                      }
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _HeaderWidget(user: user, provider: provider),
              ),
            ),

            // ─── Content ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: provider.isLoading && !provider.isInitialized
                  ? const _LoadingState()
                  : _DashboardContent(provider: provider),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header Widget ───────────────────────────────────────────────────────────

class _HeaderWidget extends StatelessWidget {
  final dynamic user;
  final MahasiswaDashboardProvider provider;

  const _HeaderWidget({required this.user, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 88, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Foto profil
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: (user?.photoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(user!.photoUrl) as ImageProvider
                    : null,
                child: (user?.photoUrl?.isEmpty ?? true)
                    ? const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      user?.nama ?? 'Mahasiswa',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.nomorInduk ?? '',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats Row
          Row(
            children: [
              _StatChip(
                icon: Icons.book_rounded,
                label: '${provider.kelasList.length} Mata Kuliah',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.layers_rounded,
                label: '${provider.totalSKS} SKS',
              ),
              const SizedBox(width: 8),
              if (provider.ipSemester > 0)
                _StatChip(
                  icon: Icons.star_rounded,
                  label: 'IP: ${provider.ipSemester.toStringAsFixed(2)}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Content ───────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final MahasiswaDashboardProvider provider;
  const _DashboardContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          // ─ Deadline Terdekat ─────────────────────────────────
          _SectionTitle('Deadline Terdekat'),
          const SizedBox(height: 10),
          provider.tugasDeadlineDekat.isEmpty
              ? const _EmptyCard(
                  icon: Icons.task_alt_rounded,
                  message: 'Tidak ada deadline dalam 7 hari',
                )
              : Column(
                  children: provider.tugasDeadlineDekat
                      .take(3)
                      .map((t) => _DeadlineCard(tugas: t, provider: provider))
                      .toList(),
                ),

          const SizedBox(height: 24),

          // ─ Jadwal Hari Ini ───────────────────────────────────
          _SectionTitle('Jadwal Hari Ini'),
          const SizedBox(height: 10),
          provider.jadwalHariIni.isEmpty
              ? const _EmptyCard(
                  icon: Icons.event_busy_rounded,
                  message: 'Tidak ada jadwal hari ini',
                )
              : Column(
                  children: provider.jadwalHariIni
                      .map((j) => _JadwalCard(jadwal: j))
                      .toList(),
                ),

          const SizedBox(height: 24),

          // ─ Lihat Semua Mata Kuliah ───────────────────────────
          AppButton(
            label: 'Lihat Semua Mata Kuliah',
            icon: Icons.book_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MahasiswaMatakuliahPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ─ Footer ────────────────────────────────────────────
          Center(
            child: Text(
              'SAKTI v1.0.0 — Sistem Akademik Transparan dan Terintegrasi',
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.titleMedium);
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textDisabled),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ─── Progress Kehadiran Card ─────────────────────────────────────────────────



// ─── Jadwal Card ─────────────────────────────────────────────────────────────

class _JadwalCard extends StatelessWidget {
  final JadwalModel jadwal;
  const _JadwalCard({required this.jadwal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jadwal.matakuliahNama, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '${jadwal.jamMulai} – ${jadwal.jamSelesai}  •  ${jadwal.ruangan}',
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              jadwal.matakuliahKode,
              style: AppTextStyles.badge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Deadline Card ────────────────────────────────────────────────────────────

class _DeadlineCard extends StatelessWidget {
  final TugasModel tugas;
  final MahasiswaDashboardProvider provider;
  const _DeadlineCard({required this.tugas, required this.provider});

  @override
  Widget build(BuildContext context) {
    final deadline = tugas.deadline.toDate();
    final dayLeft = deadline.difference(DateTime.now()).inDays;
    final isSubmitted = provider.hasSubmitted(tugas.id);
    final isUrgent = dayLeft <= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent ? AppColors.error.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSubmitted
                  ? AppColors.successLight
                  : isUrgent
                  ? AppColors.errorLight
                  : AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSubmitted
                  ? Icons.check_circle_rounded
                  : Icons.assignment_late_rounded,
              color: isSubmitted
                  ? AppColors.success
                  : isUrgent
                  ? AppColors.error
                  : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tugas.judul, style: AppTextStyles.cardTitle),
                Text(tugas.matakuliahNama, style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dayLeft == 0 ? 'Hari ini!' : '$dayLeft hari lagi',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isUrgent ? AppColors.error : AppColors.textSecondary,
                  fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              if (isSubmitted)
                Text(
                  'Dikumpulkan',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
