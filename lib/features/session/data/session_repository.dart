import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/hrv_sample.dart';
import '../domain/intervention_model.dart';
import '../domain/session_model.dart';
import '../domain/synchrony_window.dart';
import '../domain/task_model.dart';

class SessionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  Stream<SessionModel?> watchSession(String sessionId) {
    return _db.collection('sessions').doc(sessionId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return SessionModel.fromJson({'id': snap.id, ...snap.data()!});
    });
  }

  /// Finds the participant's current active session, if one exists.
  /// The whereIn filter is cheaper than a client-side filter at this scale.
  // TODO: add a composite index on (memberUids, status) in Firestore console
  // before running the study — Firestore will prompt you on first query.
  Stream<SessionModel?> watchActiveSessionForUser(String uid) {
    return _db
        .collection('sessions')
        .where('memberUids', arrayContains: uid)
        .where('status', whereIn: [
          SessionStatus.waiting.name,
          SessionStatus.calibrating.name,
          SessionStatus.task.name,
          SessionStatus.survey.name,
          SessionStatus.breakTime.name,
        ])
        .limit(1)
        .snapshots()
        .map((qs) {
          if (qs.docs.isEmpty) return null;
          final doc = qs.docs.first;
          return SessionModel.fromJson({'id': doc.id, ...doc.data()});
        });
  }

  /// Watches the RTDB node that the Cloud Function writes after each
  /// AppConstants.ruleEvalIntervalSec evaluation cycle.
  Stream<SynchronyWindow?> watchLatestSynchrony(String sessionId) {
    return _rtdb
        .ref('${AppConstants.rtdbSessionsPath}/$sessionId/synchrony/latest')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return null;
      final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
      return SynchronyWindow.fromJson({'sessionId': sessionId, ...raw});
    });
  }

  Stream<List<InterventionModel>> watchInterventions(String sessionId) {
    return _db
        .collection('interventions')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestampMs')
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => InterventionModel.fromJson({'id': d.id, ...d.data()}))
            .toList());
  }

  /// Subscribes to the RTDB node the ESP32 writes at /sessions/{id}/{uid}/latest.
  Stream<HrvSample?> watchLiveHrv({
    required String sessionId,
    required String userId,
  }) {
    return _rtdb
        .ref('${AppConstants.rtdbSessionsPath}/$sessionId/$userId/latest')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return null;
      final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
      return HrvSample.fromJson({
        'userId': userId,
        'sessionId': sessionId,
        ...raw,
      });
    });
  }

  Future<void> advanceSessionStatus({
    required String sessionId,
    required SessionStatus newStatus,
  }) async {
    final update = <String, dynamic>{'status': newStatus.name};
    if (newStatus == SessionStatus.task) {
      update['startedAtMs'] = DateTime.now().millisecondsSinceEpoch;
    }
    if (newStatus == SessionStatus.calibrating) {
      // Record when calibration started so the Cloud Function can compute
      // baseline end time (startMs + AppConstants.baselineCalibrationSec * 1000)
      update['calibrationStartMs'] = DateTime.now().millisecondsSinceEpoch;
    }
    await _db.collection('sessions').doc(sessionId).update(update);
  }

  Future<void> toggleAi({
    required String sessionId,
    required bool enabled,
  }) async {
    await _db.collection('sessions').doc(sessionId).update({'aiEnabled': enabled});
  }

  Future<void> sendManualIntervention({
    required String sessionId,
    required String message,
    required String ruleId,
    required String adminUid,
  }) async {
    await _db.collection('interventions').add({
      'sessionId': sessionId,
      'message': message,
      'ruleId': ruleId,
      'source': InterventionSource.admin.name,
      'adminUid': adminUid,
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
      'syncIndexAtTime': null,
    });
  }

  Future<void> submitAnswer({
    required String sessionId,
    required String userId,
    required String answer,
    required String taskId,
  }) async {
    await _db.collection('answers').add({
      'sessionId': sessionId,
      'userId': userId,
      'taskId': taskId,
      'answer': answer,
      'submittedAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> submitSurvey({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> responses,
  }) async {
    await _db.collection('surveys').add({
      'sessionId': sessionId,
      'userId': userId,
      ...responses,
      'submittedAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<TaskModel>> watchTasks() {
    return _db
        .collection('tasks')
        .orderBy('orderIndex')
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => TaskModel.fromJson({'id': d.id, ...d.data()}))
            .toList());
  }

  Future<void> createTask(TaskModel task) async {
    await _db.collection('tasks').add(task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.id).update(task.toJson());
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  Stream<List<SessionModel>> watchAllActiveSessions() {
    return _db
        .collection('sessions')
        .where('status', whereIn: [
          SessionStatus.calibrating.name,
          SessionStatus.task.name,
          SessionStatus.survey.name,
          SessionStatus.breakTime.name,
        ])
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => SessionModel.fromJson({'id': d.id, ...d.data()}))
            .toList());
  }

  Stream<List<SessionModel>> watchCompletedSessionsForUser(String uid) {
    return _db
        .collection('sessions')
        .where('memberUids', arrayContains: uid)
        .where('status', isEqualTo: SessionStatus.complete.name)
        .orderBy('startedAtMs', descending: true)
        .limit(10)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => SessionModel.fromJson({'id': d.id, ...d.data()}))
            .toList());
  }

  Future<String> createSession({
    required String teamId,
    required List<String> memberUids,
    required String taskId,
  }) async {
    final doc = await _db.collection('sessions').add({
      'teamId': teamId,
      'memberUids': memberUids,
      'currentTaskId': taskId,
      'status': SessionStatus.waiting.name,
      'aiEnabled': true,
      'startedAtMs': null,
      'taskDurationSec': AppConstants.defaultTaskDurationSec,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      'latestSyncIndex': 0.0,
    });
    return doc.id;
  }

  Future<int> getEnrolledParticipantCount() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'participant')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> getCompletedSessionCount() async {
    final snap = await _db
        .collection('sessions')
        .where('status', isEqualTo: SessionStatus.complete.name)
        .count()
        .get();
    return snap.count ?? 0;
  }
}
