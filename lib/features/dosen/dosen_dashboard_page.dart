import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/kelas_model.dart';
import '../../../models/jadwal_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dosen_dashboard_provider.dart';
import 'absensi/dosen_absensi_page.dart';
import 'package:sakti_final/core/utils/formatter.dart';
import 'penilaian/dosen_penilaian_page.dart';

class DosenDashboardPage extends StatefulWidget {
  const DosenDashboardPage({super.key});

  @override
  State<DosenDashboardPage> createState() => _DosenDashboardPageState();
}

class _DosenDashboardPageState extends State<DosenDashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<DosenDashboardProvider>().loadSchedules(
              auth.user!.uid,
              auth.user!.nama,
            );
      }
    });
  }

  // Daftar view halaman untuk setiap tab
  List<Widget> _buildPages() {
    return [
      const _DosenHomeTab(),
      const _DosenMataKuliahTab(),
      const DosenAbsensiPage(),
      const DosenPenilaianPage(),
      const _DosenProfilTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenDashboardProvider>();

    return Scaffold(
      body: provider.isLoading && !provider.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: _buildPages(),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.class_outlined),
                activeIcon: Icon(Icons.class_rounded),
                label: 'Mata Kuliah',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                activeIcon: Icon(Icons.location_on_rounded),
                label: 'Absensi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grade_outlined),
                activeIcon: Icon(Icons.grade_rounded),
                label: 'Penilaian',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1: BERANDA DOSEN
// ─────────────────────────────────────────────────────────────
class _DosenHomeTab extends StatelessWidget {
  const _DosenHomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<DosenDashboardProvider>();
    final user = auth.user;
    final todaySchedules = provider.schedulesHariIni;

    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          title: Text('SAKTI Dosen', style: AppTextStyles.appBarTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: 'Logout',
              onPressed: () => _handleLogout(context),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
              padding: const EdgeInsets.fromLTRB(20, 88, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Selamat Datang, Dosen Pengampu',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              user?.nama ?? 'Dosen Pengampu',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'NIDN. ${user?.nomorInduk ?? ""}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
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

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(20.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Ringkasan Jumlah Kelas Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Kelas Diajar',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.kelasList.length} Kelas',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Icon(Icons.bubble_chart_rounded, color: Colors.white60, size: 40),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title Jadwal Hari Ini
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kelas Mengajar Hari Ini',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${todaySchedules.length} Kelas',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (todaySchedules.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const EmptyStateWidget(
                    icon: Icons.event_available_rounded,
                    title: 'Hari Ini Bebas Mengajar',
                    description: 'Anda tidak memiliki jadwal mengajar hari ini.',
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todaySchedules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final j = todaySchedules[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  j.matakuliahNama,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Kelas ${j.kelasNama}  •  ${j.jamMulai} - ${j.jamSelesai}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                        ],
                      ),
                    );
                  },
                ),
            ]),
          ),
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context) {
    ConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Apakah Anda yakin ingin keluar?',
      confirmLabel: 'Logout',
      isDanger: true,
      onConfirm: () async {
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, RouteName.login);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2: MATA KULIAH DOSEN
// ─────────────────────────────────────────────────────────────
class _DosenMataKuliahTab extends StatefulWidget {
  const _DosenMataKuliahTab();

  @override
  State<_DosenMataKuliahTab> createState() => _DosenMataKuliahTabState();
}

class _DosenMataKuliahTabState extends State<_DosenMataKuliahTab> {
  final Map<String, bool> _expandedCourses = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenDashboardProvider>();

    if (provider.kelasList.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Mata Kuliah Diampu'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: EmptyStateWidget(
            icon: Icons.menu_book_rounded,
            title: 'Tidak Ada Kelas',
            description: 'Anda tidak terdaftar mengampu kelas mata kuliah apapun.',
          ),
        ),
      );
    }

    // Grouping classes by unique course (matakuliahKode)
    final Map<String, List<KelasModel>> groupedCourses = {};
    for (final kelas in provider.kelasList) {
      final key = kelas.matakuliahKode;
      if (!groupedCourses.containsKey(key)) {
        groupedCourses[key] = [];
      }
      groupedCourses[key]!.add(kelas);
    }

    final courseKeys = groupedCourses.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mata Kuliah Diampu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: courseKeys.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final courseCode = courseKeys[index];
          final classes = groupedCourses[courseCode]!;
          final sampleKelas = classes.first;
          final isExpanded = _expandedCourses[courseCode] ?? false;

          return Container(
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
            child: Column(
              children: [
                // Header (Clickable card for Course)
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedCourses[courseCode] = !isExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sampleKelas.matakuliahNama,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kode: ${CourseFormatter.getAbbreviation(sampleKelas.matakuliahNama, courseCode)}  •  ${classes.length} Kelas Terdaftar',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Section: List of Classes
                if (isExpanded) ...[
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
                  Container(
                    color: AppColors.background.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: classes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, classIdx) {
                        final kelas = classes[classIdx];
                        return InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteName.dosenKelasDetail,
                              arguments: kelas.id,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.class_rounded, color: Colors.indigo, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kelas ${kelas.namaKelas}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Jumlah Mahasiswa: ${kelas.jumlahMahasiswa} / ${kelas.kapasitas}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 4: TUGAS DOSEN
// ─────────────────────────────────────────────────────────────
class _DosenTugasTab extends StatelessWidget {
  const _DosenTugasTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Tugas Mahasiswa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: EmptyStateWidget(
          icon: Icons.task_rounded,
          title: 'Kelola Tugas Mahasiswa',
          description: 'Halaman untuk membuat tugas, meninjau submisi, dan memberikan penilaian segera hadir.',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 5: PROFIL DOSEN
// ─────────────────────────────────────────────────────────────
class _DosenProfilTab extends StatelessWidget {
  const _DosenProfilTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Dosen'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profil Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.nama ?? 'Dosen Pengampu',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'NIDN. ${user?.nomorInduk ?? "-"}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'DOSEN',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detail Info List
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? '-'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.account_balance_outlined, color: AppColors.primary),
                  title: Text('Jabatan Fungsional'),
                  subtitle: Text('Dosen Pengampu Utama'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.card_membership_outlined, color: AppColors.primary),
                  title: Text('Status Akun'),
                  subtitle: Text('Aktif'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          AppButton.danger(
            label: 'Keluar Aplikasi',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    ConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi SAKTI?',
      confirmLabel: 'Logout',
      isDanger: true,
      onConfirm: () async {
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, RouteName.login);
        }
      },
    );
  }
}
