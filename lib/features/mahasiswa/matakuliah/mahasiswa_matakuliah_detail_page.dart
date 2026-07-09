import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/sakti_pdf_viewer_page.dart';
import '../../../../models/kelas_model.dart';
import '../../../../models/absensi_model.dart';
import '../../../../models/tugas_model.dart';
import '../../../../models/nilai_model.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/kelas_repository.dart';
import '../tugas/mahasiswa_tugas_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class MahasiswaMatakuliahDetailPage extends StatefulWidget {
  final String kelasId;
  const MahasiswaMatakuliahDetailPage({super.key, required this.kelasId});

  @override
  State<MahasiswaMatakuliahDetailPage> createState() =>
      _MahasiswaMatakuliahDetailPageState();
}

class _MahasiswaMatakuliahDetailPageState
    extends State<MahasiswaMatakuliahDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  KelasModel? _kelas;
  bool _isLoadingKelas = true;

  List<AbsensiModel> _absensiList = [];
  List<TugasModel> _tugasList = [];
  List<MateriModel> _materiList = [];

  List<Map<String, dynamic>> _modulList = [];
  List<int> _openedModulKeList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingKelas = true);
    try {
      final provider = context.read<MahasiswaDashboardProvider>();
      _kelas = await KelasRepository.instance.getById(widget.kelasId);
      _absensiList = await provider.getAbsensiByKelas(widget.kelasId);
      _tugasList = await provider.getTugasByKelas(widget.kelasId);
      _materiList = await provider.getMateriByKelas(widget.kelasId);

      // Load modul praktikum & progress if it's a practical class
      if (_kelas != null && _kelas!.asdosIds.isNotEmpty) {
        final db = FirebaseFirestore.instance;
        final modulSnap = await db
            .collection('modul_praktikum')
            .where('kelasId', isEqualTo: widget.kelasId)
            .get();
        _modulList = modulSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

        final uid = context.read<AuthProvider>().user?.uid;
        if (uid != null) {
          final progressSnap = await db
              .collection('modul_progress')
              .where('mahasiswaId', isEqualTo: uid)
              .where('kelasId', isEqualTo: widget.kelasId)
              .get();
          _openedModulKeList = progressSnap.docs
              .map((d) => d.data()['modulKe'] as int)
              .toList();
        }
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal memuat data.');
    } finally {
      if (mounted) setState(() => _isLoadingKelas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingKelas) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_kelas == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Mata Kuliah')),
        body: const Center(child: Text('Kelas tidak ditemukan.')),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_kelas!.matakuliahNama),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Materi'),
              Tab(text: 'Presensi'),
              Tab(text: 'Tugas'),
              Tab(text: 'Nilai'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _InfoTab(kelas: _kelas!),
            _MateriTab(
              materiList: _materiList,
              kelas: _kelas!,
              modulList: _modulList,
              openedModulKeList: _openedModulKeList,
              onRefreshModul: _loadData,
            ),
            _AbsensiTab(absensiList: _absensiList),
            _TugasTab(
              tugasList: _tugasList,
              kelasId: widget.kelasId,
              onRefresh: _loadData,
            ),
            _NilaiTab(kelas: _kelas!),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Info ─────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final KelasModel kelas;
  const _InfoTab({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B5BDB), Color(0xFF6741D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kelas.matakuliahNama,
                  style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  CourseFormatter.getAbbreviation(kelas.matakuliahNama, kelas.matakuliahKode),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detail info
          _InfoSection('Informasi Kelas', [
            _InfoRow(Icons.class_rounded, 'Kelas', kelas.namaKelas),
            _InfoRow(
              Icons.person_rounded,
              'Dosen Pengampu',
              kelas.dosenNama.isNotEmpty ? kelas.dosenNama : '-',
            ),
            _InfoRow(
              Icons.calendar_month_rounded,
              'Semester',
              kelas.semesterNama,
            ),
            _InfoRow(
              Icons.group_rounded,
              'Jumlah Mahasiswa',
              '${kelas.jumlahMahasiswa}/${kelas.kapasitas} orang',
            ),
            _InfoRow(
              Icons.circle,
              'Status',
              kelas.status ? 'Aktif' : 'Nonaktif',
              valueColor: kelas.status ? AppColors.success : AppColors.error,
            ),
          ]),

          if (kelas.asdosNama.isNotEmpty) ...[
            const SizedBox(height: 20),
            _InfoSection('Asisten Dosen', [
              for (final nama in kelas.asdosNama)
                _InfoRow(Icons.people_rounded, 'Asdos', nama),
            ]),
          ],
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _InfoSection(this.title, this.rows);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: valueColor != null ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Materi ───────────────────────────────────────────────────────────────

class _MateriTab extends StatefulWidget {
  final List<MateriModel> materiList;
  final KelasModel kelas;
  final List<Map<String, dynamic>> modulList;
  final List<int> openedModulKeList;
  final VoidCallback onRefreshModul;

  const _MateriTab({
    required this.materiList,
    required this.kelas,
    required this.modulList,
    required this.openedModulKeList,
    required this.onRefreshModul,
  });

  @override
  State<_MateriTab> createState() => _MateriTabState();
}

class _MateriTabState extends State<_MateriTab> {
  int _selectedSegment = 0; // 0: Teori, 1: Praktikum

  @override
  Widget build(BuildContext context) {
    final bool hasPractical = widget.kelas.asdosIds.isNotEmpty;

    if (!hasPractical) {
      return _buildTeoriList();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Materi Teori')),
                  selected: _selectedSegment == 0,
                  onSelected: (val) {
                    if (val) setState(() => _selectedSegment = 0);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Modul Praktikum')),
                  selected: _selectedSegment == 1,
                  onSelected: (val) {
                    if (val) setState(() => _selectedSegment = 1);
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _selectedSegment == 0 ? _buildTeoriList() : _buildPraktikumList(),
        ),
      ],
    );
  }

  Widget _buildTeoriList() {
    if (widget.materiList.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.folder_open_rounded,
        title: 'Belum Ada Materi',
        description: 'Dosen belum mengunggah materi pertemuan.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.materiList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final m = widget.materiList[i];
        final bool hasFile = m.fileUrl.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!hasFile) {
                AppSnackbar.warning(context, 'Materi belum diunggah oleh Dosen.');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SaktiPdfViewerPage(
                    title: 'Pertemuan ${m.pertemuanKe}: ${m.topik}',
                    pdfUrl: m.fileUrl,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${m.pertemuanKe}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pertemuan ${m.pertemuanKe}: ${m.topik}',
                          style: AppTextStyles.cardTitle,
                        ),
                        if (m.deskripsi.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            m.deskripsi,
                            style: AppTextStyles.cardSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (m.tanggal.isNotEmpty)
                          Text(m.tanggal, style: AppTextStyles.labelSmall),
                      ],
                    ),
                  ),
                  if (hasFile)
                    const Icon(
                      Icons.visibility_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPraktikumList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final modulKe = index + 1;

        Map<String, dynamic>? currentModul;
        for (final m in widget.modulList) {
          if (m['modulKe'] == modulKe) {
            currentModul = m;
            break;
          }
        }

        final bool isUnlocked = modulKe == 1 || widget.openedModulKeList.contains(modulKe - 1);
        final bool isCompleted = widget.openedModulKeList.contains(modulKe);
        final bool hasFile = currentModul != null && (currentModul['fileUrl'] ?? '').toString().isNotEmpty;

        Color cardColor = AppColors.surface;
        Color accentColor = AppColors.textSecondary;
        Widget statusWidget;

        if (!isUnlocked) {
          statusWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text('Terkunci', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        } else if (isCompleted) {
          cardColor = AppColors.success.withOpacity(0.02);
          accentColor = AppColors.success;
          statusWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                SizedBox(width: 4),
                Text('Selesai', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        } else if (!hasFile) {
          statusWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty_rounded, size: 12, color: AppColors.warning),
                SizedBox(width: 4),
                Text('Menunggu', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        } else {
          accentColor = AppColors.primary;
          statusWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill_rounded, size: 12, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Mulai Baca', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        final title = currentModul != null && (currentModul['judul'] ?? '').toString().isNotEmpty
            ? currentModul['judul']
            : 'Modul Praktikum $modulKe';

        final desc = currentModul != null && (currentModul['deskripsi'] ?? '').toString().isNotEmpty
            ? currentModul['deskripsi']
            : 'Materi praktikum untuk Modul $modulKe.';

        return GestureDetector(
          onTap: () async {
            if (!isUnlocked) {
              AppSnackbar.error(context, 'Modul ini masih terkunci. Harap baca modul sebelumnya terlebih dahulu.');
              return;
            }
            if (!hasFile) {
              AppSnackbar.warning(context, 'Modul belum diunggah oleh Asisten Dosen.');
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SaktiPdfViewerPage(
                  title: 'Modul $modulKe: $title',
                  pdfUrl: currentModul!['fileUrl'],
                ),
              ),
            );

            final uid = context.read<AuthProvider>().user?.uid;
            if (uid != null) {
              await FirebaseFirestore.instance
                  .collection('modul_progress')
                  .doc('${uid}_${widget.kelas.id}_$modulKe')
                  .set({
                'mahasiswaId': uid,
                'kelasId': widget.kelas.id,
                'modulKe': modulKe,
                'openedAt': FieldValue.serverTimestamp(),
              });
              widget.onRefreshModul();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked
                    ? (isCompleted ? AppColors.success.withOpacity(0.4) : AppColors.border)
                    : AppColors.border.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? (isCompleted ? AppColors.success.withOpacity(0.1) : AppColors.primaryContainer)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUnlocked
                        ? (isCompleted ? Icons.check_circle_outline_rounded : Icons.menu_book_rounded)
                        : Icons.lock_outline_rounded,
                    color: isUnlocked
                        ? (isCompleted ? AppColors.success : AppColors.primary)
                        : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Modul $modulKe',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          statusWidget,
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: AppTextStyles.cardSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab Absensi ──────────────────────────────────────────────────────────────

class _AbsensiTab extends StatelessWidget {
  final List<AbsensiModel> absensiList;
  const _AbsensiTab({required this.absensiList});

  @override
  Widget build(BuildContext context) {
    if (absensiList.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.how_to_reg_rounded,
        title: 'Belum Ada Data Absensi',
        description: 'Data absensi akan muncul setelah pertemuan.',
      );
    }

    final hadir = absensiList.where((a) => a.isHadir).length;
    final izin = absensiList.where((a) => a.isIzin).length;
    final sakit = absensiList.where((a) => a.isSakit).length;
    final alpha = absensiList.where((a) => a.isAlpha).length;
    final persen = hadir / absensiList.length * 100;

    return Column(
      children: [
        // Summary header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B5BDB), Color(0xFF6741D9)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AbsensiStat('Hadir', hadir, Colors.white),
                  _AbsensiStat('Izin', izin, Colors.yellow.shade200),
                  _AbsensiStat('Sakit', sakit, Colors.orange.shade200),
                  _AbsensiStat('Alpha', alpha, Colors.red.shade200),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: hadir / absensiList.length,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kehadiran: ${persen.toStringAsFixed(0)}%',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),

        // List absensi
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: absensiList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final a = absensiList[i];
              return _AbsensiItem(absensi: a);
            },
          ),
        ),
      ],
    );
  }
}

class _AbsensiStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AbsensiStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: AppTextStyles.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _AbsensiItem extends StatelessWidget {
  final AbsensiModel absensi;
  const _AbsensiItem({required this.absensi});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (absensi.status) {
      case 'hadir':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Hadir';
        break;
      case 'terlambat':
        statusColor = AppColors.warning;
        statusIcon = Icons.watch_later_rounded;
        statusLabel = 'Terlambat';
        break;
      case 'izin':
        statusColor = AppColors.info;
        statusIcon = Icons.info_rounded;
        statusLabel = 'Izin';
        break;
      case 'sakit':
        statusColor = AppColors.warning;
        statusIcon = Icons.medical_services_rounded;
        statusLabel = 'Sakit';
        break;
      default:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Alpha';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${absensi.pertemuanKe}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pertemuan ${absensi.pertemuanKe}',
                  style: AppTextStyles.cardTitle,
                ),
                if (absensi.tanggal.isNotEmpty)
                  Text(absensi.tanggal, style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: AppTextStyles.labelSmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tab Tugas ────────────────────────────────────────────────────────────────

class _TugasTab extends StatelessWidget {
  final List<TugasModel> tugasList;
  final String kelasId;
  final VoidCallback onRefresh;

  const _TugasTab({
    required this.tugasList,
    required this.kelasId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaDashboardProvider>();

    if (tugasList.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: 'Belum Ada Tugas',
        description: 'Belum ada tugas yang diberikan.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tugasList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final tugas = tugasList[i];
        final isSubmitted = provider.hasSubmitted(tugas.id);
        final deadline = tugas.deadline.toDate();
        final isOverdue = deadline.isBefore(DateTime.now());
        final dayLeft = deadline.difference(DateTime.now()).inDays;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MahasiswaTugasDetailPage(tugas: tugas, kelasId: kelasId),
            ),
          ).then((_) => onRefresh()),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOverdue && !isSubmitted
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSubmitted
                            ? AppColors.successLight
                            : isOverdue
                            ? AppColors.errorLight
                            : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSubmitted
                            ? Icons.check_circle_rounded
                            : Icons.assignment_rounded,
                        color: isSubmitted
                            ? AppColors.success
                            : isOverdue
                            ? AppColors.error
                            : AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tugas.judul, style: AppTextStyles.cardTitle),
                          Text(
                            tugas.dosenNama,
                            style: AppTextStyles.cardSubtitle,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM yyyy', 'id').format(deadline),
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                    if (isSubmitted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Dikumpulkan',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      )
                    else if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Terlambat',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dayLeft == 0 ? 'Hari ini' : '$dayLeft hari lagi',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab Nilai ────────────────────────────────────────────────────────────────

class _NilaiTab extends StatelessWidget {
  final KelasModel kelas;
  const _NilaiTab({required this.kelas});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaDashboardProvider>();
    final nilaiList = provider.nilaiList
        .where((n) => n.kelasId == kelas.id)
        .toList();

    if (nilaiList.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.grade_outlined,
        title: 'Belum Ada Nilai',
        description: 'Nilai akan muncul setelah dosen memasukkan penilaian.',
      );
    }

    final n = nilaiList.first;
    final bool isPractical = kelas.asdosIds.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Nilai akhir highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2F9E44), Color(0xFF69DB7C)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  n.huruf,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 56,
                  ),
                ),
                Text(
                  'Nilai Akhir: ${n.nilaiAkhir.toStringAsFixed(1)}',
                  style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
                ),
                Text(
                  'Bobot: ${n.bobot.toStringAsFixed(1)} | Mutu: ${n.mutu.toStringAsFixed(1)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Detail nilai komponen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Komponen Nilai', style: AppTextStyles.titleSmall),
                const SizedBox(height: 12),
                if (isPractical) ...[
                  _NilaiRow('Kehadiran (${kelas.bobotAbsensi}%)', n.nilaiAbsensi, AppColors.info),
                  const SizedBox(height: 8),
                  _NilaiRow('Laporan Praktikum / LP (${kelas.bobotLaporan}%)', n.nilaiLaporan, AppColors.warning),
                  const SizedBox(height: 8),
                  _NilaiRow('Tugas Pendahuluan / TP (${kelas.bobotTugas}%)', n.nilaiTugas, AppColors.success),
                  const SizedBox(height: 8),
                  _NilaiRow('Keaktifan / Quiz (${kelas.bobotQuiz}%)', n.nilaiQuiz, Colors.purple),
                  const SizedBox(height: 8),
                  _NilaiRow('Final Praktikum (${kelas.bobotPraktikum}%)', n.nilaiPraktikum, Colors.orange),
                ] else ...[
                  _NilaiRow('Nilai Tugas (${kelas.bobotTugas}%)', n.nilaiTugas, AppColors.info),
                  const SizedBox(height: 8),
                  _NilaiRow('Nilai UTS (${kelas.bobotUTS}%)', n.nilaiUTS, AppColors.warning),
                  const SizedBox(height: 8),
                  _NilaiRow('Nilai UAS (${kelas.bobotUAS}%)', n.nilaiUAS, AppColors.success),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NilaiRow extends StatelessWidget {
  final String label;
  final double nilai;
  final Color color;
  const _NilaiRow(this.label, this.nilai, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            nilai.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
