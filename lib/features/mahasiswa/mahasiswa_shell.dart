import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/mahasiswa_dashboard_provider.dart';
import '../../../providers/auth_provider.dart';
import 'dashboard/mahasiswa_dashboard_page.dart';
import 'tugas/mahasiswa_tugas_page.dart';
import 'presensi/mahasiswa_presensi_page.dart';
import 'nilai/mahasiswa_nilai_page.dart';
import 'profil/mahasiswa_profil_page.dart';

class MahasiswaShell extends StatefulWidget {
  const MahasiswaShell({super.key});

  @override
  State<MahasiswaShell> createState() => _MahasiswaShellState();
}

class _MahasiswaShellState extends State<MahasiswaShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MahasiswaDashboardPage(),
    MahasiswaTugasPage(),
    SizedBox.shrink(), // Placeholder for Absensi (which triggers Bottom Sheet directly)
    MahasiswaNilaiPage(),
    MahasiswaProfilPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MahasiswaDashboardProvider>().init();
      context.read<MahasiswaDashboardProvider>().listenNotifikasi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 2) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const MahasiswaAbsensiPage(),
                );
              } else {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment_rounded),
                label: 'Tugas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                activeIcon: Icon(Icons.location_on_rounded),
                label: 'Absensi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grade_outlined),
                activeIcon: Icon(Icons.grade_rounded),
                label: 'Nilai',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
