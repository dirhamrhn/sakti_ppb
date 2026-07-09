import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/kelas_model.dart';
import '../../../models/nilai_model.dart';
import '../../../models/matakuliah_model.dart';
import '../../../models/class_enrollment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dosen_dashboard_provider.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class DosenPenilaianPage extends StatefulWidget {
  const DosenPenilaianPage({super.key});

  @override
  State<DosenPenilaianPage> createState() => _DosenPenilaianPageState();
}

class _DosenPenilaianPageState extends State<DosenPenilaianPage> {
  bool _isBobotExpanded = false;
  
  // Controllers untuk input bobot
  final _absensiController = TextEditingController(text: '10');
  final _tugasController = TextEditingController(text: '20');
  final _utsController = TextEditingController(text: '30');
  final _uasController = TextEditingController(text: '40');
  final _quizController = TextEditingController(text: '0');
  final _praktikumController = TextEditingController(text: '0');
  final _laporanController = TextEditingController(text: '0');
  final _lainController = TextEditingController(text: '0');

  String _selectedScope = 'kelas'; // 'kelas', 'matakuliah', 'semua'
  KelasModel? _selectedKelasForBobot;
  String _selectedJenisMatkul = 'teori'; // 'teori' or 'praktikum'
  bool _hadSchedules = false;

  // Map untuk melacak progres penilaian per matakuliah
  final Map<String, double> _progressMap = {};
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _absensiController.dispose();
    _tugasController.dispose();
    _utsController.dispose();
    _uasController.dispose();
    _quizController.dispose();
    _praktikumController.dispose();
    _laporanController.dispose();
    _lainController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    if (!mounted) return;
    setState(() => _isLoadingProgress = true);
    
    try {
      final provider = context.read<DosenDashboardProvider>();
      final classes = provider.kelasList;
      final FirebaseFirestore db = FirebaseFirestore.instance;

      for (final kelas in classes) {
        // Ambil jumlah mahasiswa terdaftar di kelas
        final enrollments = await provider.getEnrollments(kelas.id);
        final totalMhs = enrollments.length;

        if (totalMhs == 0) {
          _progressMap[kelas.id] = 0.0;
          continue;
        }

        // Ambil jumlah nilai yang sudah lengkap
        final nilaiSnap = await db
            .collection('nilai')
            .where('kelasId', isEqualTo: kelas.id)
            .get();

        int gradedCount = 0;
        for (final doc in nilaiSnap.docs) {
          final data = doc.data();
          // Cek kelengkapan nilai uts/uas/akhir
          final uts = (data['nilaiUTS'] as num?)?.toDouble() ?? 0.0;
          final uas = (data['nilaiUAS'] as num?)?.toDouble() ?? 0.0;
          if (uts > 0 || uas > 0 || (data['nilaiAkhir'] as num?)?.toDouble() != null) {
            gradedCount++;
          }
        }

        _progressMap[kelas.id] = (gradedCount / totalMhs) * 100.0;
      }
    } catch (e) {
      debugPrint('Error loading grading progress: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProgress = false);
    }
  }

  void _initializeControllers(KelasModel kelas, List<dynamic> schedules, Map<String, MatakuliahModel> mkMap) {
    _absensiController.text = kelas.bobotAbsensi.toString();
    _tugasController.text = kelas.bobotTugas.toString();
    _utsController.text = kelas.bobotUTS.toString();
    _uasController.text = kelas.bobotUAS.toString();
    _quizController.text = kelas.bobotQuiz.toString();
    _lainController.text = kelas.bobotLain.toString();
    
    final mk = mkMap[kelas.matakuliahId] ?? mkMap[kelas.matakuliahKode];
    final courseHasPraktikum = (mk != null && mk.hasPraktikum) ||
        kelas.asdosIds.isNotEmpty ||
        schedules.any((s) => s.kelasId == kelas.id && s.jenisSesi.toLowerCase().contains('prak'));
    if (courseHasPraktikum) {
      _praktikumController.text = kelas.bobotPraktikum.toString();
    } else {
      _praktikumController.text = '0';
    }
    _laporanController.text = '0';
  }

  int get _totalBobot {
    final absensi = int.tryParse(_absensiController.text) ?? 0;
    final tugas = int.tryParse(_tugasController.text) ?? 0;
    final uts = int.tryParse(_utsController.text) ?? 0;
    final uas = int.tryParse(_uasController.text) ?? 0;
    final quiz = int.tryParse(_quizController.text) ?? 0;
    final praktikum = int.tryParse(_praktikumController.text) ?? 0;
    final laporan = 0; // combined into praktikum
    final lain = int.tryParse(_lainController.text) ?? 0;
    return absensi + tugas + uts + uas + quiz + praktikum + laporan + lain;
  }

  Future<void> _saveBobot() async {
    final total = _totalBobot;
    if (total != 100) {
      AppSnackbar.error(context, 'Total bobot harus tepat 100% (Saat ini: $total%).');
      return;
    }

    if (_selectedScope == 'kelas' && _selectedKelasForBobot == null) {
      AppSnackbar.error(context, 'Pilih kelas terlebih dahulu.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<DosenDashboardProvider>();
    final targetKelasId = _selectedKelasForBobot?.id ?? '';
    final targetMatakuliahKode = _selectedKelasForBobot?.matakuliahKode ?? '';

    setState(() => _isLoadingProgress = true);

    setState(() => _isLoadingProgress = true);

    final String actualScope;
    if (_selectedScope == 'semua') {
      actualScope = _selectedJenisMatkul == 'praktikum' ? 'semua_praktikum' : 'semua_teori';
    } else {
      actualScope = _selectedScope;
    }

    final success = await provider.updateKelasBobot(
      kelasId: targetKelasId,
      dosenId: auth.user!.uid,
      matakuliahKode: targetMatakuliahKode,
      absensi: int.parse(_absensiController.text),
      tugas: int.parse(_tugasController.text),
      uts: int.parse(_utsController.text),
      uas: int.parse(_uasController.text),
      quiz: int.parse(_quizController.text),
      praktikum: int.parse(_praktikumController.text),
      laporan: 0, // combined into praktikum
      lain: int.parse(_lainController.text),
      scope: actualScope,
    );

    if (success) {
      if (mounted) AppSnackbar.success(context, 'Bobot penilaian berhasil disimpan.');
      setState(() {
        _isBobotExpanded = false;
      });
      _loadProgress();
    } else {
      if (mounted) AppSnackbar.error(context, 'Gagal menyimpan bobot penilaian.');
      setState(() => _isLoadingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenDashboardProvider>();
    final classes = provider.kelasList;
    final schedules = provider.schedules;
    final mkMap = provider.matakuliahMap;

    // Detect schedules loading transition and reinitialize controllers safely
    if (!_hadSchedules && (schedules.isNotEmpty || mkMap.isNotEmpty)) {
      _hadSchedules = true;
      if (_selectedKelasForBobot != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedKelasForBobot != null) {
            setState(() {
              _initializeControllers(_selectedKelasForBobot!, schedules, mkMap);
            });
          }
        });
      }
    }

    // Filter classes based on selected course type
    final filteredClasses = classes.where((k) {
      final mk = mkMap[k.matakuliahId] ?? mkMap[k.matakuliahKode];
      final hasP = (mk != null && mk.hasPraktikum) ||
          k.asdosIds.isNotEmpty ||
          schedules.any((s) => s.kelasId == k.id && s.jenisSesi.toLowerCase().contains('prak'));
      return _selectedJenisMatkul == 'praktikum' ? hasP : !hasP;
    }).toList();

    final mkForBobot = _selectedKelasForBobot == null ? null : (mkMap[_selectedKelasForBobot!.matakuliahId] ?? mkMap[_selectedKelasForBobot!.matakuliahKode]);
    final hasPraktikum = _selectedKelasForBobot != null &&
        ((mkForBobot != null && mkForBobot.hasPraktikum) ||
            _selectedKelasForBobot!.asdosIds.isNotEmpty ||
            schedules.any((s) => s.kelasId == _selectedKelasForBobot?.id && s.jenisSesi.toLowerCase().contains('prak')));

    // Grouping classes by Course Name
    final Map<String, List<KelasModel>> groupedClasses = {};
    for (final k in filteredClasses) {
      final key = '${CourseFormatter.getAbbreviation(k.matakuliahNama, k.matakuliahKode)} - ${k.matakuliahNama}';
      if (!groupedClasses.containsKey(key)) {
        groupedClasses[key] = [];
      }
      groupedClasses[key]!.add(k);
    }

    // Set default kelas for bobot if not selected or if invalid for current filter
    final bool isSelectedValid = _selectedKelasForBobot != null && filteredClasses.any((k) => k.id == _selectedKelasForBobot!.id);
    if (!isSelectedValid && filteredClasses.isNotEmpty) {
      _selectedKelasForBobot = filteredClasses.first;
      _initializeControllers(_selectedKelasForBobot!, schedules, mkMap);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Penilaian Mahasiswa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final auth = context.read<AuthProvider>();
          if (auth.user != null) {
            await provider.loadSchedules(auth.user!.uid, auth.user!.nama);
            await _loadProgress();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ── Pilihan Jenis Mata Kuliah ──
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  segments: const [
                    ButtonSegment<String>(
                      value: 'teori',
                      label: Text('Teori', style: TextStyle(fontWeight: FontWeight.bold)),
                      icon: Icon(Icons.menu_book_rounded),
                    ),
                    ButtonSegment<String>(
                      value: 'praktikum',
                      label: Text('Teori + Praktikum', style: TextStyle(fontWeight: FontWeight.bold)),
                      icon: Icon(Icons.biotech_rounded),
                    ),
                  ],
                  selected: {_selectedJenisMatkul},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedJenisMatkul = newSelection.first;
                      _selectedKelasForBobot = null;
                    });
                  },
                ),
              ),
            ),

            // ── PANEL ATUR BOBOT ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ExpansionTile(
                initiallyExpanded: _isBobotExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => _isBobotExpanded = expanded);
                },
                title: Row(
                  children: [
                    const Icon(Icons.settings_suggest_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Atur Bobot Penilaian',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        
                        // Select target kelas for initial values
                        if (filteredClasses.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              _selectedJenisMatkul == 'praktikum'
                                  ? 'Tidak ada kelas Teori + Praktikum yang tersedia.'
                                  : 'Tidak ada kelas Teori yang tersedia.',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          const Text(
                            'Pilih Kelas Sebagai Acuan Awal:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<KelasModel>(
                                isExpanded: true,
                                value: _selectedKelasForBobot,
                                items: filteredClasses.map((k) {
                                  return DropdownMenuItem<KelasModel>(
                                    value: k,
                                    child: Text('${k.matakuliahNama} - Kelas ${k.namaKelas}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedKelasForBobot = val;
                                      _initializeControllers(val, schedules, mkMap);
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Weights inputs grid
                        Row(
                          children: [
                            Expanded(child: _buildWeightInput('Absensi (%)', _absensiController)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildWeightInput('Tugas (%)', _tugasController)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildWeightInput('UTS (%)', _utsController)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildWeightInput('UAS (%)', _uasController)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildWeightInput('Partisipasi (Keaktifan/Quiz) (%)', _quizController)),
                            const SizedBox(width: 12),
                            if (_selectedJenisMatkul == 'praktikum')
                              Expanded(
                                child: _buildWeightInput(
                                  'Praktikum (%)',
                                  _praktikumController,
                                  enabled: hasPraktikum,
                                  helperText: hasPraktikum ? null : 'Mata kuliah tidak ada praktikum',
                                ),
                              )
                            else
                              Expanded(child: _buildWeightInput('Lainnya (%)', _lainController)),
                          ],
                        ),
                        if (_selectedJenisMatkul == 'praktikum') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildWeightInput('Lainnya (%)', _lainController)),
                              const SizedBox(width: 12),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Total counter indicator
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _totalBobot == 100 ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _totalBobot == 100 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pengaturan Bobot:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(
                                '$_totalBobot / 100 %',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _totalBobot == 100 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Scope radio options
                        const Text(
                          'Terapkan Konfigurasi Bobot Pada:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: 'kelas',
                                  groupValue: _selectedScope,
                                  onChanged: (val) => setState(() => _selectedScope = val!),
                                ),
                                const Text('Kelas Ini', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: 'matakuliah',
                                  groupValue: _selectedScope,
                                  onChanged: (val) => setState(() => _selectedScope = val!),
                                ),
                                const Text('Satu Matakuliah', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: 'semua',
                                  groupValue: _selectedScope,
                                  onChanged: (val) => setState(() => _selectedScope = val!),
                                ),
                                Text(
                                  _selectedJenisMatkul == 'praktikum'
                                      ? 'Semua Matakuliah Teori + Praktikum'
                                      : 'Semua Matakuliah Teori',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Simpan Bobot Penilaian',
                            onPressed: _saveBobot,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── TITLE DAFTAR MATAKULIAH ──────────────────────────────
            Text(
              'Daftar Mata Kuliah',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (filteredClasses.isEmpty)
              EmptyStateWidget(
                icon: Icons.grade_rounded,
                title: 'Tidak Ada Data Penilaian',
                description: _selectedJenisMatkul == 'praktikum'
                    ? 'Tidak ada kelas Teori + Praktikum yang Anda ampu.'
                    : 'Tidak ada kelas Teori yang Anda ampu.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedClasses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, idx) {
                  final key = groupedClasses.keys.elementAt(idx);
                  final kelasGroup = groupedClasses[key]!;
                  final matakuliahNama = key.split(' - ')[1];
                  final matakuliahKode = key.split(' - ')[0];

                  // Hitung progres rata-rata dari kelas-kelas di matakuliah ini
                  double totalProgress = 0.0;
                  for (final k in kelasGroup) {
                    totalProgress += _progressMap[k.id] ?? 0.0;
                  }
                  final avgProgress = totalProgress / kelasGroup.length;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              matakuliahNama,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Kode: $matakuliahKode  •  ${kelasGroup.length} Kelas',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _isLoadingProgress ? 0.0 : avgProgress / 100.0,
                                backgroundColor: AppColors.border,
                                color: avgProgress >= 100.0 ? Colors.green : AppColors.primary,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Progres Penilaian:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                Text(
                                  _isLoadingProgress ? 'Loading...' : '${avgProgress.toStringAsFixed(0)}% Selesai',
                                  style: TextStyle(
                                    color: avgProgress >= 100.0 ? Colors.green : AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        children: kelasGroup.map((k) {
                          final p = _progressMap[k.id] ?? 0.0;
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 18),
                            ),
                            title: Text('Kelas ${k.namaKelas}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('Tahun Akademik: ${k.tahunAkademik}', style: const TextStyle(fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (p >= 100.0 ? Colors.green : Colors.amber).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p >= 100.0 ? 'Lengkap' : 'Belum Lengkap',
                                    style: TextStyle(
                                      color: p >= 100.0 ? Colors.green : Colors.amber[800],
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _DosenKelasGradingPage(kelas: k),
                                ),
                              ).then((_) => _loadProgress());
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightInput(String label, TextEditingController controller, {bool enabled = true, String? helperText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: enabled ? AppColors.textSecondary : AppColors.textDisabled, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: enabled ? AppColors.background : AppColors.background.withOpacity(0.5),
            helperText: helperText,
            helperStyle: TextStyle(fontSize: 9, color: enabled ? AppColors.textSecondary : AppColors.textDisabled),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DAFTAR MAHASISWA KELAS
// ─────────────────────────────────────────────────────────────
class _DosenKelasGradingPage extends StatefulWidget {
  final KelasModel kelas;
  const _DosenKelasGradingPage({required this.kelas});

  @override
  State<_DosenKelasGradingPage> createState() => _DosenKelasGradingPageState();
}

class _DosenKelasGradingPageState extends State<_DosenKelasGradingPage> {
  List<ClassEnrollmentModel> _students = [];
  List<NilaiModel> _grades = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final provider = context.read<DosenDashboardProvider>();
      final FirebaseFirestore db = FirebaseFirestore.instance;

      // 1. Get enrollments
      _students = await provider.getEnrollments(widget.kelas.id);

      // 2. Get grades documents
      final gradesSnap = await db
          .collection('nilai')
          .where('kelasId', isEqualTo: widget.kelas.id)
          .get();

      _grades = gradesSnap.docs
          .map((d) => NilaiModel.fromMap(d.id, d.data()))
          .toList();

    } catch (e) {
      debugPrint('Error loading student grades: $e');
      if (mounted) AppSnackbar.error(context, 'Gagal memuat rekap nilai.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ClassEnrollmentModel> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) {
      return s.mahasiswaNama.toLowerCase().contains(q) ||
          s.mahasiswaNim.contains(q);
    }).toList();
  }

  bool _isGradingComplete(NilaiModel? nilai, KelasModel kelas) {
    if (nilai == null) return false;
    // Cek komponen manual yang harus diisi jika bobotnya aktif (> 0)
    if (kelas.bobotUTS > 0 && nilai.nilaiUTS == 0) return false;
    if (kelas.bobotUAS > 0 && nilai.nilaiUAS == 0) return false;
    if (kelas.bobotQuiz > 0 && nilai.nilaiQuiz == 0) return false;
    if (kelas.bobotLain > 0 && nilai.nilaiLain == 0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenDashboardProvider>();
    final kelas = provider.kelasList.firstWhere((k) => k.id == widget.kelas.id, orElse: () => widget.kelas);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${kelas.matakuliahNama} - Kelas ${kelas.namaKelas}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau NIM mahasiswa...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: _filteredStudents.isEmpty
                      ? const Center(
                          child: EmptyStateWidget(
                            icon: Icons.people_rounded,
                            title: 'Tidak Ada Mahasiswa',
                            description: 'Mahasiswa tidak ditemukan di kelas ini.',
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filteredStudents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final student = _filteredStudents[idx];
                            final nilaiIdx = _grades.indexWhere((n) => n.mahasiswaId == student.mahasiswaId);
                            final nilai = nilaiIdx != -1 ? _grades[nilaiIdx] : null;
                            final isComplete = _isGradingComplete(nilai, kelas);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary.withOpacity(0.08),
                                    child: const Icon(Icons.person_rounded, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.mahasiswaNama,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          'NIM. ${student.mahasiswaNim}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isComplete ? Colors.green : Colors.amber).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isComplete ? 'Lengkap' : 'Belum Lengkap',
                                                style: TextStyle(
                                                  color: isComplete ? Colors.green : Colors.amber[800],
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (nilai != null && nilai.isOverridden) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Override',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ]
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Nilai Akhir', style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                                      Text(
                                        nilai != null ? nilai.nilaiAkhir.toStringAsFixed(1) : '-',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: nilai != null ? AppColors.primary : AppColors.textDisabled,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DosenStudentGradingDetailPage(
                                            kelas: kelas,
                                            student: student,
                                            initialNilai: nilai,
                                          ),
                                        ),
                                      ).then((_) => _loadData());
                                    },
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
}

// ─────────────────────────────────────────────────────────────
// DETAIL INPUT PENILAIAN MAHASISWA
// ─────────────────────────────────────────────────────────────
class DosenStudentGradingDetailPage extends StatefulWidget {
  final KelasModel kelas;
  final ClassEnrollmentModel student;
  final NilaiModel? initialNilai;

  const DosenStudentGradingDetailPage({
    super.key,
    required this.kelas,
    required this.student,
    required this.initialNilai,
  });

  @override
  State<DosenStudentGradingDetailPage> createState() => _DosenStudentGradingDetailPageState();
}

class _DosenStudentGradingDetailPageState extends State<DosenStudentGradingDetailPage> {
  bool _isLoading = true;

  // Nilai otomatis (Sistem)
  double _nilaiAbsensi = 0.0;
  double _nilaiTugas = 0.0;
  double _nilaiPraktikum = 0.0;
  double _nilaiLaporan = 0.0;

  // Controllers untuk input manual
  final _utsController = TextEditingController(text: '0');
  final _uasController = TextEditingController(text: '0');
  final _quizController = TextEditingController(text: '0');
  final _lainController = TextEditingController(text: '0');

  // Override State
  bool _isOverridden = false;
  final _overrideController = TextEditingController(text: '0');
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAutomaticGrades();
  }

  @override
  void dispose() {
    _utsController.dispose();
    _uasController.dispose();
    _quizController.dispose();
    _lainController.dispose();
    _overrideController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadAutomaticGrades() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<DosenDashboardProvider>();
      
      // 1. Hitung Absensi otomatis
      _nilaiAbsensi = await provider.calculateAttendancePercentage(
        widget.student.mahasiswaId,
        widget.kelas.id,
      );

      // 2. Hitung Tugas, Laporan (LP), Praktikum (TP) otomatis
      final autos = await provider.calculateAutomaticGrades(
        studentId: widget.student.mahasiswaId,
        kelasId: widget.kelas.id,
      );

      _nilaiTugas = autos['tugas'] ?? 0.0;
      _nilaiLaporan = autos['laporan'] ?? 0.0;
      _nilaiPraktikum = autos['praktikum'] ?? 0.0;

      // 3. Set initial manual values
      if (widget.initialNilai != null) {
        final n = widget.initialNilai!;
        _utsController.text = n.nilaiUTS.toString();
        _uasController.text = n.nilaiUAS.toString();
        _quizController.text = n.nilaiQuiz.toString();
        _lainController.text = n.nilaiLain.toString();
        _isOverridden = n.isOverridden;
        _overrideController.text = n.nilaiAkhir.toString();
        _reasonController.text = n.overrideReason;
      }
    } catch (e) {
      debugPrint('Error loading automatic grades: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculatedFinalGrade(KelasModel kelas) {
    double total = 0.0;
    
    // Hitung bobot komponen
    total += _nilaiAbsensi * (kelas.bobotAbsensi / 100.0);
    total += _nilaiTugas * (kelas.bobotTugas / 100.0);
    total += _nilaiLaporan * (kelas.bobotLaporan / 100.0);
    total += _nilaiPraktikum * (kelas.bobotPraktikum / 100.0);
    
    // Tambah nilai manual
    final uts = double.tryParse(_utsController.text) ?? 0.0;
    final uas = double.tryParse(_uasController.text) ?? 0.0;
    final quiz = double.tryParse(_quizController.text) ?? 0.0;
    final lain = double.tryParse(_lainController.text) ?? 0.0;

    total += uts * (kelas.bobotUTS / 100.0);
    total += uas * (kelas.bobotUAS / 100.0);
    total += quiz * (kelas.bobotQuiz / 100.0);
    total += lain * (kelas.bobotLain / 100.0);

    return total;
  }

  double _displayFinalGrade(KelasModel kelas) {
    if (_isOverridden) {
      return double.tryParse(_overrideController.text) ?? 0.0;
    }
    return _calculatedFinalGrade(kelas);
  }

  Future<void> _submitGrades(KelasModel kelas) async {
    final provider = context.read<DosenDashboardProvider>();
    final FirebaseFirestore db = FirebaseFirestore.instance;

    final uts = double.tryParse(_utsController.text) ?? 0.0;
    final uas = double.tryParse(_uasController.text) ?? 0.0;
    final quiz = double.tryParse(_quizController.text) ?? 0.0;
    final lain = double.tryParse(_lainController.text) ?? 0.0;

    if (_isOverridden && _reasonController.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Alasan penyesuaian (override) wajib diisi.');
      return;
    }

    final calculatedGrade = _calculatedFinalGrade(kelas);
    final finalGrade = _displayFinalGrade(kelas);
    final gradeLetter = NilaiModel.bobotFromNilai(finalGrade);
    final gradeBobot = NilaiModel.bobotFromHuruf(gradeLetter);

    // Cari ID untuk nilai, jika null buat doc baru
    final String docId = widget.initialNilai?.id ?? db.collection('nilai').doc().id;

    final updatedNilai = NilaiModel(
      id: docId,
      kelasId: kelas.id,
      matakuliahId: kelas.matakuliahId,
      matakuliahNama: kelas.matakuliahNama,
      matakuliahKode: kelas.matakuliahKode,
      sks: 3, // SKS default
      mahasiswaId: widget.student.mahasiswaId,
      semesterId: kelas.semesterId,
      semesterNama: kelas.semesterNama,
      nilaiTugas: _nilaiTugas,
      nilaiUTS: uts,
      nilaiUAS: uas,
      nilaiQuiz: quiz,
      nilaiPraktikum: _nilaiPraktikum,
      nilaiLaporan: _nilaiLaporan,
      nilaiLain: lain,
      nilaiAbsensi: _nilaiAbsensi,
      nilaiAkhir: finalGrade,
      huruf: gradeLetter,
      bobot: gradeBobot,
      isOverridden: _isOverridden,
      nilaiAkhirCalculated: calculatedGrade,
      overrideReason: _reasonController.text.trim(),
      mahasiswaNama: widget.student.mahasiswaNama,
      updatedAt: Timestamp.now(),
    );

    setState(() => _isLoading = true);

    final success = await provider.saveNilai(updatedNilai);

    if (success) {
      if (mounted) AppSnackbar.success(context, 'Nilai ${widget.student.mahasiswaNama} berhasil disimpan.');
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) AppSnackbar.error(context, 'Gagal menyimpan nilai mahasiswa.');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenDashboardProvider>();
    final kelas = provider.kelasList.firstWhere((k) => k.id == widget.kelas.id, orElse: () => widget.kelas);

    final finalGrade = _displayFinalGrade(kelas);
    final gradeLetter = NilaiModel.bobotFromNilai(finalGrade);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Input Nilai Mahasiswa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Info Mahasiswa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
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
                        child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.student.mahasiswaNama,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'NIM. ${widget.student.mahasiswaNim}  •  Kelas ${kelas.namaKelas}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── KOMPONEN OTOMATIS (SISTEM) ─────────────────────────
                Text(
                  'Komponen Otomatis (Sistem)',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                if (kelas.bobotAbsensi > 0)
                  _buildAutoGradeItem('Kehadiran/Absensi', _nilaiAbsensi, kelas.bobotAbsensi, Icons.calendar_today_rounded),
                if (kelas.bobotTugas > 0)
                  _buildAutoGradeItem('Rata-rata Tugas', _nilaiTugas, kelas.bobotTugas, Icons.assignment_rounded),
                if (kelas.bobotLaporan > 0)
                  _buildAutoGradeItem('Rata-rata Laporan LP', _nilaiLaporan, kelas.bobotLaporan, Icons.insert_drive_file_rounded),
                if (kelas.bobotPraktikum > 0)
                  _buildAutoGradeItem('Rata-rata Praktikum', _nilaiPraktikum, kelas.bobotPraktikum, Icons.computer_rounded),

                if (kelas.bobotAbsensi == 0 && kelas.bobotTugas == 0 && kelas.bobotLaporan == 0 && kelas.bobotPraktikum == 0)
                  const Text('Tidak ada komponen otomatis yang aktif.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),

                const SizedBox(height: 24),

                // ── KOMPONEN MANUAL ──────────────────────────────────
                Text(
                  'Komponen Manual (Dosen)',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                if (kelas.bobotUTS > 0)
                  _buildManualGradeItem('UTS (${kelas.bobotUTS}%)', _utsController),
                if (kelas.bobotUAS > 0)
                  _buildManualGradeItem('UAS (${kelas.bobotUAS}%)', _uasController),
                if (kelas.bobotQuiz > 0)
                  _buildManualGradeItem('Partisipasi (Keaktifan/Quiz) (${kelas.bobotQuiz}%)', _quizController),
                if (kelas.bobotLain > 0)
                  _buildManualGradeItem('Lainnya (${kelas.bobotLain}%)', _lainController),

                if (kelas.bobotUTS == 0 && kelas.bobotUAS == 0 && kelas.bobotQuiz == 0 && kelas.bobotLain == 0)
                  const Text('Tidak ada komponen manual yang aktif.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),

                const SizedBox(height: 24),

                // ── SUMMARY & OVERRIDE ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nilai Akhir Terhitung:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            _calculatedFinalGrade(kelas).toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Override switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sesuaikan Nilai Akhir (Override)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                          ),
                          Switch.adaptive(
                            value: _isOverridden,
                            onChanged: (val) {
                              setState(() {
                                _isOverridden = val;
                                if (val) {
                                  _overrideController.text = _calculatedFinalGrade(kelas).toStringAsFixed(1);
                                }
                              });
                            },
                          ),
                        ],
                      ),

                      if (_isOverridden) ...[
                        const SizedBox(height: 12),
                        const Text('Nilai Akhir Baru:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _overrideController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Contoh: 90.0',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Alasan Penyesuaian (Wajib):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _reasonController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Mahasiswa aktif bertanya dan hadir di seminar tambahan.',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],

                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nilai Akhir:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Row(
                            children: [
                              Text(
                                finalGrade.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    gradeLetter,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                AppButton(
                  label: 'Simpan Nilai Mahasiswa',
                  onPressed: () => _submitGrades(kelas),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildAutoGradeItem(String label, double value, int weight, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Bobot: $weight%  •  Otomatis Sistem', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildManualGradeItem(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
