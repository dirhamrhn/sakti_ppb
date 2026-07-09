import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_loading_overlay.dart';
import '../../../models/gedung_model.dart';
import '../../../providers/gedung_provider.dart';

class RuanganFormPage extends StatefulWidget {
  final GedungModel gedung;
  final RuanganModel? ruangan;
  const RuanganFormPage({super.key, required this.gedung, this.ruangan});

  @override
  State<RuanganFormPage> createState() => _RuanganFormPageState();
}

class _RuanganFormPageState extends State<RuanganFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kodeController = TextEditingController();
  final _kapasitasController = TextEditingController(text: '40');
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isEdit = false;
  String _tipe = 'kelas';

  static const List<String> _tipeList = ['kelas', 'lab', 'aula', 'seminar'];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.ruangan != null;
    if (_isEdit) {
      _namaController.text = widget.ruangan!.namaRuangan;
      _kodeController.text = widget.ruangan!.kodeRuangan;
      _kapasitasController.text = widget.ruangan!.kapasitas.toString();
      _tipe = widget.ruangan!.tipe;
      if (widget.ruangan!.latitude != 0.0) {
        _latController.text = widget.ruangan!.latitude.toString();
        _lngController.text = widget.ruangan!.longitude.toString();
      }
    } else {
      // Default: pakai koordinat gedung
      if (widget.gedung.hasGpsLocation) {
        _latController.text = widget.gedung.latitude.toString();
        _lngController.text = widget.gedung.longitude.toString();
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose();
    _kapasitasController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GedungProvider>();
    final lat = double.tryParse(_latController.text.trim()) ?? 0.0;
    final lng = double.tryParse(_lngController.text.trim()) ?? 0.0;
    final kap = int.tryParse(_kapasitasController.text.trim()) ?? 40;
    bool success;

    if (_isEdit) {
      final updated = widget.ruangan!.copyWith(
        namaRuangan: _namaController.text.trim(),
        kodeRuangan: _kodeController.text.trim().toUpperCase(),
        kapasitas: kap,
        tipe: _tipe,
        latitude: lat,
        longitude: lng,
        updatedAt: Timestamp.now(),
      );
      success = await provider.updateRuangan(updated);
    } else {
      final model = RuanganModel(
        id: '',
        gedungId: widget.gedung.id,
        gedungNama: widget.gedung.nama,
        namaRuangan: _namaController.text.trim(),
        kodeRuangan: _kodeController.text.trim().toUpperCase(),
        kapasitas: kap,
        tipe: _tipe,
        latitude: lat,
        longitude: lng,
        status: true,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      success = await provider.createRuangan(model);
    }

    if (!mounted) return;
    if (success) {
      AppSnackbar.success(
        context,
        _isEdit ? 'Ruangan diperbarui.' : 'Ruangan ditambahkan.',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.errorMessage ?? 'Terjadi kesalahan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GedungProvider>();
    return AppLoadingOverlay(
      isLoading: provider.isLoadingRuangan,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit Ruangan' : 'Tambah Ruangan',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                widget.gedung.nama,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
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
                AppTextField(
                  controller: _namaController,
                  label: 'Nama Ruangan',
                  hint: 'Contoh: Lab Komputer 1',
                  prefixIcon: Icons.door_front_door_rounded,
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _kodeController,
                        label: 'Kode Ruangan',
                        hint: 'LK1',
                        prefixIcon: Icons.tag_rounded,
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _kapasitasController,
                        label: 'Kapasitas',
                        hint: '40',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tipe
                Text(
                  'Tipe Ruangan',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tipeList
                      .map(
                        (t) => GestureDetector(
                          onTap: () => setState(() => _tipe = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _tipe == t
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _tipe == t
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: _tipe == t ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              t[0].toUpperCase() + t.substring(1),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _tipe == t
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: _tipe == t
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),

                // GPS
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.gps_fixed_rounded,
                            color: AppColors.info,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Koordinat GPS Ruangan',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (widget.gedung.hasGpsLocation)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Default: koordinat gedung ${widget.gedung.nama}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _latController,
                              label: 'Latitude',
                              hint: '-6.123456',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _lngController,
                              label: 'Longitude',
                              hint: '106.123456',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: _isEdit ? 'Simpan Perubahan' : 'Tambah Ruangan',
                  onPressed: provider.isLoadingRuangan ? null : _submit,
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
}
