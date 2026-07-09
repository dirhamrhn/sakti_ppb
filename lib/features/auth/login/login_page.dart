import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.user!;
      AppSnackbar.success(context, 'Selamat datang, ${user.nama}!');

      // Redirect berdasarkan role
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
          AppSnackbar.error(context, 'Role tidak dikenali.');
      }
    } else {
      AppSnackbar.error(
        context,
        authProvider.errorMessage ??
            'Login gagal. Periksa kembali kredensial Anda.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─── Header ──────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SAKTI',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sistem Akademik Transparan dan Terintegrasi',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Form ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Masuk ke Akun Anda',
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gunakan email dan password yang telah didaftarkan',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 28),

                      // Email
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'contoh@kampus.ac.id',
                        prefixIcon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(v.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: '••••••••',
                        prefixIcon: Icons.lock_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        suffix: GestureDetector(
                          onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (v.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Login Button
                      AppButton(
                        label: 'Masuk',
                        isLoading: authProvider.isLoading,
                        onPressed: authProvider.isLoading ? null : _login,
                        icon: Icons.login_rounded,
                      ),

                      const SizedBox(height: 20),

                      // Info
                      Center(
                        child: Text(
                          'Hubungi administrator jika mengalami masalah login',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
