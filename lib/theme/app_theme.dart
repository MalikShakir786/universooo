import 'package:flutter/material.dart';
import '../models/application_model.dart';

class AppTheme {
  // macOS Accent colors
  static const Color macosBlue = Color(0xFF007AFF);
  static const Color macosIndigo = Color(0xFF5856D6);
  static const Color macosPurple = Color(0xFFAF52DE);
  static const Color macosPink = Color(0xFFFF2D55);
  static const Color macosRed = Color(0xFFFF3B30);
  static const Color macosOrange = Color(0xFFFF9500);
  static const Color macosYellow = Color(0xFFFFCC00);
  static const Color macosGreen = Color(0xFF34C759);
  static const Color macosTeal = Color(0xFF5AC8FA);

  // Light Mode Palette
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSidebar = Color(0xFFEBEFF5);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF121316);
  static const Color darkSidebar = Color(0xFF181A20);
  static const Color darkCard = Color(0xFF20232B);
  static const Color darkBorder = Color(0xFF2E3340);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: macosBlue,
    colorScheme: const ColorScheme.light(
      primary: macosBlue,
      secondary: macosIndigo,
      surface: lightCard,
      error: macosRed,
      onPrimary: Colors.white,
      onSurface: lightTextPrimary,
    ),
    fontFamily: '-apple-system',
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: lightBorder,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: macosBlue, width: 1.5),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: macosBlue,
    colorScheme: const ColorScheme.dark(
      primary: macosBlue,
      secondary: macosIndigo,
      surface: darkCard,
      error: macosRed,
      onPrimary: Colors.white,
      onSurface: darkTextPrimary,
    ),
    fontFamily: '-apple-system',
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF282B35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: macosBlue, width: 1.5),
      ),
    ),
  );

  // Status Badge Styling Helper
  static (Color bg, Color fg) getStatusColors(String status, bool isDark) {
    switch (status.trim().toLowerCase()) {
      case 'researching':
        return isDark
            ? (const Color(0xFF2D3748), const Color(0xFFA0AEC0))
            : (const Color(0xFFEDF2F7), const Color(0xFF4A5568));
      case 'interested':
        return isDark
            ? (const Color(0xFF1E3A8A).withAlpha(100), const Color(0xFF93C5FD))
            : (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8));
      case 'shortlisted':
        return isDark
            ? (const Color(0xFF4C1D95).withAlpha(100), const Color(0xFFC4B5FD))
            : (const Color(0xFFF5F3FF), const Color(0xFF6D28D9));
      case 'preparing':
      case 'documents pending':
        return isDark
            ? (const Color(0xFF78350F).withAlpha(100), const Color(0xFFFCD34D))
            : (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      case 'ready to apply':
        return isDark
            ? (const Color(0xFF134E4A).withAlpha(100), const Color(0xFF5EEAD4))
            : (const Color(0xFFCCFBF1), const Color(0xFF0F766E));
      case 'applied':
        return isDark
            ? (const Color(0xFF1E40AF).withAlpha(100), const Color(0xFF60A5FA))
            : (const Color(0xFFDBEAFE), const Color(0xFF1E40AF));
      case 'under review':
        return isDark
            ? (const Color(0xFF581C87).withAlpha(100), const Color(0xFFD8B4FE))
            : (const Color(0xFFF3E8FF), const Color(0xFF7E22CE));
      case 'interview':
        return isDark
            ? (const Color(0xFF701A75).withAlpha(100), const Color(0xFFF472B6))
            : (const Color(0xFFFCE7F3), const Color(0xFFBE185D));
      case 'conditional offer':
      case 'unconditional offer':
      case 'accepted':
        return isDark
            ? (const Color(0xFF064E3B).withAlpha(100), const Color(0xFF6EE7B7))
            : (const Color(0xFFD1FAE5), const Color(0xFF047857));
      case 'rejected':
        return isDark
            ? (const Color(0xFF7F1D1D).withAlpha(100), const Color(0xFFFCA5A5))
            : (const Color(0xFFFEE2E2), const Color(0xFFB91C1C));
      case 'waitlisted':
        return isDark
            ? (const Color(0xFF713F12).withAlpha(100), const Color(0xFFFDE047))
            : (const Color(0xFFFEF9C3), const Color(0xFFA16207));
      case 'withdrawn':
        return isDark
            ? (const Color(0xFF374151), const Color(0xFF9CA3AF))
            : (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
      default:
        return isDark
            ? (const Color(0xFF334155), const Color(0xFFCBD5E1))
            : (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
  }

  // Urgency Badge Styling Helper
  static (Color bg, Color fg, String label) getUrgencyColors(ApplicationUrgency urgency, bool isDark) {
    switch (urgency) {
      case ApplicationUrgency.normal:
        return (
          isDark ? const Color(0xFF064E3B).withAlpha(120) : const Color(0xFFE8F5E9),
          isDark ? const Color(0xFF6EE7B7) : const Color(0xFF2E7D32),
          'Normal (>30d)',
        );
      case ApplicationUrgency.attention:
        return (
          isDark ? const Color(0xFF1E3A8A).withAlpha(120) : const Color(0xFFE3F2FD),
          isDark ? const Color(0xFF93C5FD) : const Color(0xFF1565C0),
          'Attention (15-30d)',
        );
      case ApplicationUrgency.urgent:
        return (
          isDark ? const Color(0xFF78350F).withAlpha(120) : const Color(0xFFFFF3E0),
          isDark ? const Color(0xFFFCD34D) : const Color(0xFFE65100),
          'Urgent (7-14d)',
        );
      case ApplicationUrgency.critical:
        return (
          isDark ? const Color(0xFF7F1D1D).withAlpha(140) : const Color(0xFFFFEBEE),
          isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC62828),
          'Critical (0-6d)',
        );
      case ApplicationUrgency.overdue:
        return (
          isDark ? const Color(0xFF450A0A) : const Color(0xFFFFCDD2),
          isDark ? const Color(0xFFF87171) : const Color(0xFFB71C1C),
          'Overdue',
        );
      case ApplicationUrgency.none:
        return (
          isDark ? const Color(0xFF26262E) : const Color(0xFFF5F5F5),
          isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
          'No Deadline',
        );
    }
  }
}
