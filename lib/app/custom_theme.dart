import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static const Color customPrimaryColor = AppColors.primaryColor;

  static ThemeData get lightTheme => ThemeData.light().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: customPrimaryColor,
      brightness: Brightness.light,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: customPrimaryColor,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: customPrimaryColor,
      selectionColor: customPrimaryColor.withOpacity(0.4),
      selectionHandleColor: customPrimaryColor,
    ),
  );

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: customPrimaryColor,
      brightness: Brightness.dark,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: customPrimaryColor,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: customPrimaryColor,
      selectionColor: customPrimaryColor.withOpacity(0.4),
      selectionHandleColor: customPrimaryColor,
    ),
  );
}
