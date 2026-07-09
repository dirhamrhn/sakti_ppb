import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';

// Theme
import 'core/theme/app_theme.dart';

// Routes
import 'core/routes/app_routes.dart';
import 'core/routes/route_name.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/mahasiswa_provider.dart';
import 'providers/dosen_provider.dart';
import 'providers/asdos_provider.dart';
import 'providers/matakuliah_provider.dart';
import 'providers/kelas_provider.dart';
import 'providers/jadwal_provider.dart';
import 'providers/mahasiswa_dashboard_provider.dart';
import 'providers/gedung_provider.dart';
import 'providers/pertemuan_provider.dart';
import 'providers/dosen_dashboard_provider.dart';
import 'providers/asdos_dashboard_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://jxcqadkkefrvbgfraxaj.supabase.co',
    anonKey: 'sb_publishable_CETc-e0Jv9kY5kKdKq-uNg_PSEUqQhh',
  );

  runApp(const SaktiApp());
}

class SaktiApp extends StatelessWidget {
  const SaktiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MahasiswaProvider()),
        ChangeNotifierProvider(create: (_) => DosenProvider()),
        ChangeNotifierProvider(create: (_) => AsdosProvider()),
        ChangeNotifierProvider(create: (_) => MatakuliahProvider()),
        ChangeNotifierProvider(create: (_) => KelasProvider()),
        ChangeNotifierProvider(create: (_) => JadwalProvider()),
        ChangeNotifierProvider(create: (_) => MahasiswaDashboardProvider()),
        ChangeNotifierProvider(create: (_) => GedungProvider()),
        ChangeNotifierProvider(create: (_) => PertemuanProvider()),
        ChangeNotifierProvider(create: (_) => DosenDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AsdosDashboardProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SAKTI',
        theme: AppTheme.lightTheme,
        initialRoute: RouteName.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
