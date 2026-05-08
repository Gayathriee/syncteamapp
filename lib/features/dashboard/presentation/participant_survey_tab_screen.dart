import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../session/domain/session_model.dart';

final _surveySessionProvider = StreamProvider<SessionModel?>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(sessionRepositoryProvider).watchSurveyPendingSession(user.uid);
});

final _surveyCompletedSessionsProvider = StreamProvider<List<SessionModel>>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(sessionRepositoryProvider).watchCompletedSessionsForUser(user.uid);
});

class ParticipantSurveyTabScreen extends ConsumerWidget {
  const ParticipantSurveyTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveyAsync = ref.watch(_surveySessionProvider);
    final completedAsync = ref.watch(_surveyCompletedSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.mustard,
            expandedHeight: 110,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('survey',
                  style: AppTypography.headingMedium.copyWith(color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.mustard, Color(0xFFD4A017)],
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
                surveyAsync.when(
                  data: (session) => session != null
                      ? _PendingSurveyCard(session: session)
                      : const _AllDoneCard(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const _AllDoneCard(),
                ),
                const SizedBox(height: 28),
                Text('what is this survey?', style: AppTypography.headingSmall),
                const SizedBox(height: 12),
                const _ExplainerCard(),
                const SizedBox(height: 28),
                Text('past surveys', style: AppTypography.headingSmall),
                const SizedBox(height: 12),
                completedAsync.when(
                  data: (sessions) => sessions.isEmpty
                      ? const _EmptySurveyHistory()
                      : Column(
                          children: sessions
                              .map((s) => _PastSurveyTile(session: s))
                              .toList(),
                        ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.mustard),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSurveyCard extends StatelessWidget {
  const _PendingSurveyCard({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.mustard, Color(0xFFD4A017)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.mustard.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('ACTION REQUIRED',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('post-session survey ready',
              style: AppTypography.headingSmall.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            "your team just completed a task! Please fill in the NASA-TLX workload survey — it takes about 2 minutes.",
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.mustard,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => context.go('/session/${session.id}/survey'),
              child: Text('start survey',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.mustard, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.mustardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mustard.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('✅', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('all caught up!', style: AppTypography.headingSmall),
          const SizedBox(height: 6),
          Text(
            'no surveys pending — you\'ll see one here after each task.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ExplainerCard extends StatelessWidget {
  const _ExplainerCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.psychology_rounded, 'NASA-TLX', 'Measures mental, physical, and temporal demand, plus effort and frustration.'),
      (Icons.favorite_rounded, 'HRV sync', 'Your physiological data is recorded during the task and compared to your team.'),
      (Icons.lock_rounded, 'Private', 'Your answers are anonymised — the researcher only sees aggregate patterns.'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.mustardLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.$1, color: AppColors.mustard, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$2, style: AppTypography.labelMedium),
                      const SizedBox(height: 2),
                      Text(item.$3, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PastSurveyTile extends StatelessWidget {
  const _PastSurveyTile({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final dateLabel = session.startedAtMs != null
        ? _formatDate(DateTime.fromMillisecondsSinceEpoch(session.startedAtMs!))
        : 'unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.mustardLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_turned_in_rounded,
                color: AppColors.mustard, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('survey — $dateLabel', style: AppTypography.labelMedium),
                Text('submitted ✓', style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}

class _EmptySurveyHistory extends StatelessWidget {
  const _EmptySurveyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'no completed surveys yet',
          style: AppTypography.bodySmall,
        ),
      ),
    );
  }
}
