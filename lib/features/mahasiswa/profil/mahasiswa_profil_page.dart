import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';

class MahasiswaProfilPage extends StatelessWidget {
  const MahasiswaProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<MahasiswaDashboardProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MahasiswaEditProfilPage(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─ Header ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  // Foto profil
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: (user?.photoUrl?.isNotEmpty ?? false)
                            ? NetworkImage(user!.photoUrl) as ImageProvider
                            : null,
                        child: (user?.photoUrl?.isEmpty ?? true)
                            ? const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 52,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.nama ?? 'Mahasiswa',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.nomorInduk ?? '',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatBadge('${provider.kelasList.length}', 'Mata Kuliah'),
                      const SizedBox(width: 20),
                      _StatBadge('${provider.totalSKS}', 'SKS'),
                      const SizedBox(width: 20),
                      _StatBadge(
                        provider.ipk > 0
                            ? provider.ipk.toStringAsFixed(2)
                            : '-',
                        'IPK',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─ Info Detail ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informasi Akademik', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 12),
                  _InfoCard([
                    _InfoTile(
                      icon: Icons.person_rounded,
                      label: 'Nama Lengkap',
                      value: user?.nama ?? '-',
                    ),
                    _InfoTile(
                      icon: Icons.badge_rounded,
                      label: 'NIM',
                      value: user?.nomorInduk ?? '-',
                    ),
                    _InfoTile(
                      icon: Icons.school_rounded,
                      label: 'Program Studi',
                      value: _getProgramStudi(provider),
                    ),
                    _InfoTile(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: user?.email ?? '-',
                    ),
                  ]),

                  const SizedBox(height: 20),
                  Text('Pencapaian', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 12),
                  _AchievementCard(provider: provider),

                  const SizedBox(height: 28),

                  // Logout
                  AppButton.danger(
                    label: 'Logout',
                    icon: Icons.logout_rounded,
                    onPressed: () => ConfirmDialog.show(
                      context,
                      title: 'Logout',
                      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
                      confirmLabel: 'Logout',
                      isDanger: true,
                      onConfirm: () async {
                        provider.reset();
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            RouteName.login,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProgramStudi(MahasiswaDashboardProvider provider) {
    // Data program studi dari enrollment / mahasiswa model
    return '-';
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  const _StatBadge(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> tiles;
  const _InfoCard(this.tiles);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: tiles
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < tiles.length - 1)
                    const Divider(height: 1, indent: 52),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final MahasiswaDashboardProvider provider;
  const _AchievementCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final tugasSelesai = provider.submisiList.length;
    final totalTugas = provider.tugasList.length;
    final hadirCount = provider.absensiList.where((a) => a.isHadir).length;
    final totalAbsensi = provider.absensiList.length;
    final nilaiCount = provider.nilaiList.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AchievementItem(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Tugas Selesai',
                  value: '$tugasSelesai/$totalTugas',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AchievementItem(
                  icon: Icons.how_to_reg_rounded,
                  label: 'Kehadiran',
                  value: '$hadirCount/$totalAbsensi',
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AchievementItem(
                  icon: Icons.grade_rounded,
                  label: 'Nilai Tersedia',
                  value: '$nilaiCount',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _AchievementItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Edit Profil Page ─────────────────────────────────────────────────────────

class MahasiswaEditProfilPage extends StatefulWidget {
  const MahasiswaEditProfilPage({super.key});

  @override
  State<MahasiswaEditProfilPage> createState() =>
      _MahasiswaEditProfilPageState();
}

class _MahasiswaEditProfilPageState extends State<MahasiswaEditProfilPage> {
  final _namaController = TextEditingController();
  final _noHPController = TextEditingController();
  File? _fotoFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _namaController.text = user?.nama ?? '';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noHPController.dispose();
    super.dispose();
  }

  Future<void> _pickFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _fotoFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_namaController.text.trim().isEmpty) {
      AppSnackbar.warning(context, 'Nama tidak boleh kosong.');
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<MahasiswaDashboardProvider>();
    final user = context.read<AuthProvider>().user;

    final success = await provider.updateProfil(
      nama: _namaController.text.trim(),
      noHP: _noHPController.text.trim(),
      fotoFile: _fotoFile,
      existingPhotoUrl: user?.photoUrl,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppSnackbar.success(context, 'Profil berhasil diperbarui!');
      Navigator.pop(context);
    } else {
      AppSnackbar.error(
        context,
        provider.errorMessage ?? 'Gagal menyimpan profil.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Foto profil
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: _fotoFile != null
                        ? FileImage(_fotoFile!) as ImageProvider
                        : (user?.photoUrl?.isNotEmpty ?? false)
                        ? NetworkImage(user!.photoUrl) as ImageProvider
                        : null,
                    child:
                        (_fotoFile == null && (user?.photoUrl?.isEmpty ?? true))
                        ? const Icon(
                            Icons.person_rounded,
                            size: 56,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickFoto,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickFoto,
              child: Text(
                'Ubah Foto Profil',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Form fields
            AppTextField(
              controller: _namaController,
              label: 'Nama Lengkap',
              prefixIcon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _noHPController,
              label: 'Nomor HP',
              hint: '08xxxxxxxxxx',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Email dan NIM tidak dapat diubah melalui aplikasi.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            AppButton(
              label: 'Simpan Perubahan',
              icon: Icons.save_rounded,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
