import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/tugas_model.dart';
import '../../../../providers/mahasiswa_dashboard_provider.dart';
import 'mahasiswa_tugas_detail_page.dart';

class MahasiswaTugasPage extends StatefulWidget {
  const MahasiswaTugasPage({super.key});

  @override
  State<MahasiswaTugasPage> createState() => _MahasiswaTugasPageState();
}

class _MahasiswaTugasPageState extends State<MahasiswaTugasPage> {
  bool _showSelesai = false; // false = Belum Selesai, true = Selesai
  String _selectedCategory = 'Semua Kategori'; // 'Semua Kategori', 'Tugas', 'Laporan Praktikum'

  // Map to store expansion state of each group.
  final Map<String, bool> _expandedGroups = {
    'Lewat Tenggat': true,
    'Sebelumnya': true,
    'Hari ini': true,
    'Besok': true,
    'Minggu Ini': true,
    'Minggu Depan': true,
    'Nanti': true,
  };

  String _getDeadlineGroup(TugasModel tugas, bool isSubmitted) {
    final now = DateTime.now();
    final deadlineDate = tugas.deadline.toDate();

    if (deadlineDate.isBefore(now)) {
      return isSubmitted ? 'Sebelumnya' : 'Lewat Tenggat';
    }

    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (deadlineDate.year == today.year &&
        deadlineDate.month == today.month &&
        deadlineDate.day == today.day) {
      return 'Hari ini';
    } else if (deadlineDate.year == tomorrow.year &&
        deadlineDate.month == tomorrow.month &&
        deadlineDate.day == tomorrow.day) {
      return 'Besok';
    }

    final int currentWeekday = today.weekday;
    final endOfThisWeek = today.add(Duration(days: 7 - currentWeekday, hours: 23, minutes: 59, seconds: 59));
    final endOfNextWeek = endOfThisWeek.add(const Duration(days: 7));

    if (deadlineDate.isBefore(endOfThisWeek) || deadlineDate.isAtSameMomentAs(endOfThisWeek)) {
      return 'Minggu Ini';
    } else if (deadlineDate.isBefore(endOfNextWeek) || deadlineDate.isAtSameMomentAs(endOfNextWeek)) {
      return 'Minggu Depan';
    } else {
      return 'Nanti';
    }
  }

  String _getTaskCategory(TugasModel tugas) {
    final judulLower = tugas.judul.toLowerCase();
    final deskripsiLower = tugas.deskripsi.toLowerCase();

    if (judulLower.contains('laporan') ||
        judulLower.contains('praktikum') ||
        deskripsiLower.contains('laporan') ||
        deskripsiLower.contains('praktikum')) {
      return 'Laporan Praktikum';
    }
    return 'Tugas';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaDashboardProvider>();

    // Calculate statistics
    final allTasks = provider.tugasList;
    final totalTugasCount = allTasks.length;
    final selesaiCount = allTasks.where((t) => provider.hasSubmitted(t.id)).length;
    final belumSelesaiCount = totalTugasCount - selesaiCount;

    // Filter by completed/uncompleted status
    final statusFilteredTasks = allTasks.where((t) {
      final isSubmitted = provider.hasSubmitted(t.id);
      return isSubmitted == _showSelesai;
    }).toList();

    // Filter by category
    final filteredTasks = statusFilteredTasks.where((t) {
      if (_selectedCategory == 'Semua Kategori') return true;
      return _getTaskCategory(t) == _selectedCategory;
    }).toList();

    // Grouping tasks by deadline group
    final Map<String, List<TugasModel>> groupedTasks = {
      if (!_showSelesai) 'Lewat Tenggat': [],
      if (_showSelesai) 'Sebelumnya': [],
      'Hari ini': [],
      'Besok': [],
      'Minggu Ini': [],
      'Minggu Depan': [],
      'Nanti': [],
    };

    for (final tugas in filteredTasks) {
      final isSubmitted = provider.hasSubmitted(tugas.id);
      final group = _getDeadlineGroup(tugas, isSubmitted);
      if (groupedTasks.containsKey(group)) {
        groupedTasks[group]!.add(tugas);
      } else {
        groupedTasks[group] = [tugas];
      }
    }

    // Filter out groups with 0 items to clean up the UI
    final visibleGroups = groupedTasks.entries.where((e) => e.value.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: provider.isLoading && !provider.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.loadAll,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // 1. STATS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F5132), Color(0xFF1B6A3E)], // Forest green theme
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F5132).withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem('$totalTugasCount', 'Total Tugas'),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        Expanded(
                          child: _buildStatItem('$belumSelesaiCount', 'Belum Selesai'),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        Expanded(
                          child: _buildStatItem('$selesaiCount', 'Selesai'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. PILL SWITCHER (Belum Selesai / Selesai)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _showSelesai = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: !_showSelesai ? AppColors.success : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Belum Selesai',
                                style: TextStyle(
                                  color: !_showSelesai ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showSelesai = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: _showSelesai ? AppColors.success : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Selesai',
                                style: TextStyle(
                                  color: _showSelesai ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. DROPDOWN CATEGORY FILTER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        items: <String>['Semua Kategori', 'Tugas', 'Laporan Praktikum']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. ACCORDIONS / TASK LIST
                  if (visibleGroups.isEmpty)
                    EmptyStateWidget(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'Tidak Ada Tugas',
                      description: allTasks.isEmpty
                          ? 'Tidak ada tugas yang aktif saat ini.'
                          : 'Tidak ada tugas dalam kategori ini.',
                    )
                  else
                    ...visibleGroups.map((entry) {
                      final groupName = entry.key;
                      final tasks = entry.value;
                      final isExpanded = _expandedGroups[groupName] ?? true;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Accordion
                            _buildGroupHeader(
                              groupName,
                              tasks.length,
                              isExpanded,
                              () {
                                setState(() {
                                  _expandedGroups[groupName] = !isExpanded;
                                });
                              },
                            ),

                            // Konten Tugas (List) jika expanded
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: tasks.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final tugas = tasks[idx];
                                    final isSubmitted = provider.hasSubmitted(tugas.id);
                                    final isOverdue = tugas.deadline.toDate().isBefore(DateTime.now());

                                    return _TugasListCard(
                                      tugas: tugas,
                                      isSubmitted: isSubmitted,
                                      isOverdue: isOverdue,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MahasiswaTugasDetailPage(
                                              tugas: tugas,
                                              kelasId: tugas.kelasId,
                                            ),
                                          ),
                                        ).then((_) => provider.loadAll());
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupHeader(
    String groupName,
    int count,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    final isOverdueGroup = groupName == 'Lewat Tenggat';
    final headerBgColor = isOverdueGroup
        ? AppColors.errorLight.withOpacity(0.4)
        : AppColors.surface;
    final textColor = isOverdueGroup ? AppColors.error : AppColors.textPrimary;
    final badgeBgColor = isOverdueGroup ? AppColors.error : AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: headerBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                groupName,
                style: AppTextStyles.titleMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: textColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TugasListCard extends StatelessWidget {
  final TugasModel tugas;
  final bool isSubmitted;
  final bool isOverdue;
  final VoidCallback onTap;

  const _TugasListCard({
    required this.tugas,
    required this.isSubmitted,
    required this.isOverdue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineDate = tugas.deadline.toDate();
    final formattedDeadline = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(deadlineDate);

    // Status styling
    Color badgeColor;
    Color textColor;
    String statusText;

    if (isSubmitted) {
      badgeColor = AppColors.successLight;
      textColor = AppColors.success;
      statusText = 'Selesai';
    } else if (isOverdue) {
      badgeColor = AppColors.errorLight;
      textColor = AppColors.error;
      statusText = 'Terlambat';
    } else {
      badgeColor = AppColors.warningLight;
      textColor = AppColors.warning;
      statusText = 'Belum Selesai';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Matakuliah & Badge Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${tugas.matakuliahKode} • ${tugas.kelasNama}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyles.badge.copyWith(color: textColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Judul Tugas
            Text(
              tugas.judul,
              style: AppTextStyles.cardTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            const Divider(height: 1, thickness: 1, color: AppColors.border),
            const SizedBox(height: 12),

            // Deadline & Dosen
            Row(
              children: [
                const Icon(
                  Icons.alarm_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Batas: $formattedDeadline',
                    style: AppTextStyles.cardSubtitle.copyWith(
                      color: isOverdue && !isSubmitted ? AppColors.error : AppColors.textSecondary,
                      fontWeight: isOverdue && !isSubmitted ? FontWeight.w500 : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tugas.dosenNama,
                    style: AppTextStyles.cardSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
