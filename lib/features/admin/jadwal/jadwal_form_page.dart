import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_loading_overlay.dart';
import '../../../models/jadwal_model.dart';
import '../../../models/kelas_model.dart';
import '../../../models/gedung_model.dart';
import '../../../models/matakuliah_model.dart';
import '../../../providers/jadwal_provider.dart';
import '../../../providers/kelas_provider.dart';
import '../../../providers/gedung_provider.dart';
import '../../../repositories/jadwal_repository.dart';
import '../../../repositories/matakuliah_repository.dart';
import 'map_picker_page.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class JadwalFormPage extends StatefulWidget {
  final String? jadwalId;
  const JadwalFormPage({super.key, this.jadwalId});

  @override
  State<JadwalFormPage> createState() => _JadwalFormPageState();
}

class _JadwalFormPageState extends State<JadwalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isEdit = false;
  bool _isLoadingData = false;
  JadwalModel? _existing;

  // ── Form State ─────────────────────────────────────────────────
  KelasModel? _selectedKelas;
  String _hari = 'Senin';
  String _jamMulai = '08:00';
  String _jamSelesai = '10:00';
  String _jenisSesi = 'teori';
  String _lokasiType = 'offline';
  GedungModel? _selectedGedung;
  RuanganModel? _selectedRuangan;
  String _platformMeet = 'meet';
  int _radiusAbsensi = 100;
  int _toleransiMenit = 15;
  String _metodeAbsensi = 'gps';
  bool _lokasiWajib = true;
  bool _selfieWajib = false;
  int _totalPertemuan = 16;

  List<MatakuliahModel> _matakuliahList = [];

  static const List<String> _hariList = JadwalRepository.hariList;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.jadwalId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<GedungProvider>().loadAllGedung();
      
      // Load all classes dynamically
      await context.read<KelasProvider>().loadAll();
      
      // Load all courses
      _matakuliahList = await MatakuliahRepository.instance.getAll();
      
      if (_isEdit) {
        await _loadData();
      }
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      _existing = await JadwalRepository.instance.getById(widget.jadwalId!);
      if (_existing != null && mounted) {
        final kelasList = context.read<KelasProvider>().list;
        final gedungProvider = context.read<GedungProvider>();
        
        setState(() {
          _selectedKelas = kelasList
              .where((k) => k.id == _existing!.kelasId)
              .firstOrNull;
          _hari = _existing!.hari;
          _jamMulai = _existing!.jamMulai;
          _jamSelesai = _existing!.jamSelesai;
          _jenisSesi = _existing!.jenisSesi;
          _lokasiType = _existing!.lokasiType;
          _linkController.text = _existing!.linkMeet;
          _platformMeet = _existing!.platformMeet;
          _radiusAbsensi = _existing!.radiusAbsensi;
          _toleransiMenit = _existing!.toleransiMenit;
          _metodeAbsensi = _existing!.metodeAbsensi;
          _lokasiWajib = _existing!.lokasiWajib;
          _selfieWajib = _existing!.selfieWajib;
          _totalPertemuan = _existing!.totalPertemuan;
          
          _latitudeController.text = _existing!.latitude.toString();
          _longitudeController.text = _existing!.longitude.toString();
          
          _selectedGedung = gedungProvider.gedungList
              .where((g) => g.nama == _existing!.gedungNama)
              .firstOrNull;
        });

        if (_selectedGedung != null) {
          await gedungProvider.loadRuanganByGedung(_selectedGedung!.id);
          setState(() {
            _selectedRuangan = gedungProvider.ruanganList
                .where((r) => r.namaRuangan == _existing!.ruanganNama)
                .firstOrNull;
          });
        }
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal memuat data.');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickJam({required bool isStart}) async {
    final initTime = _parseTime(isStart ? _jamMulai : _jamSelesai);
    final picked = await showTimePicker(
      context: context,
      initialTime: initTime,
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart)
          _jamMulai = formatted;
        else
          _jamSelesai = formatted;
      });
    }
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool get _selectedKelasHasPraktikum {
    if (_selectedKelas == null) return false;
    final course = _matakuliahList.where((m) => m.id == _selectedKelas!.matakuliahId).firstOrNull;
    return course?.hasPraktikum ?? false;
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) AppSnackbar.error(context, 'Layanan lokasi dinonaktifkan.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) AppSnackbar.error(context, 'Izin lokasi ditolak.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) AppSnackbar.error(context, 'Izin lokasi ditolak secara permanen.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
      if (mounted) AppSnackbar.success(context, 'Berhasil mengambil lokasi realtime.');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal mengambil lokasi: $e');
    }
  }

  Future<void> _selectLocationOnMap() async {
    final double currentLat = double.tryParse(_latitudeController.text) ?? -5.2030;
    final double currentLng = double.tryParse(_longitudeController.text) ?? 119.4972;
    
    final LatLng? picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialPosition: LatLng(currentLat, currentLng),
        ),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _latitudeController.text = picked.latitude.toString();
        _longitudeController.text = picked.longitude.toString();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKelas == null) {
      AppSnackbar.error(context, 'Pilih kelas terlebih dahulu.');
      return;
    }
    if (_selectedRuangan == null && !_isEdit) {
      AppSnackbar.error(context, 'Pilih ruangan terlebih dahulu.');
      return;
    }

    final provider = context.read<JadwalProvider>();
    bool success;

    final double lat = double.tryParse(_latitudeController.text.trim()) ?? 0.0;
    final double lng = double.tryParse(_longitudeController.text.trim()) ?? 0.0;

    if (_isEdit) {
      final updated = _existing!.copyWith(
        kelasId: _selectedKelas!.id,
        kelasNama: _selectedKelas!.namaKelas,
        matakuliahId: _selectedKelas!.matakuliahId,
        matakuliahNama: _selectedKelas!.matakuliahNama,
        matakuliahKode: _selectedKelas!.matakuliahKode,
        dosenNama: _selectedKelas!.dosenNama,
        hari: _hari,
        jenisSesi: _jenisSesi,
        jamMulai: _jamMulai,
        jamSelesai: _jamSelesai,
        lokasiType: 'offline',
        gedungNama: _selectedGedung?.nama ?? _existing!.gedungNama,
        ruanganNama: _selectedRuangan?.namaRuangan ?? _existing!.ruanganNama,
        latitude: lat,
        longitude: lng,
        linkMeet: '',
        platformMeet: 'meet',
        radiusAbsensi: _radiusAbsensi,
        toleransiMenit: 15,
        metodeAbsensi: 'gps',
        lokasiWajib: _lokasiWajib,
        selfieWajib: false,
        totalPertemuan: _totalPertemuan,
        updatedAt: Timestamp.now(),
      );
      success = await provider.update(updated);
    } else {
      final model = JadwalModel(
        id: '',
        kelasId: _selectedKelas!.id,
        kelasNama: _selectedKelas!.namaKelas,
        matakuliahId: _selectedKelas!.matakuliahId,
        matakuliahNama: _selectedKelas!.matakuliahNama,
        matakuliahKode: _selectedKelas!.matakuliahKode,
        dosenNama: _selectedKelas!.dosenNama,
        hari: _hari,
        jenisSesi: _jenisSesi,
        jamMulai: _jamMulai,
        jamSelesai: _jamSelesai,
        lokasiType: 'offline',
        gedungNama: _selectedGedung?.nama ?? '',
        ruanganNama: _selectedRuangan?.namaRuangan ?? '',
        latitude: lat,
        longitude: lng,
        linkMeet: '',
        platformMeet: 'meet',
        radiusAbsensi: _radiusAbsensi,
        toleransiMenit: 15,
        metodeAbsensi: 'gps',
        lokasiWajib: _lokasiWajib,
        selfieWajib: false,
        totalPertemuan: _totalPertemuan,
        status: true,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      success = await provider.create(model, kelas: _selectedKelas);
    }

    if (!mounted) return;
    if (success) {
      AppSnackbar.success(
        context,
        _isEdit
            ? 'Jadwal diperbarui.'
            : 'Jadwal dibuat & ${_totalPertemuan} pertemuan di-generate.',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.errorMessage ?? 'Terjadi kesalahan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final jadwalProvider = context.watch<JadwalProvider>();
    final kelasList = context.watch<KelasProvider>().list;
    final gedungProvider = context.watch<GedungProvider>();

    return AppLoadingOverlay(
      isLoading: jadwalProvider.isLoading || _isLoadingData,
      message: _isEdit
          ? 'Menyimpan perubahan...'
          : 'Membuat jadwal & pertemuan...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Jadwal' : 'Tambah Jadwal'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Kelas ────────────────────────────────────────
                _sectionHeader(Icons.class_rounded, 'Kelas & Sesi'),
                const SizedBox(height: 12),
                _buildDropdown<KelasModel?>(
                  value: _selectedKelas,
                  hint: 'Pilih kelas...',
                  items: [
                    const DropdownMenuItem<KelasModel?>(
                      value: null,
                      child: Text('-- Pilih Kelas --'),
                    ),
                    ...kelasList.map(
                      (k) => DropdownMenuItem<KelasModel?>(
                        value: k,
                        child: Text(
                          '${CourseFormatter.getAbbreviation(k.matakuliahNama, k.matakuliahKode)} - ${k.namaKelas}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedKelas = v;
                      
                      if (v != null) {
                        _jenisSesi = v.jenisKelas.isNotEmpty ? v.jenisKelas : 'teori';
                        if (_jenisSesi == 'praktikum') {
                          _totalPertemuan = 8;
                        } else {
                          _totalPertemuan = 16;
                        }
                      }
                    });
                  },
                  validator: (_) =>
                      _selectedKelas == null ? 'Pilih kelas' : null,
                ),
                const SizedBox(height: 12),

                // Jenis Sesi
                _buildSectionLabel('Jenis Sesi'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _jenisChip(
                        'teori',
                        'Teori',
                        Icons.menu_book_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _jenisChip(
                        'praktikum',
                        'Praktikum',
                        Icons.science_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Waktu ─────────────────────────────────────────
                _sectionHeader(Icons.schedule_rounded, 'Waktu'),
                const SizedBox(height: 12),

                // Hari
                _buildSectionLabel('Hari'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _hariList
                      .map(
                        (h) => GestureDetector(
                          onTap: () => setState(() => _hari = h),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _hari == h
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _hari == h
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              h,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _hari == h
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),

                // Jam
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickJam(isStart: true),
                        child: _timeCard(
                          'Mulai',
                          _jamMulai,
                          Icons.play_arrow_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickJam(isStart: false),
                        child: _timeCard(
                          'Selesai',
                          _jamSelesai,
                          Icons.stop_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Lokasi ────────────────────────────────────────
                _sectionHeader(Icons.location_on_rounded, 'Lokasi & Koordinat'),
                const SizedBox(height: 12),

                // Gedung
                _buildSectionLabel('Gedung'),
                const SizedBox(height: 8),
                gedungProvider.isLoadingGedung
                    ? const Center(child: CircularProgressIndicator())
                    : _buildDropdown<GedungModel?>(
                        value: _selectedGedung,
                        hint: 'Pilih gedung...',
                        items: [
                          const DropdownMenuItem<GedungModel?>(
                            value: null,
                            child: Text('-- Pilih Gedung --'),
                          ),
                          ...gedungProvider.gedungList.map(
                            (g) => DropdownMenuItem<GedungModel?>(
                              value: g,
                              child: Text(
                                '${g.kode} - ${g.nama}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedGedung = v;
                            _selectedRuangan = null;
                            _latitudeController.clear();
                            _longitudeController.clear();
                          });
                          if (v != null) {
                            context
                                .read<GedungProvider>()
                                .loadRuanganByGedung(v.id);
                          }
                        },
                      ),
                const SizedBox(height: 12),

                if (_selectedGedung != null) ...[
                  _buildSectionLabel('Ruangan'),
                  const SizedBox(height: 8),
                  gedungProvider.isLoadingRuangan
                      ? const LinearProgressIndicator()
                      : _buildDropdown<RuanganModel?>(
                          value: _selectedRuangan,
                          hint: 'Pilih ruangan...',
                          items: [
                            const DropdownMenuItem<RuanganModel?>(
                              value: null,
                              child: Text('-- Pilih Ruangan --'),
                            ),
                            ...gedungProvider.ruanganList.map(
                              (r) => DropdownMenuItem<RuanganModel?>(
                                value: r,
                                child: Text(
                                  '${r.kodeRuangan} - ${r.namaRuangan}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedRuangan = v;
                              if (v != null) {
                                _latitudeController.text = v.latitude.toString();
                                _longitudeController.text = v.longitude.toString();
                              } else {
                                _latitudeController.clear();
                                _longitudeController.clear();
                              }
                            });
                          },
                        ),
                  const SizedBox(height: 12),
                ],

                // Koordinat Lokasi GPS manual / realtime / maps
                _buildSectionLabel('Koordinat Lokasi GPS'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _latitudeController,
                        label: 'Latitude',
                        hint: '-7.2575',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        validator: (v) => v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _longitudeController,
                        label: 'Longitude',
                        hint: '112.7521',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        validator: (v) => v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outlined(
                        label: 'GPS Realtime',
                        icon: Icons.my_location_rounded,
                        onPressed: _getCurrentLocation,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton.outlined(
                        label: 'Google Maps',
                        icon: Icons.map_rounded,
                        onPressed: _selectLocationOnMap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Konfigurasi Absensi ───────────────────────────
                _sectionHeader(Icons.how_to_reg_rounded, 'Konfigurasi Absensi'),
                const SizedBox(height: 12),

                // Total Pertemuan
                _buildSectionLabel('Total Pertemuan'),
                const SizedBox(height: 8),
                Row(
                  children: [8, 16]
                      .map(
                        (n) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setState(() => _totalPertemuan = n),
                              child: _buildChip(
                                '$n Pertemuan',
                                _totalPertemuan == n,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),

                // Radius Absensi
                _buildSectionLabel('Radius Absensi GPS'),
                const SizedBox(height: 8),
                Row(
                  children: [50, 100, 150]
                      .map(
                        (r) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            child: GestureDetector(
                              onTap: () => setState(() => _radiusAbsensi = r),
                              child: _buildChip('${r}m', _radiusAbsensi == r),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Toggles
                _buildToggleTile(
                  title: 'Wajib dalam radius GPS',
                  subtitle: 'Mahasiswa harus berada dalam radius saat absen',
                  value: _lokasiWajib,
                  onChanged: (v) => setState(() => _lokasiWajib = v),
                  icon: Icons.gps_fixed_rounded,
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: _isEdit ? 'Simpan Perubahan' : 'Buat Jadwal',
                  onPressed: jadwalProvider.isLoading ? null : _submit,
                  icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
                ),
                const SizedBox(height: 12),
                AppButton.outlined(
                  label: 'Batal',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(child: Divider(indent: 12, color: AppColors.border)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _jenisChip(String value, String label, IconData icon) {
    bool disabled = false;
    if (_selectedKelas != null) {
      disabled = (_selectedKelas!.jenisKelas.isNotEmpty ? _selectedKelas!.jenisKelas : 'teori') != value;
    } else {
      final isPraktikumVal = value == 'praktikum';
      final hasPraktikum = _selectedKelasHasPraktikum;
      disabled = isPraktikumVal && !hasPraktikum;
    }
    final sel = _jenisSesi == value && !disabled;
    
    return GestureDetector(
      onTap: () {
        if (disabled) {
          if (_selectedKelas != null) {
            AppSnackbar.warning(
              context,
              'Sesi harus sesuai dengan Jenis Kelas yang dipilih (${_selectedKelas!.jenisKelas == 'teori' ? 'Teori' : 'Praktikum'}).',
            );
          } else {
            AppSnackbar.warning(context, 'Mata kuliah kelas ini tidak memiliki praktikum.');
          }
          return;
        }
        setState(() {
          _jenisSesi = value;
          if (value == 'praktikum') {
            _totalPertemuan = 8;
          } else {
            _totalPertemuan = 16;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.withOpacity(0.1)
              : (sel ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled
                ? AppColors.border.withOpacity(0.5)
                : (sel ? AppColors.primary : AppColors.border),
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: disabled
                  ? Colors.grey
                  : (sel ? AppColors.primary : AppColors.textSecondary),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              disabled && _selectedKelas == null ? 'Tidak memiliki praktikum' : label,
              style: AppTextStyles.labelMedium.copyWith(
                color: disabled
                    ? Colors.grey
                    : (sel ? AppColors.primary : AppColors.textPrimary),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _lokasiChip(String value, String label, IconData icon) {
    final sel = _lokasiType == value;
    return GestureDetector(
      onTap: () => setState(() => _lokasiType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.border,
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: sel ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: sel ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformChip(String value, String label, IconData icon, Color color) {
    final sel = _platformMeet == value;
    return GestureDetector(
      onTap: () => setState(() => _platformMeet = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? color : AppColors.border,
            width: sel ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: sel ? color : AppColors.textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: sel ? color : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metodeChip(String value, String label, IconData icon) {
    final sel = _metodeAbsensi == value;
    return GestureDetector(
      onTap: () => setState(() => _metodeAbsensi = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.border,
            width: sel ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: sel ? AppColors.primary : AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: sel ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _timeCard(String label, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                time,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gpsInfoBanner(RuanganModel ruangan) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.gps_fixed_rounded, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GPS: ${ruangan.latitude.toStringAsFixed(6)}, ${ruangan.longitude.toStringAsFixed(6)}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        hint: Text(hint),
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
