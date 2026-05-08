import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/session/domain/intervention_model.dart';

/// Slides in from the bottom when a new intervention arrives.
/// Auto-dismisses after 8s — long enough to read, short enough not to
/// block the task view for the full 90s cooldown between interventions.
///
/// The left border colour (mustard = AI, lavender = admin) distinguishes
/// sources visually and matters for the audit trail in §5.2.
class InterventionToast extends StatefulWidget {
  const InterventionToast({
    super.key,
    required this.intervention,
    required this.onDismiss,
  });

  final InterventionModel intervention;
  final VoidCallback onDismiss;

  @override
  State<InterventionToast> createState() => _InterventionToastState();
}

class _InterventionToastState extends State<InterventionToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 8), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAi = widget.intervention.source == InterventionSource.ai;
    final borderColor = isAi ? AppColors.interventionAi : AppColors.interventionAdmin;
    final sourceLabel =
        isAi ? '🤖 ${widget.intervention.ruleId}' : '👩‍🔬 researcher note';

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.sessionSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: borderColor, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sourceLabel,
                        style: AppTypography.caption.copyWith(
                          color: borderColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.intervention.message, style: AppTypography.sessionBody),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.white38),
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
