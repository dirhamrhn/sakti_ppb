import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../providers/mahasiswa_provider.dart';
import '../../../models/mahasiswa_model.dart';

class MahasiswaListPage extends StatefulWidget {
  const MahasiswaListPage({super.key});

  @override
  State<MahasiswaListPage> createState() => _MahasiswaListPageState();
}

class _MahasiswaListPageState extends State<MahasiswaListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MahasiswaProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(MahasiswaModel mahasiswa) async {
    ConfirmDialog.show(
      context,
      title: 'Hapus Mahasiswa',
      message:
          'Yakin ingin menghapus data "${mahasiswa.nama}"?\nData yang dihapus tidak dapat dikembalikan.',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final success = await context.read<MahasiswaProvider>().delete(
          mahasiswa.uid,
        );
        if (!mounted) return;
        if (success) {
          AppSnackbar.success(context, 'Mahasiswa berhasil dihapus.');
        } else {
          AppSnackbar.error(
            context,
            context.read<MahasiswaProvider>().errorMessage ??
                'Gagal menghapus.',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaProvider>();
    final filtered = provider.search(_searchQuery);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Data Mahasiswa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          RouteName.adminMahasiswaForm,
        ).then((_) => context.read<MahasiswaProvider>().loadAll()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ─── Search Bar ──────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari nama, NIM, atau email...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white54,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white70,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // ─── Count ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} mahasiswa',
                  style: AppTextStyles.labelMedium,
                ),
              ],
            ),
          ),

          // ─── List ────────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.school_rounded,
                    title: 'Belum Ada Mahasiswa',
                    description: 'Tap tombol + untuk menambah mahasiswa baru.',
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        context.read<MahasiswaProvider>().loadAll(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _MahasiswaCard(
                        mahasiswa: filtered[i],
                        onEdit: () =>
                            Navigator.pushNamed(
                              context,
                              RouteName.adminMahasiswaForm,
                              arguments: filtered[i].uid,
                            ).then(
                              (_) =>
                                  context.read<MahasiswaProvider>().loadAll(),
                            ),
                        onDelete: () => _delete(filtered[i]),
                        onToggleStatus: () => context
                            .read<MahasiswaProvider>()
                            .toggleStatus(filtered[i].uid, filtered[i].status),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MahasiswaCard extends StatelessWidget {
  final MahasiswaModel mahasiswa;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _MahasiswaCard({
    required this.mahasiswa,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            mahasiswa.nama.isNotEmpty ? mahasiswa.nama[0].toUpperCase() : 'M',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
          ),
        ),
        title: Text(mahasiswa.nama, style: AppTextStyles.cardTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('NIM: ${mahasiswa.nim}', style: AppTextStyles.cardSubtitle),
            Text(mahasiswa.email, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(
                  mahasiswa.angkatan.isNotEmpty ? mahasiswa.angkatan : '-',
                  AppColors.infoLight,
                  AppColors.info,
                ),
                const SizedBox(width: 6),
                _buildBadge(
                  mahasiswa.status ? 'Aktif' : 'Nonaktif',
                  mahasiswa.status
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  mahasiswa.status ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: AppColors.textSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(mahasiswa.status ? 'Nonaktifkan' : 'Aktifkan'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Hapus', style: TextStyle(color: AppColors.error)),
            ),
          ],
          onSelected: (val) {
            if (val == 'edit') onEdit();
            if (val == 'toggle') onToggleStatus();
            if (val == 'delete') onDelete();
          },
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTextStyles.badge.copyWith(color: fg)),
    );
  }
}
