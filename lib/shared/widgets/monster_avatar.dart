import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/user_model.dart';

export '../../features/auth/domain/user_model.dart' show MonsterVariant;

enum MonsterMood { happy, neutral, stressed }

/// Chibi-style monster avatar. Each participant has one assigned at signup.
/// Mood reflects HRV state: happy = within baseline, neutral = mild drop,
/// stressed = >40% RMSSD drop (same threshold as intervention rule R3).
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
  const _MonsterFace(
      {required this.variant, required this.mood, required this.size});
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

  // Soft pastel body colours — warm enough to feel friendly, distinct per variant.
  static const _bodyColors = {
    MonsterVariant.octopus: Color(0xFFF4806B),
    MonsterVariant.dragon: Color(0xFF5BBFB8),
    MonsterVariant.fox: Color(0xFFF0A840),
    MonsterVariant.bear: Color(0xFFB8906A),
    MonsterVariant.dino: Color(0xFF82CB7E),
    MonsterVariant.frog: Color(0xFF5DC47A),
    MonsterVariant.panda: Color(0xFF6E6E7A),
    MonsterVariant.hedgehog: Color(0xFFAA8EC8),
  };

  // Slightly darker shade used for ears, horns, and inner details.
  static Color _shade(Color c) => Color.fromARGB(
        (c.a * 255.0).round().clamp(0, 255),
        ((c.r * 255.0).round().clamp(0, 255) * 0.82).round(),
        ((c.g * 255.0).round().clamp(0, 255) * 0.82).round(),
        ((c.b * 255.0).round().clamp(0, 255) * 0.82).round(),
      );

  // Lightest tint for belly / inner ear highlights.
  static Color _light(Color c) => Color.lerp(c, Colors.white, 0.55)!;

  @override
  void paint(Canvas canvas, Size size) {
    final body = _bodyColors[variant] ?? AppColors.coral;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Chibi body: big round head fills most of the canvas.
    final r = size.width * 0.43;

    // Drop shadow for depth
    canvas.drawCircle(
      Offset(cx, cy + r * 0.06),
      r,
      Paint()
        ..color = body.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Body circle
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = body);

    // Belly highlight — soft lighter circle in the lower-centre
    final bellyPaint = Paint()..color = _light(body).withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.28),
        width: r * 0.9,
        height: r * 0.7,
      ),
      bellyPaint,
    );

    // Variant-specific ears/horns/details (drawn before face so they're behind eyes)
    _drawVariantTop(canvas, size, body, cx, cy, r);

    // ── Eyes ──────────────────────────────────────────────────────────────
    final eyeY = cy - r * 0.10;
    final eyeOffsetX = r * 0.33;
    // Bigger eyes = cuter (chibi rule)
    final eyeR = r * 0.245;
    final pupilR = eyeR * 0.58;
    final shinR = pupilR * 0.38;

    final whitePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF1E1A2E);
    final shinePaint = Paint()..color = Colors.white;

    // Eye whites
    canvas.drawCircle(Offset(cx - eyeOffsetX, eyeY), eyeR, whitePaint);
    canvas.drawCircle(Offset(cx + eyeOffsetX, eyeY), eyeR, whitePaint);

    // Mood-driven pupil position / shape
    final pupilDrop = mood == MonsterMood.stressed ? eyeR * 0.12 : 0.0;
    final lPupil = Offset(cx - eyeOffsetX, eyeY + pupilDrop);
    final rPupil = Offset(cx + eyeOffsetX, eyeY + pupilDrop);

    if (mood == MonsterMood.happy) {
      // Happy = slightly upward pupils, full circles
      canvas.drawCircle(lPupil - Offset(0, eyeR * 0.06), pupilR, pupilPaint);
      canvas.drawCircle(rPupil - Offset(0, eyeR * 0.06), pupilR, pupilPaint);
    } else if (mood == MonsterMood.neutral) {
      canvas.drawCircle(lPupil, pupilR, pupilPaint);
      canvas.drawCircle(rPupil, pupilR, pupilPaint);
    } else {
      // Stressed = pupils at bottom of eye whites, slightly smaller
      canvas.drawCircle(lPupil, pupilR * 0.88, pupilPaint);
      canvas.drawCircle(rPupil, pupilR * 0.88, pupilPaint);
    }

    // Eye shines (always top-right of pupil)
    final shineOff = Offset(pupilR * 0.28, -pupilR * 0.35);
    canvas.drawCircle(lPupil + shineOff, shinR, shinePaint);
    canvas.drawCircle(rPupil + shineOff, shinR, shinePaint);

    // Small second shine dot
    canvas.drawCircle(lPupil + shineOff * 1.9, shinR * 0.48, shinePaint);
    canvas.drawCircle(rPupil + shineOff * 1.9, shinR * 0.48, shinePaint);

    // ── Eyebrows ──────────────────────────────────────────────────────────
    _drawEyebrows(canvas, size, body, cx, eyeY, eyeOffsetX, eyeR, r);

    // ── Rosy cheeks ───────────────────────────────────────────────────────
    final cheekPaint = Paint()
      ..color = const Color(0xFFF8A0A0).withValues(alpha: 0.55);
    final cheekR = r * 0.17;
    final cheekY = eyeY + eyeR * 1.35;
    canvas.drawCircle(Offset(cx - eyeOffsetX - eyeR * 0.2, cheekY), cheekR, cheekPaint);
    canvas.drawCircle(Offset(cx + eyeOffsetX + eyeR * 0.2, cheekY), cheekR, cheekPaint);

    // ── Mouth ────────────────────────────────────────────────────────────
    _drawMouth(canvas, size, cx, cy, r);

    // ── Variant accessory (drawn last so it's on top) ─────────────────────
    _drawVariantAccessory(canvas, size, body, cx, cy, r);
  }

  void _drawEyebrows(Canvas canvas, Size size, Color body, double cx,
      double eyeY, double eyeOffsetX, double eyeR, double r) {
    final browPaint = Paint()
      ..color = _shade(body).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.028
      ..strokeCap = StrokeCap.round;

    final browY = eyeY - eyeR * 1.15;
    final browW = eyeR * 1.0;

    switch (mood) {
      case MonsterMood.happy:
        // Raised arched brows — very friendly
        final lp = Path()
          ..moveTo(cx - eyeOffsetX - browW * 0.6, browY + browW * 0.15)
          ..quadraticBezierTo(
              cx - eyeOffsetX, browY - browW * 0.18, cx - eyeOffsetX + browW * 0.6, browY + browW * 0.15);
        final rp = Path()
          ..moveTo(cx + eyeOffsetX - browW * 0.6, browY + browW * 0.15)
          ..quadraticBezierTo(
              cx + eyeOffsetX, browY - browW * 0.18, cx + eyeOffsetX + browW * 0.6, browY + browW * 0.15);
        canvas.drawPath(lp, browPaint);
        canvas.drawPath(rp, browPaint);
      case MonsterMood.neutral:
        // Flat brows
        canvas.drawLine(
          Offset(cx - eyeOffsetX - browW * 0.55, browY),
          Offset(cx - eyeOffsetX + browW * 0.55, browY),
          browPaint,
        );
        canvas.drawLine(
          Offset(cx + eyeOffsetX - browW * 0.55, browY),
          Offset(cx + eyeOffsetX + browW * 0.55, browY),
          browPaint,
        );
      case MonsterMood.stressed:
        // Inner corners raised — worried V-shape
        canvas.drawLine(
          Offset(cx - eyeOffsetX - browW * 0.55, browY),
          Offset(cx - eyeOffsetX + browW * 0.45, browY - browW * 0.32),
          browPaint,
        );
        canvas.drawLine(
          Offset(cx + eyeOffsetX + browW * 0.55, browY),
          Offset(cx + eyeOffsetX - browW * 0.45, browY - browW * 0.32),
          browPaint,
        );
    }
  }

  void _drawMouth(
      Canvas canvas, Size size, double cx, double cy, double r) {
    final mouthPaint = Paint()
      ..color = const Color(0xFF2A1A1A).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.038
      ..strokeCap = StrokeCap.round;

    final mouthY = cy + r * 0.38;
    final mouthW = r * 0.44;
    final path = Path();

    switch (mood) {
      case MonsterMood.happy:
        // Big open smile — shows inner mouth colour
        path
          ..moveTo(cx - mouthW, mouthY)
          ..quadraticBezierTo(cx, mouthY + r * 0.32, cx + mouthW, mouthY);
        // Filled teeth area
        final teethPath = Path()
          ..moveTo(cx - mouthW, mouthY)
          ..quadraticBezierTo(cx, mouthY + r * 0.32, cx + mouthW, mouthY)
          ..lineTo(cx + mouthW, mouthY + r * 0.16)
          ..quadraticBezierTo(cx, mouthY + r * 0.42, cx - mouthW, mouthY + r * 0.16)
          ..close();
        canvas.drawPath(
          teethPath,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
        canvas.drawPath(path, mouthPaint);
      case MonsterMood.neutral:
        path
          ..moveTo(cx - mouthW * 0.8, mouthY)
          ..lineTo(cx + mouthW * 0.8, mouthY);
        canvas.drawPath(path, mouthPaint);
      case MonsterMood.stressed:
        // Sad frown
        path
          ..moveTo(cx - mouthW, mouthY + r * 0.10)
          ..quadraticBezierTo(cx, mouthY - r * 0.12, cx + mouthW, mouthY + r * 0.10);
        canvas.drawPath(path, mouthPaint);
    }
  }

  void _drawVariantTop(Canvas canvas, Size size, Color body, double cx,
      double cy, double r) {
    final shade = _shade(body);
    final light = _light(body);

    switch (variant) {
      case MonsterVariant.bear:
        // Round fluffy ears
        for (final side in [-1.0, 1.0]) {
          final ex = cx + side * r * 0.68;
          final ey = cy - r * 0.75;
          canvas.drawCircle(Offset(ex, ey), r * 0.25, Paint()..color = shade);
          canvas.drawCircle(Offset(ex, ey), r * 0.15, Paint()..color = light);
        }
      case MonsterVariant.fox:
        // Triangular pointy ears with inner pink
        for (final side in [-1.0, 1.0]) {
          final earPath = Path()
            ..moveTo(cx + side * r * 0.55, cy - r * 0.60)
            ..lineTo(cx + side * r * 0.22, cy - r * 1.05)
            ..lineTo(cx + side * r * 0.88, cy - r * 0.90)
            ..close();
          canvas.drawPath(earPath, Paint()..color = shade);
          final innerPath = Path()
            ..moveTo(cx + side * r * 0.55, cy - r * 0.65)
            ..lineTo(cx + side * r * 0.28, cy - r * 0.96)
            ..lineTo(cx + side * r * 0.80, cy - r * 0.85)
            ..close();
          canvas.drawPath(innerPath, Paint()..color = const Color(0xFFF8B8B0));
        }
      case MonsterVariant.dragon:
        // Chunky horns
        for (final side in [-1.0, 1.0]) {
          final hornRect = Rect.fromCenter(
            center: Offset(cx + side * r * 0.4, cy - r * 0.88),
            width: r * 0.22,
            height: r * 0.42,
          );
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              hornRect,
              topLeft: const Radius.circular(8),
              topRight: const Radius.circular(8),
            ),
            Paint()..color = shade,
          );
        }
      case MonsterVariant.dino:
        // Row of small spines on top
        for (var i = -2; i <= 2; i++) {
          final spineX = cx + i * r * 0.28;
          final spineH = r * (0.22 - i.abs() * 0.04);
          final spinePath = Path()
            ..moveTo(spineX - r * 0.08, cy - r * 0.78)
            ..lineTo(spineX, cy - r * 0.78 - spineH)
            ..lineTo(spineX + r * 0.08, cy - r * 0.78)
            ..close();
          canvas.drawPath(spinePath, Paint()..color = shade);
        }
      case MonsterVariant.hedgehog:
        // Spiky quills fan out from the top-back of the head
        final quillPaint = Paint()
          ..color = shade
          ..strokeWidth = size.width * 0.04
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        for (var i = -3; i <= 3; i++) {
          final angle = -1.5 + i * 0.32;
          final startX = cx + r * 0.55 * _cos(angle);
          final startY = cy + r * 0.55 * _sin(angle);
          final endX = cx + r * 0.92 * _cos(angle);
          final endY = cy + r * 0.92 * _sin(angle);
          canvas.drawLine(Offset(startX, startY), Offset(endX, endY), quillPaint);
        }
      default:
        break;
    }
  }

  void _drawVariantAccessory(Canvas canvas, Size size, Color body, double cx,
      double cy, double r) {
    switch (variant) {
      case MonsterVariant.octopus:
        // Three cute tentacle bumps at the bottom
        final tentaclePaint = Paint()..color = _shade(body);
        for (var i = -1; i <= 1; i++) {
          canvas.drawCircle(
            Offset(cx + i * r * 0.42, cy + r * 0.88),
            r * 0.14,
            tentaclePaint,
          );
        }
        // Sucker dots
        final suckerPaint = Paint()..color = _light(body).withValues(alpha: 0.8);
        for (var i = -1; i <= 1; i++) {
          canvas.drawCircle(
            Offset(cx + i * r * 0.42, cy + r * 0.88),
            r * 0.06,
            suckerPaint,
          );
        }
      case MonsterVariant.frog:
        // Big round eyes on TOP of head (frog style)
        final eyeBumpPaint = Paint()..color = _shade(body);
        canvas.drawCircle(Offset(cx - r * 0.38, cy - r * 0.72), r * 0.18, eyeBumpPaint);
        canvas.drawCircle(Offset(cx + r * 0.38, cy - r * 0.72), r * 0.18, eyeBumpPaint);
      case MonsterVariant.panda:
        // Black eye patches — painted behind the white eye circles
        // (we draw them AFTER the body but BEFORE the eyes in paint() order,
        // but since this is called last we just add decorative dark rings)
        final patchPaint = Paint()
          ..color = const Color(0xFF2A2A35).withValues(alpha: 0.18);
        final eyeY = cy - r * 0.10;
        final eyeOffsetX = r * 0.33;
        final eyeR = r * 0.245;
        canvas.drawCircle(Offset(cx - eyeOffsetX, eyeY), eyeR * 1.45, patchPaint);
        canvas.drawCircle(Offset(cx + eyeOffsetX, eyeY), eyeR * 1.45, patchPaint);
      default:
        break;
    }
  }

  // Simple trig helpers to avoid importing dart:math in painter.
  static double _cos(double rad) {
    // Taylor series for cosine — accurate enough for small angles
    double x = rad % (3.14159265 * 2);
    return 1 -
        x * x / 2 +
        x * x * x * x / 24 -
        x * x * x * x * x * x / 720;
  }

  static double _sin(double rad) {
    double x = rad % (3.14159265 * 2);
    return x - x * x * x / 6 + x * x * x * x * x / 120;
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
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (60000 / bpm).round()),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.10).animate(
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
