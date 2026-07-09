import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_loading_overlay.dart';
import '../../../models/dosen_model.dart';
import '../../../providers/dosen_provider.dart';
import '../../../repositories/user_repository.dart';

class DosenFormPage extends StatefulWidget {
  final String? dosenId;
  const DosenFormPage({super.key, this.dosenId});

  @override
  State<DosenFormPage> createState() => _DosenFormPageState();
}

class _DosenFormPageState extends State<DosenFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _nidnController = TextEditingController();
  final _jabatanController = TextEditingController();
  final _keahlianController = TextEditingController();

  bool _isEdit = false;
  bool _isLoadingData = false;
  DosenModel? _existing;

  static const List<String> _prodiList = [
    'Teknik Informatika',
    'Sistem Informasi',
    'Ilmu Komputer',
    'Teknik Elektro',
    'Manajemen',
    'Akuntansi',
  ];

  static const List<String> _jabatanList = [
    'Asisten Ahli',
    'Lektor',
    'Lektor Kepala',
    'Profesor',
    'Tenaga Pengajar',
  ];

  String _selectedProdi = 'Teknik Informatika';
  String _selectedJabatan = 'Asisten Ahli';

  @override
  void initState() {
    super.initState();
    _isEdit = widget.dosenId != null;
    if (_isEdit) _loadData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _nidnController.dispose();
    _jabatanController.dispose();
    _keahlianController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      _existing = await UserRepository.instance.getDosenById(widget.dosenId!);
      if (_existing != null && mounted) {
        _namaController.text = _existing!.nama;
        _emailController.text = _existing!.email;
        _nidnController.text = _existing!.nidn;
        _keahlianController.text = _existing!.bidangKeahlian;
        setState(() {
          _selectedProdi = _prodiList.contains(_existing!.programStudiNama)
              ? _existing!.programStudiNama
              : _prodiList.first;
          _selectedJabatan = _jabatanList.contains(_existing!.jabatan)
              ? _existing!.jabatan
              : _jabatanList.first;
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal memuat data.');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<DosenProvider>();
    bool success;

    if (_isEdit) {
      final updated = _existing!.copyWith(
        nama: _namaController.text.trim(),
        nidn: _nidnController.text.trim(),
        jabatan: _selectedJabatan,
        bidangKeahlian: _keahlianController.text.trim(),
        programStudiNama: _selectedProdi,
        programStudiId: _selectedProdi.toLowerCase().replaceAll(' ', '_'),
        updatedAt: Timestamp.now(),
      );
      success = await provider.update(updated);
    } else {
      final model = DosenModel(
        uid: '',
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        nidn: _nidnController.text.trim(),
        programStudiId: _selectedProdi.toLowerCase().replaceAll(' ', '_'),
        programStudiNama: _selectedProdi,
        jabatan: _selectedJabatan,
        bidangKeahlian: _keahlianController.text.trim(),
        photoUrl: '',
        status: true,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      success = await provider.create(model);
    }

    if (!mounted) return;
    if (success) {
      AppSnackbar.success(
        context,
        _isEdit
            ? 'Data dosen berhasil diperbarui.'
            : 'Dosen berhasil ditambahkan.\nPassword default: Sakti@2025',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.errorMessage ?? 'Terjadi kesalahan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();
    return AppLoadingOverlay(
      isLoading: provider.isLoading || _isLoadingData,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Dosen' : 'Tambah Dosen'),
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
                if (!_isEdit)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Password default: Sakti@2025',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                AppTextField(
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  prefixIcon: Icons.person_rounded,
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _nidnController,
                  label: 'NIDN',
                  hint: '0123456789',
                  prefixIcon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'dosen@kampus.ac.id',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _isEdit,
                  enabled: !_isEdit,
                  helperText: _isEdit ? 'Email tidak dapat diubah' : null,
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Wajib diisi';
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v!.trim()))
                      return 'Format tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _keahlianController,
                  label: 'Bidang Keahlian',
                  hint: 'Contoh: Kecerdasan Buatan',
                  prefixIcon: Icons.science_rounded,
                ),
                const SizedBox(height: 16),
                _DropdownField(
                  label: 'Jabatan',
                  value: _selectedJabatan,
                  items: _jabatanList,
                  onChanged: (v) => setState(() => _selectedJabatan = v!),
                ),
                const SizedBox(height: 16),
                _DropdownField(
                  label: 'Program Studi',
                  value: _selectedProdi,
                  items: _prodiList,
                  onChanged: (v) => setState(() => _selectedProdi = v!),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: _isEdit ? 'Simpan Perubahan' : 'Tambah Dosen',
                  onPressed: provider.isLoading ? null : _submit,
                  icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
                ),
                const SizedBox(height: 16),
                AppButton.outlined(
                  label: 'Batal',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        items: items
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
