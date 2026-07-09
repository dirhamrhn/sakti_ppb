import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/route_name.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward().then((_) => _initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loadCurrentUser();

    if (!mounted) return;

    // Minimum splash duration
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final user = authProvider.user;

    if (user == null) {
      Navigator.pushReplacementNamed(context, RouteName.login);
      return;
    }

    // Routing berdasarkan role
    switch (user.role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, RouteName.adminDashboard);
        break;
      case 'mahasiswa':
        Navigator.pushReplacementNamed(context, RouteName.mahasiswaDashboard);
        break;
      case 'dosen':
        Navigator.pushReplacementNamed(context, RouteName.dosenDashboard);
        break;
      case 'asdos':
        Navigator.pushReplacementNamed(context, RouteName.asdosDashboard);
        break;
      default:
        Navigator.pushReplacementNamed(context, RouteName.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Name
                    Text(
                      'SAKTI',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        fontSize: 36,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Sistem Akademik Transparan\ndan Terintegrasi',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading indicator
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
