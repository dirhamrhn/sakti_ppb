import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/kelas_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/pertemuan_model.dart';
import '../../models/absensi_model.dart';
import '../../models/class_enrollment_model.dart';
import '../../models/gedung_model.dart';
import '../../providers/asdos_dashboard_provider.dart';
import '../../providers/gedung_provider.dart';

class AsdosAbsensiBottomSheet extends StatefulWidget {
  final JadwalModel jadwal;

  const AsdosAbsensiBottomSheet({
    super.key,
    required this.jadwal,
  });

  @override
  State<AsdosAbsensiBottomSheet> createState() => _AsdosAbsensiBottomSheetState();
}

class _AsdosAbsensiBottomSheetState extends State<AsdosAbsensiBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late JadwalModel _currentJadwal;
  final TextEditingController _topikController = TextEditingController();
  final FocusNode _topikFocusNode = FocusNode();
  List<ClassEnrollmentModel> _enrollments = [];
  bool _isLoadingEnrollments = false;
  bool _isInitializingMeetings = false;

  @override
  void initState() {
    super.initState();
    _currentJadwal = widget.jadwal;
    _tabController = TabController(length: 2, vsync: this);
    _loadEnrollmentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topikController.dispose();
    _topikFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadEnrollmentData() async {
    setState(() => _isLoadingEnrollments = true);
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db
          .collection('class_enrollments')
          .where('kelasId', isEqualTo: _currentJadwal.kelasId)
          .get();

      _enrollments = snap.docs
          .map((d) => ClassEnrollmentModel.fromMap(d.id, d.data()))
          .toList();
      _enrollments.sort((a, b) => a.mahasiswaNama.toLowerCase().compareTo(b.mahasiswaNama.toLowerCase()));
    } catch (e) {
      debugPrint('Error loading enrollments: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingEnrollments = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // DIALOG PEMBUATAN / EDIT DATA KELAS
  // ─────────────────────────────────────────────────────────

  void _showUbahHariDialog(BuildContext context, AsdosDashboardProvider provider) {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    String selectedDay = _currentJadwal.hari;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Hari Kuliah'),
        content: DropdownButtonFormField<String>(
          value: selectedDay,
          decoration: const InputDecoration(labelText: 'Pilih Hari'),
          items: days
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (val) {
            if (val != null) selectedDay = val;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final updated = _currentJadwal.copyWith(hari: selectedDay);
              final success = await provider.updateJadwal(updated);
              if (success && mounted) {
                setState(() {
                  _currentJadwal = updated;
                });
                AppSnackbar.success(context, 'Hari praktikum berhasil diubah.');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showUbahJamDialog(BuildContext context, AsdosDashboardProvider provider) {
    TimeOfDay parseTime(String timeStr) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      return const TimeOfDay(hour: 8, minute: 0);
    }

    TimeOfDay start = parseTime(_currentJadwal.jamMulai);
    TimeOfDay end = parseTime(_currentJadwal.jamSelesai);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah Jam Praktikum'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Jam Mulai'),
                trailing: Text(
                  '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: start);
                  if (picked != null) {
                    setDialogState(() => start = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('Jam Selesai'),
                trailing: Text(
                  '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: end);
                  if (picked != null) {
                    setDialogState(() => end = picked);
                  }
                },
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
                Navigator.pop(context);
                final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                
                final updated = _currentJadwal.copyWith(
                  jamMulai: startStr,
                  jamSelesai: endStr,
                );
                final success = await provider.updateJadwal(updated);
                if (success && mounted) {
                  setState(() {
                    _currentJadwal = updated;
                  });
                  AppSnackbar.success(context, 'Waktu praktikum berhasil diubah.');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUbahMetodeDanLokasiDialog(BuildContext context, AsdosDashboardProvider provider) {
    final gProvider = context.read<GedungProvider>();
    gProvider.loadAllGedung();

    String currentType = _currentJadwal.lokasiType;
    GedungModel? selectedGedung;
    RuanganModel? selectedRuangan;
    String currentPlatform = _currentJadwal.platformMeet;
    final TextEditingController linkController = TextEditingController(text: _currentJadwal.linkMeet);
    final TextEditingController radiusController = TextEditingController(text: _currentJadwal.radiusAbsensi.toString());
    final TextEditingController toleransiController = TextEditingController(text: _currentJadwal.toleransiMenit.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (currentType == 'offline' && gProvider.gedungList.isNotEmpty && selectedGedung == null) {
            try {
              selectedGedung = gProvider.gedungList.firstWhere(
                (g) => g.nama == _currentJadwal.gedungNama,
              );
              gProvider.loadRuanganByGedung(selectedGedung!.id);
            } catch (_) {}
          }

          return AlertDialog(
            title: const Text('Ubah Lokasi, Radius, & Waktu'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: currentType,
                    decoration: const InputDecoration(labelText: 'Metode Pembelajaran'),
                    items: const [
                      DropdownMenuItem(value: 'offline', child: Text('Offline (Tatap Muka)')),
                      DropdownMenuItem(value: 'online', child: Text('Online (Daring)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          currentType = val;
                          selectedGedung = null;
                          selectedRuangan = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  if (currentType == 'offline') ...[
                    DropdownButtonFormField<GedungModel>(
                      value: selectedGedung,
                      decoration: const InputDecoration(labelText: 'Gedung Lab'),
                      items: gProvider.gedungList
                          .map((g) => DropdownMenuItem(value: g, child: Text(g.nama)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedGedung = val;
                            selectedRuangan = null;
                          });
                          gProvider.loadRuanganByGedung(val.id);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RuanganModel>(
                      value: selectedRuangan,
                      decoration: const InputDecoration(labelText: 'Ruangan Lab'),
                      items: gProvider.ruanganList
                          .map((r) => DropdownMenuItem(value: r, child: Text(r.namaRuangan)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRuangan = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: radiusController,
                      label: 'Radius Presensi (Meter)',
                      keyboardType: TextInputType.number,
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: currentPlatform,
                      decoration: const InputDecoration(labelText: 'Platform Video Conference'),
                      items: const [
                        DropdownMenuItem(value: 'meet', child: Text('Google Meet')),
                        DropdownMenuItem(value: 'zoom', child: Text('Zoom')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => currentPlatform = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: linkController,
                      label: 'Link Virtual Class',
                      hint: 'https://meet.google.com/abc-defg-hij',
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: toleransiController,
                    label: 'Toleransi Terlambat (Menit)',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  linkController.dispose();
                  radiusController.dispose();
                  toleransiController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  JadwalModel updated;
                  final radiusVal = int.tryParse(radiusController.text) ?? 50;
                  final toleransiVal = int.tryParse(toleransiController.text) ?? 15;

                  if (currentType == 'offline') {
                    final gdName = selectedGedung?.nama ?? _currentJadwal.gedungNama;
                    final ruName = selectedRuangan?.namaRuangan ?? _currentJadwal.ruanganNama;
                    final lat = selectedRuangan?.latitude ?? selectedGedung?.latitude ?? 0.0;
                    final lng = selectedRuangan?.longitude ?? selectedGedung?.longitude ?? 0.0;

                    updated = _currentJadwal.copyWith(
                      lokasiType: 'offline',
                      gedungNama: gdName,
                      ruanganNama: ruName,
                      latitude: lat,
                      longitude: lng,
                      linkMeet: '',
                      radiusAbsensi: radiusVal,
                      toleransiMenit: toleransiVal,
                    );
                  } else {
                    updated = _currentJadwal.copyWith(
                      lokasiType: 'online',
                      linkMeet: linkController.text,
                      platformMeet: currentPlatform,
                      gedungNama: '',
                      ruanganNama: '',
                      latitude: 0.0,
                      longitude: 0.0,
                      radiusAbsensi: 0,
                      toleransiMenit: toleransiVal,
                    );
                  }

                  linkController.dispose();
                  radiusController.dispose();
                  toleransiController.dispose();
                  
                  final success = await provider.updateJadwal(updated);
                  if (success && mounted) {
                    setState(() {
                      _currentJadwal = updated;
                    });
                    AppSnackbar.success(context, 'Konfigurasi praktikum berhasil diperbarui.');
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMembatalkanPerkuliahanDialog(BuildContext context, AsdosDashboardProvider provider) {
    final bool currentStatus = _currentJadwal.status;
    
    ConfirmDialog.show(
      context,
      title: currentStatus ? 'Batalkan Praktikum' : 'Aktifkan Praktikum',
      message: currentStatus 
          ? 'Apakah Anda yakin ingin membatalkan praktikum hari ini? Mahasiswa akan melihat status kelas "Dibatalkan".'
          : 'Apakah Anda yakin ingin mengaktifkan kembali praktikum hari ini?',
      confirmLabel: currentStatus ? 'Batalkan' : 'Aktifkan',
      isDanger: currentStatus,
      onConfirm: () async {
        final updated = _currentJadwal.copyWith(status: !currentStatus);
        final success = await provider.updateJadwal(updated);
        if (success && mounted) {
          setState(() {
            _currentJadwal = updated;
          });
          AppSnackbar.success(
            context, 
            currentStatus ? 'Praktikum hari ini telah dibatalkan.' : 'Praktikum diaktifkan kembali.',
          );
        }
      },
    );
  }

  void _showUbahStatusKelasDialog(BuildContext context, AsdosDashboardProvider provider) {
    // Allows setting status class directly into: Offline, Online, Dipindahkan, Dibatalkan
    // In our model/Firestore, if status is false -> Dibatalkan.
    // If we want to change lokasiType to offline -> Offline, online -> Online.
    // If we want to mark status as active but moved, we can modify the location/hari/jam.
    // Let's show a dialog to choose one:
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Status Praktikum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.room_rounded, color: AppColors.primary),
              title: const Text('Offline (Tatap Muka)'),
              onTap: () async {
                Navigator.pop(context);
                final updated = _currentJadwal.copyWith(lokasiType: 'offline', status: true);
                final success = await provider.updateJadwal(updated);
                if (success && mounted) {
                  setState(() {
                    _currentJadwal = updated;
                  });
                  AppSnackbar.success(context, 'Status kelas praktikum diubah ke Offline.');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: AppColors.success),
              title: const Text('Online (Daring)'),
              onTap: () async {
                Navigator.pop(context);
                final updated = _currentJadwal.copyWith(lokasiType: 'online', status: true);
                final success = await provider.updateJadwal(updated);
                if (success && mounted) {
                  setState(() {
                    _currentJadwal = updated;
                  });
                  AppSnackbar.success(context, 'Status kelas praktikum diubah ke Online.');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_rounded, color: AppColors.warning),
              title: const Text('Dipindahkan (Ganti Hari/Jam)'),
              onTap: () {
                Navigator.pop(context);
                _showUbahHariDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_rounded, color: AppColors.error),
              title: const Text('Batalkan Sesi'),
              onTap: () {
                Navigator.pop(context);
                _showMembatalkanPerkuliahanDialog(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // MANIPULASI ABSENSI MANUAL MAHASISWA
  // ─────────────────────────────────────────────────────────

  void _showValidasiAbsensiDialog(BuildContext context, AsdosDashboardProvider provider, PertemuanModel activeMeeting, AbsensiModel absensi) {
    String selectedStatus = absensi.status;
    final TextEditingController ketController = TextEditingController(text: absensi.keterangan);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Edit Kehadiran ${absensi.mahasiswaNama}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status Kehadiran'),
                items: const [
                  DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                  DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                  DropdownMenuItem(value: 'izin', child: Text('Izin')),
                  DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                  DropdownMenuItem(value: 'alpha', child: Text('Belum Absen (Alpha)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() {
                      selectedStatus = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: ketController,
                label: 'Keterangan',
                hint: 'Tulis alasan perubahan...',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ketController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                bool success = false;
                if (selectedStatus == 'alpha') {
                  success = await provider.deleteAbsensiRecord(absensi.id);
                } else {
                  success = await provider.updateAbsensiStatus(
                    absensi.id, 
                    selectedStatus, 
                    ketController.text.trim().isEmpty ? 'Ubah status oleh Asdos' : ketController.text,
                  );
                }

                // Recalculate student grades for attendance change
                final db = FirebaseFirestore.instance;
                final classDoc = await db.collection('kelas').doc(_currentJadwal.kelasId).get();
                if (classDoc.exists) {
                  final kelas = KelasModel.fromMap(classDoc.id, classDoc.data()!);
                  await provider.recalculateStudentGrades(
                    studentId: absensi.mahasiswaId,
                    studentNama: absensi.mahasiswaNama,
                    studentNim: absensi.mahasiswaNim,
                    kelas: kelas,
                  );
                }

                ketController.dispose();
                if (success && mounted) {
                  AppSnackbar.success(context, 'Kehadiran berhasil diperbarui.');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAbsensiManualDialog(BuildContext context, AsdosDashboardProvider provider, PertemuanModel activeMeeting, ClassEnrollmentModel enrollment) {
    String selectedStatus = 'hadir';
    final TextEditingController ketController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Absen Manual: ${enrollment.mahasiswaNama}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status Kehadiran'),
                items: const [
                  DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                  DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                  DropdownMenuItem(value: 'izin', child: Text('Izin')),
                  DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                  DropdownMenuItem(value: 'alpha', child: Text('Alfa (Tidak Hadir)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() {
                      selectedStatus = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: ketController,
                label: 'Keterangan',
                hint: 'Contoh: Absensi manual disetujui asdos',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ketController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final mTime = DateTime.now();
                final dateStr = '${mTime.year}-${mTime.month.toString().padLeft(2, '0')}-${mTime.day.toString().padLeft(2, '0')}';
                final timeStr = '${mTime.hour.toString().padLeft(2, '0')}:${mTime.minute.toString().padLeft(2, '0')}';

                final Map<String, dynamic> data = {
                  'mahasiswaId': enrollment.mahasiswaId,
                  'mahasiswaNama': enrollment.mahasiswaNama,
                  'mahasiswaNim': enrollment.mahasiswaNim,
                  'kelasId': _currentJadwal.kelasId,
                  'kelasNama': _currentJadwal.kelasNama,
                  'jadwalId': _currentJadwal.id,
                  'matakuliahId': _currentJadwal.matakuliahId,
                  'matakuliahNama': _currentJadwal.matakuliahNama,
                  'matakuliahKode': _currentJadwal.matakuliahKode,
                  'pertemuanKe': activeMeeting.pertemuanKe,
                  'pertemuanId': activeMeeting.id,
                  'jenisSesi': _currentJadwal.jenisSesi,
                  'tanggal': dateStr,
                  'jamAbsensi': timeStr,
                  'status': selectedStatus,
                  'keterangan': ketController.text.trim().isEmpty ? 'Absensi manual oleh Asdos' : ketController.text.trim(),
                  'isCheckedIn': true,
                  'latitude': 0.0,
                  'longitude': 0.0,
                  'jarak': 0.0,
                  'metodeAbsensi': 'manual',
                  'selfieUrl': '',
                };

                final success = await provider.addAbsensiManual(data);

                // Recalculate student grades
                final db = FirebaseFirestore.instance;
                final classDoc = await db.collection('kelas').doc(_currentJadwal.kelasId).get();
                if (classDoc.exists) {
                  final kelas = KelasModel.fromMap(classDoc.id, classDoc.data()!);
                  await provider.recalculateStudentGrades(
                    studentId: enrollment.mahasiswaId,
                    studentNama: enrollment.mahasiswaNama,
                    studentNim: enrollment.mahasiswaNim,
                    kelas: kelas,
                  );
                }

                ketController.dispose();
                if (success && mounted) {
                  AppSnackbar.success(context, 'Absensi manual berhasil disimpan.');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // UI BUILDERS
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AsdosDashboardProvider>();
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        height: (MediaQuery.of(context).size.height * 0.85) - viewInsets.bottom,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: AppColors.surface,
              width: double.infinity,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(icon: Icon(Icons.settings_rounded), text: 'Kelola Kelas'),
                  Tab(icon: Icon(Icons.people_rounded), text: 'Kehadiran Mahasiswa'),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('pertemuan')
                    .where('jadwalId', isEqualTo: _currentJadwal.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    if (_isInitializingMeetings) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Menginisialisasi sesi praktikum...',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }
                    return EmptyStateWidget(
                      icon: Icons.event_busy_rounded,
                      title: 'Pertemuan Belum Di-generate',
                      description: 'Pertemuan praktikum (8 pertemuan) untuk jadwal ini belum diinisialisasi.',
                      actionLabel: 'Generate 8 Pertemuan',
                      onAction: () async {
                        setState(() {
                          _isInitializingMeetings = true;
                        });
                        try {
                          final success = await provider.generateMeetingsForJadwal(_currentJadwal);
                          if (success) {
                            if (context.mounted) {
                              AppSnackbar.success(
                                context,
                                'Berhasil menginisialisasi 8 pertemuan praktikum.',
                              );
                            }
                          } else {
                            if (context.mounted) {
                              AppSnackbar.error(
                                context,
                                provider.errorMessage ?? 'Gagal menginisialisasi pertemuan.',
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackbar.error(context, 'Terjadi kesalahan: $e');
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isInitializingMeetings = false;
                            });
                          }
                        }
                      },
                    );
                  }

                  final rawList = snapshot.data!.docs
                      .map((d) => PertemuanModel.fromMap(d.id, d.data()))
                      .toList();

                  // Deduplicate by pertemuanKe to prevent duplicate meetings in UI
                  final List<PertemuanModel> listPertemuan = [];
                  final Set<int> seenPertemuanKe = {};
                  for (final p in rawList) {
                    if (!seenPertemuanKe.contains(p.pertemuanKe)) {
                      seenPertemuanKe.add(p.pertemuanKe);
                      listPertemuan.add(p);
                    }
                  }
                  listPertemuan.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));

                  PertemuanModel? activeMeeting;
                  PertemuanModel? nextBelumMeeting;

                  try {
                    activeMeeting = listPertemuan.firstWhere((p) => p.isAktif);
                    if (activeMeeting != null && !_topikFocusNode.hasFocus && _topikController.text != activeMeeting.topik) {
                      _topikController.text = activeMeeting.topik;
                    }
                  } catch (_) {}

                  try {
                    nextBelumMeeting = listPertemuan.firstWhere((p) => p.isBelum);
                  } catch (_) {}

                  final PertemuanModel currentHandlingMeeting = activeMeeting ?? 
                      nextBelumMeeting ?? 
                      listPertemuan.last;

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildKelolaKelasTab(context, provider, activeMeeting, nextBelumMeeting, currentHandlingMeeting),
                      _buildKehadiranTab(context, provider, currentHandlingMeeting, activeMeeting != null || currentHandlingMeeting.isSelesai),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildKelolaKelasTab(
    BuildContext context,
    AsdosDashboardProvider provider,
    PertemuanModel? activeMeeting,
    PertemuanModel? nextBelumMeeting,
    PertemuanModel currentMeeting,
  ) {
    String statusKelasText = 'Selesai';
    Color statusKelasColor = AppColors.info;
    if (!_currentJadwal.status) {
      statusKelasText = 'Dibatalkan';
      statusKelasColor = AppColors.error;
    } else if (activeMeeting != null) {
      statusKelasText = 'Berlangsung (Praktikum ${activeMeeting.pertemuanKe})';
      statusKelasColor = AppColors.success;
    } else if (nextBelumMeeting != null) {
      statusKelasText = 'Belum Dimulai (Praktikum ${nextBelumMeeting.pertemuanKe})';
      statusKelasColor = AppColors.warning;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Expanded(
                      child: Text(
                        _currentJadwal.matakuliahNama,
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusKelasColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusKelasColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusKelasText,
                        style: TextStyle(color: statusKelasColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.class_rounded, 'Kelas', 'Kelas ${_currentJadwal.kelasNama}  •  Praktikum'),
                _buildInfoRow(Icons.calendar_today_rounded, 'Waktu', '${_currentJadwal.hari}, ${_currentJadwal.jamMulai} - ${_currentJadwal.jamSelesai}'),
                _buildInfoRow(
                  _currentJadwal.isOnline ? Icons.videocam_rounded : Icons.room_rounded,
                  'Tempat',
                  _currentJadwal.isOnline 
                      ? 'Kelas Online (${_currentJadwal.platformMeet.toUpperCase()})' 
                      : '${_currentJadwal.gedungNama} - ${_currentJadwal.ruanganNama}',
                ),
                if (_currentJadwal.isOnline && _currentJadwal.linkMeet.isNotEmpty)
                  _buildInfoRow(Icons.link_rounded, 'Link Meet', _currentJadwal.linkMeet),
                if (!_currentJadwal.isOnline)
                  _buildInfoRow(Icons.radar_rounded, 'Radius Presensi', '${_currentJadwal.radiusAbsensi} Meter'),
                _buildInfoRow(Icons.access_time_filled_rounded, 'Toleransi Terlambat', '${_currentJadwal.toleransiMenit} Menit'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Kontrol Sesi Praktikum', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (!_currentJadwal.status)
            Card(
              color: AppColors.error.withOpacity(0.05),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.error.withOpacity(0.2)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sesi praktikum hari ini dibatalkan. Mahasiswa tidak dapat melakukan absensi.',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (activeMeeting != null) ...[
            AppTextField(
              controller: _topikController,
              focusNode: _topikFocusNode,
              label: 'Topik Pembahasan Praktikum',
              hint: 'Isi materi praktikum...',
              suffix: TextButton(
                onPressed: () async {
                  final text = _topikController.text.trim();
                  await FirebaseFirestore.instance
                      .collection('pertemuan')
                      .doc(activeMeeting.id)
                      .update({'topik': text});
                  if (context.mounted) {
                    AppSnackbar.success(context, 'Topik pembahasan berhasil disimpan.');
                  }
                },
                child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Selesaikan Praktikum & Tutup Absensi',
              onPressed: () => ConfirmDialog.show(
                context,
                title: 'Tutup Absensi Sesi',
                message: 'Apakah Anda yakin ingin menyelesaikan praktikum ke-${activeMeeting.pertemuanKe} dan menutup akses absensi mahasiswa?',
                confirmLabel: 'Selesaikan',
                onConfirm: () async {
                  final success = await provider.selesaikanPertemuan(activeMeeting.id);
                  if (success && mounted) {
                    AppSnackbar.success(context, 'Praktikum selesai dan absensi ditutup.');
                  }
                },
              ),
            ),
          ] else if (nextBelumMeeting != null) ...[
            AppTextField(
              controller: _topikController,
              label: 'Topik Praktikum',
              hint: 'Contoh: CRUD Database SQLite',
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Mulai Praktikum & Buka Absensi Pertemuan ${nextBelumMeeting.pertemuanKe}',
              onPressed: () async {
                final topik = _topikController.text.trim();
                final finalTopik = topik.isEmpty ? 'Praktikum Pertemuan ${nextBelumMeeting!.pertemuanKe}' : topik;
                
                final success = await provider.aktivasiPertemuan(nextBelumMeeting!.id, finalTopik);
                if (success && mounted) {
                  AppSnackbar.success(context, 'Absensi praktikum pertemuan ${nextBelumMeeting.pertemuanKe} dibuka!');
                  _topikController.clear();
                }
              },
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Seluruh 8 pertemuan praktikum kelas ini telah selesai dilaksanakan.', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          const SizedBox(height: 24),

          Text('Edit Konfigurasi Kelas', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildConfigCard(
                Icons.room_rounded,
                'Ubah Lokasi/Metode',
                () => _showUbahMetodeDanLokasiDialog(context, provider),
              ),
              _buildConfigCard(
                Icons.access_time_rounded,
                'Ubah Waktu/Jam',
                () => _showUbahJamDialog(context, provider),
              ),
              _buildConfigCard(
                Icons.settings_suggest_rounded,
                'Status Praktikum',
                () => _showUbahStatusKelasDialog(context, provider),
              ),
              _buildConfigCard(
                _currentJadwal.status ? Icons.cancel_rounded : Icons.check_circle_rounded,
                _currentJadwal.status ? 'Batalkan Sesi' : 'Aktifkan Sesi',
                () => _showMembatalkanPerkuliahanDialog(context, provider),
                color: _currentJadwal.status ? AppColors.error : AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKehadiranTab(
    BuildContext context,
    AsdosDashboardProvider provider,
    PertemuanModel currentMeeting,
    bool isSesiAktifAtauSelesai,
  ) {
    if (!isSesiAktifAtauSelesai) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: EmptyStateWidget(
            icon: Icons.lock_rounded,
            title: 'Kehadiran Belum Dibuka',
            description: 'Silakan mulai kelas terlebih dahulu di tab "Kelola Kelas" untuk membuka daftar monitoring absensi.',
          ),
        ),
      );
    }

    if (_isLoadingEnrollments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_enrollments.isEmpty) {
      return const Center(child: Text('Tidak ada mahasiswa terdaftar di kelas praktikum ini.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('absensi')
          .where('pertemuanId', isEqualTo: currentMeeting.id)
          .snapshots(),
      builder: (context, absensiSnapshot) {
        if (absensiSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final absensiDocs = absensiSnapshot.data?.docs ?? [];
        final Map<String, AbsensiModel> absensiMap = {
          for (var doc in absensiDocs)
            (doc.data())['mahasiswaId']: AbsensiModel.fromMap(doc.id, doc.data())
        };

        int totalEnrolled = _enrollments.length;
        int hadir = 0;
        int terlambat = 0;
        int izin = 0;
        int sakit = 0;

        for (final abs in absensiMap.values) {
          if (abs.status == 'hadir') hadir++;
          if (abs.status == 'terlambat') terlambat++;
          if (abs.status == 'izin') izin++;
          if (abs.status == 'sakit') sakit++;
        }
        int belumAbsen = totalEnrolled - (hadir + terlambat + izin + sakit);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatTile('Hadir', hadir, AppColors.success),
                  _buildStatTile('Terlambat', terlambat, AppColors.warning),
                  _buildStatTile('Izin/Sakit', izin + sakit, AppColors.info),
                  _buildStatTile('Belum', belumAbsen, Colors.grey),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _enrollments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final enrollment = _enrollments[index];
                  final absensi = absensiMap[enrollment.mahasiswaId];

                  return _MahasiswaAttendanceTile(
                    enrollment: enrollment,
                    absensi: absensi,
                    onEdit: () {
                      if (absensi != null) {
                        _showValidasiAbsensiDialog(context, provider, currentMeeting, absensi);
                      } else {
                        _showAddAbsensiManualDialog(context, provider, currentMeeting, enrollment);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatTile(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(icon, color: activeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MahasiswaAttendanceTile extends StatelessWidget {
  final ClassEnrollmentModel enrollment;
  final AbsensiModel? absensi;
  final VoidCallback onEdit;

  const _MahasiswaAttendanceTile({
    required this.enrollment,
    required this.absensi,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    String statusStr = 'Belum Absen';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline_rounded;

    if (absensi != null) {
      if (absensi!.status == 'hadir') {
        statusStr = 'Hadir';
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
      } else if (absensi!.status == 'terlambat') {
        statusStr = 'Terlambat';
        statusColor = AppColors.warning;
        statusIcon = Icons.watch_later_rounded;
      } else if (absensi!.status == 'izin') {
        statusStr = 'Izin';
        statusColor = Colors.blue;
        statusIcon = Icons.info_rounded;
      } else if (absensi!.status == 'sakit') {
        statusStr = 'Sakit';
        statusColor = Colors.orange;
        statusIcon = Icons.sick_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(statusIcon, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrollment.mahasiswaNama,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'NIM. ${enrollment.mahasiswaNim}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                if (absensi != null && absensi!.jamAbsensi.isNotEmpty)
                  Text(
                    'Absen jam ${absensi!.jamAbsensi} (${absensi!.metodeAbsensi.toUpperCase()})',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(
              absensi == null ? 'Absen Manual' : 'Ubah Status',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
