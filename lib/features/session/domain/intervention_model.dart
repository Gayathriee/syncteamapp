enum InterventionSource { ai, admin }

/// An intervention is a message pushed to the team during a session.
/// It can be fired automatically by the rule engine (source = ai) or
/// manually by the researcher from the monitor screen (source = admin).
///
/// The ruleId tags which rule triggered it — important for the audit trail
/// that maps each intervention back to physiological state in §5.2 analysis.
class InterventionModel {
  const InterventionModel({
    required this.id,
    required this.sessionId,
    required this.ruleId,
    required this.message,
    required this.source,
    required this.timestampMs,
    this.adminUid,
    this.syncIndexAtTime,
  });

  final String id;
  final String sessionId;

  /// R1, R2, R3, R4, or R_MANUAL — matches the rule identifiers in §4.2.
  final String ruleId;
  final String message;
  final InterventionSource source;
  final int timestampMs;

  /// Only populated for admin-sent interventions — used in the export
  /// to distinguish PI interventions from co-researcher interventions.
  final String? adminUid;

  /// Group sync index at the moment the intervention fired, written by the
  /// Cloud Function. Null for manual interventions where sync isn't the trigger.
  final double? syncIndexAtTime;

  factory InterventionModel.fromJson(Map<String, dynamic> json) {
    return InterventionModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      ruleId: json['ruleId'] as String,
      message: json['message'] as String,
      source: json['source'] == 'ai'
          ? InterventionSource.ai
          : InterventionSource.admin,
      timestampMs: json['timestampMs'] as int,
      adminUid: json['adminUid'] as String?,
      syncIndexAtTime: (json['syncIndexAtTime'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'ruleId': ruleId,
        'message': message,
        'source': source.name,
        'timestampMs': timestampMs,
        'adminUid': adminUid,
        'syncIndexAtTime': syncIndexAtTime,
      };
}
