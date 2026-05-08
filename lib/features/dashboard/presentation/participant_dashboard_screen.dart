import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../../shared/widgets/monster_avatar.dart';
import '../../auth/domain/user_model.dart';
import '../../session/domain/session_model.dart';

// Watches for any active session the current user belongs to.
// If one exists, the dashboard shows a "join session" card.
final _activeSessionProvider = StreamProvider<SessionModel?>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref
      .watch(sessionRepositoryProvider)
      .watchActiveSessionForUser(user.uid);
});

final _completedSessionsProvider =
    StreamProvider<List<SessionModel>>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(sessionRepositoryProvider)
      .watchCompletedSessionsForUser(user.uid);
});

class ParticipantDashboardScreen extends ConsumerWidget {
  const ParticipantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final activeSessionAsync = ref.watch(_activeSessionProvider);
    final completedAsync = ref.watch(_completedSessionsProvider);

    final user = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(user: user),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Active session card — appears whenever the admin starts a session
                  activeSessionAsync.when(
                    data: (session) => session != null
                        ? _ActiveSessionCard(session: session)
                        : _NoSessionCard(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  if (user != null && !user.hasBaseline) ...[
                    _BaselineNudgeCard(userId: user.uid),
                    const SizedBox(height: 24),
                  ],

                  if (user != null && user.achievements.isNotEmpty) ...[
                    Text('your badges', style: AppTypography.headingSmall),
                    const SizedBox(height: 12),
                    _AchievementsRow(achievements: user.achievements),
                    const SizedBox(height: 24),
                  ],

                  Text('past sessions', style: AppTypography.headingSmall),
                  const SizedBox(height: 12),
                  completedAsync.when(
                    data: (sessions) => sessions.isEmpty
                        ? _EmptySessionHistory()
                        : Column(
                            children: sessions
                                .map((s) => _SessionHistoryTile(session: s))
                                .toList(),
                          ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    ),
                    error: (_, __) => Text('could not load history',
                        style: AppTypography.bodySmall),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.coral, Color(0xFFEB7A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          if (user?.monsterVariant != null)
            MonsterAvatar(
              variant: user!.monsterVariant!,
              size: 64,
              mood: user!.hasBaseline ? MonsterMood.happy : MonsterMood.neutral,
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'hey, ${user?.pseudonym ?? '...'}!',
                  style: AppTypography.headingLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.hasBaseline == true
                      ? 'baseline calibrated — ready to sync'
                      : 'waiting for your first session',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Consumer(
            builder: (_, ref, __) => IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white70),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({required this.session});
  final SessionModel session;

  String get _statusLabel {
    switch (session.status) {
      case SessionStatus.waiting:
        return 'session starting soon';
      case SessionStatus.calibrating:
        return 'calibrating your baseline';
      case SessionStatus.task:
        return 'session in progress!';
      case SessionStatus.survey:
        return 'time to complete the survey';
      case SessionStatus.breakTime:
        return "take a break — you've earned it";
      case SessionStatus.complete:
        return 'session complete';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/session/${session.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.teal, AppColors.sage],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.signalGood,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.signalGood,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusLabel,
                    style: AppTypography.headingSmall.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'tap to open session room →',
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 28),
          ],
        ),
      ),
    );
  }
}

class _NoSessionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule_rounded,
                color: AppColors.warm, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('no session scheduled',
                    style: AppTypography.labelMedium),
                const SizedBox(height: 2),
                Text(
                    "your session room will appear here when the researcher starts one",
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BaselineNudgeCard extends StatelessWidget {
  const _BaselineNudgeCard({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mustardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mustard.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_border_rounded,
              color: AppColors.mustard, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "baseline not yet recorded — it'll be done automatically at the start of your first session.",
              style: AppTypography.bodySmall
                  .copyWith(color: const Color(0xFF6B5A00)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsRow extends StatelessWidget {
  const _AchievementsRow({required this.achievements});
  final List<String> achievements;

  static const _badgeConfig = {
    AppConstants.badgeSyncStar: ('⭐', 'sync star'),
    AppConstants.badgeCalmCore: ('🧘', 'calm core'),
    AppConstants.badgeStreakThree: ('🔥', '3-day streak'),
    AppConstants.badgeStreakFive: ('🔥🔥', '5-day streak'),
    AppConstants.badgeFirstSession: ('🎉', 'first session'),
    AppConstants.badgeTimeAware: ('⏱', 'time aware'),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: achievements.map((id) {
          final config = _badgeConfig[id] ?? ('🏅', id);
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(config.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text(config.$2, style: AppTypography.caption),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SessionHistoryTile extends StatelessWidget {
  const _SessionHistoryTile({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final syncPct = session.latestSyncIndex != null
        ? '${(session.latestSyncIndex! * 100).round()}%'
        : '—';

    final dateLabel = session.startedAtMs != null
        ? _formatDate(DateTime.fromMillisecondsSinceEpoch(session.startedAtMs!))
        : 'unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(syncPct,
                  style: AppTypography.numericMedium.copyWith(
                    color: AppColors.teal,
                    fontSize: 14,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel, style: AppTypography.labelMedium),
                Text('group sync index: $syncPct',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.warm, size: 18),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _EmptySessionHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          "no completed sessions yet\n— your history will appear here",
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
      ),
    );
  }
}
