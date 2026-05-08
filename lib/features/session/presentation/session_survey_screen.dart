import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';

/// Post-session NASA-TLX survey plus two qualitative questions.
///
/// NASA-TLX uses a 0–20 scale per dimension (Hart & Staveland, 1988).
/// We present it as 0–10 for simplicity and multiply by 2 before storing,
/// so the scale is still standard in the export but less intimidating in the UI.
///
/// The two qualitative questions are not in the original TLX — they're added
/// to give the thematic analysis in §5.3 something to work with.
class SessionSurveyScreen extends ConsumerStatefulWidget {
  const SessionSurveyScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<SessionSurveyScreen> createState() =>
      _SessionSurveyScreenState();
}

class _SessionSurveyScreenState extends ConsumerState<SessionSurveyScreen> {
  // NASA-TLX dimensions, stored as 0–10 sliders (×2 on submit = 0–20 scale)
  final Map<String, double> _tlxValues = {
    'mentalDemand': 5.0,
    'physicalDemand': 5.0,
    'temporalDemand': 5.0,
    'performance': 5.0,
    'effort': 5.0,
    'frustration': 5.0,
  };

  int _teamCommunication = 3; // 1–5 star rating
  final _wentWellController = TextEditingController();
  final _challengingController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final user =
        ref.read(currentUserModelProvider).valueOrNull;

    try {
      await ref.read(sessionRepositoryProvider).submitSurvey(
        sessionId: widget.sessionId,
        userId: user?.uid ?? 'unknown',
        responses: {
          // Store the standard 0–20 scale in Firestore for analysis in SPSS
          'tlxMentalDemand': (_tlxValues['mentalDemand']! * 2).round(),
          'tlxPhysicalDemand': (_tlxValues['physicalDemand']! * 2).round(),
          'tlxTemporalDemand': (_tlxValues['temporalDemand']! * 2).round(),
          'tlxPerformance': (_tlxValues['performance']! * 2).round(),
          'tlxEffort': (_tlxValues['effort']! * 2).round(),
          'tlxFrustration': (_tlxValues['frustration']! * 2).round(),
          'teamCommunication': _teamCommunication,
          'wentWell': _wentWellController.text.trim(),
          'challenging': _challengingController.text.trim(),
        },
      );
      if (mounted) context.go('/session/${widget.sessionId}/results');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _wentWellController.dispose();
    _challengingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('how did that feel?', style: AppTypography.headingMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'take your time — these answers help us understand how the task felt, not how well you performed.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.teal),
              ),
            ),
            const SizedBox(height: 24),
            Text('workload rating', style: AppTypography.headingSmall),
            const SizedBox(height: 4),
            Text(
              'move each slider to match how you felt during the task (NASA Task Load Index)',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            _TlxSlider(
              label: 'Mental Demand',
              description: 'How much thinking, deciding, calculating, remembering was required?',
              value: _tlxValues['mentalDemand']!,
              onChanged: (v) => setState(() => _tlxValues['mentalDemand'] = v),
            ),
            _TlxSlider(
              label: 'Physical Demand',
              description: 'How much physical activity was required?',
              value: _tlxValues['physicalDemand']!,
              onChanged: (v) => setState(() => _tlxValues['physicalDemand'] = v),
            ),
            _TlxSlider(
              label: 'Time Pressure',
              description: 'How much time pressure did you feel?',
              value: _tlxValues['temporalDemand']!,
              onChanged: (v) => setState(() => _tlxValues['temporalDemand'] = v),
            ),
            _TlxSlider(
              label: 'Performance',
              description: 'How successful were you at the task? (low = very successful)',
              value: _tlxValues['performance']!,
              onChanged: (v) => setState(() => _tlxValues['performance'] = v),
              lowLabel: 'perfect',
              highLabel: 'failure',
            ),
            _TlxSlider(
              label: 'Effort',
              description: 'How hard did you have to work?',
              value: _tlxValues['effort']!,
              onChanged: (v) => setState(() => _tlxValues['effort'] = v),
            ),
            _TlxSlider(
              label: 'Frustration',
              description: 'How irritated, stressed, or annoyed did you feel?',
              value: _tlxValues['frustration']!,
              onChanged: (v) => setState(() => _tlxValues['frustration'] = v),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),
            Text('team communication', style: AppTypography.headingSmall),
            const SizedBox(height: 4),
            Text('how well did your team communicate during the task?',
                style: AppTypography.bodySmall),
            const SizedBox(height: 12),
            _StarRating(
              value: _teamCommunication,
              onChanged: (v) => setState(() => _teamCommunication = v),
            ),
            const SizedBox(height: 24),
            Text('open questions', style: AppTypography.headingSmall),
            const SizedBox(height: 16),
            Text('what went well?', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _wentWellController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. we divided the work clearly...',
              ),
            ),
            const SizedBox(height: 16),
            Text('what was challenging?', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _challengingController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. we disagreed on the approach...',
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('submit survey →'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TlxSlider extends StatelessWidget {
  const _TlxSlider({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.lowLabel = 'low',
    this.highLabel = 'high',
  });
  final String label;
  final String description;
  final double value;
  final ValueChanged<double> onChanged;
  final String lowLabel;
  final String highLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.labelMedium),
              Text(value.round().toString(),
                  style: AppTypography.numericMedium.copyWith(
                      fontSize: 14, color: AppColors.coral)),
            ],
          ),
          const SizedBox(height: 2),
          Text(description, style: AppTypography.bodySmall),
          Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: AppColors.coral,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lowLabel, style: AppTypography.caption),
              Text(highLabel, style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              i < value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < value ? AppColors.mustard : AppColors.border,
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}
