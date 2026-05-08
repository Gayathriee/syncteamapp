import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _textFade = Tween(begin: 0.0, end: 1.0).animate(_textController);
    _textSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _textController.forward();
    await Future.delayed(
        const Duration(milliseconds: AppConstants.splashDurationMs - 900));

    if (!mounted) return;

    // Check if the user has already seen onboarding — avoids re-showing it
    // every launch for returning participants.
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (!mounted) return;
    // The router redirect will intercept and send authenticated users
    // straight to /dashboard or /admin — we just need to leave /splash.
    context.go(onboardingDone ? '/login' : '/onboarding');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.coral,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoController,
              builder: (_, __) => FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: const _SplashMonster(size: 120),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    Text(
                      'SyncTeam',
                      style: AppTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'feel the flow. find your sync.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashMonster extends StatelessWidget {
  const _SplashMonster({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SplashMonsterPainter(),
    );
  }
}

class _SplashMonsterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    final bodyPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final featurePaint = Paint()..color = AppColors.coral;

    canvas.drawCircle(Offset(cx, cy + r * 0.1), r,
        Paint()..color = Colors.black.withValues(alpha: 0.1));
    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);

    final eyeY = cy - r * 0.12;
    canvas.drawCircle(Offset(cx - r * 0.36, eyeY), r * 0.22, featurePaint);
    canvas.drawCircle(Offset(cx + r * 0.36, eyeY), r * 0.22, featurePaint);
    canvas.drawCircle(Offset(cx - r * 0.36, eyeY), r * 0.10, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + r * 0.36, eyeY), r * 0.10, Paint()..color = Colors.white);

    final mouthPath = Path()
      ..moveTo(cx - r * 0.3, cy + r * 0.28)
      ..quadraticBezierTo(cx, cy + r * 0.52, cx + r * 0.3, cy + r * 0.28);

    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = featurePaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Arms
    for (final side in [-1.1, 1.1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx + side * r, cy + r * 0.1),
              width: r * 0.3,
              height: r * 0.55),
          Radius.circular(r * 0.15),
        ),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
