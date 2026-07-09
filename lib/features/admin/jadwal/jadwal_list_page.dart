import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../models/jadwal_model.dart';
import '../../../providers/jadwal_provider.dart';
import '../../../repositories/jadwal_repository.dart';

class JadwalListPage extends StatefulWidget {
  const JadwalListPage({super.key});

  @override
  State<JadwalListPage> createState() => _JadwalListPageState();
}

class _JadwalListPageState extends State<JadwalListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedHari = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JadwalProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _delete(JadwalModel jadwal) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Jadwal',
      message:
          'Yakin ingin menghapus jadwal "${jadwal.matakuliahNama}" hari ${jadwal.hari}?',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final success = await context.read<JadwalProvider>().delete(jadwal.id);
        if (!mounted) return;
        if (success) {
          AppSnackbar.success(context, 'Jadwal berhasil dihapus.');
        } else {
          AppSnackbar.error(context, 'Gagal menghapus jadwal.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JadwalProvider>();
    List<JadwalModel> filtered = provider.search(_searchQuery);
    if (_selectedHari.isNotEmpty) {
      filtered = filtered.where((j) => j.hari == _selectedHari).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jadwal Kuliah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          RouteName.adminJadwalForm,
        ).then((_) => context.read<JadwalProvider>().loadAll()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search + Filter
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari mata kuliah, ruangan, hari...',
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
                const SizedBox(height: 10),
                // Hari filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _HariChip(
                        label: 'Semua',
                        selected: _selectedHari.isEmpty,
                        onTap: () => setState(() => _selectedHari = ''),
                      ),
                      ...JadwalRepository.hariList.map(
                        (h) => _HariChip(
                          label: h,
                          selected: _selectedHari == h,
                          onTap: () => setState(() => _selectedHari = h),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} jadwal',
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
                    icon: Icons.schedule_rounded,
                    title: 'Belum Ada Jadwal',
                    description: 'Tap tombol + untuk menambah jadwal kuliah.',
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<JadwalProvider>().loadAll(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _JadwalCard(
                        jadwal: filtered[i],
                        onEdit: () => Navigator.pushNamed(
                          context,
                          RouteName.adminJadwalForm,
                          arguments: filtered[i].id,
                        ).then((_) => context.read<JadwalProvider>().loadAll()),
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

class _HariChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HariChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? AppColors.primary : Colors.white,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final JadwalModel jadwal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JadwalCard({
    required this.jadwal,
    required this.onEdit,
    required this.onDelete,
  });

  static const Map<String, Color> _hariColors = {
    'Senin': Color(0xFF3B5BDB),
    'Selasa': Color(0xFF2F9E44),
    'Rabu': Color(0xFFF08C00),
    'Kamis': Color(0xFF6741D9),
    'Jumat': Color(0xFFE03131),
    'Sabtu': Color(0xFF1971C2),
  };

  @override
  Widget build(BuildContext context) {
    final hariColor = _hariColors[jadwal.hari] ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Hari bar
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: hariColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
            child: Column(
              children: [
                Text(
                  jadwal.hari.substring(0, 3).toUpperCase(),
                  style: AppTextStyles.badge.copyWith(
                    color: hariColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.schedule_rounded, color: hariColor, size: 18),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${jadwal.matakuliahKode} — ${jadwal.matakuliahNama}',
                    style: AppTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${jadwal.jamMulai} – ${jadwal.jamSelesai}',
                    style: AppTextStyles.titleSmall.copyWith(color: hariColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.room_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(jadwal.ruangan, style: AppTextStyles.cardSubtitle),
                    ],
                  ),
                ],
              ),
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
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus', style: TextStyle(color: AppColors.error)),
              ),
            ],
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}
