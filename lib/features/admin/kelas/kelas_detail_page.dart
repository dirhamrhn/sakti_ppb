import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/kelas_model.dart';
import '../../../models/mahasiswa_model.dart';
import '../../../models/asdos_model.dart';
import '../../../providers/kelas_provider.dart';
import '../../../repositories/kelas_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/matakuliah_repository.dart';

class KelasDetailPage extends StatefulWidget {
  final String kelasId;
  const KelasDetailPage({super.key, required this.kelasId});

  @override
  State<KelasDetailPage> createState() => _KelasDetailPageState();
}

class _KelasDetailPageState extends State<KelasDetailPage> {
  KelasModel? _kelas;
  bool _isLoadingKelas = true;

  @override
  void initState() {
    super.initState();
    _loadKelas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KelasProvider>().loadEnrollments(widget.kelasId);
    });
  }

  Future<void> _loadKelas() async {
    setState(() => _isLoadingKelas = true);
    try {
      _kelas = await KelasRepository.instance.getById(widget.kelasId);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal memuat data kelas.');
    } finally {
      if (mounted) setState(() => _isLoadingKelas = false);
    }
  }

  Future<void> _showAddMahasiswaDialog() async {
    if (_kelas == null) return;
    final mahasiswaList = await UserRepository.instance.getMahasiswaList();
    if (!mounted) return;

    final provider = context.read<KelasProvider>();
    final enrolledIds = provider.enrollments.map((e) => e.mahasiswaId).toSet();
    final available = mahasiswaList
        .where((m) => !enrolledIds.contains(m.uid))
        .toList();

    if (available.isEmpty) {
      AppSnackbar.info(
        context,
        'Semua mahasiswa sudah terdaftar di kelas ini.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddMahasiswaSheet(
        mahasiswaList: available,
        onAdd: (mahasiswa) async {
          Navigator.pop(context);
          final success = await provider.enrollMahasiswa(mahasiswa, _kelas!);
          if (!mounted) return;
          if (success) {
            AppSnackbar.success(
              context,
              '${mahasiswa.nama} berhasil didaftarkan.',
            );
            await _loadKelas();
          } else {
            AppSnackbar.error(
              context,
              provider.errorMessage ?? 'Gagal mendaftarkan.',
            );
          }
        },
      ),
    );
  }

  Future<void> _showAddAsdosDialog() async {
    if (_kelas == null) return;
    
    // Validasi apakah mata kuliah memiliki sesi praktikum
    final course = await MatakuliahRepository.instance.getById(_kelas!.matakuliahId);
    if (!mounted) return;
    if (course == null) return;
    if (!course.hasPraktikum) {
      AppSnackbar.warning(
        context,
        'Mata kuliah ini tidak memiliki praktikum, tidak dapat menambahkan asisten dosen.',
      );
      return;
    }

    final asdosList = await UserRepository.instance.getAsdosList();
    if (!mounted) return;

    final assignedIds = _kelas!.asdosIds.toSet();
    final available = asdosList
        .where((a) => !assignedIds.contains(a.uid) && a.praktikumIds.contains(_kelas!.matakuliahId))
        .toList();

    if (available.isEmpty) {
      AppSnackbar.info(
        context,
        'Semua asisten dosen sudah diassign ke kelas ini.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddAsdosSheet(
        asdosList: available,
        onAdd: (asdos) async {
          Navigator.pop(context);
          try {
            await KelasRepository.instance.addAsdos(
              widget.kelasId,
              asdos.uid,
              asdos.nama,
            );
            await _loadKelas();
            if (!mounted) return;
            AppSnackbar.success(context, '${asdos.nama} berhasil diassign.');
          } catch (e) {
            if (mounted)
              AppSnackbar.error(context, 'Gagal assign asisten dosen.');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kelasProvider = context.watch<KelasProvider>();

    if (_isLoadingKelas) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_kelas == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Kelas'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Kelas tidak ditemukan.')),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('${_kelas!.matakuliahKode} - ${_kelas!.namaKelas}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => Navigator.pushNamed(
                context,
                RouteName.adminKelasForm,
                arguments: widget.kelasId,
              ).then((_) => _loadKelas()),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Mahasiswa'),
              Tab(text: 'Asisten Dosen'),
              Tab(text: 'Bobot Nilai'),
              Tab(text: 'Fitur LMS'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Info Kelas
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kelas!.matakuliahNama,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    Icons.person_rounded,
                    'Dosen',
                    _kelas!.dosenNama.isNotEmpty
                        ? _kelas!.dosenNama
                        : 'Belum diassign',
                  ),
                  _InfoRow(
                    Icons.calendar_month_rounded,
                    'Semester',
                    _kelas!.semesterNama,
                  ),
                  _InfoRow(
                    Icons.group_rounded,
                    'Kapasitas',
                    '${_kelas!.jumlahMahasiswa}/${_kelas!.kapasitas} mahasiswa',
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab Mahasiswa
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AppButton(
                          label: 'Tambah Mahasiswa',
                          icon: Icons.person_add_rounded,
                          onPressed: _showAddMahasiswaDialog,
                          height: 44,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: kelasProvider.isEnrollmentLoading
                            ? const Center(child: CircularProgressIndicator())
                            : kelasProvider.enrollments.isEmpty
                            ? const EmptyStateWidget(
                                icon: Icons.school_rounded,
                                title: 'Belum Ada Mahasiswa',
                                description:
                                    'Tap tombol di atas untuk menambah.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                itemCount: kelasProvider.enrollments.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final e = kelasProvider.enrollments[i];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              AppColors.primaryContainer,
                                          child: Text(
                                            e.mahasiswaNama.isNotEmpty
                                                ? e.mahasiswaNama[0]
                                                      .toUpperCase()
                                                : 'M',
                                            style: AppTextStyles.titleSmall
                                                .copyWith(
                                                  color: AppColors.primary,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.mahasiswaNama,
                                                style: AppTextStyles.cardTitle,
                                              ),
                                              Text(
                                                'NIM: ${e.mahasiswaNim}',
                                                style:
                                                    AppTextStyles.cardSubtitle,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_rounded,
                                            color: AppColors.error,
                                          ),
                                          onPressed: () => ConfirmDialog.show(
                                            context,
                                            title: 'Keluarkan Mahasiswa',
                                            message:
                                                'Yakin ingin mengeluarkan ${e.mahasiswaNama} dari kelas ini?',
                                            confirmLabel: 'Keluarkan',
                                            isDanger: true,
                                            onConfirm: () async {
                                              final success =
                                                  await kelasProvider
                                                      .unenrollMahasiswa(
                                                        e.id,
                                                        widget.kelasId,
                                                      );
                                              if (!mounted) return;
                                              if (success) {
                                                AppSnackbar.success(
                                                  context,
                                                  'Mahasiswa dikeluarkan dari kelas.',
                                                );
                                                await _loadKelas();
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),

                  // Tab Asdos
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AppButton(
                          label: 'Assign Asisten Dosen',
                          icon: Icons.person_add_rounded,
                          onPressed: _showAddAsdosDialog,
                          height: 44,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _kelas!.asdosIds.isEmpty
                            ? const EmptyStateWidget(
                                icon: Icons.people_rounded,
                                title: 'Belum Ada Asisten Dosen',
                                description:
                                    'Tap tombol di atas untuk mengassign.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                itemCount: _kelas!.asdosIds.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) => Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            AppColors.secondaryContainer,
                                        child: Text(
                                          _kelas!.asdosNama[i].isNotEmpty
                                              ? _kelas!.asdosNama[i][0]
                                                    .toUpperCase()
                                              : 'A',
                                          style: AppTextStyles.titleSmall
                                              .copyWith(
                                                color: AppColors.secondary,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _kelas!.asdosNama[i],
                                          style: AppTextStyles.cardTitle,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_rounded,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () => ConfirmDialog.show(
                                          context,
                                          title: 'Hapus Asisten Dosen',
                                          message:
                                              'Yakin ingin melepas ${_kelas!.asdosNama[i]} dari kelas ini?',
                                          confirmLabel: 'Lepas',
                                          isDanger: true,
                                          onConfirm: () async {
                                            try {
                                              await KelasRepository.instance
                                                  .removeAsdos(
                                                    widget.kelasId,
                                                    _kelas!.asdosIds[i],
                                                    _kelas!.asdosNama[i],
                                                  );
                                              await _loadKelas();
                                              if (!mounted) return;
                                              AppSnackbar.success(
                                                context,
                                                'Asisten dosen dilepas.',
                                              );
                                            } catch (e) {
                                              if (mounted)
                                                AppSnackbar.error(
                                                  context,
                                                  'Gagal.',
                                                );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  // ────────────────────────────────────────────
                  // Tab Bobot Nilai
                  // ────────────────────────────────────────────
                  _BobotNilaiTab(kelas: _kelas!, onSaved: _loadKelas),
                  // ────────────────────────────────────────────
                  // Tab Fitur LMS
                  // ────────────────────────────────────────────
                  _FiturLmsTab(kelas: _kelas!, onSaved: _loadKelas),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.labelMedium),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _AddMahasiswaSheet extends StatefulWidget {
  final List<MahasiswaModel> mahasiswaList;
  final void Function(MahasiswaModel) onAdd;
  const _AddMahasiswaSheet({required this.mahasiswaList, required this.onAdd});

  @override
  State<_AddMahasiswaSheet> createState() => _AddMahasiswaSheetState();
}

class _AddMahasiswaSheetState extends State<_AddMahasiswaSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.mahasiswaList.where((m) {
      final q = _query.toLowerCase();
      return m.nama.toLowerCase().contains(q) ||
          m.nim.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Pilih Mahasiswa', style: AppTextStyles.titleMedium),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIM...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: filtered.length,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    filtered[i].nama[0].toUpperCase(),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                title: Text(filtered[i].nama),
                subtitle: Text('NIM: ${filtered[i].nim}'),
                trailing: const Icon(
                  Icons.add_circle_rounded,
                  color: AppColors.primary,
                ),
                onTap: () => widget.onAdd(filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAsdosSheet extends StatefulWidget {
  final List<AsdosModel> asdosList;
  final void Function(AsdosModel) onAdd;
  const _AddAsdosSheet({required this.asdosList, required this.onAdd});

  @override
  State<_AddAsdosSheet> createState() => _AddAsdosSheetState();
}

class _AddAsdosSheetState extends State<_AddAsdosSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pilih Asisten Dosen',
              style: AppTextStyles.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: widget.asdosList.length,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondaryContainer,
                  child: Text(
                    widget.asdosList[i].nama[0].toUpperCase(),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                title: Text(widget.asdosList[i].nama),
                subtitle: Text('NIM: ${widget.asdosList[i].nim}'),
                trailing: const Icon(
                  Icons.add_circle_rounded,
                  color: AppColors.secondary,
                ),
                onTap: () => widget.onAdd(widget.asdosList[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Tab Bobot Nilai
// ══════════════════════════════════════════════════════════════════
class _BobotNilaiTab extends StatefulWidget {
  final KelasModel kelas;
  final VoidCallback onSaved;
  const _BobotNilaiTab({required this.kelas, required this.onSaved});

  @override
  State<_BobotNilaiTab> createState() => _BobotNilaiTabState();
}

class _BobotNilaiTabState extends State<_BobotNilaiTab> {
  late int _absensi;
  late int _tugas;
  late int _uts;
  late int _uas;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _absensi = widget.kelas.bobotAbsensi;
    _tugas = widget.kelas.bobotTugas;
    _uts = widget.kelas.bobotUTS;
    _uas = widget.kelas.bobotUAS;
  }

  int get _total => _absensi + _tugas + _uts + _uas;

  Future<void> _save() async {
    if (_total != 100) {
      AppSnackbar.error(context, 'Total bobot harus 100%. Saat ini: $_total%');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final success = await context.read<KelasProvider>().updateBobotNilai(
        widget.kelas.id,
        bobotAbsensi: _absensi,
        bobotTugas: _tugas,
        bobotUTS: _uts,
        bobotUAS: _uas,
      );
      if (!mounted) return;
      if (success) {
        AppSnackbar.success(context, 'Bobot nilai disimpan.');
        widget.onSaved();
      } else {
        AppSnackbar.error(context, 'Gagal menyimpan bobot nilai.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _total == 100
                  ? AppColors.successLight
                  : AppColors.errorLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _total == 100 ? AppColors.success : AppColors.error,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _total == 100
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: _total == 100 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 10),
                Text(
                  _total == 100
                      ? 'Total bobot: 100% ✓'
                      : 'Total bobot: $_total% (harus 100%)',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: _total == 100 ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSlider(
            'Absensi',
            _absensi,
            (v) => setState(() => _absensi = v),
            AppColors.info,
          ),
          _buildSlider(
            'Tugas',
            _tugas,
            (v) => setState(() => _tugas = v),
            AppColors.warning,
          ),
          _buildSlider(
            'UTS',
            _uts,
            (v) => setState(() => _uts = v),
            AppColors.secondary,
          ),
          _buildSlider(
            'UAS',
            _uas,
            (v) => setState(() => _uas = v),
            AppColors.error,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: _isSaving ? 'Menyimpan...' : 'Simpan Bobot Nilai',
            onPressed: (_isSaving || _total != 100) ? null : _save,
            icon: Icons.save_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    int value,
    ValueChanged<int> onChanged,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.labelLarge),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value%',
                style: AppTextStyles.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 60,
          divisions: 12,
          activeColor: color,
          inactiveColor: color.withOpacity(0.2),
          onChanged: (v) => onChanged(v.toInt()),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Tab Fitur LMS
// ══════════════════════════════════════════════════════════════════
class _FiturLmsTab extends StatefulWidget {
  final KelasModel kelas;
  final VoidCallback onSaved;
  const _FiturLmsTab({required this.kelas, required this.onSaved});

  @override
  State<_FiturLmsTab> createState() => _FiturLmsTabState();
}

class _FiturLmsTabState extends State<_FiturLmsTab> {
  late bool _materi;
  late bool _tugas;
  late bool _quiz;
  late bool _pengumuman;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _materi = widget.kelas.fiturMateri;
    _tugas = widget.kelas.fiturTugas;
    _quiz = widget.kelas.fiturQuiz;
    _pengumuman = widget.kelas.fiturPengumuman;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final success = await context.read<KelasProvider>().updateFitur(
        widget.kelas.id,
        fiturMateri: _materi,
        fiturTugas: _tugas,
        fiturQuiz: _quiz,
        fiturPengumuman: _pengumuman,
      );
      if (!mounted) return;
      if (success) {
        AppSnackbar.success(context, 'Konfigurasi fitur disimpan.');
        widget.onSaved();
      } else {
        AppSnackbar.error(context, 'Gagal menyimpan fitur.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Text(
              'Fitur yang diaktifkan akan terlihat oleh mahasiswa di kelas ini. '
              'Mahasiswa tidak dapat mengakses fitur yang dinonaktifkan.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
            ),
          ),
          const SizedBox(height: 20),
          _buildToggle(
            'Materi',
            'Modul dan file materi kuliah',
            Icons.menu_book_rounded,
            _materi,
            (v) => setState(() => _materi = v),
            AppColors.primary,
          ),
          const SizedBox(height: 8),
          _buildToggle(
            'Tugas',
            'Upload dan kumpulkan tugas',
            Icons.assignment_rounded,
            _tugas,
            (v) => setState(() => _tugas = v),
            AppColors.warning,
          ),
          const SizedBox(height: 8),
          _buildToggle(
            'Quiz',
            'Kuis online real-time',
            Icons.quiz_rounded,
            _quiz,
            (v) => setState(() => _quiz = v),
            AppColors.secondary,
          ),
          const SizedBox(height: 8),
          _buildToggle(
            'Pengumuman',
            'Notifikasi & pengumuman dari dosen',
            Icons.campaign_rounded,
            _pengumuman,
            (v) => setState(() => _pengumuman = v),
            AppColors.info,
          ),
          const SizedBox(height: 32),
          AppButton(
            label: _isSaving ? 'Menyimpan...' : 'Simpan Konfigurasi Fitur',
            onPressed: _isSaving ? null : _save,
            icon: Icons.save_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.06) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? color.withOpacity(0.4) : AppColors.border,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? color.withOpacity(0.15)
                  : AppColors.border.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? color : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: value ? color : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }
}
