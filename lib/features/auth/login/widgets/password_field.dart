import 'package:flutter/material.dart';

import '../../../../core/utils/validator.dart';

class PasswordField extends StatelessWidget {
  final TextEditingController controller;

  final bool obscureText;

  final VoidCallback onToggle;

  const PasswordField({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,

      validator: AppValidator.password,

      obscureText: obscureText,

      decoration: InputDecoration(
        labelText: "Password",

        hintText: "Masukkan password",

        prefixIcon: const Icon(Icons.lock_outline),

        suffixIcon: IconButton(
          onPressed: onToggle,

          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}
