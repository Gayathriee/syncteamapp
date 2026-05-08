import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// The SyncRing is the visual centrepiece of the session room.
/// It shows group synchrony (0–1) as an animated arc that fills clockwise.
///
/// Colour encoding mirrors the intervention thresholds in AppConstants:
///   0.00–0.30  coral  (R1 zone — guided breathing may fire)
///   0.30–0.60  mustard (building toward flow)
///   0.60–0.80  teal   (R2 zone — positive reinforcement)
///   0.80–1.00  sage   (peak flow)
class SyncRing extends StatefulWidget {
  const SyncRing({
    super.key,
    required this.syncIndex,
    this.size = 180,
    this.strokeWidth = 14,
    this.showLabel = true,
  });

  final double syncIndex;
  final double size;
  final double strokeWidth;
  final bool showLabel;

  @override
  State<SyncRing> createState() => _SyncRingState();
}

class _SyncRingState extends State<SyncRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animatedSync;
  double _previousSync = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animatedSync = Tween(begin: 0.0, end: widget.syncIndex).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SyncRing old) {
    super.didUpdateWidget(old);
    if (old.syncIndex != widget.syncIndex) {
      _previousSync = _animatedSync.value;
      _animatedSync = Tween(begin: _previousSync, end: widget.syncIndex).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForSync(double sync) {
    if (sync < 0.30) return AppColors.syncLow;
    if (sync < 0.60) {
      return Color.lerp(AppColors.syncLow, AppColors.syncMid, (sync - 0.30) / 0.30)!;
    }
    if (sync < 0.80) {
      return Color.lerp(AppColors.syncMid, AppColors.syncHigh, (sync - 0.60) / 0.20)!;
    }
    return Color.lerp(AppColors.syncHigh, AppColors.syncPeak, (sync - 0.80) / 0.20)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animatedSync,
      builder: (_, __) {
        final current = _animatedSync.value;
        final colour = _colorForSync(current);
        final percent = (current * 100).round();

        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SyncRingPainter(
            syncValue: current,
            ringColor: colour,
            trackColor: Colors.white.withValues(alpha: 0.08),
            strokeWidth: widget.strokeWidth,
          ),
          child: widget.showLabel
              ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percent%',
                        style: AppTypography.sessionNumeric.copyWith(
                          color: colour,
                          fontSize: widget.size * 0.2,
                        ),
                      ),
                      Text(
                        'group sync',
                        style: AppTypography.sessionBody.copyWith(
                          fontSize: widget.size * 0.07,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _SyncRingPainter extends CustomPainter {
  _SyncRingPainter({
    required this.syncValue,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double syncValue;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * syncValue,
      false,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SyncRingPainter old) =>
      old.syncValue != syncValue || old.ringColor != ringColor;
}
