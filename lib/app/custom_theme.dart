import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final Color customPrimaryColor = AppColors.primaryColor;

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: customPrimaryColor,
        brightness: Brightness.light,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: customPrimaryColor,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: customPrimaryColor,
        selectionColor: customPrimaryColor.withOpacity(0.4),
        selectionHandleColor: customPrimaryColor,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: customPrimaryColor,
        brightness: Brightness.dark,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: customPrimaryColor,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: customPrimaryColor,
        selectionColor: customPrimaryColor.withOpacity(0.4),
        selectionHandleColor: customPrimaryColor,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
