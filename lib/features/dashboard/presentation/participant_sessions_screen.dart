import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../session/domain/session_model.dart';

final _sessionsActiveProvider = StreamProvider<SessionModel?>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(sessionRepositoryProvider).watchActiveSessionForUser(user.uid);
});

final _sessionsHistoryProvider = StreamProvider<List<SessionModel>>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(sessionRepositoryProvider).watchCompletedSessionsForUser(user.uid);
});

class ParticipantSessionsScreen extends ConsumerWidget {
  const ParticipantSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(_sessionsActiveProvider);
    final historyAsync = ref.watch(_sessionsHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.teal,
            expandedHeight: 110,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('sessions',
                  style: AppTypography.headingMedium.copyWith(color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.teal, AppColors.sage],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('current session', style: AppTypography.headingSmall),
                const SizedBox(height: 12),
                activeAsync.when(
                  data: (session) => session != null
                      ? _ActiveSessionCard(session: session)
                      : const _WaitingCard(),
                  loading: () => const _WaitingCard(),
                  error: (_, __) => const _WaitingCard(),
                ),
                const SizedBox(height: 28),
                Text('session history', style: AppTypography.headingSmall),
                const SizedBox(height: 12),
                historyAsync.when(
                  data: (sessions) => sessions.isEmpty
                      ? const _EmptyHistory()
                      : Column(
                          children: sessions
                              .map((s) => _SessionHistoryCard(session: s))
                              .toList(),
                        ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  ),
                  error: (_, __) =>
                      Text('could not load history', style: AppTypography.bodySmall),
                ),
              ]),
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
        return 'starting soon — get ready!';
      case SessionStatus.calibrating:
        return 'calibrating your baseline HRV';
      case SessionStatus.task:
        return 'collaborative task in progress';
      case SessionStatus.survey:
        return 'task done — please fill in the survey';
      case SessionStatus.breakTime:
        return 'take a break, you earned it ☕';
      case SessionStatus.complete:
        return 'session complete';
    }
  }

  Color get _statusColor {
    switch (session.status) {
      case SessionStatus.task:
        return AppColors.signalGood;
      case SessionStatus.survey:
        return AppColors.mustard;
      case SessionStatus.breakTime:
        return AppColors.lavender;
      default:
        return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/session/${session.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_statusColor, _statusColor.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _statusColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('LIVE',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_statusLabel,
                      style: AppTypography.labelMedium.copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('tap to enter session room',
                      style: AppTypography.caption.copyWith(color: Colors.white70)),
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

class _WaitingCard extends StatelessWidget {
  const _WaitingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.hourglass_empty_rounded,
                color: AppColors.teal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('no active session', style: AppTypography.labelMedium),
                const SizedBox(height: 2),
                Text(
                  'your session room will appear here when the researcher starts one',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final syncPct = session.latestSyncIndex != null
        ? '${(session.latestSyncIndex! * 100).round()}%'
        : '—';

    final dateLabel = session.startedAtMs != null
        ? _formatDate(DateTime.fromMillisecondsSinceEpoch(session.startedAtMs!))
        : 'unknown date';

    final syncColor = session.latestSyncIndex != null
        ? (session.latestSyncIndex! >= 0.7
            ? AppColors.signalGood
            : session.latestSyncIndex! >= 0.4
                ? AppColors.mustard
                : AppColors.coral)
        : AppColors.warm;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: syncColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: syncColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(syncPct,
                  style: AppTypography.numericMedium.copyWith(
                    color: syncColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel, style: AppTypography.labelMedium),
                const SizedBox(height: 2),
                Text(
                  'group synchrony: $syncPct',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.warm, size: 18),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.history_rounded,
                color: AppColors.teal, size: 36),
          ),
          const SizedBox(height: 16),
          Text('no sessions yet', style: AppTypography.headingSmall),
          const SizedBox(height: 6),
          Text(
            'completed sessions will appear here\nwith your synchrony scores',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
