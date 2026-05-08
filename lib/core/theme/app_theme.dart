import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.coral,
    primary: AppColors.coral,
    secondary: AppColors.teal,
    surface: AppColors.background,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.ink,
  ),
  scaffoldBackgroundColor: AppColors.background,
  textTheme: GoogleFonts.dmSansTextTheme().copyWith(
    displayLarge: AppTypography.displayLarge,
    displayMedium: AppTypography.displayMedium,
    headlineLarge: AppTypography.headingLarge,
    headlineMedium: AppTypography.headingMedium,
    headlineSmall: AppTypography.headingSmall,
    bodyLarge: AppTypography.bodyLarge,
    bodyMedium: AppTypography.bodyMedium,
    bodySmall: AppTypography.bodySmall,
    labelMedium: AppTypography.labelMedium,
    labelSmall: AppTypography.labelSmall,
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    margin: EdgeInsets.zero,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.coral,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: Colors.white,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.coral,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      side: const BorderSide(color: AppColors.coral),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTypography.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderStrong),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderStrong),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.warm),
    labelStyle: AppTypography.labelMedium,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: AppTypography.headingMedium,
    iconTheme: const IconThemeData(color: AppColors.ink),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.cardSurface,
    selectedItemColor: AppColors.coral,
    unselectedItemColor: AppColors.warm,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedLabelStyle: AppTypography.caption.copyWith(color: AppColors.coral),
    unselectedLabelStyle: AppTypography.caption,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.cream,
    labelStyle: AppTypography.labelSmall,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.ink,
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
