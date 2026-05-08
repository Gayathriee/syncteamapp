import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../../shared/widgets/sync_ring.dart';
import '../domain/session_model.dart';

class SessionResultsScreen extends ConsumerWidget {
  const SessionResultsScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(
      StreamProvider.family<SessionModel?, String>(
        (ref, id) => ref.watch(sessionRepositoryProvider).watchSession(id),
      )(sessionId),
    );

    final session = sessionAsync.valueOrNull;
    final syncIndex = session?.latestSyncIndex ?? 0.0;
    final syncPct = (syncIndex * 100).round();

    String syncMessage;
    if (syncPct >= 70) {
      syncMessage = "brilliant — your team was really in flow! 🔥";
    } else if (syncPct >= 40) {
      syncMessage = "not bad — there was some good synchrony there";
    } else {
      syncMessage = "you'll get there — sync takes practice";
    }

    return Scaffold(
      backgroundColor: AppColors.sessionDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                "session complete!",
                style: AppTypography.sessionHeading.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                syncMessage,
                style: AppTypography.sessionBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Center(
                child: SyncRing(
                  syncIndex: syncIndex,
                  size: 180,
                  strokeWidth: 14,
                ),
              ),
              const SizedBox(height: 32),
              // Summary stats
              _ResultsCard(
                children: [
                  _StatRow(label: 'group sync index', value: '$syncPct%'),
                  _StatRow(
                    label: 'session duration',
                    value: _formatDuration(session?.startedAtMs),
                  ),
                  const _StatRow(
                    label: 'AI interventions received',
                    value: '—',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Achievements unlocked this session (simplified — in production
              // the Cloud Function writes to /users/{uid}/achievements after
              // computing the badge conditions server-side)
              if (syncPct >= 70) ...[
                _AchievementBanner(
                  icon: '⭐',
                  title: 'sync star unlocked!',
                  subtitle: "you hit $syncPct% group synchrony",
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                ),
                child: const Text('back to home →'),
              ),
              const SizedBox(height: 12),
              Text(
                'thank you for taking part in this session.\nyour responses have been recorded.',
                style: AppTypography.sessionBody.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int? startMs) {
    if (startMs == null) return '—';
    final minutes =
        (DateTime.now().millisecondsSinceEpoch - startMs) ~/ 60000;
    return '${minutes}m';
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sessionSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.sessionBody),
          Text(value,
              style: AppTypography.sessionNumeric.copyWith(
                  fontSize: 16, color: AppColors.teal)),
        ],
      ),
    );
  }
}

class _AchievementBanner extends StatelessWidget {
  const _AchievementBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D4A1E), Color(0xFF1E3A2A)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.sessionBody.copyWith(
                      color: AppColors.sage, fontWeight: FontWeight.w600)),
              Text(subtitle, style: AppTypography.sessionBody),
            ],
          ),
        ],
      ),
    );
  }
}
