import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── Display ───────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.12,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static TextStyle get displaySmall => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.22,
  );

  // ─── Heading ───────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.28,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.33,
  );

  // ─── Title ─────────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.27,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.42,
    letterSpacing: 0.1,
  );

  // ─── Body ──────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.42,
    letterSpacing: 0.25,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // ─── Label ─────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.42,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ─── Custom App Styles ─────────────────────────────────────
  static TextStyle get appBarTitle => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary.withOpacity(0.8),
  );

  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get cardSubtitle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get statNumber => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnPrimary,
    height: 1.0,
  );

  static TextStyle get statLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textOnPrimary.withOpacity(0.8),
  );

  static TextStyle get badge => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  static TextStyle get emptyStateTitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle get emptyStateBody => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDisabled,
    height: 1.5,
  );
}
