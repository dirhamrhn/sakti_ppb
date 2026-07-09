import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_loading_overlay.dart';
import '../../../models/asdos_model.dart';
import '../../../models/matakuliah_model.dart';
import '../../../providers/asdos_provider.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/matakuliah_repository.dart';

class AsdosFormPage extends StatefulWidget {
  final String? asdosId;
  const AsdosFormPage({super.key, this.asdosId});

  @override
  State<AsdosFormPage> createState() => _AsdosFormPageState();
}

class _AsdosFormPageState extends State<AsdosFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _angkatanController = TextEditingController();

  bool _isEdit = false;
  bool _isLoadingData = false;
  bool _isLoadingPraktikum = true;
  AsdosModel? _existing;

  List<MatakuliahModel> _praktikumList = [];
  List<MatakuliahModel> _selectedPraktikumList = [];

  static const List<String> _prodiList = [
    'Teknik Informatika',
    'Sistem Informasi',
    'Ilmu Komputer',
    'Teknik Elektro',
    'Manajemen',
    'Akuntansi',
  ];
  String _selectedProdi = 'Teknik Informatika';

  @override
  void initState() {
    super.initState();
    _isEdit = widget.asdosId != null;
    _loadPraktikumOptions();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _angkatanController.dispose();
    super.dispose();
  }

  Future<void> _loadPraktikumOptions() async {
    setState(() => _isLoadingPraktikum = true);
    try {
      _praktikumList = await MatakuliahRepository.instance.getByJenis('teori_praktikum');
      if (_isEdit) {
        await _loadData();
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal memuat opsi praktikum.');
    } finally {
      if (mounted) setState(() => _isLoadingPraktikum = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      _existing = await UserRepository.instance.getAsdosById(widget.asdosId!);
      if (_existing != null && mounted) {
        _namaController.text = _existing!.nama;
        _emailController.text = _existing!.email;
        _nimController.text = _existing!.nim;
        _angkatanController.text = _existing!.angkatan;
        setState(() {
          _selectedProdi = _prodiList.contains(_existing!.programStudiNama)
              ? _existing!.programStudiNama
              : _prodiList.first;
          
          _selectedPraktikumList = _praktikumList
              .where((m) =>
                  _existing!.praktikumIds.contains(m.id) ||
                  _existing!.praktikumNama.contains(m.nama))
              .toList();
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
    if (_selectedPraktikumList.isEmpty) {
      AppSnackbar.warning(context, 'Pilih minimal satu praktikum.');
      return;
    }
    
    final provider = context.read<AsdosProvider>();
    bool success;

    if (_isEdit) {
      final updated = _existing!.copyWith(
        nama: _namaController.text.trim(),
        nim: _nimController.text.trim(),
        angkatan: _angkatanController.text.trim(),
        programStudiNama: _selectedProdi,
        programStudiId: _selectedProdi.toLowerCase().replaceAll(' ', '_'),
        updatedAt: Timestamp.now(),
        praktikumIds: _selectedPraktikumList.map((m) => m.id).toList(),
        praktikumNama: _selectedPraktikumList.map((m) => m.nama).toList(),
      );
      success = await provider.update(updated);
    } else {
      final model = AsdosModel(
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
        praktikumIds: _selectedPraktikumList.map((m) => m.id).toList(),
        praktikumNama: _selectedPraktikumList.map((m) => m.nama).toList(),
      );
      success = await provider.create(model);
    }

    if (!mounted) return;
    if (success) {
      AppSnackbar.success(
        context,
        _isEdit
            ? 'Data berhasil diperbarui.'
            : 'Asisten dosen berhasil ditambahkan.\nPassword default: Sakti@2025',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.errorMessage ?? 'Terjadi kesalahan.');
    }
  }

  void _showPraktikumSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih Mata Kuliah Praktikum',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _praktikumList.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada mata kuliah praktikum aktif',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _praktikumList.length,
                              itemBuilder: (context, index) {
                                final item = _praktikumList[index];
                                final isSelected = _selectedPraktikumList.any((m) => m.id == item.id);
                                return CheckboxListTile(
                                  title: Text(item.nama),
                                  subtitle: Text(item.kode),
                                  value: isSelected,
                                  activeColor: AppColors.primary,
                                  onChanged: (bool? checked) {
                                    setModalState(() {
                                      if (checked == true) {
                                        _selectedPraktikumList.add(item);
                                      } else {
                                        _selectedPraktikumList.removeWhere((m) => m.id == item.id);
                                      }
                                    });
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: AppButton(
                        label: 'Selesai',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AsdosProvider>();
    return AppLoadingOverlay(
      isLoading: provider.isLoading || _isLoadingData || _isLoadingPraktikum,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Asisten Dosen' : 'Tambah Asisten Dosen'),
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
                  controller: _nimController,
                  label: 'NIM',
                  hint: '20210001',
                  prefixIcon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _angkatanController,
                  label: 'Angkatan',
                  hint: '2021',
                  prefixIcon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Wajib diisi';
                    if (v!.trim().length != 4) return 'Harus 4 digit tahun';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // --- Pemilihan Praktikum ---
                Text(
                  'Praktikum yang Diajar',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.science_rounded, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedPraktikumList.isEmpty
                              ? 'Pilih mata kuliah praktikum...'
                              : '${_selectedPraktikumList.length} mata kuliah dipilih',
                          style: _selectedPraktikumList.isEmpty
                              ? AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)
                              : AppTextStyles.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _showPraktikumSelectionDialog,
                        child: const Text('Pilih'),
                      ),
                    ],
                  ),
                ),
                if (_selectedPraktikumList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedPraktikumList.map((m) {
                      return InputChip(
                        label: Text('${m.kode} - ${m.nama}'),
                        onDeleted: () {
                          setState(() {
                            _selectedPraktikumList.remove(m);
                          });
                        },
                        deleteIconColor: AppColors.error,
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
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
                      labelText: 'Program Studi',
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
                  label: _isEdit ? 'Simpan Perubahan' : 'Tambah Asisten Dosen',
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
