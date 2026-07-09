import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../models/dosen_model.dart';
import '../../../providers/dosen_provider.dart';

class DosenListPage extends StatefulWidget {
  const DosenListPage({super.key});

  @override
  State<DosenListPage> createState() => _DosenListPageState();
}

class _DosenListPageState extends State<DosenListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DosenProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(DosenModel dosen) async {
    ConfirmDialog.show(
      context,
      title: 'Hapus Dosen',
      message: 'Yakin ingin menghapus data "${dosen.nama}"?',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final success = await context.read<DosenProvider>().delete(dosen.uid);
        if (!mounted) return;
        if (success) {
          AppSnackbar.success(context, 'Dosen berhasil dihapus.');
        } else {
          AppSnackbar.error(
            context,
            context.read<DosenProvider>().errorMessage ?? 'Gagal.',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();
    final filtered = provider.search(_searchQuery);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Data Dosen'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          RouteName.adminDosenForm,
        ).then((_) => context.read<DosenProvider>().loadAll()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari nama, NIDN, atau email...',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} dosen',
                  style: AppTextStyles.labelMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.person_rounded,
                    title: 'Belum Ada Dosen',
                    description: 'Tap tombol + untuk menambah dosen baru.',
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<DosenProvider>().loadAll(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _DosenCard(
                        dosen: filtered[i],
                        onEdit: () => Navigator.pushNamed(
                          context,
                          RouteName.adminDosenForm,
                          arguments: filtered[i].uid,
                        ).then((_) => context.read<DosenProvider>().loadAll()),
                        onDelete: () => _delete(filtered[i]),
                        onToggleStatus: () => context
                            .read<DosenProvider>()
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

class _DosenCard extends StatelessWidget {
  final DosenModel dosen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _DosenCard({
    required this.dosen,
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
          backgroundColor: const Color(0xFFFFF3BF),
          child: Text(
            dosen.nama.isNotEmpty ? dosen.nama[0].toUpperCase() : 'D',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.warning),
          ),
        ),
        title: Text(dosen.nama, style: AppTextStyles.cardTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('NIDN: ${dosen.nidn}', style: AppTextStyles.cardSubtitle),
            Text(dosen.jabatan, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: dosen.status
                    ? AppColors.successLight
                    : AppColors.errorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                dosen.status ? 'Aktif' : 'Nonaktif',
                style: AppTextStyles.badge.copyWith(
                  color: dosen.status ? AppColors.success : AppColors.error,
                ),
              ),
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
              child: Text(dosen.status ? 'Nonaktifkan' : 'Aktifkan'),
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
}
