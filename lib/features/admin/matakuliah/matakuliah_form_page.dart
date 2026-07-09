import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_loading_overlay.dart';
import '../../../models/matakuliah_model.dart';
import '../../../models/dosen_model.dart';
import '../../../providers/matakuliah_provider.dart';
import '../../../repositories/matakuliah_repository.dart';
import '../../../repositories/user_repository.dart';

class MatakuliahFormPage extends StatefulWidget {
  final String? matakuliahId;
  const MatakuliahFormPage({super.key, this.matakuliahId});

  @override
  State<MatakuliahFormPage> createState() => _MatakuliahFormPageState();
}

class _MatakuliahFormPageState extends State<MatakuliahFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kodeController = TextEditingController();
  final _deskripsiController = TextEditingController();

  bool _isEdit = false;
  bool _isLoadingData = false;
  bool _isLoadingOptions = true;
  MatakuliahModel? _existing;

  int _sks = 2;
  String _semester = '1';
  String _selectedProdi = 'Teknik Informatika';
  String _jenisMatakuliah = 'teori'; // 'teori' atau 'teori_praktikum'

  List<DosenModel> _dosenList = [];
  DosenModel? _selectedDosen;

  static const List<String> _prodiList = [
    'Teknik Informatika',
    'Sistem Informasi',
    'Ilmu Komputer',
    'Teknik Elektro',
    'Manajemen',
    'Akuntansi',
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.matakuliahId != null;
    _loadOptions();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoadingOptions = true);
    try {
      _dosenList = await UserRepository.instance.getDosenList();
      if (_isEdit) await _loadData();
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal memuat opsi.');
    } finally {
      if (mounted) setState(() => _isLoadingOptions = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      _existing = await MatakuliahRepository.instance.getById(
        widget.matakuliahId!,
      );
      if (_existing != null && mounted) {
        _namaController.text = _existing!.nama;
        _kodeController.text = _existing!.kode;
        _deskripsiController.text = _existing!.deskripsi;
        setState(() {
          _sks = _existing!.sks;
          _semester = _existing!.semester;
          _jenisMatakuliah = _existing!.jenisMatakuliah;
          _selectedProdi = _prodiList.contains(_existing!.programStudiNama)
              ? _existing!.programStudiNama
              : _prodiList.first;
          _selectedDosen = _dosenList
              .where((d) => d.uid == _existing!.dosenId)
              .firstOrNull;
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
    final provider = context.read<MatakuliahProvider>();
    bool success;

    if (_isEdit) {
      final updated = _existing!.copyWith(
        nama: _namaController.text.trim(),
        kode: _kodeController.text.trim().toUpperCase(),
        sks: _sks,
        semester: _semester,
        programStudiNama: _selectedProdi,
        programStudiId: _selectedProdi.toLowerCase().replaceAll(' ', '_'),
        deskripsi: _deskripsiController.text.trim(),
        jenisMatakuliah: _jenisMatakuliah,
        dosenId: _selectedDosen?.uid ?? '',
        dosenNama: _selectedDosen?.nama ?? '',
        updatedAt: Timestamp.now(),
      );
      success = await provider.update(updated);
    } else {
      final model = MatakuliahModel(
        id: '',
        nama: _namaController.text.trim(),
        kode: _kodeController.text.trim().toUpperCase(),
        sks: _sks,
        semester: _semester,
        programStudiId: _selectedProdi.toLowerCase().replaceAll(' ', '_'),
        programStudiNama: _selectedProdi,
        deskripsi: _deskripsiController.text.trim(),
        status: true,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        jenisMatakuliah: _jenisMatakuliah,
        dosenId: _selectedDosen?.uid ?? '',
        dosenNama: _selectedDosen?.nama ?? '',
      );
      success = await provider.create(model);
    }

    if (!mounted) return;
    if (success) {
      AppSnackbar.success(
        context,
        _isEdit ? 'Mata kuliah diperbarui.' : 'Mata kuliah ditambahkan.',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.errorMessage ?? 'Terjadi kesalahan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatakuliahProvider>();
    return AppLoadingOverlay(
      isLoading: provider.isLoading || _isLoadingData || _isLoadingOptions,
      message: _isLoadingOptions ? 'Memuat data dosen...' : 'Menyimpan...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoadingOptions
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _namaController,
                        label: 'Nama Mata Kuliah',
                        prefixIcon: Icons.book_rounded,
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _kodeController,
                        label: 'Kode Mata Kuliah',
                        hint: 'Contoh: CS101',
                        prefixIcon: Icons.tag_rounded,
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 20),

                      // ── Jenis Mata Kuliah ─────────────────────
                      _buildSectionLabel('Jenis Mata Kuliah'),
                      const SizedBox(height: 10),
                      _buildJenisSelector(),
                      const SizedBox(height: 8),

                      // Info banner untuk teori + praktikum
                      if (_jenisMatakuliah == 'teori_praktikum')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.info.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.info,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sistem akan mendukung Pertemuan, Materi, Tugas, Absensi, '
                                  'dan Nilai untuk sesi Teori dan Praktikum secara terpisah.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ── SKS Selector ──────────────────────────
                      _buildSectionLabel('Jumlah SKS'),
                      const SizedBox(height: 8),
                      Row(
                        children: [1, 2, 3, 4]
                            .map(
                              (n) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _sks = n),
                                    child: _buildChip(
                                      label: '$n SKS',
                                      isSelected: _sks == n,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      // ── Semester Selector ─────────────────────
                      _buildSectionLabel('Semester'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(8, (i) {
                          final sem = '${i + 1}';
                          return GestureDetector(
                            onTap: () => setState(() => _semester = sem),
                            child: SizedBox(
                              width: 52,
                              child: _buildChip(
                                label: sem,
                                isSelected: _semester == sem,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // ── Program Studi ─────────────────────────
                      _buildSectionLabel('Program Studi'),
                      const SizedBox(height: 8),
                      _buildDropdown<String>(
                        value: _selectedProdi,
                        hint: 'Pilih program studi...',
                        items: _prodiList
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedProdi = v!),
                      ),
                      const SizedBox(height: 16),

                      // ── Dosen Pengampu ────────────────────────
                      _buildSectionLabel('Dosen Pengampu (Opsional)'),
                      const SizedBox(height: 8),
                      _buildDropdown<DosenModel?>(
                        value: _selectedDosen,
                        hint: 'Pilih dosen pengampu...',
                        items: [
                          const DropdownMenuItem<DosenModel?>(
                            value: null,
                            child: Text('— Belum ditentukan —'),
                          ),
                          ..._dosenList.map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                d.nama,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedDosen = v),
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _deskripsiController,
                        label: 'Deskripsi (Opsional)',
                        hint: 'Deskripsi singkat mata kuliah...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: _isEdit
                            ? 'Simpan Perubahan'
                            : 'Tambah Mata Kuliah',
                        onPressed: provider.isLoading ? null : _submit,
                        icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildJenisSelector() {
    return Column(
      children: [
        _buildJenisOption(
          value: 'teori',
          label: 'Hanya Teori',
          subtitle: 'Pertemuan dan absensi hanya untuk sesi teori',
          icon: Icons.menu_book_rounded,
        ),
        const SizedBox(height: 8),
        _buildJenisOption(
          value: 'teori_praktikum',
          label: 'Teori + Praktikum',
          subtitle: 'Mendukung sesi teori dan praktikum secara terpisah',
          icon: Icons.science_rounded,
        ),
      ],
    );
  }

  Widget _buildJenisOption({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _jenisMatakuliah == value;
    return GestureDetector(
      onTap: () => setState(() => _jenisMatakuliah = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
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
            Radio<String>(
              value: value,
              groupValue: _jenisMatakuliah,
              onChanged: (v) => setState(() => _jenisMatakuliah = v!),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({required String label, required bool isSelected}) {
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

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
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
      ),
    );
  }
}
