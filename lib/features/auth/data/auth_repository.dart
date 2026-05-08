import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel?> watchCurrentUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromJson({'uid': snap.id, ...snap.data()!});
    });
  }

  Future<UserModel> signInParticipant({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) throw Exception('account not found in study database');

    final user = UserModel.fromJson({'uid': doc.id, ...doc.data()!});
    if (!user.isParticipant) {
      await _auth.signOut();
      throw Exception('not a participant account — use the admin login');
    }
    return user;
  }

  Future<UserModel> signInAdmin({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) throw Exception('admin account not found');

    final user = UserModel.fromJson({'uid': doc.id, ...doc.data()!});
    if (!user.isAdmin) {
      await _auth.signOut();
      throw Exception('not an admin account — use the participant login');
    }
    return user;
  }

  Future<UserModel> signUpParticipant({
    required String email,
    required String password,
    required MonsterVariant variant,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final pseudonym = await _generatePseudonym();
    final now = DateTime.now().millisecondsSinceEpoch;

    final data = {
      'uid': uid,
      'email': email,
      'role': 'participant',
      'pseudonym': pseudonym,
      'displayName': pseudonym,
      'monsterVariant': variant.name,
      'createdAtMs': now,
      'consentAtMs': now,
      'achievements': <String>[],
      'baselineRmssdMs': null,
    };

    await _db.collection('users').doc(uid).set(data);
    return UserModel.fromJson(data);
  }

  Future<UserModel> signUpAdmin({
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    // Validate before creating the Firebase Auth account so the invite check
    // fails fast and doesn't leave a dangling auth user on bad codes.
    final inviteRef = _db.collection('adminInvites').doc(inviteCode);
    final inviteDoc = await inviteRef.get();

    if (!inviteDoc.exists) throw Exception('invite code not recognised');
    if (inviteDoc.data()!['consumed'] == true) {
      throw Exception('invite code has already been used');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final now = DateTime.now().millisecondsSinceEpoch;

    final data = {
      'uid': uid,
      'email': email,
      'role': 'admin',
      'pseudonym': 'ADMIN',
      'displayName': email.split('@').first,
      'createdAtMs': now,
      'consentAtMs': now,
      'achievements': <String>[],
    };

    // Batch: create user doc + mark invite consumed atomically
    final batch = _db.batch();
    batch.set(_db.collection('users').doc(uid), data);
    batch.update(inviteRef, {
      'consumed': true,
      'consumedByUid': uid,
      'consumedAtMs': now,
    });
    await batch.commit();

    return UserModel.fromJson(data);
  }

  Future<void> updateBaselineRmssd({
    required String uid,
    required double rmssdMs,
  }) async {
    await _db.collection('users').doc(uid).update({'baselineRmssdMs': rmssdMs});
  }

  Future<void> signOut() => _auth.signOut();

  /// Uses a Firestore transaction so concurrent signups never collide on
  /// the same pseudonym number. At 30 participants the counter fits in a
  /// single document read — no sharding needed.
  Future<String> _generatePseudonym() {
    final counter = _db.collection('meta').doc('participantCount');
    return _db.runTransaction((tx) async {
      final snap = await tx.get(counter);
      final n = (snap.exists ? (snap.data()!['count'] as int) : 0) + 1;
      tx.set(counter, {'count': n});
      return '${AppConstants.pseudonymPrefix}${n.toString().padLeft(AppConstants.pseudonymDigits, '0')}';
    });
  }
}
