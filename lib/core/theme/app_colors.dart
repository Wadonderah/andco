import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Modern Robin.do Style
  static const Color primary = Color(0xFF10B981); // Emerald green
  static const Color primaryDark = Color(0xFF059669); // Darker emerald
  static const Color primaryLight = Color(0xFF34D399); // Light emerald

  // Secondary Colors - Safety & Trust
  static const Color secondary = Color(0xFF2E7D32); // Safety Green
  static const Color secondaryDark = Color(0xFF1B5E20);
  static const Color secondaryLight = Color(0xFF4CAF50);

  // Accent Colors
  static const Color accent = Color(0xFF1976D2); // Trust Blue
  static const Color accentLight = Color(0xFF42A5F5);

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFF000000);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Additional Colors
  static const Color purple = Color(0xFF9C27B0);
  static const Color teal = Color(0xFF009688);
  static const Color orange = Color(0xFFFF5722);
  static const Color pink = Color(0xFFE91E63);
  static const Color indigo = Color(0xFF3F51B5);
  static const Color border = Color(0xFFE0E0E0);

  // Role-specific Colors - Modern & Distinct
  static const Color parentColor = Color(0xFF10B981); // Emerald green
  static const Color driverColor = Color(0xFF3B82F6); // Blue
  static const Color schoolAdminColor = Color(0xFF8B5CF6); // Purple
  static const Color superAdminColor = Color(0xFFEF4444); // Red

  // Dark theme colors (Robin.do style)
  static const Color darkBackground = Color(0xFF1A1A1A); // Very dark gray
  static const Color darkSurface = Color(0xFF2A2A2A); // Dark gray
  static const Color darkCard = Color(0xFF2A2A2A); // Same as surface

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFB800),
      Color(0xFFFFC933),
      Color(0xFFFFE082),
    ],
  );
}
