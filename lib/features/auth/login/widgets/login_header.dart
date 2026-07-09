import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset("assets/images/logo.png", width: 120),

        const SizedBox(height: 24),

        const Text(
          "Selamat Datang",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Text(
          "Silakan masuk menggunakan akun SAKTI",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
