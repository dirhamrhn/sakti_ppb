import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final bool isLoading;

  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,

      height: 55,

      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,

        child: isLoading
            ? const SizedBox(
                width: 24,

                height: 24,

                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text("MASUK", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
