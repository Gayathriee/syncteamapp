/// MonsterVariant lives here because it is a fundamental user attribute —
/// participants choose their character at signup and it persists throughout
/// the study. The 8 variants give enough variety for a 30-person team
/// without the visual complexity of generating unique designs per user.
enum MonsterVariant {
  octopus,
  dragon,
  fox,
  bear,
  dino,
  frog,
  panda,
  hedgehog,
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.pseudonym,
    required this.displayName,
    required this.createdAtMs,
    this.consentAtMs,
    this.monsterVariant,
    this.baselineRmssdMs,
    this.achievements = const [],
  });

  final String uid;
  final String email;

  /// 'participant' | 'admin'
  final String role;

  /// P-042 format for participants, 'ADMIN' for admin accounts.
  final String pseudonym;
  final String displayName;
  final int createdAtMs;

  /// Null until the participant ticks the consent checkbox at signup.
  final int? consentAtMs;

  /// Null for admin accounts — they don't have a monster.
  final MonsterVariant? monsterVariant;

  /// Resting RMSSD in milliseconds, computed during the 90s baseline
  /// calibration phase (§3.4.2). Null until first calibration completes.
  final double? baselineRmssdMs;

  /// Badge IDs from AppConstants. Stored as a flat list in Firestore
  /// so the client can check membership in O(n) — n is at most ~6 badges,
  /// so a Set lookup would be premature.
  final List<String> achievements;

  bool get isAdmin => role == 'admin';
  bool get isParticipant => role == 'participant';
  bool get hasBaseline => baselineRmssdMs != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      pseudonym: json['pseudonym'] as String,
      displayName: json['displayName'] as String,
      createdAtMs: json['createdAtMs'] as int,
      consentAtMs: json['consentAtMs'] as int?,
      monsterVariant: json['monsterVariant'] != null
          ? MonsterVariant.values.firstWhere(
              (v) => v.name == json['monsterVariant'],
              orElse: () => MonsterVariant.octopus,
            )
          : null,
      baselineRmssdMs: (json['baselineRmssdMs'] as num?)?.toDouble(),
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'role': role,
        'pseudonym': pseudonym,
        'displayName': displayName,
        'createdAtMs': createdAtMs,
        'consentAtMs': consentAtMs,
        'monsterVariant': monsterVariant?.name,
        'baselineRmssdMs': baselineRmssdMs,
        'achievements': achievements,
      };

  UserModel copyWith({
    double? baselineRmssdMs,
    List<String>? achievements,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        role: role,
        pseudonym: pseudonym,
        displayName: displayName,
        createdAtMs: createdAtMs,
        consentAtMs: consentAtMs,
        monsterVariant: monsterVariant,
        baselineRmssdMs: baselineRmssdMs ?? this.baselineRmssdMs,
        achievements: achievements ?? this.achievements,
      );
}
