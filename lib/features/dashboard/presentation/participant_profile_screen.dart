import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../../shared/widgets/monster_avatar.dart';
import '../../auth/domain/user_model.dart';

class ParticipantProfileScreen extends ConsumerWidget {
  const ParticipantProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.lavender,
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lavender, Color(0xFF9B8EC4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      if (user?.monsterVariant != null)
                        MonsterAvatar(
                          variant: user!.monsterVariant!,
                          size: 88,
                          mood: user.hasBaseline
                              ? MonsterMood.happy
                              : MonsterMood.neutral,
                        )
                      else
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 44),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        user?.pseudonym ?? '...',
                        style: AppTypography.headingMedium
                            .copyWith(color: Colors.white),
                      ),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.bodySmall
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatusSection(user: user),
                const SizedBox(height: 24),
                if (user != null && user.achievements.isNotEmpty) ...[
                  Text('your badges', style: AppTypography.headingSmall),
                  const SizedBox(height: 12),
                  _BadgesGrid(achievements: user.achievements),
                  const SizedBox(height: 24),
                ],
                Text('study info', style: AppTypography.headingSmall),
                const SizedBox(height: 12),
                _StudyInfoCard(user: user),
                const SizedBox(height: 24),
                _LogoutButton(ref: ref),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.favorite_rounded,
            label: 'baseline',
            value: user?.hasBaseline == true ? 'calibrated' : 'pending',
            color: user?.hasBaseline == true ? AppColors.signalGood : AppColors.mustard,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.emoji_events_rounded,
            label: 'badges',
            value: '${user?.achievements.length ?? 0}',
            color: AppColors.lavender,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.star_rounded,
            label: 'rmssd',
            value: user?.baselineRmssdMs != null
                ? '${user!.baselineRmssdMs!.round()} ms'
                : '—',
            color: AppColors.teal,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: AppTypography.labelMedium
                  .copyWith(color: color, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption, maxLines: 1),
        ],
      ),
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  const _BadgesGrid({required this.achievements});
  final List<String> achievements;

  static const _badgeConfig = {
    AppConstants.badgeSyncStar: ('⭐', 'sync star', 'top sync score in a session'),
    AppConstants.badgeCalmCore: ('🧘', 'calm core', 'stayed calm under pressure'),
    AppConstants.badgeStreakThree: ('🔥', '3-day streak', 'sessions 3 days in a row'),
    AppConstants.badgeStreakFive: ('🔥🔥', '5-day streak', 'sessions 5 days in a row'),
    AppConstants.badgeFirstSession: ('🎉', 'first session', 'completed your first task'),
    AppConstants.badgeTimeAware: ('⏱', 'time aware', 'submitted answers on time'),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: achievements.map((id) {
        final config = _badgeConfig[id] ?? ('🏅', id, '');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(config.$1, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.$2, style: AppTypography.labelMedium),
                  if (config.$3.isNotEmpty)
                    Text(config.$3,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.warm)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StudyInfoCard extends StatelessWidget {
  const _StudyInfoCard({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final joinDate = user?.createdAtMs != null
        ? _formatDate(DateTime.fromMillisecondsSinceEpoch(user!.createdAtMs))
        : '—';
    final consentDate = user?.consentAtMs != null
        ? _formatDate(DateTime.fromMillisecondsSinceEpoch(user!.consentAtMs!))
        : 'not recorded';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'participant ID', value: user?.pseudonym ?? '—'),
          const Divider(height: 1),
          _InfoRow(label: 'joined study', value: joinDate),
          const Divider(height: 1),
          _InfoRow(label: 'consent date', value: consentDate),
          const Divider(height: 1),
          _InfoRow(label: 'monster', value: user?.monsterVariant?.name ?? '—'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: AppTypography.bodySmall),
          const Spacer(),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(authRepositoryProvider).signOut(),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('sign out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.coral,
          side: const BorderSide(color: AppColors.coral),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
