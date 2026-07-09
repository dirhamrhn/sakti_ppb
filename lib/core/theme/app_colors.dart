import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary ───────────────────────────────────────────────
  static const Color primary = Color(0xFF3B5BDB);
  static const Color primaryLight = Color(0xFF748FFC);
  static const Color primaryDark = Color(0xFF2F44A8);
  static const Color primaryContainer = Color(0xFFDBE4FF);
  static const Color onPrimaryContainer = Color(0xFF1A2980);

  // ─── Secondary ─────────────────────────────────────────────
  static const Color secondary = Color(0xFF6741D9);
  static const Color secondaryLight = Color(0xFF9775FA);
  static const Color secondaryContainer = Color(0xFFE5DBFF);

  // ─── Background & Surface ──────────────────────────────────
  static const Color background = Color(0xFFF4F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF0F4);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ─── Semantic ──────────────────────────────────────────────
  static const Color success = Color(0xFF2F9E44);
  static const Color successLight = Color(0xFFD3F9D8);
  static const Color warning = Color(0xFFF08C00);
  static const Color warningLight = Color(0xFFFFF3BF);
  static const Color error = Color(0xFFE03131);
  static const Color errorLight = Color(0xFFFFE3E3);
  static const Color info = Color(0xFF1971C2);
  static const Color infoLight = Color(0xFFD0EBFF);

  // ─── Text ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1C2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFFB0B7C3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ─── Border & Divider ──────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // ─── Role Badges ───────────────────────────────────────────
  static const Color badgeAdmin = Color(0xFF3B5BDB);
  static const Color badgeMahasiswa = Color(0xFF2F9E44);
  static const Color badgeDosen = Color(0xFFF08C00);
  static const Color badgeAsdos = Color(0xFF6741D9);

  // ─── Gradients ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B5BDB), Color(0xFF6741D9)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2980), Color(0xFF3B5BDB)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B5BDB), Color(0xFF748FFC)],
  );
}
