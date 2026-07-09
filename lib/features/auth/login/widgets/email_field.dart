import 'package:flutter/material.dart';

import '../../../../core/utils/validator.dart';

class EmailField extends StatelessWidget {
  final TextEditingController controller;

  const EmailField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,

      validator: AppValidator.email,

      keyboardType: TextInputType.emailAddress,

      decoration: const InputDecoration(
        labelText: "Email",

        hintText: "Masukkan email",

        prefixIcon: Icon(Icons.email_outlined),
      ),
    );
  }
}
