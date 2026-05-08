/// One reading from a single participant's sensor, written to RTDB by
/// the ESP32 via the Firebase REST API (PUT to /sessions/{id}/{uid}/latest).
///
/// The ESP32 computes BPM and RMSSD on-device over the last 30s window
/// to save bandwidth — sending raw R-R intervals over WiFi at 1Hz would
/// work but doubles the data volume for no gain at this sample rate.
class HrvSample {
  const HrvSample({
    required this.userId,
    required this.sessionId,
    required this.timestampMs,
    required this.bpm,
    this.rmssdMs,
    this.signalQuality,
  });

  final String userId;
  final String sessionId;
  final int timestampMs;

  /// Instantaneous BPM from the last R-R interval. Used for the pulsing
  /// ring animation speed — inaccurate on a single beat but visually right.
  final double bpm;

  /// RMSSD over the 30s window (AppConstants.hrvWindowMs) in milliseconds.
  /// Null if fewer than 20 R-R intervals have been captured in the window
  /// (Shaffer & Ginsberg, 2017 minimum for reliable RMSSD).
  final double? rmssdMs;

  /// Signal quality 0–100 as computed by the ESP32's PPG algorithm.
  /// Below 40 = noisy (AppColors.signalNoisy), below 20 = lost.
  final int? signalQuality;

  factory HrvSample.fromJson(Map<String, dynamic> json) {
    return HrvSample(
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      timestampMs: json['timestampMs'] as int,
      bpm: (json['bpm'] as num).toDouble(),
      rmssdMs: (json['rmssdMs'] as num?)?.toDouble(),
      signalQuality: json['signalQuality'] as int?,
    );
  }
}
