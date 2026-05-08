import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../domain/session_model.dart';

class SessionBreakScreen extends ConsumerStatefulWidget {
  const SessionBreakScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<SessionBreakScreen> createState() => _SessionBreakScreenState();
}

class _SessionBreakScreenState extends ConsumerState<SessionBreakScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _breathScale = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for the session to advance to the next task or complete
    final sessionAsync = ref.watch(
      StreamProvider.family<SessionModel?, String>(
        (ref, id) => ref.watch(sessionRepositoryProvider).watchSession(id),
      )(widget.sessionId),
    );

    sessionAsync.whenData((session) {
      if (session == null) return;
      if (session.status == SessionStatus.task) {
        // Admin has started the next task — router will redirect
        // This listener fires even after dispose so check mounted
      }
    });

    return Scaffold(
      backgroundColor: AppColors.sessionDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _breathScale,
                  builder: (_, child) => Transform.scale(
                    scale: _breathScale.value,
                    child: child,
                  ),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.sage.withOpacity(0.4),
                          AppColors.teal.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                          color: AppColors.sage.withOpacity(0.5), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.self_improvement_rounded,
                            color: AppColors.sage, size: 40),
                        const SizedBox(height: 4),
                        Text('breathe',
                            style: AppTypography.sessionBody
                                .copyWith(color: AppColors.sage)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  '☕  take a break',
                  style: AppTypography.sessionHeading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "you've completed a task — well done.\nthe next one starts when the researcher is ready.",
                  style: AppTypography.sessionBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sessionSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text('while you wait',
                          style: AppTypography.sessionBody
                              .copyWith(color: Colors.white60)),
                      const SizedBox(height: 10),
                      _BreakTip(icon: '💧', text: 'have some water'),
                      _BreakTip(icon: '🧘', text: 'take a few deep breaths'),
                      _BreakTip(
                          icon: '👀',
                          text: 'look away from the screen for 20 seconds'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakTip extends StatelessWidget {
  const _BreakTip({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(text, style: AppTypography.sessionBody),
        ],
      ),
    );
  }
}
