import 'package:flutter/material.dart';

import '../../features/auth/login/login_page.dart';
import '../../features/auth/forgot_password/forgot_password_page.dart';
import '../../features/splash/splash_screen.dart';

// Admin
import '../../features/admin/dashboard/dashboard_page.dart';
import '../../features/admin/mahasiswa/mahasiswa_list_page.dart';
import '../../features/admin/mahasiswa/mahasiswa_form_page.dart';
import '../../features/admin/dosen/dosen_list_page.dart';
import '../../features/admin/dosen/dosen_form_page.dart';
import '../../features/admin/asdos/asdos_list_page.dart';
import '../../features/admin/asdos/asdos_form_page.dart';
import '../../features/admin/matakuliah/matakuliah_list_page.dart';
import '../../features/admin/matakuliah/matakuliah_form_page.dart';
import '../../features/admin/kelas/kelas_list_page.dart';
import '../../features/admin/kelas/kelas_form_page.dart';
import '../../features/admin/kelas/kelas_detail_page.dart';
import '../../features/admin/jadwal/jadwal_list_page.dart';
import '../../features/admin/jadwal/jadwal_form_page.dart';
import '../../features/admin/gedung/gedung_list_page.dart';
import '../../features/admin/gedung/gedung_form_page.dart';
import '../../features/admin/gedung/ruangan_list_page.dart';
import '../../features/admin/gedung/ruangan_form_page.dart';
import '../../models/gedung_model.dart';

// Mahasiswa
import '../../features/mahasiswa/mahasiswa_shell.dart';
import '../../features/mahasiswa/nilai/mahasiswa_nilai_page.dart';

// Dosen
import '../../features/dosen/dosen_dashboard_page.dart';
import '../../features/dosen/kelas/dosen_kelas_detail_page.dart';

// Asdos
import '../../features/asdos/asdos_dashboard_page.dart';

import '../routes/route_name.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // ─── Core ──────────────────────────────────────────────
      case RouteName.splash:
        return _route(const SplashScreen());

      case RouteName.login:
        return _route(const LoginPage());

      case RouteName.forgotPassword:
        return _route(const ForgotPasswordPage());

      // ─── Admin ─────────────────────────────────────────────
      case RouteName.adminDashboard:
        return _route(const DashboardPage());

      // Mahasiswa
      case RouteName.adminMahasiswaList:
        return _route(const MahasiswaListPage());

      case RouteName.adminMahasiswaForm:
        return _route(
          MahasiswaFormPage(mahasiswaId: args is String ? args : null),
        );

      // Dosen
      case RouteName.adminDosenList:
        return _route(const DosenListPage());

      case RouteName.adminDosenForm:
        return _route(DosenFormPage(dosenId: args is String ? args : null));

      // Asdos
      case RouteName.adminAsdosList:
        return _route(const AsdosListPage());

      case RouteName.adminAsdosForm:
        return _route(AsdosFormPage(asdosId: args is String ? args : null));

      // Mata Kuliah
      case RouteName.adminMatakuliahList:
        return _route(const MatakuliahListPage());

      case RouteName.adminMatakuliahForm:
        return _route(
          MatakuliahFormPage(matakuliahId: args is String ? args : null),
        );

      // Kelas
      case RouteName.adminKelasList:
        return _route(const KelasListPage());

      case RouteName.adminKelasForm:
        return _route(KelasFormPage(kelasId: args is String ? args : null));

      case RouteName.adminKelasDetail:
        return _route(KelasDetailPage(kelasId: args as String));

      // Jadwal
      case RouteName.adminJadwalList:
        return _route(const JadwalListPage());

      case RouteName.adminJadwalForm:
        return _route(JadwalFormPage(jadwalId: args is String ? args : null));

      case RouteName.adminGedungList:
        return _route(const GedungListPage());

      case RouteName.adminGedungForm:
        return _route(
          GedungFormPage(gedung: args is GedungModel ? args : null),
        );

      case RouteName.adminRuanganList:
        if (args is! GedungModel) {
          return _invalidArguments('Data gedung wajib diisi');
        }
        return _route(RuanganListPage(gedung: args));

      case RouteName.adminRuanganForm:
        if (args is! Map<String, dynamic> || args['gedung'] is! GedungModel) {
          return _invalidArguments('Data gedung wajib diisi');
        }
        return _route(
          RuanganFormPage(
            gedung: args['gedung'] as GedungModel,
            ruangan: args['ruangan'] is RuanganModel
                ? args['ruangan'] as RuanganModel
                : null,
          ),
        );

      // ─── Mahasiswa ─────────────────────────────────────────
      case RouteName.mahasiswaDashboard:
        return _route(const MahasiswaShell());

      case RouteName.mahasiswaNilai:
        return _route(const MahasiswaNilaiPage());

      // ─── Dosen ─────────────────────────────────────────────
      case RouteName.dosenDashboard:
        return _route(const DosenDashboardPage());

      case RouteName.dosenKelasDetail:
        return _route(DosenKelasDetailPage(kelasId: args as String));

      // ─── Asdos ─────────────────────────────────────────────
      case RouteName.asdosDashboard:
        return _route(const AsdosDashboardPage());

      // ─── 404 ───────────────────────────────────────────────
      default:
        return _route(
          Scaffold(
            body: Center(
              child: Text(
                '404\nHalaman Tidak Ditemukan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ),
          ),
        );
    }
  }

  static MaterialPageRoute _route(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }

  static MaterialPageRoute _invalidArguments(String message) =>
      _route(Scaffold(body: Center(child: Text(message))));
}
