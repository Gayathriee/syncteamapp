import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

/// Lets the researcher tune intervention rule thresholds before the study.
///
/// These defaults mirror AppConstants — changing them here should also
/// update a Firestore /config/aiRules document that the Cloud Function reads.
/// For now the sliders are purely local (no Firestore write) because the
/// Cloud Function reads AppConstants directly in the prototype.
// TODO: write slider values to /config/aiRules so the Cloud Function
// picks them up without a redeploy — straightforward once the study config
// doc structure is finalised.
class AdminAiConfigScreen extends ConsumerStatefulWidget {
  const AdminAiConfigScreen({super.key});

  @override
  ConsumerState<AdminAiConfigScreen> createState() =>
      _AdminAiConfigScreenState();
}

class _AdminAiConfigScreenState extends ConsumerState<AdminAiConfigScreen> {
  double _r1SyncLow = AppConstants.syncLowThreshold;
  double _r2SyncHigh = AppConstants.syncHighThreshold;
  double _r3RmssdDrop = AppConstants.rmssdDropFraction;
  int _cooldownSec = AppConstants.interventionCooldownSec;

  bool _r1Enabled = true;
  bool _r2Enabled = true;
  bool _r3Enabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AI rule config', style: AppTypography.headingMedium),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: Text('save',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.coral)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _InfoBanner(
              text: 'changes affect new sessions only — currently running '
                  'sessions use the thresholds from when they started.',
            ),
            const SizedBox(height: 24),

            _RuleCard(
              ruleId: 'R1',
              title: 'guided breathing',
              description:
                  'fires if group sync stays below the threshold for >5 minutes',
              enabled: _r1Enabled,
              onToggle: (v) => setState(() => _r1Enabled = v),
              color: AppColors.coral,
              sliders: [
                _ThresholdSlider(
                  label: 'sync low threshold',
                  value: _r1SyncLow,
                  min: 0.10,
                  max: 0.60,
                  format: (v) => '${(v * 100).round()}%',
                  onChanged: (v) => setState(() => _r1SyncLow = v),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _RuleCard(
              ruleId: 'R2',
              title: 'flow reinforcement',
              description:
                  'positive message when sync exceeds the threshold and task is progressing',
              enabled: _r2Enabled,
              onToggle: (v) => setState(() => _r2Enabled = v),
              color: AppColors.sage,
              sliders: [
                _ThresholdSlider(
                  label: 'sync high threshold',
                  value: _r2SyncHigh,
                  min: 0.40,
                  max: 0.90,
                  format: (v) => '${(v * 100).round()}%',
                  onChanged: (v) => setState(() => _r2SyncHigh = v),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _RuleCard(
              ruleId: 'R3',
              title: 'personal check-in',
              description:
                  "fires if one member's RMSSD drops more than the threshold from their personal baseline",
              enabled: _r3Enabled,
              onToggle: (v) => setState(() => _r3Enabled = v),
              color: AppColors.lavender,
              sliders: [
                _ThresholdSlider(
                  label: 'RMSSD drop fraction',
                  value: _r3RmssdDrop,
                  min: 0.20,
                  max: 0.70,
                  format: (v) => '${(v * 100).round()}%',
                  onChanged: (v) => setState(() => _r3RmssdDrop = v),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('global cooldown', style: AppTypography.headingSmall),
            const SizedBox(height: 4),
            Text(
              'minimum gap between any two interventions for a given session',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            _ThresholdSlider(
              label: 'cooldown',
              value: _cooldownSec.toDouble(),
              min: 30,
              max: 300,
              format: (v) => '${v.round()}s',
              onChanged: (v) => setState(() => _cooldownSec = v.round()),
            ),
          ],
        ),
      ),
    );
  }

  void _saveConfig() {
    // TODO: write to /config/aiRules in Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('config saved (local only for now)')),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mustardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.mustard.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.mustard),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: AppTypography.bodySmall
                      .copyWith(color: const Color(0xFF6B5A00)))),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.ruleId,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onToggle,
    required this.color,
    required this.sliders,
  });
  final String ruleId;
  final String title;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Color color;
  final List<Widget> sliders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: enabled ? color.withValues(alpha: 0.1) : AppColors.cream,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(ruleId,
                    style: AppTypography.labelSmall.copyWith(
                        color: enabled ? color : AppColors.warm,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTypography.labelMedium),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: color,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: AppTypography.bodySmall),
          if (enabled) ...[
            const SizedBox(height: 12),
            ...sliders,
          ],
        ],
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.format,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTypography.bodySmall),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppColors.coral,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(format(value),
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.coral),
              textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
