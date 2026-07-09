import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_loading_overlay.dart';
import '../../../models/mahasiswa_model.dart';
import '../../../providers/mahasiswa_provider.dart';
import '../../../repositories/user_repository.dart';

class MahasiswaFormPage extends StatefulWidget {
  final String? mahasiswaId; // null = tambah baru, ada = edit

  const MahasiswaFormPage({super.key, this.mahasiswaId});

  @override
  State<MahasiswaFormPage> createState() => _MahasiswaFormPageState();
}

class _MahasiswaFormPageState extends State<MahasiswaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _angkatanController = TextEditingController();
  final _prodiController = TextEditingController();

  bool _isEdit = false;
  bool _isLoadingData = false;
  MahasiswaModel? _existing;

  static const List<String> _prodiList = [
    'Teknik Informatika',
    'Sistem Informasi',
    'Ilmu Komputer',
    'Teknik Elektro',
    'Manajemen',
    'Akuntansi',
    'Hukum',
    'Pendidikan',
  ];

  String _selectedProdi = 'Teknik Informatika';

  @override
  void initState() {
    super.initState();
    _isEdit = widget.mahasiswaId != null;
    if (_isEdit) _loadData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _angkatanController.dispose();
    _prodiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      _existing = await UserRepository.instance.getMahasiswaById(
        widget.mahasiswaId!,
      );
      if (_existing != null && mounted) {
        _namaController.text = _existing!.nama;
        _emailController.text = _existing!.email;
        _nimController.text = _existing!.nim;
        _angkatanController.text = _existing!.angkatan;
        setState(() {
          _selectedProdi = _prodiList.contains(_existing!.programStudiNama)
              ? _existing!.programStudiNama
              : _prodiList.first;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Gagal memuat data.');
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MahasiswaProvider>();
    bool success;

    if (_isEdit) {
      final updated = _existing!.copyWith(
        nama: _namaController.text.trim(),
        nim: _nimController.text.trim(),
        programStudiNama: _selectedProdi,
        programStudiId: _selectedProdi.toLowerCase().replaceAll(' ', '_'),
        angkatan: _angkatanController.text.trim(),
        updatedAt: Timestamp.now(),
      );
      success = await provider.update(updated);
    } else {
      final model = MahasiswaModel(
        uid: '',
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        nim: _nimController.text.trim(),
        programStudiId: _selectedProdi.toLowerCase().replaceAll(' ', '_'),
        programStudiNama: _selectedProdi,
        angkatan: _angkatanController.text.trim(),
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
            ? 'Data mahasiswa berhasil diperbarui.'
            : 'Mahasiswa berhasil ditambahkan.\nPassword default: Sakti@2025',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.errorMessage ?? 'Terjadi kesalahan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaProvider>();

    return AppLoadingOverlay(
      isLoading: provider.isLoading || _isLoadingData,
      message: _isLoadingData ? 'Memuat data...' : 'Menyimpan...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Mahasiswa' : 'Tambah Mahasiswa'),
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
                // Info card
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
                            'Password default akan diset: Sakti@2025',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                _SectionTitle('Data Pribadi'),
                const SizedBox(height: 12),

                AppTextField(
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  prefixIcon: Icons.person_rounded,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _nimController,
                  label: 'NIM',
                  hint: 'Contoh: 20210001',
                  prefixIcon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'NIM tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _angkatanController,
                  label: 'Angkatan',
                  hint: 'Contoh: 2021',
                  prefixIcon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Angkatan tidak boleh kosong';
                    if (v.trim().length != 4)
                      return 'Angkatan harus 4 digit tahun';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                _SectionTitle('Akun'),
                const SizedBox(height: 12),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'nim@kampus.ac.id',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _isEdit,
                  enabled: !_isEdit,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email tidak boleh kosong';
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                  helperText: _isEdit ? 'Email tidak dapat diubah' : null,
                ),
                const SizedBox(height: 24),

                _SectionTitle('Program Studi'),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedProdi,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _prodiList
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedProdi = v!),
                  ),
                ),

                const SizedBox(height: 32),

                AppButton(
                  label: _isEdit ? 'Simpan Perubahan' : 'Tambah Mahasiswa',
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.titleSmall),
      ],
    );
  }
}
