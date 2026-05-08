import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardPage(
      backgroundColor: AppColors.teal,
      title: 'welcome to SyncTeam.',
      subtitle:
          "you're about to take part in a study on how teams synchronise under collaboration.",
      painter: _WavingMonsterPainter(),
    ),
    _OnboardPage(
      backgroundColor: AppColors.mustard,
      title: "what's the study about?",
      subtitle:
          "you'll wear a heart-rate sensor while working with your team on a series of tasks. we measure how your stress levels align over time.",
      painter: _SensorMonsterPainter(),
    ),
    _OnboardPage(
      backgroundColor: AppColors.lavender,
      title: 'here\'s what to expect.',
      subtitle:
          "1. wear your sensor\n2. do the tasks as a team\n3. complete a short survey after\n\nyou can withdraw at any time without giving a reason.",
      painter: _HappyMonsterPainter(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _pages[i],
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Page dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLast
                        ? _finish
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _pages[_currentPage].backgroundColor,
                    ),
                    child: Text(isLast ? 'get started →' : 'next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.painter,
  });

  final Color backgroundColor;
  final String title;
  final String subtitle;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: painter,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTypography.displayMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Monster painters for each onboarding slide ────────────────────────────────
// Simple shapes only — we don't need the full MonsterAvatar here since
// the onboarding screen is a one-time experience and the assets aren't yet bundled.

class _WavingMonsterPainter extends CustomPainter {
  const _WavingMonsterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white.withValues(alpha: 0.9));

    // Eyes
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.1), r * 0.18,
        Paint()..color = AppColors.teal);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.1), r * 0.18,
        Paint()..color = AppColors.teal);
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.1), r * 0.08,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.1), r * 0.08,
        Paint()..color = Colors.white);

    // Wave arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx + r * 1.05, cy - r * 0.15),
            width: r * 0.28,
            height: r * 0.6),
        Radius.circular(r * 0.14),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // Smile
    final path = Path()
      ..moveTo(cx - r * 0.28, cy + r * 0.28)
      ..quadraticBezierTo(cx, cy + r * 0.5, cx + r * 0.28, cy + r * 0.28);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SensorMonsterPainter extends CustomPainter {
  const _SensorMonsterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final r = size.width * 0.36;

    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white.withValues(alpha: 0.9));

    // Eyes — looking curious
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.15), r * 0.18,
        Paint()..color = AppColors.mustard);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.15), r * 0.18,
        Paint()..color = AppColors.mustard);

    // Heart sensor band on wrist
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx - r * 1.1, cy + r * 0.2),
            width: r * 0.28,
            height: r * 0.55),
        Radius.circular(r * 0.14),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(cx - r * 1.1, cy + r * 0.25), width: r * 0.2, height: r * 0.14),
      Paint()..color = AppColors.coral,
    );

    // Neutral mouth
    canvas.drawLine(
      Offset(cx - r * 0.25, cy + r * 0.32),
      Offset(cx + r * 0.25, cy + r * 0.32),
      Paint()
        ..color = AppColors.mustard
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _HappyMonsterPainter extends CustomPainter {
  const _HappyMonsterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white.withValues(alpha: 0.9));

    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.12), r * 0.18,
        Paint()..color = AppColors.lavender);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.12), r * 0.18,
        Paint()..color = AppColors.lavender);
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.12), r * 0.08,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.12), r * 0.08,
        Paint()..color = Colors.white);

    // Big smile
    final path = Path()
      ..moveTo(cx - r * 0.35, cy + r * 0.22)
      ..quadraticBezierTo(cx, cy + r * 0.55, cx + r * 0.35, cy + r * 0.22);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.lavender
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );

    // Both arms up
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx + side * r * 1.05, cy - r * 0.1),
              width: r * 0.27,
              height: r * 0.58),
          Radius.circular(r * 0.14),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
