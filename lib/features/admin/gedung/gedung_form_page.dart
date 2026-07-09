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

class GedungFormPage extends StatefulWidget {
  final GedungModel? gedung;
  const GedungFormPage({super.key, this.gedung});

  @override
  State<GedungFormPage> createState() => _GedungFormPageState();
}

class _GedungFormPageState extends State<GedungFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kodeController = TextEditingController();
  final _alamatController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.gedung != null;
    if (_isEdit) {
      _namaController.text = widget.gedung!.nama;
      _kodeController.text = widget.gedung!.kode;
      _alamatController.text = widget.gedung!.alamat;
      _latController.text = widget.gedung!.latitude != 0.0
          ? widget.gedung!.latitude.toString()
          : '';
      _lngController.text = widget.gedung!.longitude != 0.0
          ? widget.gedung!.longitude.toString()
          : '';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose();
    _alamatController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GedungProvider>();
    final lat = double.tryParse(_latController.text.trim()) ?? 0.0;
    final lng = double.tryParse(_lngController.text.trim()) ?? 0.0;
    bool success;

    if (_isEdit) {
      final updated = widget.gedung!.copyWith(
        nama: _namaController.text.trim(),
        kode: _kodeController.text.trim().toUpperCase(),
        alamat: _alamatController.text.trim(),
        latitude: lat,
        longitude: lng,
        updatedAt: Timestamp.now(),
      );
      success = await provider.updateGedung(updated);
    } else {
      final model = GedungModel(
        id: '',
        nama: _namaController.text.trim(),
        kode: _kodeController.text.trim().toUpperCase(),
        alamat: _alamatController.text.trim(),
        latitude: lat,
        longitude: lng,
        status: true,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      success = await provider.createGedung(model);
    }

    if (!mounted) return;
    if (success) {
      AppSnackbar.success(
        context,
        _isEdit ? 'Gedung diperbarui.' : 'Gedung ditambahkan.',
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
      isLoading: provider.isLoadingGedung,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Gedung' : 'Tambah Gedung'),
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
                  label: 'Nama Gedung',
                  hint: 'Contoh: Gedung A',
                  prefixIcon: Icons.business_rounded,
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _kodeController,
                  label: 'Kode Gedung',
                  hint: 'Contoh: GDA',
                  prefixIcon: Icons.tag_rounded,
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _alamatController,
                  label: 'Alamat / Lokasi (Opsional)',
                  hint: 'Contoh: Lantai 2, Kampus Barat',
                  prefixIcon: Icons.location_on_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // GPS Banner
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
                            'Koordinat GPS',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Koordinat GPS digunakan sebagai referensi absensi mahasiswa. '
                        'Buka Google Maps, tap titik lokasi, dan copy koordinatnya.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
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
                  label: _isEdit ? 'Simpan Perubahan' : 'Tambah Gedung',
                  onPressed: provider.isLoadingGedung ? null : _submit,
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
