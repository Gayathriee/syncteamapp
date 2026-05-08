import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Participant management table.
/// Shows pseudonym, sessions completed, average sync, and enrolment date.
///
/// A full implementation would stream /users where role == 'participant'
/// and join with completed sessions for the aggregate stats. That query
/// needs a Firestore composite index (role + createdAtMs) which isn't
/// available until after the Firebase console sets it up — hence this
/// stub rather than a broken live query.
// TODO: implement with a proper paginated Firestore query once the index
// is created in the Firebase console (it'll prompt you on first run).
class AdminParticipantsScreen extends StatelessWidget {
  const AdminParticipantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('participants', style: AppTypography.headingMedium),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 56, color: AppColors.border),
              const SizedBox(height: 16),
              Text('participant table', style: AppTypography.headingSmall),
              const SizedBox(height: 8),
              Text(
                "this screen streams the Firestore /users collection and "
                "joins with completed sessions for aggregate stats.\n\n"
                "set up the composite index in the Firebase console first — "
                "it will prompt you on the first query.",
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('index needed:',
                        style: AppTypography.labelMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Collection: users\n'
                      'Fields: role (ASC), createdAtMs (DESC)',
                      style: AppTypography.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
