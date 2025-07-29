// File: lib/providers/app_colors.dart
// Note: This file should be placed in the 'lib/providers/' directory.
import 'package:flutter/material.dart';

class AppColors {
  // Primary Green Colors - Premium Look
  static const Color primaryGreen = Color(0xFF00C851); // Bright premium green
  static const Color primaryGreenDark = Color(0xFF00A142); // Darker green for pressed states
  static const Color primaryGreenLight = Color(0xFF4CAF50); // Light green for accents
  static const Color accentGreen = Color(0xFF1DB954); // Spotify-like green
  
  // Black Colors - Premium Dark Theme
  static const Color primaryBlack = Color(0xFF0A0A0A); // Pure premium black
  static const Color surfaceBlack = Color(0xFF1A1A1A); // Card/surface black
  static const Color backgroundBlack = Color(0xFF121212); // Background black
  static const Color darkGrey = Color(0xFF2A2A2A); // Dark grey for elements
  
  // White Colors - Light Theme
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color lightGrey = Color(0xFFF5F5F7);
  static const Color surfaceWhite = Color(0xFFFAFAFA);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFFB3B3B3);
  
  // Status Colors
  static const Color success = Color(0xFF00C851);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFAA00);
  static const Color info = Color(0xFF33B5E5);
  
  // Gradient Colors
  static const List<Color> premiumGreenGradient = [
    Color(0xFF00C851),
    Color(0xFF1DB954),
    Color(0xFF4CAF50),
  ];
  
  static const List<Color> premiumBlackGradient = [
    Color(0xFF0A0A0A),
    Color(0xFF1A1A1A),
    Color(0xFF2A2A2A),
  ];
  
  // Light Theme Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: primaryGreen,
    primaryContainer: primaryGreenLight,
    secondary: accentGreen,
    secondaryContainer: Color(0xFFE8F5E8),
    surface: pureWhite,
    surfaceContainerHighest: lightGrey,
    background: offWhite,
    error: error,
    onPrimary: pureWhite,
    onPrimaryContainer: textPrimary,
    onSecondary: pureWhite,
    onSecondaryContainer: textPrimary,
    onSurface: textPrimary,
    onBackground: textPrimary,
    onError: pureWhite,
    outline: Color(0xFFE0E0E0),
    outlineVariant: Color(0xFFF0F0F0),
  );
  
  // Dark Theme Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: primaryGreen,
    primaryContainer: primaryGreenDark,
    secondary: accentGreen,
    secondaryContainer: Color(0xFF0D4F1C),
    surface: surfaceBlack,
    surfaceContainerHighest: darkGrey,
    background: primaryBlack,
    error: error,
    onPrimary: primaryBlack,
    onPrimaryContainer: textOnDark,
    onSecondary: primaryBlack,
    onSecondaryContainer: textOnDark,
    onSurface: textOnDark,
    onBackground: textOnDark,
    onError: primaryBlack,
    outline: Color(0xFF404040),
    outlineVariant: Color(0xFF2A2A2A),
  );
  
  // Helper Methods
  static LinearGradient getPremiumGreenGradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: premiumGreenGradient,
      begin: begin,
      end: end,
    );
  }
  
  static LinearGradient getPremiumBlackGradient({
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      colors: premiumBlackGradient,
      begin: begin,
      end: end,
    );
  }
  
  // Theme-aware color getters
  static Color getTextColor(BuildContext context, {bool secondary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (secondary) {
      return isDark ? textOnDarkSecondary : textSecondary;
    }
    return isDark ? textOnDark : textPrimary;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? surfaceBlack : pureWhite;
  }
  
  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? primaryBlack : offWhite;
  }
}
