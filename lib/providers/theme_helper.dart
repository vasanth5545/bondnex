// File: lib/providers/theme_helper.dart
// Note: This file should be placed in the 'lib/providers/' directory.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_colors.dart'; // Ensure app_colors.dart is in lib/providers/

class ThemeHelper {
  // Common Text Styles
  static TextStyle getHeadingStyle(BuildContext context, {double? fontSize, FontWeight? fontWeight}) {
    return GoogleFonts.poppins(
      fontSize: fontSize ?? 24,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: AppColors.getTextColor(context),
    );
  }
  
  static TextStyle getSubheadingStyle(BuildContext context, {double? fontSize}) {
    return GoogleFonts.poppins(
      fontSize: fontSize ?? 18,
      fontWeight: FontWeight.w600,
      color: AppColors.getTextColor(context),
    );
  }
  
  static TextStyle getBodyStyle(BuildContext context, {double? fontSize, bool secondary = false}) {
    return GoogleFonts.poppins(
      fontSize: fontSize ?? 16,
      fontWeight: FontWeight.w400,
      color: AppColors.getTextColor(context, secondary: secondary),
    );
  }
  
  static TextStyle getCaptionStyle(BuildContext context, {double? fontSize}) {
    return GoogleFonts.poppins(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w400,
      color: AppColors.getTextColor(context, secondary: true),
    );
  }
  
  // Common Decorations
  static BoxDecoration getPremiumCardDecoration(BuildContext context, {
    double borderRadius = 16,
    bool withShadow = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: AppColors.getSurfaceColor(context),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: withShadow ? [
        BoxShadow(
          color: isDark 
            ? Colors.black.withOpacity(0.3)
            : AppColors.textSecondary.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }
  
  static BoxDecoration getPremiumGradientDecoration({
    double borderRadius = 16,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      gradient: AppColors.getPremiumGreenGradient(begin: begin, end: end),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
  
  // Common Button Styles
  static ButtonStyle getPrimaryButtonStyle(BuildContext context, {
    double borderRadius = 12,
    EdgeInsets? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppColors.primaryBlack 
          : AppColors.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      elevation: 0,
      shadowColor: Colors.transparent,
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  static ButtonStyle getSecondaryButtonStyle(BuildContext context, {
    double borderRadius = 12,
    EdgeInsets? padding,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryGreen,
      side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  // Common Input Decorations
  static InputDecoration getPremiumInputDecoration(BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    double borderRadius = 12,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.getSurfaceColor(context),
      labelStyle: GoogleFonts.poppins(
        color: AppColors.getTextColor(context, secondary: true),
      ),
      hintStyle: GoogleFonts.poppins(
        color: AppColors.getTextColor(context, secondary: true),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkGrey.withOpacity(0.5)
              : AppColors.textTertiary.withOpacity(0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkGrey.withOpacity(0.5)
              : AppColors.textTertiary.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
  
  // Common App Bar
  static AppBar getPremiumAppBar(BuildContext context, {
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.getTextColor(context),
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: AppColors.getBackgroundColor(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      actions: actions,
      iconTheme: IconThemeData(
        color: AppColors.getTextColor(context),
      ),
    );
  }
  
  // Common Snackbar
  static void showPremiumSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: isError ? AppColors.pureWhite : AppColors.primaryBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primaryGreen,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      ),
    );
  }
}
