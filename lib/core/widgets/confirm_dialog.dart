import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Konfirmasi',
    this.cancelLabel = 'Batal',
    this.isDanger = false,
    required this.onConfirm,
  });

  /// Show dialog and return true if confirmed
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Konfirmasi',
    String cancelLabel = 'Batal',
    bool isDanger = false,
    required VoidCallback onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        onConfirm: onConfirm,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDanger
                  ? AppColors.errorLight
                  : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDanger ? Icons.delete_rounded : Icons.help_rounded,
              color: isDanger ? AppColors.error : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
        ],
      ),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton.outlined(
                label: cancelLabel,
                onPressed: () => Navigator.of(context).pop(false),
                height: 44,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isDanger
                  ? AppButton.danger(
                      label: confirmLabel,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        onConfirm();
                      },
                      height: 44,
                    )
                  : AppButton(
                      label: confirmLabel,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        onConfirm();
                      },
                      height: 44,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
