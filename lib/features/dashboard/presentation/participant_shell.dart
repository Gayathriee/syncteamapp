import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../session/domain/session_model.dart';
import 'participant_dashboard_screen.dart';
import 'participant_profile_screen.dart';
import 'participant_sessions_screen.dart';
import 'participant_survey_tab_screen.dart';

final _surveyPendingProvider = StreamProvider<SessionModel?>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(sessionRepositoryProvider).watchSurveyPendingSession(user.uid);
});

class ParticipantShell extends ConsumerStatefulWidget {
  const ParticipantShell({super.key});

  @override
  ConsumerState<ParticipantShell> createState() => _ParticipantShellState();
}

class _ParticipantShellState extends ConsumerState<ParticipantShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fabController;

  final _pages = const [
    ParticipantDashboardScreen(),
    ParticipantSessionsScreen(),
    ParticipantSurveyTabScreen(),
    ParticipantProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final surveyAsync = ref.watch(_surveyPendingProvider);
    final hasSurvey = surveyAsync.valueOrNull != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'home',
                  selected: _currentIndex == 0,
                  color: AppColors.coral,
                  onTap: () => _onTabTapped(0),
                ),
                _NavItem(
                  icon: Icons.sensors_rounded,
                  label: 'session',
                  selected: _currentIndex == 1,
                  color: AppColors.teal,
                  onTap: () => _onTabTapped(1),
                ),
                _NavItem(
                  icon: Icons.assignment_rounded,
                  label: 'survey',
                  selected: _currentIndex == 2,
                  color: AppColors.mustard,
                  onTap: () => _onTabTapped(2),
                  badge: hasSurvey ? '!' : null,
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'profile',
                  selected: _currentIndex == 3,
                  color: AppColors.lavender,
                  onTap: () => _onTabTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: 24,
                    color: selected ? color : AppColors.warm,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: selected ? color : AppColors.warm,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
