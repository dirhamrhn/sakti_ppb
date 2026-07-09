import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/jadwal_model.dart';
import '../../../models/pertemuan_model.dart';
import '../../../models/absensi_model.dart';
import '../../../models/class_enrollment_model.dart';
import '../../../models/gedung_model.dart';
import '../../../providers/dosen_dashboard_provider.dart';
import '../../../providers/gedung_provider.dart';

class DosenAbsensiBottomSheet extends StatefulWidget {
  final JadwalModel jadwal;

  const DosenAbsensiBottomSheet({
    super.key,
    required this.jadwal,
  });

  @override
  State<DosenAbsensiBottomSheet> createState() => _DosenAbsensiBottomSheetState();
}

class _DosenAbsensiBottomSheetState extends State<DosenAbsensiBottomSheet> with SingleTickerProviderStateMixin {
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
      final provider = context.read<DosenDashboardProvider>();
      _enrollments = await provider.getEnrollments(_currentJadwal.kelasId);
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

  void _showUbahHariDialog(BuildContext context, DosenDashboardProvider provider) {
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
                AppSnackbar.success(context, 'Hari perkuliahan berhasil diubah.');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showUbahJamDialog(BuildContext context, DosenDashboardProvider provider) {
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
          title: const Text('Ubah Jam Kuliah'),
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
                  AppSnackbar.success(context, 'Waktu perkuliahan berhasil diubah.');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUbahMetodeDanLokasiDialog(BuildContext context, DosenDashboardProvider provider) {
    final gProvider = context.read<GedungProvider>();
    gProvider.loadAllGedung();

    String currentType = _currentJadwal.lokasiType; // 'offline' atau 'online'
    GedungModel? selectedGedung;
    RuanganModel? selectedRuangan;
    String currentPlatform = _currentJadwal.platformMeet; // 'meet' atau 'zoom'
    final TextEditingController linkController = TextEditingController(text: _currentJadwal.linkMeet);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Cari gedung yang sesuai saat inisialisasi jika tipe offline
          if (currentType == 'offline' && gProvider.gedungList.isNotEmpty && selectedGedung == null) {
            try {
              selectedGedung = gProvider.gedungList.firstWhere(
                (g) => g.nama == _currentJadwal.gedungNama,
              );
              gProvider.loadRuanganByGedung(selectedGedung!.id);
            } catch (_) {}
          }

          return AlertDialog(
            title: const Text('Ubah Metode & Lokasi'),
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
                  const SizedBox(height: 16),

                  if (currentType == 'offline') ...[
                    DropdownButtonFormField<GedungModel>(
                      value: selectedGedung,
                      decoration: const InputDecoration(labelText: 'Gedung'),
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RuanganModel>(
                      value: selectedRuangan,
                      decoration: const InputDecoration(labelText: 'Ruangan'),
                      items: gProvider.ruanganList
                          .map((r) => DropdownMenuItem(value: r, child: Text(r.namaRuangan)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRuangan = val);
                        }
                      },
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
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: linkController,
                      label: 'Link Virtual Class',
                      hint: 'https://meet.google.com/abc-defg-hij',
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  linkController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  JadwalModel updated;
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
                    );
                  }

                  linkController.dispose();
                  final success = await provider.updateJadwal(updated);
                  if (success && mounted) {
                    setState(() {
                      _currentJadwal = updated;
                    });
                    AppSnackbar.success(context, 'Lokasi/Metode perkuliahan berhasil diperbarui.');
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

  void _showMembatalkanPerkuliahanDialog(BuildContext context, DosenDashboardProvider provider) {
    final bool currentStatus = _currentJadwal.status;
    
    ConfirmDialog.show(
      context,
      title: currentStatus ? 'Batalkan Perkuliahan' : 'Aktifkan Perkuliahan',
      message: currentStatus 
          ? 'Apakah Anda yakin ingin membatalkan perkuliahan hari ini? Mahasiswa akan melihat status kelas "Dibatalkan".'
          : 'Apakah Anda yakin ingin mengaktifkan kembali perkuliahan hari ini?',
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
            currentStatus ? 'Perkuliahan hari ini telah dibatalkan.' : 'Perkuliahan diaktifkan kembali.',
          );
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // MANIPULASI ABSENSI MANUAL MAHASISWA
  // ─────────────────────────────────────────────────────────

  void _showValidasiAbsensiDialog(BuildContext context, DosenDashboardProvider provider, PertemuanModel activeMeeting, AbsensiModel absensi) {
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
                  // Hapus entry agar status kembali ke belum absen
                  success = await provider.deleteAbsensiRecord(absensi.id);
                } else {
                  success = await provider.updateAbsensiStatus(
                    absensi.id, 
                    selectedStatus, 
                    ketController.text.trim().isEmpty ? 'Ubah status oleh Dosen' : ketController.text,
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

  void _showAddAbsensiManualDialog(BuildContext context, DosenDashboardProvider provider, PertemuanModel activeMeeting, ClassEnrollmentModel enrollment) {
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
                hint: 'Contoh: Absensi manual disetujui dosen',
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
                  'keterangan': ketController.text.trim().isEmpty ? 'Absensi manual oleh Dosen' : ketController.text.trim(),
                  'isCheckedIn': true,
                  'latitude': 0.0,
                  'longitude': 0.0,
                  'jarak': 0.0,
                  'metodeAbsensi': 'manual',
                  'selfieUrl': '',
                };

                final success = await provider.addAbsensiManual(data);
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
    final provider = context.watch<DosenDashboardProvider>();
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
            // Top Drag Indicator
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

            // Tab Bar
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

            // Realtime Pertemuan Stream
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
                              'Menginisialisasi sesi pertemuan...',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }
                    return EmptyStateWidget(
                      icon: Icons.event_busy_rounded,
                      title: 'Data Pertemuan Kosong',
                      description: 'Pertemuan untuk jadwal ini belum diinisialisasi.',
                      actionLabel: 'Inisialisasi Pertemuan',
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
                                'Berhasil menginisialisasi ${_currentJadwal.totalPertemuan} pertemuan.',
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

                  final listPertemuan = snapshot.data!.docs
                      .map((d) => PertemuanModel.fromMap(d.id, d.data()))
                      .toList();
                  listPertemuan.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));

                  // Identifikasi pertemuan aktif atau belum dimulai
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

                  // Tentukan pertemuan apa yang sedang ditangani saat ini
                  final PertemuanModel currentHandlingMeeting = activeMeeting ?? 
                      nextBelumMeeting ?? 
                      listPertemuan.last; // Fallback ke pertemuan terakhir jika sudah selesai semua

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: KELOLA KELAS
                      _buildKelolaKelasTab(context, provider, activeMeeting, nextBelumMeeting, currentHandlingMeeting),

                      // TAB 2: MONITORING KEHADIRAN MAHASISWA
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
    DosenDashboardProvider provider,
    PertemuanModel? activeMeeting,
    PertemuanModel? nextBelumMeeting,
    PertemuanModel currentMeeting,
  ) {
    final typeLabel = _currentJadwal.jenisSesi == 'praktikum' ? 'Praktikum' : 'Teori';
    
    // Status perkuliahan saat ini
    String statusKelasText = 'Selesai';
    Color statusKelasColor = AppColors.info;
    if (!_currentJadwal.status) {
      statusKelasText = 'Dibatalkan';
      statusKelasColor = AppColors.error;
    } else if (activeMeeting != null) {
      statusKelasText = 'Berlangsung (Pertemuan ${activeMeeting.pertemuanKe})';
      statusKelasColor = AppColors.success;
    } else if (nextBelumMeeting != null) {
      statusKelasText = 'Belum Dimulai (Pertemuan ${nextBelumMeeting.pertemuanKe})';
      statusKelasColor = AppColors.warning;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ringkasan Info Kelas Card
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
                _buildInfoRow(Icons.class_rounded, 'Kelas', 'Kelas ${_currentJadwal.kelasNama}  •  $typeLabel'),
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
              ],
            ),
          ),
          const SizedBox(height: 24),

          // AKSI KONTROL PERKULIAHAN
          Text('Kontrol Perkuliahan', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
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
                        'Perkuliahan hari ini dibatalkan. Mahasiswa tidak dapat melakukan absensi.',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (activeMeeting != null) ...[
            // Tampilkan kontrol tutup absensi jika ada pertemuan aktif
            AppTextField(
              controller: _topikController,
              focusNode: _topikFocusNode,
              label: 'Topik Pembahasan Kelas',
              hint: 'Isi materi yang dibahas...',
              suffix: TextButton(
                onPressed: () async {
                  final text = _topikController.text.trim();
                  await FirebaseFirestore.instance
                      .collection('pertemuan')
                      .doc(activeMeeting!.id)
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
              label: 'Selesaikan Pertemuan & Tutup Absensi',
              onPressed: () => ConfirmDialog.show(
                context,
                title: 'Tutup Absensi',
                message: 'Apakah Anda yakin ingin menyelesaikan pertemuan ke-${activeMeeting!.pertemuanKe} dan menutup akses absensi mahasiswa?',
                confirmLabel: 'Selesaikan',
                onConfirm: () async {
                  final success = await provider.selesaikanPertemuan(activeMeeting!.id);
                  if (success && mounted) {
                    AppSnackbar.success(context, 'Pertemuan selesai dan absensi ditutup.');
                  }
                },
              ),
            ),
          ] else if (nextBelumMeeting != null) ...[
            // Tampilkan tombol buka absensi untuk pertemuan berikutnya
            AppTextField(
              controller: _topikController,
              label: 'Topik Pembahasan',
              hint: 'Contoh: Pengenalan Flutter & Dart',
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Mulai Kelas & Buka Absensi Pertemuan ${nextBelumMeeting.pertemuanKe}',
              onPressed: () async {
                final topik = _topikController.text.trim();
                final finalTopik = topik.isEmpty ? 'Pertemuan ${nextBelumMeeting!.pertemuanKe}' : topik;
                
                final success = await provider.aktivasiPertemuan(nextBelumMeeting!.id, finalTopik);
                if (success && mounted) {
                  AppSnackbar.success(context, 'Absensi pertemuan ${nextBelumMeeting.pertemuanKe} dibuka!');
                  _topikController.clear();
                }
              },
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Semua 16 pertemuan untuk kelas ini telah selesai dilaksanakan.', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // KELOLA JADWAL & RUANGAN (EDIT CONFIG)
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
                Icons.calendar_view_day_rounded,
                'Pindahkan Hari',
                () => _showUbahHariDialog(context, provider),
              ),
              _buildConfigCard(
                _currentJadwal.status ? Icons.cancel_rounded : Icons.check_circle_rounded,
                _currentJadwal.status ? 'Batalkan Kelas' : 'Aktifkan Kelas',
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
    DosenDashboardProvider provider,
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
      return const Center(child: Text('Tidak ada mahasiswa terdaftar di kelas ini.'));
    }

    // Stream absensi realtime
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: provider.getAbsensiStream(currentMeeting.id),
      builder: (context, absensiSnapshot) {
        if (absensiSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final absensiDocs = absensiSnapshot.data?.docs ?? [];
        final Map<String, AbsensiModel> absensiMap = {
          for (var doc in absensiDocs)
            (doc.data())['mahasiswaId']: AbsensiModel.fromMap(doc.id, doc.data())
        };

        // Hitung statistik
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
            // Statistik Bar
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

            // Daftar Mahasiswa
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
                  style: TextStyle(
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
    String statusText = 'Belum Absen';
    Color statusColor = Colors.grey;

    if (absensi != null) {
      switch (absensi!.status) {
        case 'hadir':
          statusText = 'Hadir';
          statusColor = AppColors.success;
          break;
        case 'terlambat':
          statusText = 'Terlambat';
          statusColor = AppColors.warning;
          break;
        case 'izin':
          statusText = 'Izin';
          statusColor = AppColors.info;
          break;
        case 'sakit':
          statusText = 'Sakit';
          statusColor = Colors.amber;
          break;
        case 'alpha':
          statusText = 'Alpha';
          statusColor = AppColors.error;
          break;
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
          // Avatar
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.08),
            child: Text(
              enrollment.mahasiswaNama.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),

          // Detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrollment.mahasiswaNama,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  enrollment.mahasiswaNim,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                if (absensi != null && absensi!.isCheckedIn) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${absensi!.jamAbsensi}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        absensi!.metodeAbsensi == 'gps'
                            ? Icons.location_on_rounded
                            : (absensi!.metodeAbsensi == 'qrcode' ? Icons.qr_code_2_rounded : Icons.edit_note_rounded),
                        size: 10,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        absensi!.metodeAbsensi == 'gps' 
                            ? 'GPS (${absensi!.jarak.toStringAsFixed(1)}m)'
                            : (absensi!.metodeAbsensi == 'qrcode' ? 'QR Code' : 'Manual'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status Badge + Edit button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(absensi != null ? Icons.edit_rounded : Icons.add_rounded, size: 10, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Text(
                        absensi != null ? 'Edit' : 'Absen',
                        style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
