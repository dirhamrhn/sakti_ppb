import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../models/matakuliah_model.dart';
import '../../../providers/matakuliah_provider.dart';

class MatakuliahListPage extends StatefulWidget {
  const MatakuliahListPage({super.key});

  @override
  State<MatakuliahListPage> createState() => _MatakuliahListPageState();
}

class _MatakuliahListPageState extends State<MatakuliahListPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  // Tab: 0=Semua, 1=Teori, 2=T+P
  final List<String> _tabLabels = ['Semua', 'Teori', 'T + Praktikum'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatakuliahProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<MatakuliahModel> _getFiltered(MatakuliahProvider provider) {
    List<MatakuliahModel> result;
    switch (_tabController.index) {
      case 1:
        result = provider.listTeori;
        break;
      case 2:
        result = provider.listPraktikum;
        break;
      default:
        result = provider.list;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (m) =>
                m.nama.toLowerCase().contains(q) ||
                m.kode.toLowerCase().contains(q) ||
                m.dosenNama.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  void _delete(MatakuliahModel mk) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Mata Kuliah',
      message: 'Yakin ingin menghapus "${mk.nama}"?',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final success = await context.read<MatakuliahProvider>().delete(mk.id);
        if (!mounted) return;
        if (success) {
          AppSnackbar.success(context, 'Mata kuliah berhasil dihapus.');
        } else {
          AppSnackbar.error(context, 'Gagal menghapus mata kuliah.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatakuliahProvider>();
    final filtered = _getFiltered(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mata Kuliah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, kode, atau dosen...',
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
              TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                tabs: _tabLabels.map((t) => Tab(text: t)).toList(),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          RouteName.adminMatakuliahForm,
        ).then((_) => context.read<MatakuliahProvider>().loadAll()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} mata kuliah ditemukan',
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
                    icon: Icons.book_rounded,
                    title: 'Belum Ada Mata Kuliah',
                    description: 'Tap tombol + untuk menambah mata kuliah.',
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        context.read<MatakuliahProvider>().loadAll(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _MatakuliahCard(
                        mk: filtered[i],
                        onEdit: () =>
                            Navigator.pushNamed(
                              context,
                              RouteName.adminMatakuliahForm,
                              arguments: filtered[i].id,
                            ).then(
                              (_) =>
                                  context.read<MatakuliahProvider>().loadAll(),
                            ),
                        onDelete: () => _delete(filtered[i]),
                        onToggleStatus: () => context
                            .read<MatakuliahProvider>()
                            .toggleStatus(filtered[i].id, filtered[i].status),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatakuliahCard extends StatelessWidget {
  final MatakuliahModel mk;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _MatakuliahCard({
    required this.mk,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isPraktikum = mk.hasPraktikum;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isPraktikum
                ? AppColors.warningLight
                : AppColors.successLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPraktikum ? Icons.science_rounded : Icons.menu_book_rounded,
            color: isPraktikum ? AppColors.warning : AppColors.success,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(mk.nama, style: AppTextStyles.cardTitle)),
            const SizedBox(width: 6),
            // Badge jenis MK
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isPraktikum
                    ? AppColors.warningLight
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPraktikum ? 'T+P' : 'TEORI',
                style: AppTextStyles.badge.copyWith(
                  color: isPraktikum ? AppColors.warning : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${mk.kode}  •  ${mk.dosenNama.isNotEmpty ? mk.dosenNama : "Belum ada dosen"}',
              style: AppTextStyles.cardSubtitle,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _badge(
                  '${mk.sks} SKS',
                  AppColors.primaryContainer,
                  AppColors.primary,
                ),
                const SizedBox(width: 6),
                _badge(
                  'Sem ${mk.semester}',
                  AppColors.secondaryContainer,
                  AppColors.secondary,
                ),
                const SizedBox(width: 6),
                _badge(
                  mk.status ? 'Aktif' : 'Nonaktif',
                  mk.status ? AppColors.successLight : AppColors.errorLight,
                  mk.status ? AppColors.success : AppColors.error,
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
              child: Text(mk.status ? 'Nonaktifkan' : 'Aktifkan'),
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

  Widget _badge(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: AppTextStyles.badge.copyWith(color: fg)),
  );
}
