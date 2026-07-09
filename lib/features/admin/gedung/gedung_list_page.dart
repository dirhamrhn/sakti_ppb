import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../models/gedung_model.dart';
import '../../../providers/gedung_provider.dart';

class GedungListPage extends StatefulWidget {
  const GedungListPage({super.key});

  @override
  State<GedungListPage> createState() => _GedungListPageState();
}

class _GedungListPageState extends State<GedungListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GedungProvider>().loadAllGedung();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _delete(GedungModel gedung) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Gedung',
      message:
          'Yakin hapus "${gedung.nama}"? Semua ruangan di dalamnya juga akan dihapus.',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final success = await context.read<GedungProvider>().deleteGedung(
          gedung.id,
        );
        if (!mounted) return;
        if (success) {
          AppSnackbar.success(context, 'Gedung berhasil dihapus.');
        } else {
          AppSnackbar.error(context, 'Gagal menghapus gedung.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GedungProvider>();
    final filtered = provider.searchGedung(_searchQuery);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gedung & Ruangan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari gedung...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white54,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white70,
                ),
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          RouteName.adminGedungForm,
        ).then((_) => context.read<GedungProvider>().loadAllGedung()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Gedung'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoadingGedung
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.business_rounded,
              title: 'Belum Ada Gedung',
              description:
                  'Tambahkan gedung dan ruangan sebagai lokasi jadwal.',
            )
          : RefreshIndicator(
              onRefresh: () => context.read<GedungProvider>().loadAllGedung(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _GedungCard(
                  gedung: filtered[i],
                  onEdit: () => Navigator.pushNamed(
                    context,
                    RouteName.adminGedungForm,
                    arguments: filtered[i],
                  ).then((_) => context.read<GedungProvider>().loadAllGedung()),
                  onViewRuangan: () => Navigator.pushNamed(
                    context,
                    RouteName.adminRuanganList,
                    arguments: filtered[i],
                  ),
                  onDelete: () => _delete(filtered[i]),
                ),
              ),
            ),
    );
  }
}

class _GedungCard extends StatelessWidget {
  final GedungModel gedung;
  final VoidCallback onEdit;
  final VoidCallback onViewRuangan;
  final VoidCallback onDelete;

  const _GedungCard({
    required this.gedung,
    required this.onEdit,
    required this.onViewRuangan,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(gedung.nama, style: AppTextStyles.cardTitle),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    gedung.kode,
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                if (gedung.alamat.isNotEmpty)
                  Text(gedung.alamat, style: AppTextStyles.cardSubtitle),
                if (gedung.hasGpsLocation)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed_rounded,
                          color: AppColors.success,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${gedung.latitude.toStringAsFixed(4)}, ${gedung.longitude.toStringAsFixed(4)}',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
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
                const PopupMenuItem(value: 'edit', child: Text('Edit Gedung')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Hapus',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          InkWell(
            onTap: onViewRuangan,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.door_front_door_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kelola Ruangan',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
