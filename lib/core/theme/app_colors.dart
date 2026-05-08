import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand primaries ────────────────────────────────────────────────────────
  static const coral = Color(0xFFE8614A);
  static const coralLight = Color(0xFFF5CFC8);

  static const teal = Color(0xFF4AADA5);
  static const tealLight = Color(0xFFD0EEEC);

  static const mustard = Color(0xFFE8C040);
  static const mustardLight = Color(0xFFFFF3C4);

  static const sage = Color(0xFF7DB87A);
  static const sageLight = Color(0xFFD4EDCA);

  static const lavender = Color(0xFF9B8EC4);
  static const lavenderLight = Color(0xFFE4DFF5);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const ink = Color(0xFF2A2724);
  static const warm = Color(0xFF8A7F76);
  static const cream = Color(0xFFFAF3EE);
  static const background = Color(0xFFFDF8F3);
  static const cardSurface = Color(0xFFFFFFFF);
  static const border = Color(0xFFF0EBE4);
  static const borderStrong = Color(0xFFE8E3DD);

  // ── Session room (dark surface) ────────────────────────────────────────────
  // Dark because participants need to focus on the task, not the chrome.
  static const sessionDark = Color(0xFF1E2833);
  static const sessionDarker = Color(0xFF111921);
  static const sessionSurface = Color(0xFF252F3D);

  // ── Sensor health states ───────────────────────────────────────────────────
  // Named for what they communicate, not their hue — colour-blind-safe.
  static const signalGood = Color(0xFF4AFF9A);
  static const signalNoisy = Color(0xFFFFB740);
  static const signalLost = Color(0xFFFF5F5F);

  // ── Synchrony ring gradient stops ─────────────────────────────────────────
  // Low sync → coral; rising → mustard; high sync → teal+sage.
  // These are chosen so the colour shift is perceptually smooth.
  // See SyncRing for usage and threshold values.
  static const syncLow = coral;
  static const syncMid = mustard;
  static const syncHigh = teal;
  static const syncPeak = sage;

  // ── Intervention source colours ────────────────────────────────────────────
  static const interventionAi = mustard;
  static const interventionAdmin = lavender;
}
