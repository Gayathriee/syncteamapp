/// One computed synchrony window, written to RTDB by the Cloud Function
/// every AppConstants.ruleEvalIntervalSec seconds.
///
/// groupIndex is the mean of the three pairwise Pearson r values computed
/// over each participant pair's RMSSD time-series within the current window.
/// This is the "group synchrony index" defined in §3.2.1.
///
/// Using Pearson r (not cross-correlation or DTW) because:
///   1. It's interpretable as a single 0–1 value for the UI ring.
///   2. It's what Boukarras et al. (2025) used for the HRV synchrony metric
///      we're replicating, so the baseline comparison holds.
///   3. Cross-correlation handles lag better but a 30s window at 1Hz gives
///      30 samples, and typical inter-person lag in sync tasks is <5s —
///      well within the window, so alignment matters less here.
class SynchronyWindow {
  const SynchronyWindow({
    required this.sessionId,
    required this.windowStartMs,
    required this.windowEndMs,
    required this.groupIndex,
    required this.pairwiseR,
    required this.computedAtMs,
  });

  final String sessionId;
  final int windowStartMs;
  final int windowEndMs;

  /// Mean of the three pairwise Pearson r values, clamped to [0, 1].
  final double groupIndex;

  /// uid1_uid2 → Pearson r. Keys are UIDs joined with underscore,
  /// sorted lexicographically so the key is stable regardless of team order.
  final Map<String, double> pairwiseR;

  final int computedAtMs;

  factory SynchronyWindow.fromJson(Map<String, dynamic> json) {
    final rawPairs = json['pairwiseR'] as Map? ?? {};
    return SynchronyWindow(
      sessionId: json['sessionId'] as String? ?? '',
      windowStartMs: json['windowStartMs'] as int? ?? 0,
      windowEndMs: json['windowEndMs'] as int? ?? 0,
      groupIndex: (json['groupIndex'] as num?)?.toDouble() ?? 0.0,
      pairwiseR: rawPairs.map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
      computedAtMs: json['computedAtMs'] as int? ?? 0,
    );
  }
}
