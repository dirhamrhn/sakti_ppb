import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../models/kelas_model.dart';
import '../../../providers/kelas_provider.dart';
import 'package:sakti_final/core/utils/formatter.dart';

class KelasListPage extends StatefulWidget {
  const KelasListPage({super.key});

  @override
  State<KelasListPage> createState() => _KelasListPageState();
}

class _KelasListPageState extends State<KelasListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KelasProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _delete(KelasModel kelas) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Kelas',
      message:
          'Yakin ingin menghapus kelas "${kelas.matakuliahNama} - ${kelas.namaKelas}"?\nSemua data enrollment mahasiswa juga akan dihapus.',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final success = await context.read<KelasProvider>().delete(kelas.id);
        if (!mounted) return;
        if (success) {
          AppSnackbar.success(context, 'Kelas berhasil dihapus.');
        } else {
          AppSnackbar.error(context, 'Gagal menghapus kelas.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KelasProvider>();
    final filtered = provider.search(_searchQuery);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          RouteName.adminKelasForm,
        ).then((_) => context.read<KelasProvider>().loadAll()),
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
                hintText: 'Cari kelas, mata kuliah, atau dosen...',
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
                  '${filtered.length} kelas',
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
                    icon: Icons.class_rounded,
                    title: 'Belum Ada Kelas',
                    description: 'Tap tombol + untuk menambah kelas baru.',
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<KelasProvider>().loadAll(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _KelasCard(
                        kelas: filtered[i],
                        onDetail: () => Navigator.pushNamed(
                          context,
                          RouteName.adminKelasDetail,
                          arguments: filtered[i].id,
                        ).then((_) => context.read<KelasProvider>().loadAll()),
                        onEdit: () => Navigator.pushNamed(
                          context,
                          RouteName.adminKelasForm,
                          arguments: filtered[i].id,
                        ).then((_) => context.read<KelasProvider>().loadAll()),
                        onDelete: () => _delete(filtered[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KelasCard extends StatelessWidget {
  final KelasModel kelas;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KelasCard({
    required this.kelas,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetail,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.class_rounded,
                color: AppColors.info,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${kelas.matakuliahNama} - ${ClassNameFormatter.format(kelas.namaKelas)}',
                    style: AppTextStyles.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kelas.dosenNama.isNotEmpty
                        ? kelas.dosenNama
                        : 'Dosen belum diassign',
                    style: AppTextStyles.cardSubtitle,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _badge(
                        '${kelas.jumlahMahasiswa}/${kelas.kapasitas} mhs',
                        AppColors.primaryContainer,
                        AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      if (kelas.asdosIds.isNotEmpty)
                        _badge(
                          '${kelas.asdosIds.length} asdos',
                          AppColors.secondaryContainer,
                          AppColors.secondary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'detail',
                  child: Text('Lihat Detail'),
                ),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Hapus',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'detail') onDetail();
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: AppTextStyles.badge.copyWith(color: fg)),
  );
}
