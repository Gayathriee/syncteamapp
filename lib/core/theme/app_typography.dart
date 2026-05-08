import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography tokens. Fraunces is the display/heading face — its slightly
/// irregular, humanist quality fits the monster brand and reads well at
/// the large sizes used for sync values and dashboard headers.
/// DM Sans is the body face — geometric, clean, readable at small sizes.
///
/// Both mirror the web's next/font/google setup in layout.tsx exactly.
abstract final class AppTypography {
  // ── Display ────────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.fraunces(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: -0.3,
        height: 1.15,
      );

  // ── Headings ───────────────────────────────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.2,
      );

  static TextStyle get headingMedium => GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.25,
      );

  static TextStyle get headingSmall => GoogleFonts.fraunces(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.3,
      );

  // ── Body ───────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        height: 1.55,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.warm,
        height: 1.5,
      );

  // ── Labels ─────────────────────────────────────────────────────────────────
  static TextStyle get labelMedium => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.warm,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.warm,
        letterSpacing: 0.2,
      );

  // ── Numerics (HRV values, BPM, timers) ────────────────────────────────────
  // Fraunces because these appear prominently alongside the monster avatars
  // and need to feel brand-native, not like a medical readout.
  static TextStyle get numericLarge => GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.0,
      );

  static TextStyle get numericMedium => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.0,
      );

  // ── Session room variants (white text on dark bg) ──────────────────────────
  static TextStyle get sessionHeading => GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
      );

  static TextStyle get sessionBody => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        height: 1.5,
      );

  static TextStyle get sessionNumeric => GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.0,
      );
}
