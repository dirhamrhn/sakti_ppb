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

class RuanganListPage extends StatefulWidget {
  final GedungModel gedung;
  const RuanganListPage({super.key, required this.gedung});

  @override
  State<RuanganListPage> createState() => _RuanganListPageState();
}

class _RuanganListPageState extends State<RuanganListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GedungProvider>().loadRuanganByGedung(widget.gedung.id);
    });
  }

  void _delete(RuanganModel ruangan) {
    ConfirmDialog.show(
      context,
      title: 'Hapus Ruangan',
      message: 'Yakin hapus "${ruangan.namaRuangan}"?',
      confirmLabel: 'Hapus',
      isDanger: true,
      onConfirm: () async {
        final success = await context.read<GedungProvider>().deleteRuangan(
          ruangan.id,
          widget.gedung.id,
        );
        if (!mounted) return;
        if (success) {
          AppSnackbar.success(context, 'Ruangan berhasil dihapus.');
        } else {
          AppSnackbar.error(context, 'Gagal menghapus ruangan.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GedungProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ruangan', style: const TextStyle(fontSize: 16)),
            Text(
              widget.gedung.nama,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(
              context,
              RouteName.adminRuanganForm,
              arguments: widget.gedung,
            ).then(
              (_) => context.read<GedungProvider>().loadRuanganByGedung(
                widget.gedung.id,
              ),
            ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Ruangan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoadingRuangan
          ? const Center(child: CircularProgressIndicator())
          : provider.ruanganList.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.door_front_door_rounded,
              title: 'Belum Ada Ruangan',
              description: 'Tap tombol + untuk menambah ruangan.',
            )
          : RefreshIndicator(
              onRefresh: () => context
                  .read<GedungProvider>()
                  .loadRuanganByGedung(widget.gedung.id),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: provider.ruanganList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = provider.ruanganList[i];
                  return _RuanganCard(
                    ruangan: r,
                    onEdit: () =>
                        Navigator.pushNamed(
                          context,
                          RouteName.adminRuanganForm,
                          arguments: {'gedung': widget.gedung, 'ruangan': r},
                        ).then(
                          (_) => context
                              .read<GedungProvider>()
                              .loadRuanganByGedung(widget.gedung.id),
                        ),
                    onDelete: () => _delete(r),
                  );
                },
              ),
            ),
    );
  }
}

class _RuanganCard extends StatelessWidget {
  final RuanganModel ruangan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuanganCard({
    required this.ruangan,
    required this.onEdit,
    required this.onDelete,
  });

  static const _tipiconMap = {
    'kelas': Icons.class_rounded,
    'lab': Icons.science_rounded,
    'aula': Icons.meeting_room_rounded,
    'seminar': Icons.event_seat_rounded,
  };

  static const _tipiColorMap = {
    'kelas': AppColors.primary,
    'lab': AppColors.warning,
    'aula': AppColors.info,
    'seminar': AppColors.secondary,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _tipiconMap[ruangan.tipe] ?? Icons.door_front_door_rounded;
    final color = _tipiColorMap[ruangan.tipe] ?? AppColors.textSecondary;

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
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(ruangan.namaRuangan, style: AppTextStyles.cardTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${ruangan.kodeRuangan}  •  Kapasitas ${ruangan.kapasitas}',
              style: AppTextStyles.cardSubtitle,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ruangan.tipe.toUpperCase(),
                    style: AppTextStyles.badge.copyWith(color: color),
                  ),
                ),
                if (ruangan.hasGpsLocation) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed_rounded,
                          color: AppColors.success,
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'GPS',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
      ),
    );
  }
}
