import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_loading_overlay.dart';
import '../../../models/kelas_model.dart';
import '../../../models/matakuliah_model.dart';
import '../../../models/dosen_model.dart';
import '../../../models/asdos_model.dart';
import '../../../providers/kelas_provider.dart';
import '../../../repositories/kelas_repository.dart';
import '../../../repositories/matakuliah_repository.dart';
import '../../../repositories/user_repository.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class KelasFormPage extends StatefulWidget {
  final String? kelasId;
  const KelasFormPage({super.key, this.kelasId});

  @override
  State<KelasFormPage> createState() => _KelasFormPageState();
}

class _KelasFormPageState extends State<KelasFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaKelasController = TextEditingController();
  final _semesterController = TextEditingController();
  final _kapasitasController = TextEditingController(text: '40');

  bool _isEdit = false;
  bool _isLoadingData = false;
  bool _isLoadingOptions = true;
  KelasModel? _existing;

  List<MatakuliahModel> _matakuliahList = [];
  List<DosenModel> _dosenList = [];
  List<AsdosModel> _asdosList = [];

  MatakuliahModel? _selectedMatakuliah;
  DosenModel? _selectedDosen;
  List<AsdosModel> _selectedAsdosList = [];
  String _tahunAkademik = '2024/2025';
  int _semesterAktif = 1; // 1=Ganjil, 2=Genap

  static const List<String> _tahunList = [
    '2023/2024',
    '2024/2025',
    '2025/2026',
    '2026/2027',
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.kelasId != null;
    _loadOptions();
  }

  @override
  void dispose() {
    _namaKelasController.dispose();
    _semesterController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoadingOptions = true);
    try {
      final results = await Future.wait([
        MatakuliahRepository.instance.getAll(),
        UserRepository.instance.getDosenList(),
        UserRepository.instance.getAsdosList(),
      ]);
      _matakuliahList = results[0] as List<MatakuliahModel>;
      _dosenList = results[1] as List<DosenModel>;
      _asdosList = results[2] as List<AsdosModel>;

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
      _existing = await KelasRepository.instance.getById(widget.kelasId!);
      if (_existing != null && mounted) {
        _namaKelasController.text = _existing!.namaKelas;
        _semesterController.text = _existing!.semesterNama;
        _kapasitasController.text = _existing!.kapasitas.toString();
        setState(() {
          _selectedMatakuliah = _matakuliahList
              .where((m) => m.id == _existing!.matakuliahId)
              .firstOrNull;
          _selectedDosen = _dosenList
              .where((d) => d.uid == _existing!.dosenId)
              .firstOrNull;
          _tahunAkademik = _existing!.tahunAkademik.isNotEmpty
              ? _existing!.tahunAkademik
              : '2024/2025';
          _semesterAktif = _existing!.semesterAktif;

          _selectedAsdosList = _asdosList
              .where((a) => _existing!.asdosIds.contains(a.uid))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal memuat data kelas.');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMatakuliah == null) {
      AppSnackbar.warning(context, 'Pilih mata kuliah terlebih dahulu.');
      return;
    }

    final provider = context.read<KelasProvider>();
    bool success;

    final kapasitas = int.tryParse(_kapasitasController.text) ?? 40;

    final hasPraktikum = _selectedMatakuliah!.hasPraktikum;
    final finalAsdosIds = hasPraktikum ? _selectedAsdosList.map((a) => a.uid).toList() : <String>[];
    final finalAsdosNama = hasPraktikum ? _selectedAsdosList.map((a) => a.nama).toList() : <String>[];

    if (_isEdit) {
      final updated = _existing!.copyWith(
        namaKelas: _namaKelasController.text.trim().toUpperCase(),
        matakuliahId: _selectedMatakuliah!.id,
        matakuliahNama: _selectedMatakuliah!.nama,
        matakuliahKode: _selectedMatakuliah!.kode,
        dosenId: _selectedDosen?.uid ?? '',
        dosenNama: _selectedDosen?.nama ?? '',
        asdosIds: finalAsdosIds,
        asdosNama: finalAsdosNama,
        semesterNama: _semesterController.text.trim(),
        kapasitas: kapasitas,
        tahunAkademik: _tahunAkademik,
        semesterAktif: _semesterAktif,
        updatedAt: Timestamp.now(),
      );
      success = await provider.update(updated);
    } else {
      final model = KelasModel(
        id: '',
        namaKelas: _namaKelasController.text.trim().toUpperCase(),
        matakuliahId: _selectedMatakuliah!.id,
        matakuliahNama: _selectedMatakuliah!.nama,
        matakuliahKode: _selectedMatakuliah!.kode,
        dosenId: _selectedDosen?.uid ?? '',
        dosenNama: _selectedDosen?.nama ?? '',
        asdosIds: finalAsdosIds,
        asdosNama: finalAsdosNama,
        semesterId: '',
        semesterNama: _semesterController.text.trim(),
        kapasitas: kapasitas,
        jumlahMahasiswa: 0,
        status: true,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        tahunAkademik: _tahunAkademik,
        semesterAktif: _semesterAktif,
      );
      success = await provider.create(model);
    }

    if (!mounted) return;
    if (success) {
      AppSnackbar.success(
        context,
        _isEdit ? 'Kelas diperbarui.' : 'Kelas ditambahkan.',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.errorMessage ?? 'Terjadi kesalahan.');
    }
  }

  void _showAsdosSelectionDialog() {
    if (_selectedMatakuliah == null) return;
    
    // Filter Asdos whose praktikumIds contains selected matakuliah id
    final availableAsdos = _asdosList
        .where((asdos) => asdos.praktikumIds.contains(_selectedMatakuliah!.id))
        .toList();
        
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
              initialChildSize: 0.5,
              maxChildSize: 0.9,
              minChildSize: 0.3,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Pilih Asisten Dosen untuk ${_selectedMatakuliah!.nama}',
                        style: AppTextStyles.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: availableAsdos.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada asdos terdaftar di praktikum ini',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: availableAsdos.length,
                              itemBuilder: (context, index) {
                                final item = availableAsdos[index];
                                final isSelected = _selectedAsdosList.any((a) => a.uid == item.uid);
                                return CheckboxListTile(
                                  title: Text(item.nama),
                                  subtitle: Text('NIM: ${item.nim}'),
                                  value: isSelected,
                                  activeColor: AppColors.primary,
                                  onChanged: (bool? checked) {
                                    setModalState(() {
                                      if (checked == true) {
                                        _selectedAsdosList.add(item);
                                      } else {
                                        _selectedAsdosList.removeWhere((a) => a.uid == item.uid);
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
    final provider = context.watch<KelasProvider>();
    return AppLoadingOverlay(
      isLoading: provider.isLoading || _isLoadingData || _isLoadingOptions,
      message: _isLoadingOptions ? 'Memuat opsi...' : 'Menyimpan...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Kelas' : 'Tambah Kelas'),
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
                      // Pilih Mata Kuliah
                      Text(
                        'Mata Kuliah',
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<MatakuliahModel>(
                          isExpanded: true,
                          value: _selectedMatakuliah,
                          hint: const Text('Pilih mata kuliah...'),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: _matakuliahList
                              .map(
                                (m) => DropdownMenuItem<MatakuliahModel>(
                                  value: m,
                                  child: Text(
                                    '${CourseFormatter.getAbbreviation(m.nama, m.kode)} - ${m.nama}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedMatakuliah = v;
                              
                              // Auto sync Dosen if course has a dosen assigned
                              if (v != null && v.dosenId.isNotEmpty) {
                                _selectedDosen = _dosenList
                                    .where((d) => d.uid == v.dosenId)
                                    .firstOrNull;
                              } else {
                                _selectedDosen = null;
                              }
                              
                              // Clear any selected Asdos that are not registered for this new course
                              if (v != null) {
                                _selectedAsdosList.removeWhere((asdos) => !asdos.praktikumIds.contains(v.id));
                              } else {
                                _selectedAsdosList.clear();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _namaKelasController,
                        label: 'Nama Kelas',
                        hint: 'Contoh: A, B, Paralel 1',
                        prefixIcon: Icons.class_rounded,
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _semesterController,
                        label: 'Semester / Tahun Ajaran',
                        hint: 'Contoh: Ganjil 2024/2025',
                        prefixIcon: Icons.calendar_month_rounded,
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _kapasitasController,
                        label: 'Kapasitas Mahasiswa',
                        hint: '40',
                        prefixIcon: Icons.group_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.trim().isEmpty == true) return 'Wajib diisi';
                          if (int.tryParse(v!) == null) return 'Harus angka';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Pilih Dosen
                      Text(
                        'Dosen Pengampu (Opsional)',
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<DosenModel?>(
                          isExpanded: true,
                          value: _selectedDosen,
                          hint: const Text('Pilih dosen... (bisa diisi nanti)'),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: [
                            const DropdownMenuItem<DosenModel?>(
                              value: null,
                              child: Text('— Belum ditentukan —'),
                            ),
                            ..._dosenList.map(
                              (d) => DropdownMenuItem<DosenModel?>(
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
                      ),
                      
                      // Pilih Asisten Dosen (Hanya muncul jika matakuliah memiliki praktikum)
                      if (_selectedMatakuliah != null && _selectedMatakuliah!.hasPraktikum) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Asisten Dosen (Asdos)',
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
                              const Icon(Icons.people_outline_rounded, color: AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedAsdosList.isEmpty
                                      ? 'Pilih asisten dosen...'
                                      : '${_selectedAsdosList.length} asisten dosen dipilih',
                                  style: _selectedAsdosList.isEmpty
                                      ? AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)
                                      : AppTextStyles.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: _showAsdosSelectionDialog,
                                child: const Text('Pilih'),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedAsdosList.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedAsdosList.map((a) {
                              return InputChip(
                                label: Text(a.nama),
                                onDeleted: () {
                                  setState(() {
                                    _selectedAsdosList.remove(a);
                                  });
                                },
                                deleteIconColor: AppColors.error,
                                backgroundColor: AppColors.secondary.withOpacity(0.08),
                                side: BorderSide(color: AppColors.secondary.withOpacity(0.3)),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                      const SizedBox(height: 32),

                      // Tahun Akademik
                      Text(
                        'Tahun Akademik',
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _tahunAkademik,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: _tahunList
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _tahunAkademik = v!),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Semester Aktif
                      Text(
                        'Semester',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _semesterAktif = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _semesterAktif == 1
                                      ? AppColors.primary
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _semesterAktif == 1
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  'Ganjil',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: _semesterAktif == 1
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _semesterAktif = 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _semesterAktif == 2
                                      ? AppColors.primary
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _semesterAktif == 2
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  'Genap',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: _semesterAktif == 2
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      AppButton(
                        label: _isEdit ? 'Simpan Perubahan' : 'Tambah Kelas',
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
