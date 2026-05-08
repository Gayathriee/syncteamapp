import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Data export screen. In production this triggers a Cloud Function that
/// compiles all surveys, HRV summaries, and intervention logs into a CSV
/// and returns a download URL.
///
/// The export is server-side for two reasons:
///   1. Firestore security rules don't allow participants to read other
///      participants' survey data — only the admin Cloud Function context
///      has the necessary privileges.
///   2. Cross-joining sessions × surveys × HRV summaries is too slow to
///      do client-side at 30 participants × 3 sessions each.
// TODO: wire up the Cloud Function trigger and display the download link
// once the Functions are deployed. The button below should call an HTTPS
// callable function and poll for completion.
class AdminExportScreen extends StatefulWidget {
  const AdminExportScreen({super.key});

  @override
  State<AdminExportScreen> createState() => _AdminExportScreenState();
}

class _AdminExportScreenState extends State<AdminExportScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('export data', style: AppTypography.headingMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ExportCard(
              icon: Icons.favorite_outlined,
              title: 'HRV summaries',
              description:
                  'Per-participant resting RMSSD, session RMSSD, BPM mean, '
                  'and signal quality per session. One row per participant × session.',
              color: AppColors.coral,
            ),
            const SizedBox(height: 12),
            const _ExportCard(
              icon: Icons.sync_rounded,
              title: 'synchrony windows',
              description:
                  'Group synchrony index and pairwise Pearson r values sampled '
                  'every 15s per session. Useful for time-series analysis in R.',
              color: AppColors.teal,
            ),
            const SizedBox(height: 12),
            const _ExportCard(
              icon: Icons.assignment_rounded,
              title: 'survey responses',
              description:
                  'NASA-TLX scores (0–20 per dimension), team communication rating, '
                  'and verbatim open-ended responses. One row per participant × session.',
              color: AppColors.mustard,
            ),
            const SizedBox(height: 12),
            const _ExportCard(
              icon: Icons.notifications_rounded,
              title: 'intervention log',
              description:
                  'All interventions with rule ID, source (AI/admin), timestamp, '
                  'and sync index at time of firing. For §5.2 analysis.',
              color: AppColors.lavender,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mustardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mustard.withValues(alpha: 0.3)),
              ),
              child: Text(
                '⚠️  the export function is not yet deployed. '
                'trigger it manually from the Firebase Functions console '
                'or run: firebase functions:call exportStudyData',
                style:
                    AppTypography.bodySmall.copyWith(color: const Color(0xFF6B5A00)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _triggerExport,
              icon: _isExporting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_isExporting ? 'generating...' : 'export all data'),
            ),
            const SizedBox(height: 8),
            Text(
              'CSV files will be sent to your registered researcher email.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _triggerExport() {
    setState(() => _isExporting = true);
    // Simulate async — replace with actual Cloud Function call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('export function not yet deployed — see TODO above')),
        );
      }
    });
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelMedium),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
