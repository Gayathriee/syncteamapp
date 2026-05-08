/// Session lifecycle states. The admin drives transitions; participants
/// observe them and the UI adapts automatically via the stream listener
/// in SessionRoomScreen.
enum SessionStatus {
  waiting,      // created but not yet started
  calibrating,  // 90s baseline recording in progress
  task,         // collaborative task is live
  survey,       // task complete, participant fills NASA-TLX
  breakTime,    // break between tasks
  complete,     // all tasks done, session archived
}

class SessionModel {
  const SessionModel({
    required this.id,
    required this.teamId,
    required this.memberUids,
    required this.status,
    required this.aiEnabled,
    this.startedAtMs,
    this.currentTaskId,
    this.taskDurationSec,
    this.baselineEndMs,
    this.createdAtMs,
    this.latestSyncIndex,
  });

  final String id;
  final String teamId;
  final List<String> memberUids;
  final SessionStatus status;

  /// Controls whether the rule engine fires automatically.
  /// Admin can flip this mid-session from the monitor screen.
  final bool aiEnabled;

  final int? startedAtMs;
  final String? currentTaskId;

  /// Admin can override the default task duration per session.
  final int? taskDurationSec;

  /// Epoch ms when the 90s baseline period ended.
  /// Used by the rule engine to skip R3 checks until baseline is available.
  final int? baselineEndMs;

  final int? createdAtMs;

  /// Denormalised field written by the Cloud Function so the admin live
  /// list can show current sync without an RTDB query per session.
  final double? latestSyncIndex;

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      memberUids: List<String>.from(json['memberUids'] ?? []),
      status: SessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SessionStatus.waiting,
      ),
      aiEnabled: json['aiEnabled'] as bool? ?? true,
      startedAtMs: json['startedAtMs'] as int?,
      currentTaskId: json['currentTaskId'] as String?,
      taskDurationSec: json['taskDurationSec'] as int?,
      baselineEndMs: json['baselineEndMs'] as int?,
      createdAtMs: json['createdAtMs'] as int?,
      latestSyncIndex: (json['latestSyncIndex'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'memberUids': memberUids,
        'status': status.name,
        'aiEnabled': aiEnabled,
        'startedAtMs': startedAtMs,
        'currentTaskId': currentTaskId,
        'taskDurationSec': taskDurationSec,
        'baselineEndMs': baselineEndMs,
        'createdAtMs': createdAtMs,
        'latestSyncIndex': latestSyncIndex,
      };
}
