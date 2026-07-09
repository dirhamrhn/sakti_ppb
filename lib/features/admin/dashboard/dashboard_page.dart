import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/mahasiswa_provider.dart';
import '../../../providers/dosen_provider.dart';
import '../../../providers/asdos_provider.dart';
import '../../../providers/matakuliah_provider.dart';
import '../../../providers/kelas_provider.dart';
import '../../../providers/jadwal_provider.dart';
import 'widgets/stat_card.dart';
import 'widgets/menu_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _statsLoaded = false;
  int _mahasiswaCount = 0;
  int _dosenCount = 0;
  int _asdosCount = 0;
  int _matakuliahCount = 0;
  int _kelasCount = 0;
  int _jadwalCount = 0;
  int _teoriCount = 0;
  int _praktikumCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final mahasiswaP = context.read<MahasiswaProvider>();
    final dosenP = context.read<DosenProvider>();
    final asdosP = context.read<AsdosProvider>();
    final matakuliahP = context.read<MatakuliahProvider>();
    final kelasP = context.read<KelasProvider>();
    final jadwalP = context.read<JadwalProvider>();

    await Future.wait([
      mahasiswaP.loadAll(),
      dosenP.loadAll(),
      asdosP.loadAll(),
      matakuliahP.loadAll(),
      kelasP.loadAll(),
      jadwalP.loadAll(),
    ]);

    if (!mounted) return;
    setState(() {
      _mahasiswaCount = mahasiswaP.list.length;
      _dosenCount = dosenP.list.length;
      _asdosCount = asdosP.list.length;
      _matakuliahCount = matakuliahP.list.length;
      _kelasCount = kelasP.list.length;
      _jadwalCount = jadwalP.list.length;
      _teoriCount = matakuliahP.list.where((m) => m.jenisMatakuliah == 'teori' || m.jenisMatakuliah == 'teori_praktikum').length;
      _praktikumCount = matakuliahP.list.where((m) => m.hasPraktikum).length;
      _statsLoaded = true;
    });
  }

  Future<void> _logout() async {
    ConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      confirmLabel: 'Logout',
      cancelLabel: 'Batal',
      isDanger: true,
      onConfirm: () async {
        await context.read<AuthProvider>().logout();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, RouteName.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ───────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              title: Text('SAKTI Admin', style: AppTextStyles.appBarTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: _logout,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.headerGradient,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 88, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
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
                                  user?.nama ?? 'Admin',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Stats Grid ────────────────────────
                    Text('Statistik', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),

                    _statsLoaded
                        ? GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                            children: [
                              StatCard(
                                label: 'Mahasiswa',
                                value: '$_mahasiswaCount',
                                icon: Icons.school_rounded,
                                gradient: [
                                  const Color(0xFF3B5BDB),
                                  const Color(0xFF748FFC),
                                ],
                              ),
                              StatCard(
                                label: 'Dosen',
                                value: '$_dosenCount',
                                icon: Icons.person_rounded,
                                gradient: [
                                  const Color(0xFFF08C00),
                                  const Color(0xFFFFD43B),
                                ],
                              ),
                              StatCard(
                                label: 'Asisten Dosen',
                                value: '$_asdosCount',
                                icon: Icons.people_rounded,
                                gradient: [
                                  const Color(0xFF6741D9),
                                  const Color(0xFF9775FA),
                                ],
                              ),
                              StatCard(
                                label: 'Mata Kuliah',
                                value: '$_matakuliahCount',
                                icon: Icons.book_rounded,
                                gradient: [
                                  const Color(0xFF2F9E44),
                                  const Color(0xFF69DB7C),
                                ],
                              ),
                              StatCard(
                                label: 'Kelas',
                                value: '$_kelasCount',
                                icon: Icons.class_rounded,
                                gradient: [
                                  const Color(0xFF1971C2),
                                  const Color(0xFF74C0FC),
                                ],
                              ),
                              StatCard(
                                label: 'Jadwal',
                                value: '$_jadwalCount',
                                icon: Icons.schedule_rounded,
                                gradient: [
                                  const Color(0xFFE03131),
                                  const Color(0xFFFF8787),
                                ],
                              ),
                              StatCard(
                                label: 'MK Teori',
                                value: '$_teoriCount',
                                icon: Icons.menu_book_rounded,
                                gradient: const [
                                  Color(0xFF0B7285),
                                  Color(0xFF66D9E8),
                                ],
                              ),
                              StatCard(
                                label: 'MK Praktikum',
                                value: '$_praktikumCount',
                                icon: Icons.science_rounded,
                                gradient: const [
                                  Color(0xFF9C36B5),
                                  Color(0xFFE599F7),
                                ],
                              ),
                            ],
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          ),

                    const SizedBox(height: 28),

                    // ─── Menu Grid ────────────────────────
                    Text('Manajemen', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        MenuCard(
                          icon: Icons.school_rounded,
                          label: 'Mahasiswa',
                          subtitle: 'Kelola data mahasiswa',
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteName.adminMahasiswaList,
                          ).then((_) => _loadStats()),
                        ),
                        MenuCard(
                          icon: Icons.person_rounded,
                          label: 'Dosen',
                          subtitle: 'Kelola data dosen',
                          color: AppColors.warning,
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteName.adminDosenList,
                          ).then((_) => _loadStats()),
                        ),
                        MenuCard(
                          icon: Icons.people_rounded,
                          label: 'Asisten Dosen',
                          subtitle: 'Kelola data asdos',
                          color: AppColors.secondary,
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteName.adminAsdosList,
                          ).then((_) => _loadStats()),
                        ),
                        MenuCard(
                          icon: Icons.book_rounded,
                          label: 'Mata Kuliah',
                          subtitle: 'Kelola mata kuliah',
                          color: AppColors.success,
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteName.adminMatakuliahList,
                          ).then((_) => _loadStats()),
                        ),
                        MenuCard(
                          icon: Icons.class_rounded,
                          label: 'Kelas',
                          subtitle: 'Kelola kelas & assign',
                          color: AppColors.info,
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteName.adminKelasList,
                          ).then((_) => _loadStats()),
                        ),
                        MenuCard(
                          icon: Icons.schedule_rounded,
                          label: 'Jadwal',
                          subtitle: 'Kelola jadwal kuliah',
                          color: AppColors.error,
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteName.adminJadwalList,
                          ).then((_) => _loadStats()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ─── Footer ───────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text('SAKTI v1.0.0', style: AppTextStyles.labelSmall),
                          Text(
                            'Sistem Akademik Transparan dan Terintegrasi',
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
