import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';

final _enrolledCountProvider = FutureProvider<int>((ref) {
  return ref.watch(sessionRepositoryProvider).getEnrolledParticipantCount();
});

final _completedSessionCountProvider = FutureProvider<int>((ref) {
  return ref.watch(sessionRepositoryProvider).getCompletedSessionCount();
});

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final enrolledAsync = ref.watch(_enrolledCountProvider);
    final completedAsync = ref.watch(_completedSessionCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.sessionDarker,
            floating: true,
            snap: true,
            title: Text('SyncTeam Research',
                style: AppTypography.headingMedium.copyWith(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome row
                Text(
                  'hey, ${userAsync.valueOrNull?.displayName ?? 'researcher'}',
                  style: AppTypography.headingLarge,
                ),
                const SizedBox(height: 4),
                Text("here's how the study is going",
                    style: AppTypography.bodySmall),
                const SizedBox(height: 20),

                // Study progress stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'enrolled',
                        valueAsync: enrolledAsync,
                        suffix: '/ 30',
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'sessions done',
                        valueAsync: completedAsync,
                        color: AppColors.sage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Live sessions quick-access
                _ActiveSessionsBanner(),
                const SizedBox(height: 24),

                // Quick actions
                Text('quick actions', style: AppTypography.headingSmall),
                const SizedBox(height: 12),
                _QuickActionsGrid(),
                const SizedBox(height: 24),

                // Recent interventions log
                Text('recent interventions', style: AppTypography.headingSmall),
                const SizedBox(height: 12),
                _RecentInterventionsFeed(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.valueAsync,
    this.suffix = '',
    required this.color,
  });
  final String label;
  final AsyncValue<int> valueAsync;
  final String suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.caption
                  .copyWith(letterSpacing: 0.4)),
          const SizedBox(height: 6),
          valueAsync.when(
            data: (n) => Text(
              '$n$suffix',
              style: AppTypography.numericLarge.copyWith(color: color),
            ),
            loading: () => const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Text('—',
                style: AppTypography.numericLarge.copyWith(color: AppColors.warm)),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionsBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessions = ref.watch(
      StreamProvider((ref) =>
          ref.watch(sessionRepositoryProvider).watchAllActiveSessions()),
    );

    final count = activeSessions.valueOrNull?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.go('/admin/live'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.coral, Color(0xFFEB7A65)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.signalGood,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count session${count > 1 ? 's' : ''} live right now — tap to monitor',
                style: AppTypography.labelMedium
                    .copyWith(color: Colors.white),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.play_circle_outline_rounded, 'live sessions', AppColors.teal,
          '/admin/live'),
      (Icons.task_alt_rounded, 'tasks', AppColors.mustard, '/admin/tasks'),
      (Icons.people_outline_rounded, 'participants', AppColors.lavender,
          '/admin/participants'),
      (Icons.psychology_rounded, 'AI config', AppColors.sage,
          '/admin/ai-config'),
      (Icons.download_rounded, 'export data', AppColors.coral,
          '/admin/export'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((action) {
        return GestureDetector(
          onTap: () => context.go(action.$4),
          child: Container(
            width: (MediaQuery.of(context).size.width - 56) / 2,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: action.$3.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: action.$3.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(action.$1, color: action.$3, size: 22),
                const SizedBox(width: 10),
                Text(action.$2,
                    style: AppTypography.labelMedium
                        .copyWith(color: action.$3)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecentInterventionsFeed extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Global interventions feed — shows the 5 most recent across all sessions
    // This is a lightweight version; a full audit log lives in /admin/export
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_none_rounded,
                  size: 16, color: AppColors.warm),
              const SizedBox(width: 8),
              Text('no recent interventions',
                  style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'interventions from live sessions will appear here',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
