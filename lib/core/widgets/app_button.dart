import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, outlined, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 52,
  });

  const AppButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  }) : variant = AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;

    switch (variant) {
      case AppButtonVariant.primary:
        return _buildPrimary(disabled);
      case AppButtonVariant.outlined:
        return _buildOutlined(disabled);
      case AppButtonVariant.text:
        return _buildText(disabled);
      case AppButtonVariant.danger:
        return _buildDanger(disabled);
    }
  }

  Widget _buildPrimary(bool disabled) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildChild(AppColors.textOnPrimary),
      ),
    );
  }

  Widget _buildOutlined(bool disabled) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(
            color: disabled ? AppColors.border : AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildChild(
          disabled ? AppColors.textDisabled : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildText(bool disabled) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: TextButton(
        onPressed: disabled ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildChild(
          disabled ? AppColors.textDisabled : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDanger(bool disabled) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.border,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildChild(AppColors.textOnPrimary),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      ),
    );
  }
}
