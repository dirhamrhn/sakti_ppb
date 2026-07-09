import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/jadwal_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class MahasiswaAbsensiPage extends StatefulWidget {
  const MahasiswaAbsensiPage({super.key});

  @override
  State<MahasiswaAbsensiPage> createState() => _MahasiswaAbsensiPageState();
}

class _MahasiswaAbsensiPageState extends State<MahasiswaAbsensiPage> {
  JadwalModel? _selectedJadwal;
  bool _isAutoOpenInitialized = false;

  // Validation & Submission State
  bool _isValidating = false;
  bool _isSubmitting = false;
  Position? _currentPosition;
  double? _distance;

  bool _isCheckedLocation = false;
  bool _isLocationValid = false;
  bool _isTimeValid = false;
  bool _hasCheckedInBefore = false;
  bool _isMeetingActive = false;

  String _locationFeedback = 'Belum diperiksa';
  String _timeFeedback = 'Belum diperiksa';
  String _meetingFeedback = 'Memeriksa status kelas...';

  DocumentSnapshot? _activeMeetingDoc;
  int _pertemuanKe = 1;

  DateTime getMakassarTime() {
    return DateTime.now();
  }

  String getMakassarDayName(DateTime dateTime) {
    const hariMap = {
      DateTime.monday: 'Senin',
      DateTime.tuesday: 'Selasa',
      DateTime.wednesday: 'Rabu',
      DateTime.thursday: 'Kamis',
      DateTime.friday: 'Jumat',
      DateTime.saturday: 'Sabtu',
      DateTime.sunday: 'Minggu',
    };
    return hariMap[dateTime.weekday] ?? '';
  }

  bool _isOngoing(JadwalModel jadwal) {
    final mTime = getMakassarTime();
    
    final startParts = jadwal.jamMulai.split(':');
    final endParts = jadwal.jamSelesai.split(':');
    if (startParts.length < 2 || endParts.length < 2) return false;

    final startTime = DateTime(
      mTime.year, mTime.month, mTime.day,
      int.parse(startParts[0]), int.parse(startParts[1]),
    );
    final endTime = DateTime(
      mTime.year, mTime.month, mTime.day,
      int.parse(endParts[0]), int.parse(endParts[1]),
    );

    return !mTime.isBefore(startTime) && !mTime.isAfter(endTime);
  }

  JadwalModel? _getActiveSchedule(List<JadwalModel> schedules) {
    for (final jadwal in schedules) {
      if (_isOngoing(jadwal)) {
        return jadwal;
      }
    }
    return null;
  }

  void _selectJadwal(JadwalModel jadwal) {
    setState(() {
      _selectedJadwal = jadwal;
      _isValidating = false;
      _isSubmitting = false;
      _currentPosition = null;
      _distance = null;

      // Auto-validate location if class is online or location is not mandatory
      if (jadwal.isOnline) {
        _isCheckedLocation = true;
        _isLocationValid = true;
        _locationFeedback = 'Online Class (Lokasi Sesuai)';
      } else if (!jadwal.lokasiWajib) {
        _isCheckedLocation = true;
        _isLocationValid = true;
        _locationFeedback = 'Lokasi tidak wajib';
      } else {
        _isCheckedLocation = false;
        _isLocationValid = false;
        _locationFeedback = 'Belum diperiksa';
      }

      _isTimeValid = false;
      _hasCheckedInBefore = false;
      _isMeetingActive = false;
      _timeFeedback = 'Belum diperiksa';
      _meetingFeedback = 'Memeriksa status kelas...';
      _activeMeetingDoc = null;
      _pertemuanKe = 1;
    });
    _checkMeetingStatus(jadwal);
  }

  Future<void> _checkMeetingStatus(JadwalModel jadwal) async {
    setState(() {
      _meetingFeedback = 'Menghubungkan ke server...';
    });

    try {
      if (!jadwal.status) {
        setState(() {
          _isMeetingActive = false;
          _meetingFeedback = 'Perkuliahan hari ini dibatalkan oleh Dosen.';
        });
        return;
      }

      final mTime = getMakassarTime();

      // 1. Time Check
      final startParts = jadwal.jamMulai.split(':');
      final endParts = jadwal.jamSelesai.split(':');

      if (startParts.length < 2 || endParts.length < 2) {
        setState(() {
          _isTimeValid = false;
          _timeFeedback = 'Format jam jadwal salah.';
        });
        return;
      }

      final startTime = DateTime(
        mTime.year, mTime.month, mTime.day,
        int.parse(startParts[0]), int.parse(startParts[1]),
      );
      final endTime = DateTime(
        mTime.year, mTime.month, mTime.day,
        int.parse(endParts[0]), int.parse(endParts[1]),
      );

      final isWithinScheduledHours = !mTime.isBefore(startTime) && !mTime.isAfter(endTime);

      if (!isWithinScheduledHours) {
        setState(() {
          _isTimeValid = false;
          _timeFeedback = 'Di luar jam perkuliahan (${jadwal.jamMulai} - ${jadwal.jamSelesai})';
        });
      } else {
        setState(() {
          _isTimeValid = true;
          _timeFeedback = 'Sesuai jadwal';
        });
      }

      // 2. Query active meeting in collection 'pertemuan'
      final meetingQuery = await FirebaseFirestore.instance
          .collection('pertemuan')
          .where('jadwalId', isEqualTo: jadwal.id)
          .where('status', isEqualTo: 'aktif')
          .limit(1)
          .get();

      if (meetingQuery.docs.isEmpty) {
        setState(() {
          _isMeetingActive = false;
          _meetingFeedback = 'Absensi belum dibuka oleh Dosen/Asdos.';
        });
        return;
      }

      final meetingDoc = meetingQuery.docs.first;
      _activeMeetingDoc = meetingDoc;
      _pertemuanKe = (meetingDoc.data())['pertemuanKe'] ?? 1;

      // 3. Query check if already submitted attendance for this meeting
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final absensiQuery = await FirebaseFirestore.instance
          .collection('absensi')
          .where('mahasiswaId', isEqualTo: uid)
          .where('pertemuanId', isEqualTo: meetingDoc.id)
          .limit(1)
          .get();

      if (absensiQuery.docs.isNotEmpty) {
        setState(() {
          _hasCheckedInBefore = true;
          _isMeetingActive = true;
          _meetingFeedback = 'Anda sudah melakukan absensi pada pertemuan $_pertemuanKe.';
        });
      } else {
        setState(() {
          _hasCheckedInBefore = false;
          _isMeetingActive = true;
          _meetingFeedback = 'Pertemuan $_pertemuanKe Aktif (Absensi Terbuka)';
        });
      }
    } catch (e) {
      setState(() {
        _meetingFeedback = 'Gagal memuat status pertemuan: $e';
      });
    }
  }

  Future<void> _checkLocation() async {
    final jadwal = _selectedJadwal;
    if (jadwal == null) return;

    setState(() {
      _isValidating = true;
      _locationFeedback = 'Mengambil GPS...';
    });

    try {
      // 1. Geolocator services and permission checks
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isValidating = false;
          _isCheckedLocation = true;
          _isLocationValid = !jadwal.lokasiWajib;
          _locationFeedback = 'Layanan lokasi dinonaktifkan.${!jadwal.lokasiWajib ? ' (Presensi diizinkan)' : ''}';
        });
        if (mounted) {
          if (!jadwal.lokasiWajib) {
            AppSnackbar.success(context, 'Silakan aktifkan GPS Anda. (Presensi tetap diizinkan)');
          } else {
            AppSnackbar.error(context, 'Silakan aktifkan GPS Anda.');
          }
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isValidating = false;
            _isCheckedLocation = true;
            _isLocationValid = !jadwal.lokasiWajib;
            _locationFeedback = 'Izin lokasi ditolak.${!jadwal.lokasiWajib ? ' (Presensi diizinkan)' : ''}';
          });
          if (mounted) {
            if (!jadwal.lokasiWajib) {
              AppSnackbar.success(context, 'Izin GPS ditolak. (Presensi tetap diizinkan)');
            } else {
              AppSnackbar.error(context, 'Izin GPS ditolak.');
            }
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isValidating = false;
          _isCheckedLocation = true;
          _isLocationValid = !jadwal.lokasiWajib;
          _locationFeedback = 'Izin lokasi ditolak permanen.${!jadwal.lokasiWajib ? ' (Presensi diizinkan)' : ''}';
        });
        if (mounted) {
          if (!jadwal.lokasiWajib) {
            AppSnackbar.success(context, 'Izin GPS ditolak permanen. (Presensi tetap diizinkan)');
          } else {
            AppSnackbar.error(context, 'Izin GPS ditolak secara permanen. Ubah di Pengaturan.');
          }
        }
        return;
      }

      // 2. Fetch coordinate
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Distance calculation
      final classLat = jadwal.latitude;
      final classLng = jadwal.longitude;

      if (classLat == 0.0 && classLng == 0.0) {
        if (jadwal.isOnline) {
          setState(() {
            _currentPosition = position;
            _distance = 0.0;
            _isValidating = false;
            _isCheckedLocation = true;
            _isLocationValid = true;
            _locationFeedback = 'Online Class (Lokasi Sesuai)';
          });
          return;
        } else {
          setState(() {
            _currentPosition = position;
            _distance = 0.0;
            _isValidating = false;
            _isCheckedLocation = true;
            _isLocationValid = !jadwal.lokasiWajib;
            _locationFeedback = jadwal.lokasiWajib
                ? 'Lokasi kelas belum dikonfigurasi Admin.'
                : 'Lokasi kelas belum dikonfigurasi Admin (Presensi diizinkan)';
          });
          return;
        }
      }

      final distance = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        classLat, classLng,
      );

      final isWithin = distance <= jadwal.radiusAbsensi;
      final isValid = !jadwal.lokasiWajib || isWithin;

      setState(() {
        _currentPosition = position;
        _distance = distance;
        _isValidating = false;
        _isCheckedLocation = true;
        _isLocationValid = isValid;
        if (isWithin) {
          _locationFeedback = 'Lokasi Sesuai';
        } else {
          _locationFeedback = 'Jarak terlalu jauh (${distance.toStringAsFixed(1)} m > ${jadwal.radiusAbsensi} m)${!jadwal.lokasiWajib ? ' (Presensi diizinkan)' : ''}';
        }
      });

      if (mounted) {
        if (isWithin) {
          AppSnackbar.success(context, 'Lokasi sesuai! Jarak: ${distance.toStringAsFixed(1)} m');
        } else {
          if (!jadwal.lokasiWajib) {
            AppSnackbar.success(context, 'Lokasi di luar radius! Jarak: ${distance.toStringAsFixed(1)} m (Presensi tetap diizinkan)');
          } else {
            AppSnackbar.error(context, 'Lokasi di luar radius! Jarak: ${distance.toStringAsFixed(1)} m');
          }
        }
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _isCheckedLocation = true;
        _isLocationValid = !jadwal.lokasiWajib;
        _locationFeedback = 'Gagal memeriksa lokasi: $e${!jadwal.lokasiWajib ? ' (Presensi diizinkan)' : ''}';
      });
      if (mounted) {
        if (!jadwal.lokasiWajib) {
          AppSnackbar.success(context, 'Gagal mengambil GPS: $e (Presensi tetap diizinkan)');
        } else {
          AppSnackbar.error(context, 'Gagal mengambil GPS: $e');
        }
      }
    }
  }

  Future<void> _submitAbsensi(AuthProvider auth, MahasiswaDashboardProvider dashboardProvider) async {
    final user = auth.user;
    final jadwal = _selectedJadwal;
    if (user == null || _activeMeetingDoc == null || jadwal == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final mTime = getMakassarTime();

      // Calculate attendance status
      final startParts = jadwal.jamMulai.split(':');
      final startTime = DateTime(
        mTime.year, mTime.month, mTime.day,
        int.parse(startParts[0]), int.parse(startParts[1]),
      );
      final lateLimitTime = startTime.add(Duration(minutes: jadwal.toleransiMenit));

      // status: 'hadir' or 'terlambat'
      final status = mTime.isAfter(lateLimitTime) ? 'terlambat' : 'hadir';

      final tanggalStr = DateFormat('yyyy-MM-dd').format(mTime);
      final jamStr = DateFormat('HH:mm').format(mTime);

      final absensiData = {
        'mahasiswaId': user.uid,
        'mahasiswaNama': user.nama,
        'mahasiswaNim': user.nomorInduk,
        'kelasId': jadwal.kelasId,
        'kelasNama': jadwal.kelasNama,
        'jadwalId': jadwal.id,
        'matakuliahId': jadwal.matakuliahId,
        'matakuliahNama': jadwal.matakuliahNama,
        'matakuliahKode': jadwal.matakuliahKode,
        'pertemuanKe': _pertemuanKe,
        'pertemuanId': _activeMeetingDoc!.id,
        'jenisSesi': jadwal.jenisSesi,
        'tanggal': tanggalStr,
        'jamAbsensi': jamStr,
        'status': status,
        'keterangan': 'Absensi mandiri via GPS',
        'isCheckedIn': true,
        'checkedInAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'latitude': _currentPosition?.latitude ?? 0.0,
        'longitude': _currentPosition?.longitude ?? 0.0,
        'jarak': _distance ?? 0.0,
        'metodeAbsensi': 'gps',
        'selfieUrl': '',
      };

      await FirebaseFirestore.instance
          .collection('absensi')
          .add(absensiData);

      // Force-refresh provider data
      await dashboardProvider.loadAll();

      if (mounted) {
        AppSnackbar.success(
          context, 
          'Presensi berhasil disimpan! Status: ${status == 'hadir' ? 'Hadir' : 'Terlambat'}',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal menyimpan presensi: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaDashboardProvider>();

    // We filter using Makassar day of week
    final mTime = getMakassarTime();
    final hariIni = getMakassarDayName(mTime);
    final todaySchedules = provider.jadwalList
        .where((j) => j.hari == hariIni)
        .toList();

    // Auto-detect active schedule and select it
    if (provider.isInitialized && !provider.isLoading && todaySchedules.isNotEmpty && !_isAutoOpenInitialized) {
      _isAutoOpenInitialized = true;
      final activeJadwal = _getActiveSchedule(todaySchedules);
      if (activeJadwal != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _selectJadwal(activeJadwal);
        });
      }
    }

    final String todayString = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(mTime);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle bar
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

            // Content Area
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  left: 20,
                  right: 20,
                  top: 10,
                ),
                child: _selectedJadwal != null
                    ? _buildDetailView(context, _selectedJadwal!, provider)
                    : _buildListView(context, todayString, todaySchedules, provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context, 
    String todayString, 
    List<JadwalModel> schedules,
    MahasiswaDashboardProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              todayString,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        provider.isLoading && !provider.isInitialized
            ? const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ))
            : schedules.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyStateWidget(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Tidak Ada Jadwal Hari Ini',
                      description: 'Anda tidak memiliki jadwal kuliah pada hari ini (Waktu Makassar).',
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final jadwal = schedules[index];
                      return _PresensiJadwalCard(
                        jadwal: jadwal,
                        onTap: () => _selectJadwal(jadwal),
                      );
                    },
                  ),
      ],
    );
  }

  Widget _buildDetailView(
    BuildContext context, 
    JadwalModel jadwal,
    MahasiswaDashboardProvider provider,
  ) {
    final auth = context.watch<AuthProvider>();
    
    // Condition for Submit Active
    final bool canSubmit = _isCheckedLocation && 
                           _isLocationValid && 
                           _isTimeValid && 
                           _isMeetingActive && 
                           !_hasCheckedInBefore && 
                           !_isSubmitting && 
                           !_isValidating;

    final typeLabel = jadwal.jenisSesi == 'praktikum' ? 'Praktikum' : 'Teori';
    final typeColor = jadwal.jenisSesi == 'praktikum' ? Colors.indigo : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back / Close button Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedJadwal = null;
                  _isAutoOpenInitialized = true;
                });
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: Text('Daftar Hari Ini', style: AppTextStyles.labelMedium),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        const SizedBox(height: 10),

        // Judul
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                typeLabel,
                style: AppTextStyles.badge.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                CourseFormatter.getAbbreviation(jadwal.matakuliahNama, jadwal.matakuliahKode),
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          jadwal.matakuliahNama,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Dosen: ${jadwal.dosenNama}',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        const SizedBox(height: 16),

        // Detail list
        _DetailRow(icon: Icons.calendar_today_rounded, label: 'Hari', value: jadwal.hari),
        const SizedBox(height: 10),
        _DetailRow(icon: Icons.schedule_rounded, label: 'Jam Kuliah', value: '${jadwal.jamMulai} - ${jadwal.jamSelesai}'),
        const SizedBox(height: 10),
        _DetailRow(icon: Icons.room_rounded, label: 'Lokasi Kelas', value: jadwal.ruangan),
        const SizedBox(height: 10),
        _DetailRow(icon: Icons.timer_outlined, label: 'Toleransi Terlambat', value: '${jadwal.toleransiMenit} menit'),
        
        const SizedBox(height: 20),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        const SizedBox(height: 16),

        // Status Validation Box
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
              Text(
                'STATUS VALIDASI',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // 1. Status Pertemuan
              Row(
                children: [
                  Icon(
                    _isMeetingActive 
                        ? (_hasCheckedInBefore ? Icons.info_rounded : Icons.check_circle_rounded)
                        : Icons.cancel_rounded,
                    size: 18,
                    color: _isMeetingActive 
                        ? (_hasCheckedInBefore ? AppColors.info : AppColors.success) 
                        : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _meetingFeedback,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isMeetingActive 
                            ? (_hasCheckedInBefore ? AppColors.info : AppColors.textPrimary) 
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Status Waktu
              Row(
                children: [
                  Icon(
                    _isTimeValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 18,
                    color: _isTimeValid ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Waktu Kuliah: $_timeFeedback',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isTimeValid ? AppColors.textPrimary : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Status Lokasi
              Row(
                children: [
                  Icon(
                    _isCheckedLocation
                        ? (_isLocationValid ? Icons.check_circle_rounded : Icons.cancel_rounded)
                        : Icons.help_outline_rounded,
                    size: 18,
                    color: _isCheckedLocation
                        ? (_isLocationValid ? AppColors.success : AppColors.error)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Radius GPS: $_locationFeedback',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isCheckedLocation
                            ? (_isLocationValid ? AppColors.textPrimary : AppColors.error)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Actions
        Row(
          children: [
            Expanded(
              child: AppButton.outlined(
                label: 'Cek Lokasi',
                icon: Icons.gps_fixed_rounded,
                isLoading: _isValidating,
                onPressed: _isMeetingActive && !_hasCheckedInBefore && _isTimeValid
                    ? _checkLocation
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Submit Absensi',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: canSubmit ? () => _submitAbsensi(auth, provider) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresensiJadwalCard extends StatelessWidget {
  final JadwalModel jadwal;
  final VoidCallback onTap;

  const _PresensiJadwalCard({
    required this.jadwal,
    required this.onTap,
  });

  bool _isOngoing() {
    final now = DateTime.now();
    
    // Parse time
    final startParts = jadwal.jamMulai.split(':');
    final endParts = jadwal.jamSelesai.split(':');
    if (startParts.length < 2 || endParts.length < 2) return false;

    final startTime = DateTime(
      now.year, now.month, now.day,
      int.parse(startParts[0]), int.parse(startParts[1]),
    );
    final endTime = DateTime(
      now.year, now.month, now.day,
      int.parse(endParts[0]), int.parse(endParts[1]),
    );

    return !now.isBefore(startTime) && !now.isAfter(endTime);
  }

  @override
  Widget build(BuildContext context) {
    final isOngoing = _isOngoing();
    final typeLabel = jadwal.jenisSesi == 'praktikum' ? 'Praktikum' : 'Teori';
    final typeColor = jadwal.jenisSesi == 'praktikum' ? Colors.indigo : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOngoing ? AppColors.primary.withOpacity(0.3) : AppColors.border,
            width: isOngoing ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left icon / session type container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                jadwal.jenisSesi == 'praktikum' ? Icons.science_rounded : Icons.menu_book_rounded,
                color: typeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal.matakuliahNama,
                    style: AppTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${jadwal.jamMulai} - ${jadwal.jamSelesai}  •  $typeLabel',
                    style: AppTextStyles.cardSubtitle,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.room_rounded, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          jadwal.ruangan,
                          style: AppTextStyles.cardSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Active Badge / Status Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: !jadwal.status
                        ? AppColors.error.withOpacity(0.08)
                        : (isOngoing ? AppColors.successLight : AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    border: !jadwal.status
                        ? Border.all(color: AppColors.error.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: !jadwal.status
                              ? AppColors.error
                              : (isOngoing ? AppColors.success : AppColors.textSecondary),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        !jadwal.status
                            ? 'Batal'
                            : (isOngoing ? 'Aktif' : 'Nanti'),
                        style: AppTextStyles.badge.copyWith(
                          color: !jadwal.status
                              ? AppColors.error
                              : (isOngoing ? AppColors.success : AppColors.textSecondary),
                          fontWeight: FontWeight.bold,
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
