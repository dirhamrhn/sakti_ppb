import 'package:flutter/material.dart';

class ForgotPassword extends StatelessWidget {
  final VoidCallback onTap;

  const ForgotPassword({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,

      child: TextButton(onPressed: onTap, child: const Text("Lupa Password?")),
    );
  }
}
