import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/routes/route_name.dart';
import '../../models/kelas_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/pertemuan_model.dart';
import '../../models/nilai_model.dart';
import '../../models/absensi_model.dart';
import '../../models/class_enrollment_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/asdos_dashboard_provider.dart';
import 'package:sakti_final/core/utils/formatter.dart';
import '../../repositories/storage_repository.dart';
import 'asdos_kelas_detail_page.dart';
import 'asdos_absensi_bottom_sheet.dart';

class AsdosDashboardPage extends StatefulWidget {
  const AsdosDashboardPage({super.key});

  @override
  State<AsdosDashboardPage> createState() => _AsdosDashboardPageState();
}

class _AsdosDashboardPageState extends State<AsdosDashboardPage> {
  int _currentIndex = 0;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _isInit = true;
      // Defer loadAllData() ke setelah frame build selesai agar
      // notifyListeners() di dalam _setLoading() tidak dipanggil
      // saat Flutter masih dalam proses membangun widget tree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final auth = context.read<AuthProvider>();
        if (auth.user != null) {
          context.read<AsdosDashboardProvider>().loadAllData(auth.user!.uid);
        }
      });
    }
  }

  List<Widget> _buildTabs(UserModel? user) {
    return [
      _AsdosHomeTab(user: user),
      const _AsdosMataKuliahTab(),
      const _AsdosAbsensiTab(),
      const _AsdosNilaiTab(),
      _AsdosProfilTab(user: user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<AsdosDashboardProvider>();

    if (provider.isLoading && provider.kelasList.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _buildTabs(auth.user),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -3),
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
            selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
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
// TAB 1: BERANDA ASDOS (HOME)
// ─────────────────────────────────────────────────────────────
class _AsdosHomeTab extends StatelessWidget {
  final UserModel? user;

  const _AsdosHomeTab({required this.user});

  List<JadwalModel> _schedulesHariIni(List<JadwalModel> schedules) {
    final mTime = DateTime.now();
    const hariMap = {
      DateTime.monday: 'Senin',
      DateTime.tuesday: 'Selasa',
      DateTime.wednesday: 'Rabu',
      DateTime.thursday: 'Kamis',
      DateTime.friday: 'Jumat',
      DateTime.saturday: 'Sabtu',
      DateTime.sunday: 'Minggu',
    };
    final hariIni = hariMap[mTime.weekday] ?? '';
    return schedules.where((s) => s.hari == hariIni).toList();
  }

  JadwalModel? _nextSchedule(List<JadwalModel> schedules) {
    if (schedules.isEmpty) return null;
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final todayIndex = now.weekday - 1;

    final sortedSchedules = List<JadwalModel>.from(schedules);
    sortedSchedules.sort((a, b) {
      final idxA = days.indexOf(a.hari);
      final idxB = days.indexOf(b.hari);
      if (idxA != idxB) return idxA.compareTo(idxB);
      return a.jamMulai.compareTo(b.jamMulai);
    });

    final todayStr = days[todayIndex];
    final timeStr = DateFormat('HH:mm').format(now);
    for (final s in sortedSchedules) {
      if (s.hari == todayStr && s.jamMulai.compareTo(timeStr) > 0) {
        return s;
      }
    }

    for (int i = 1; i <= 7; i++) {
      final checkIndex = (todayIndex + i) % 7;
      final checkDay = days[checkIndex];
      for (final s in sortedSchedules) {
        if (s.hari == checkDay) {
          return s;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AsdosDashboardProvider>();
    final todaySchedules = _schedulesHariIni(provider.schedules);
    final nextSched = _nextSchedule(provider.schedules);

    return RefreshIndicator(
      onRefresh: () async {
        if (user != null) {
          await provider.loadAllData(user!.uid);
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            title: Text('SAKTI Asisten Dosen', style: AppTextStyles.appBarTitle),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                padding: const EdgeInsets.fromLTRB(20, 88, 20, 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      backgroundImage: user?.photoUrl != null && user!.photoUrl.isNotEmpty
                          ? NetworkImage(user!.photoUrl)
                          : null,
                      child: user?.photoUrl == null || user!.photoUrl.isEmpty
                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Selamat Datang, Asisten Dosen',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            user?.nama ?? 'Asisten Dosen',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'NIM. ${user?.nomorInduk ?? ""}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Card Grid
                _buildStatCard(
                  'Kelas Diampu',
                  '${provider.totalKelas} Kelas',
                  Icons.book_rounded,
                  Colors.indigo,
                  isWide: true,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  'LP & TP Belum Dinilai',
                  '${provider.totalBelumDinilai} Submisi',
                  Icons.rate_review_rounded,
                  Colors.orange,
                  isWide: true,
                ),
                const SizedBox(height: 24),

                // Jadwal Hari Ini
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jadwal Praktikum Hari Ini',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${todaySchedules.length} Sesi',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (todaySchedules.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const EmptyStateWidget(
                      icon: Icons.computer_rounded,
                      title: 'Bebas Praktikum Hari Ini',
                      description: 'Anda tidak memiliki sesi asistensi praktikum hari ini.',
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
                                color: Colors.teal.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.computer_rounded, color: Colors.teal, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    j.matakuliahNama,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    'Kelas ${j.kelasNama}  •  ${j.jamMulai} - ${j.jamSelesai}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Jadwal Berikutnya
                Text(
                  'Jadwal Praktikum Berikutnya',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (nextSched == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text('Tidak ada jadwal praktikum mendatang.'),
                    ),
                  )
                else
                  Container(
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
                            color: Colors.indigo.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.next_plan_rounded, color: Colors.indigo, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nextSched.matakuliahNama,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Kelas ${nextSched.kelasNama}  •  ${nextSched.hari}, ${nextSched.jamMulai} - ${nextSched.jamSelesai}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isWide = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2: MATA KULIAH ASDOS (ACCORDION GROUPING)
// ─────────────────────────────────────────────────────────────
class _AsdosMataKuliahTab extends StatelessWidget {
  const _AsdosMataKuliahTab();

  Map<String, List<KelasModel>> _groupClasses(List<KelasModel> list) {
    final Map<String, List<KelasModel>> map = {};
    for (final k in list) {
      final key = '${CourseFormatter.getAbbreviation(k.matakuliahNama, k.matakuliahKode)} - ${k.matakuliahNama}';
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(k);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AsdosDashboardProvider>();
    final grouped = _groupClasses(provider.kelasList);
    final keys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelas Praktikum Diampu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final auth = context.read<AuthProvider>();
          if (auth.user != null) {
            await provider.loadAllData(auth.user!.uid);
          }
        },
        child: grouped.isEmpty
            ? const Center(
                child: EmptyStateWidget(
                  icon: Icons.menu_book_rounded,
                  title: 'Tidak Ada Kelas',
                  description: 'Anda tidak mengampu praktikum kelas mana pun.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: keys.length,
                itemBuilder: (context, idx) {
                  final key = keys[idx];
                  final classes = grouped[key]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: ExpansionTile(
                      leading: const Icon(Icons.school_rounded, color: AppColors.primary),
                      title: Text(
                        key,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text('${classes.length} kelas diampu', style: const TextStyle(fontSize: 11)),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: classes.map((k) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text('Kelas ${k.namaKelas}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            subtitle: Text('Dosen Utama: ${k.dosenNama.isNotEmpty ? k.dosenNama : "-"}', style: const TextStyle(fontSize: 10)),
                            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AsdosKelasDetailPage(kelas: k),
                                ),
                              ).then((_) {
                                final auth = context.read<AuthProvider>();
                                if (auth.user != null) {
                                  provider.loadAllData(auth.user!.uid);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 3: ABSENSI (SESI JADWAL)
// ─────────────────────────────────────────────────────────────
class _AsdosAbsensiTab extends StatelessWidget {
  const _AsdosAbsensiTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AsdosDashboardProvider>();
    final practicalSchedules = provider.schedules.where((s) => s.jenisSesi == 'praktikum').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Absensi Praktikum'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final auth = context.read<AuthProvider>();
          if (auth.user != null) {
            await provider.loadAllData(auth.user!.uid);
          }
        },
        child: practicalSchedules.isEmpty
            ? const Center(
                child: EmptyStateWidget(
                  icon: Icons.computer_rounded,
                  title: 'Tidak Ada Jadwal',
                  description: 'Anda tidak memiliki jadwal mengajar praktikum.',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: practicalSchedules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final j = practicalSchedules[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.computer_rounded, color: Colors.teal, size: 24),
                      ),
                      title: Text(j.matakuliahNama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kelas: ${j.kelasNama}', style: const TextStyle(fontSize: 11)),
                          Text('${j.hari}, ${j.jamMulai} - ${j.jamSelesai}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      trailing: const Icon(Icons.settings_input_component_rounded, color: AppColors.primary),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AsdosAbsensiBottomSheet(jadwal: j),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 4: PENILAIAN (BOBOT & OVERRIDE NILAI)
// ─────────────────────────────────────────────────────────────
class _AsdosNilaiTab extends StatefulWidget {
  const _AsdosNilaiTab();

  @override
  State<_AsdosNilaiTab> createState() => _AsdosNilaiTabState();
}

class _AsdosNilaiTabState extends State<_AsdosNilaiTab> {
  KelasModel? _selectedKelas;
  List<ClassEnrollmentModel> _students = [];
  List<NilaiModel> _nilaiList = [];
  bool _isLoadingData = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKelasGrades(String kelasId) async {
    setState(() => _isLoadingData = true);
    try {
      final db = FirebaseFirestore.instance;

      final enrollSnap = await db
          .collection('class_enrollments')
          .where('kelasId', isEqualTo: kelasId)
          .get();

      _students = enrollSnap.docs
          .map((d) => ClassEnrollmentModel.fromMap(d.id, d.data()))
          .toList();
      _students.sort((a, b) => a.mahasiswaNama.toLowerCase().compareTo(b.mahasiswaNama.toLowerCase()));

      final gradesSnap = await db
          .collection('nilai')
          .where('kelasId', isEqualTo: kelasId)
          .get();

      _nilaiList = gradesSnap.docs
          .map((d) => NilaiModel.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      debugPrint('Error load grades: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _showAturBobotDialog() {
    if (_selectedKelas == null) return;

    final k = _selectedKelas!;
    final kehadiranController = TextEditingController(text: k.bobotAbsensi.toString());
    final lpController = TextEditingController(text: k.bobotLaporan.toString());
    final tpController = TextEditingController(text: k.bobotTugas.toString());
    final quizController = TextEditingController(text: k.bobotQuiz.toString());
    final finalController = TextEditingController(text: k.bobotPraktikum.toString());
    String selectedScope = 'kelas'; // 'kelas', 'matakuliah', 'semua'

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Atur Bobot Penilaian Praktikum'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Masukkan bobot nilai komponen praktikum (total harus 100%):',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                AppTextField(controller: kehadiranController, label: 'Kehadiran (%)', keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                AppTextField(controller: lpController, label: 'Laporan Praktikum / LP (%)', keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                AppTextField(controller: tpController, label: 'Tugas Pendahuluan / TP (%)', keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                AppTextField(controller: quizController, label: 'Keaktifan / Quiz (%)', keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                AppTextField(controller: finalController, label: 'Final Praktikum (%)', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedScope,
                  decoration: const InputDecoration(labelText: 'Terapkan Pada'),
                  items: const [
                    DropdownMenuItem(value: 'kelas', child: Text('Hanya Kelas Ini')),
                    DropdownMenuItem(value: 'matakuliah', child: Text('Semua Kelas MK Sama')),
                    DropdownMenuItem(value: 'semua', child: Text('Seluruh Kelas Diampu')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedScope = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final kVal = int.tryParse(kehadiranController.text) ?? 0;
                final lpVal = int.tryParse(lpController.text) ?? 0;
                final tpVal = int.tryParse(tpController.text) ?? 0;
                final qVal = int.tryParse(quizController.text) ?? 0;
                final fVal = int.tryParse(finalController.text) ?? 0;

                if (kVal + lpVal + tpVal + qVal + fVal != 100) {
                  AppSnackbar.error(context, 'Total persentase bobot harus sama dengan 100%. (Saat ini: ${kVal + lpVal + tpVal + qVal + fVal}%)');
                  return;
                }

                Navigator.pop(context);
                final provider = context.read<AsdosDashboardProvider>();
                final auth = context.read<AuthProvider>();

                final success = await provider.updateKelasBobot(
                  kelasId: k.id,
                  asdosId: auth.user?.uid ?? '',
                  matakuliahKode: k.matakuliahKode,
                  kehadiran: kVal,
                  lp: lpVal,
                  tp: tpVal,
                  quiz: qVal,
                  praktikum: fVal,
                  scope: selectedScope,
                );

                if (success) {
                  if (mounted) {
                    AppSnackbar.success(context, 'Bobot penilaian berhasil diperbarui.');
                    // Reload kelas model
                    final updatedKelas = provider.kelasList.firstWhere((x) => x.id == k.id);
                    setState(() {
                      _selectedKelas = updatedKelas;
                    });
                    _loadKelasGrades(k.id);
                  }
                } else {
                  if (mounted) AppSnackbar.error(context, provider.errorMessage ?? 'Gagal memperbarui bobot.');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPenilaianMahasiswaDialog(ClassEnrollmentModel student, NilaiModel? n) {
    if (_selectedKelas == null) return;
    final k = _selectedKelas!;

    // Initial state loading values
    bool overrideAbsensi = n?.isAbsensiOverridden ?? false;
    bool overrideLp = n?.isLpOverridden ?? false;
    bool overrideTp = n?.isTpOverridden ?? false;

    final absensiController = TextEditingController(text: overrideAbsensi ? n!.nilaiAbsensiManual.toString() : (n?.nilaiAbsensi.toString() ?? '100.0'));
    final lpController = TextEditingController(text: overrideLp ? n!.nilaiLaporanManual.toString() : (n?.nilaiLaporan.toString() ?? '0.0'));
    final tpController = TextEditingController(text: overrideTp ? n!.nilaiTugasManual.toString() : (n?.nilaiTugas.toString() ?? '0.0'));
    final quizController = TextEditingController(text: n?.nilaiQuiz.toString() ?? '0.0');
    final praktikumController = TextEditingController(text: n?.nilaiPraktikum.toString() ?? '0.0');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double calculated() {
            final abs = overrideAbsensi ? (double.tryParse(absensiController.text) ?? 0.0) : (n?.nilaiAbsensi ?? 100.0);
            final lp = overrideLp ? (double.tryParse(lpController.text) ?? 0.0) : (n?.nilaiLaporan ?? 0.0);
            final tp = overrideTp ? (double.tryParse(tpController.text) ?? 0.0) : (n?.nilaiTugas ?? 0.0);
            final q = double.tryParse(quizController.text) ?? 0.0;
            final f = double.tryParse(praktikumController.text) ?? 0.0;

            return (abs * (k.bobotAbsensi / 100.0)) +
                (lp * (k.bobotLaporan / 100.0)) +
                (tp * (k.bobotTugas / 100.0)) +
                (q * (k.bobotQuiz / 100.0)) +
                (f * (k.bobotPraktikum / 100.0));
          }

          final tempAkhir = calculated();
          final String tempHuruf = NilaiModel.bobotFromNilai(tempAkhir);

          return AlertDialog(
            title: Text('Penilaian: ${student.mahasiswaNama}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Gunakan switch di sebelah kanan komponen untuk menimpa (override) nilai otomatis dengan nilai manual.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: absensiController,
                          label: 'Kehadiran (${k.bobotAbsensi}%)',
                          keyboardType: TextInputType.number,
                          enabled: overrideAbsensi,
                        ),
                      ),
                      Switch(
                        value: overrideAbsensi,
                        onChanged: (val) {
                          setDialogState(() {
                            overrideAbsensi = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: lpController,
                          label: 'Laporan / LP (${k.bobotLaporan}%)',
                          keyboardType: TextInputType.number,
                          enabled: overrideLp,
                        ),
                      ),
                      Switch(
                        value: overrideLp,
                        onChanged: (val) {
                          setDialogState(() {
                            overrideLp = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: tpController,
                          label: 'Pendahuluan / TP (${k.bobotTugas}%)',
                          keyboardType: TextInputType.number,
                          enabled: overrideTp,
                        ),
                      ),
                      Switch(
                        value: overrideTp,
                        onChanged: (val) {
                          setDialogState(() {
                            overrideTp = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  AppTextField(
                    controller: quizController,
                    label: 'Keaktifan / Quiz (${k.bobotQuiz}%)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),

                  AppTextField(
                    controller: praktikumController,
                    label: 'Final Praktikum (${k.bobotPraktikum}%)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimasi Nilai Akhir:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        '${tempAkhir.toStringAsFixed(1)} ($tempHuruf)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  absensiController.dispose();
                  lpController.dispose();
                  tpController.dispose();
                  quizController.dispose();
                  praktikumController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final absVal = double.tryParse(absensiController.text) ?? 100.0;
                  final lpVal = double.tryParse(lpController.text) ?? 0.0;
                  final tpVal = double.tryParse(tpController.text) ?? 0.0;
                  final qVal = double.tryParse(quizController.text) ?? 0.0;
                  final fVal = double.tryParse(praktikumController.text) ?? 0.0;

                  Navigator.pop(context);
                  final provider = context.read<AsdosDashboardProvider>();
                  final FirebaseFirestore db = FirebaseFirestore.instance;

                  String docId = db.collection('nilai').doc().id;
                  final match = _nilaiList.where((x) => x.mahasiswaId == student.mahasiswaId).toList();
                  if (match.isNotEmpty) {
                    docId = match.first.id;
                  }

                  // 1. Save base manual fields & overrides
                  await db.collection('nilai').doc(docId).set({
                    'kelasId': k.id,
                    'mahasiswaId': student.mahasiswaId,
                    'mahasiswaNama': student.mahasiswaNama,
                    'mahasiswaNim': student.mahasiswaNim,
                    'nilaiQuiz': qVal,
                    'nilaiPraktikum': fVal,
                    'isAbsensiOverridden': overrideAbsensi,
                    'isLpOverridden': overrideLp,
                    'isTpOverridden': overrideTp,
                    'nilaiAbsensiManual': absVal,
                    'nilaiLaporanManual': lpVal,
                    'nilaiTugasManual': tpVal,
                  }, SetOptions(merge: true));

                  // 2. Trigger automatic recalculation mapping weights
                  await provider.recalculateStudentGrades(
                    studentId: student.mahasiswaId,
                    studentNama: student.mahasiswaNama,
                    studentNim: student.mahasiswaNim,
                    kelas: k,
                  );

                  absensiController.dispose();
                  lpController.dispose();
                  tpController.dispose();
                  quizController.dispose();
                  praktikumController.dispose();

                  if (mounted) {
                    AppSnackbar.success(context, 'Nilai ${student.mahasiswaNama} berhasil disimpan.');
                  }
                  _loadKelasGrades(k.id);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AsdosDashboardProvider>();

    if (_selectedKelas != null) {
      final filteredStudents = _students
          .where((s) => s.mahasiswaNama.toLowerCase().contains(_searchQuery.toLowerCase()) || s.mahasiswaNim.contains(_searchQuery))
          .toList();

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Nilai Rekap ${_selectedKelas!.namaKelas}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              setState(() {
                _selectedKelas = null;
                _students = [];
                _nilaiList = [];
                _searchQuery = '';
              });
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Atur Bobot Penilaian',
              onPressed: _showAturBobotDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // Bobot Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bobot Komponen Praktikum:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildBobotLabel('Kehadiran', _selectedKelas!.bobotAbsensi),
                      _buildBobotLabel('LP', _selectedKelas!.bobotLaporan),
                      _buildBobotLabel('TP', _selectedKelas!.bobotTugas),
                      _buildBobotLabel('Keaktifan', _selectedKelas!.bobotQuiz),
                      _buildBobotLabel('Final', _selectedKelas!.bobotPraktikum),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search Bar
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surface,
              child: AppTextField(
                controller: _searchController,
                label: 'Cari Mahasiswa',
                hint: 'Masukkan nama atau NIM...',
                prefixIcon: Icons.search_rounded,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStudents.isEmpty
                      ? const Center(child: Text('Tidak ada mahasiswa ditemukan.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredStudents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final s = filteredStudents[idx];
                            final nIdx = _nilaiList.indexWhere((n) => n.mahasiswaId == s.mahasiswaId);
                            final NilaiModel? n = nIdx != -1 ? _nilaiList[nIdx] : null;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.mahasiswaNama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('NIM. ${s.mahasiswaNim}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                        const SizedBox(height: 6),
                                        if (n == null)
                                          const Text('Nilai belum dimasukkan/dihitung.', style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic))
                                        else ...[
                                          Text(
                                            'LP: ${n.nilaiLaporan.toStringAsFixed(1)}${n.isLpOverridden ? "*" : ""} | TP: ${n.nilaiTugas.toStringAsFixed(1)}${n.isTpOverridden ? "*" : ""} | Abs: ${n.nilaiAbsensi.toStringAsFixed(0)}${n.isAbsensiOverridden ? "*" : "%"}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          ),
                                          Text(
                                            'Quiz: ${n.nilaiQuiz.toStringAsFixed(1)} | Final: ${n.nilaiPraktikum.toStringAsFixed(1)}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          ),
                                          Text(
                                            'Nilai Akhir: ${n.nilaiAkhir.toStringAsFixed(1)}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            n?.huruf ?? '-',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextButton(
                                        onPressed: () => _showPenilaianMahasiswaDialog(s, n),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Beri Nilai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rekap Penilaian Praktikum'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: provider.kelasList.isEmpty
          ? const Center(
              child: EmptyStateWidget(
                icon: Icons.grade_outlined,
                title: 'Tidak Ada Kelas',
                description: 'Anda tidak memiliki kelas asistensi untuk meninjau nilai.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: provider.kelasList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final kelas = provider.kelasList[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedKelas = kelas;
                    });
                    _loadKelasGrades(kelas.id);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.grade_outlined, color: Colors.indigo, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kelas.matakuliahNama,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Kode: ${kelas.matakuliahKode}  •  Kelas: ${kelas.namaKelas}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBobotLabel(String name, int pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$name: $pct%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 5: PROFIL ASDOS (EDIT DETAIL & RESET PASSWORD)
// ─────────────────────────────────────────────────────────────
class _AsdosProfilTab extends StatefulWidget {
  final UserModel? user;

  const _AsdosProfilTab({required this.user});

  @override
  State<_AsdosProfilTab> createState() => _AsdosProfilTabState();
}

class _AsdosProfilTabState extends State<_AsdosProfilTab> {
  bool _isUploadingPhoto = false;

  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final file = File(picked.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'profiles/asdos/${widget.user!.uid}_$timestamp.jpg';

      final fileUrl = await StorageRepository.instance.uploadFile(file: file, path: path);

      // Save url to Firestore user doc
      await FirebaseFirestore.instance.collection('users').doc(widget.user!.uid).update({
        'photoUrl': fileUrl,
      });

      // Reload profile
      if (mounted) {
        await context.read<AuthProvider>().loadCurrentUser();
        AppSnackbar.success(context, 'Foto profil berhasil diperbarui.');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal mengunggah foto: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: widget.user?.nama);
    final emailController = TextEditingController(text: widget.user?.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Informasi Pribadi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: nameController, label: 'Nama Lengkap', prefixIcon: Icons.badge_rounded),
            const SizedBox(height: 12),
            AppTextField(controller: emailController, label: 'Email', prefixIcon: Icons.email_rounded, enabled: false),
            const SizedBox(height: 6),
            const Text('Catatan: Perubahan email dinonaktifkan demi alasan keamanan akun.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                AppSnackbar.error(context, 'Nama lengkap tidak boleh kosong.');
                return;
              }

              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('users').doc(widget.user!.uid).update({
                'nama': newName,
              });

              if (mounted) {
                await context.read<AuthProvider>().loadCurrentUser();
                AppSnackbar.success(context, 'Informasi profil berhasil diperbarui.');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: passController,
              label: 'Password Baru',
              hint: 'Minimal 6 karakter...',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = passController.text.trim();
              if (newPass.length < 6) {
                AppSnackbar.error(context, 'Password baru harus minimal 6 karakter.');
                return;
              }

              Navigator.pop(context);
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.updatePassword(newPass);
                  if (mounted) AppSnackbar.success(context, 'Password berhasil diperbarui.');
                }
              } catch (e) {
                if (mounted) {
                  AppSnackbar.error(
                    context,
                    'Gagal reset password. Harap logout dan login kembali untuk melakukan autentikasi ulang.',
                  );
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi SAKTI'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aplikasi SAKTI v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Sistem Akademik Transparan dan Terintegrasi (SAKTI) adalah platform akademik kampus terintegrasi yang memudahkan interaksi antara Dosen, Asisten Dosen, dan Mahasiswa.'),
            SizedBox(height: 12),
            Text('Pengembang:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
            Text('Tim PPB Kelompok Sakti 2026', style: TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Asisten Dosen'),
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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: widget.user?.photoUrl != null && widget.user!.photoUrl.isNotEmpty
                          ? NetworkImage(widget.user!.photoUrl)
                          : null,
                      child: widget.user?.photoUrl == null || widget.user!.photoUrl.isEmpty
                          ? const Icon(Icons.person_rounded, size: 50, color: AppColors.primary)
                          : null,
                    ),
                    if (_isUploadingPhoto)
                      const Positioned.fill(
                        child: CircularProgressIndicator(),
                      ),
                    GestureDetector(
                      onTap: _updateProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.user?.nama ?? 'Asisten Dosen',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'NIM. ${widget.user?.nomorInduk ?? "-"}',
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
                    'ASISTEN DOSEN',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detail Info & Settings List
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
                  subtitle: Text(widget.user?.email ?? '-'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
                  title: const Text('Ubah Informasi Pribadi'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showEditProfileDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                  title: const Text('Reset Password Akun'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showResetPasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  title: const Text('Tentang SAKTI'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showAppInfoDialog,
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
