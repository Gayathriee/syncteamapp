/// All magic numbers in one place, with citations where they come from.
abstract final class AppConstants {
  // ── HRV signal processing ──────────────────────────────────────────────────

  /// 30s window — short enough for sub-task stress reactivity
  /// (Boukarras et al., 2025), long enough for RMSSD to stabilise
  /// (≥20 consecutive R-R intervals needed; Shaffer & Ginsberg, 2017).
  static const int hrvWindowMs = 30000;

  /// 15s eval interval keeps Cloud Function costs negligible at 30 participants
  /// while giving the rule engine fresh data for each decision — §4.3.1.
  static const int ruleEvalIntervalSec = 15;

  /// 90s cooldown prevents the AI from firing interventions mid-task
  /// which would artificially inflate stress and confound the IV — §4.3.1.
  static const int interventionCooldownSec = 90;

  // ── Session state machine ──────────────────────────────────────────────────

  /// 90s baseline — §3.4.2.
  /// Less than 60s gives unreliable resting RMSSD; more than 120s
  /// inflates dropout before the task starts.
  static const int baselineCalibrationSec = 90;

  /// Default task duration if the admin hasn't configured one — §3.3.
  static const int defaultTaskDurationSec = 600;

  // ── Intervention rule thresholds (defaults — adjustable in admin AI config) ──

  /// R1: guided breathing fires if group sync stays below this for >5 min.
  static const double syncLowThreshold = 0.30;

  /// R2: positive reinforcement fires if sync is high and task is progressing.
  static const double syncHighThreshold = 0.70;

  /// R3: personal check-in fires if one member's RMSSD drops more than this
  /// fraction from their personal baseline. 40% is conservative enough to
  /// avoid false positives from minor movement artefacts.
  static const double rmssdDropFraction = 0.40;

  // ── Firebase paths ─────────────────────────────────────────────────────────

  /// Root RTDB path where ESP32 writes via the Firebase REST API.
  /// Full write path: /sessions/{sessionId}/{userId}/latest
  static const String rtdbSessionsPath = 'sessions';

  // ── Pseudonym generation ───────────────────────────────────────────────────

  /// P-042 format — leading zeros make them sort correctly as strings.
  /// Range 001–999 is more than enough for a 30-participant study.
  static const String pseudonymPrefix = 'P-';
  static const int pseudonymDigits = 3;

  // ── Gamification ───────────────────────────────────────────────────────────
  // Badge IDs — canonical strings stored in Firestore /achievements/.
  // Display names and descriptions live in BadgeConfig so the schema
  // stays stable if the copy changes.
  static const String badgeSyncStar = 'sync_star';
  static const String badgeCalmCore = 'calm_core';
  static const String badgeStreakThree = 'streak_3';
  static const String badgeStreakFive = 'streak_5';
  static const String badgeFirstSession = 'first_session';
  static const String badgeTimeAware = 'time_aware';

  // ── App ────────────────────────────────────────────────────────────────────
  static const String appName = 'SyncTeam';
  static const int splashDurationMs = 2500;
  static const int maxTeamSize = 3;
}
