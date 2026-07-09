import 'package:flutter/material.dart';

class RememberMe extends StatelessWidget {
  final bool value;

  final ValueChanged<bool?> onChanged;

  const RememberMe({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,

      onChanged: onChanged,

      title: const Text("Ingat Saya"),

      controlAffinity: ListTileControlAffinity.leading,

      contentPadding: EdgeInsets.zero,
    );
  }
}
