import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/user_model.dart';

enum MonsterMood { happy, neutral, stressed }

/// The MonsterAvatar is the single most visible brand element in the app.
/// Every participant is represented by one throughout their study experience.
///
/// Mood shifts the eye shape and mouth curve based on RMSSD deviation from
/// baseline — happy = within 20% of baseline, neutral = 20–40% drop,
/// stressed = >40% drop (AppConstants.rmssdDropFraction). This encodes the
/// same threshold used in intervention rule R3 so the visual is consistent
/// with the underlying signal logic.
class MonsterAvatar extends StatelessWidget {
  const MonsterAvatar({
    super.key,
    required this.variant,
    this.mood = MonsterMood.happy,
    this.size = 64,
    this.showPulse = false,
    this.bpm,
  });

  final MonsterVariant variant;
  final MonsterMood mood;
  final double size;

  /// Pulsing ring around the avatar at the live BPM rate.
  final bool showPulse;
  final double? bpm;

  @override
  Widget build(BuildContext context) {
    final face = _MonsterFace(variant: variant, mood: mood, size: size);
    return SizedBox(
      width: size,
      height: size,
      child: showPulse
          ? _PulsingRing(bpm: bpm, size: size, child: face)
          : face,
    );
  }
}

class _MonsterFace extends StatelessWidget {
  const _MonsterFace({required this.variant, required this.mood, required this.size});
  final MonsterVariant variant;
  final MonsterMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MonsterPainter(variant: variant, mood: mood),
    );
  }
}

class _MonsterPainter extends CustomPainter {
  _MonsterPainter({required this.variant, required this.mood});
  final MonsterVariant variant;
  final MonsterMood mood;

  // Variant → body colour. Softer than brand primaries so avatars
  // don't fight with the UI chrome in the session room.
  static const _bodyColors = {
    MonsterVariant.octopus: Color(0xFFE8614A),
    MonsterVariant.dragon: Color(0xFF4AADA5),
    MonsterVariant.fox: Color(0xFFE8A030),
    MonsterVariant.bear: Color(0xFF8B6B4A),
    MonsterVariant.dino: Color(0xFF7DB87A),
    MonsterVariant.frog: Color(0xFF5BAD6F),
    MonsterVariant.panda: Color(0xFF4A4A4A),
    MonsterVariant.hedgehog: Color(0xFF9B7BAA),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final bodyColor = _bodyColors[variant] ?? AppColors.coral;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = bodyColor);
    _drawVariantDetails(canvas, size, bodyColor, cx, cy, r);

    // Eyes
    final eyeY = cy - r * 0.15;
    final eyeOffsetX = r * 0.38;
    final eyeR = r * 0.20;
    final pupilR = eyeR * 0.55;
    final facePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF2A2724);

    canvas.drawCircle(Offset(cx - eyeOffsetX, eyeY), eyeR, facePaint);
    canvas.drawCircle(Offset(cx + eyeOffsetX, eyeY), eyeR, facePaint);

    // Pupils drop slightly under stress — mirrors the brow furrow below
    final pupilOffset = mood == MonsterMood.stressed ? Offset(0, eyeR * 0.1) : Offset.zero;
    canvas.drawCircle(Offset(cx - eyeOffsetX, eyeY) + pupilOffset, pupilR, pupilPaint);
    canvas.drawCircle(Offset(cx + eyeOffsetX, eyeY) + pupilOffset, pupilR, pupilPaint);

    if (mood == MonsterMood.stressed) {
      final browPaint = Paint()
        ..color = bodyColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx - eyeOffsetX - eyeR, eyeY - eyeR * 1.2),
        Offset(cx - eyeOffsetX + eyeR * 0.4, eyeY - eyeR * 0.9),
        browPaint,
      );
      canvas.drawLine(
        Offset(cx + eyeOffsetX + eyeR, eyeY - eyeR * 1.2),
        Offset(cx + eyeOffsetX - eyeR * 0.4, eyeY - eyeR * 0.9),
        browPaint,
      );
    }

    // Mouth
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;
    final mouthY = cy + r * 0.32;
    final mouthW = r * 0.5;
    final path = Path();

    switch (mood) {
      case MonsterMood.happy:
        path.moveTo(cx - mouthW, mouthY);
        path.quadraticBezierTo(cx, mouthY + r * 0.28, cx + mouthW, mouthY);
      case MonsterMood.neutral:
        path.moveTo(cx - mouthW, mouthY);
        path.lineTo(cx + mouthW, mouthY);
      case MonsterMood.stressed:
        path.moveTo(cx - mouthW, mouthY + r * 0.12);
        path.quadraticBezierTo(cx, mouthY - r * 0.15, cx + mouthW, mouthY + r * 0.12);
    }
    canvas.drawPath(path, mouthPaint);
  }

  void _drawVariantDetails(
      Canvas canvas, Size size, Color bodyColor, double cx, double cy, double r) {
    switch (variant) {
      case MonsterVariant.octopus:
        for (var i = -1; i <= 1; i++) {
          canvas.drawCircle(
            Offset(cx + i * r * 0.4, size.height * 0.88),
            r * 0.12,
            Paint()..color = bodyColor,
          );
        }
      case MonsterVariant.dragon:
        final horn = Paint()..color = bodyColor.withValues(blue: bodyColor.b * 0.8);
        for (final dx in [-0.3, 0.3]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + dx * r, size.height * 0.1),
                  width: r * 0.2,
                  height: r * 0.35),
              const Radius.circular(4),
            ),
            horn,
          );
        }
      case MonsterVariant.fox:
        for (final side in [-1.0, 1.0]) {
          final ear = Path()
            ..moveTo(cx + side * r * 0.6, size.height * 0.2)
            ..lineTo(cx + side * r * 0.25, size.height * 0.08)
            ..lineTo(cx + side * r * 0.1, size.height * 0.22)
            ..close();
          canvas.drawPath(ear, Paint()..color = bodyColor);
        }
      case MonsterVariant.bear:
        canvas.drawCircle(Offset(cx - r * 0.65, size.height * 0.18), r * 0.2,
            Paint()..color = bodyColor);
        canvas.drawCircle(Offset(cx + r * 0.65, size.height * 0.18), r * 0.2,
            Paint()..color = bodyColor);
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_MonsterPainter old) =>
      old.variant != variant || old.mood != mood;
}

/// Heartbeat ring that pulses at the participant's live BPM.
class _PulsingRing extends StatefulWidget {
  const _PulsingRing({required this.child, required this.size, this.bpm});
  final Widget child;
  final double size;
  final double? bpm;

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    final bpm = widget.bpm ?? 70.0;
    // Animation period matches the heartbeat interval
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (60000 / bpm).round()),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_PulsingRing old) {
    super.didUpdateWidget(old);
    if (old.bpm != widget.bpm && widget.bpm != null) {
      _controller
        ..duration = Duration(milliseconds: (60000 / widget.bpm!).round())
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}
