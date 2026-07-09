import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../services/auth/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      AppSnackbar.success(context, 'Tautan reset password telah dikirim.');
      Navigator.pop(context);
    } catch (_) {
      if (mounted)
        AppSnackbar.error(context, 'Gagal mengirim email reset password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lupa Password')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            size: 72,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Masukkan email akun Anda. Kami akan mengirim tautan untuk membuat password baru.',
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Email wajib diisi';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Kirim Tautan Reset',
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    ),
  );
}
