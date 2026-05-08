import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../../shared/widgets/sync_ring.dart';
import '../../session/domain/session_model.dart';

final _activeSessionsProvider = StreamProvider<List<SessionModel>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchAllActiveSessions();
});

class AdminLiveListScreen extends ConsumerWidget {
  const AdminLiveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_activeSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.sessionDarker,
      appBar: AppBar(
        backgroundColor: AppColors.sessionDarker,
        foregroundColor: Colors.white,
        title: Text('live sessions',
            style: AppTypography.sessionHeading.copyWith(fontSize: 16)),
        actions: [
          // Refresh indicator — RTDB is real-time so this is cosmetic,
          // but participants expect something to show the app is live
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.signalGood, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text('live',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.signalGood)),
              ],
            ),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(
            child: Text('could not load sessions',
                style: AppTypography.sessionBody)),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sensors_off_rounded,
                      size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text('no active sessions',
                      style: AppTypography.sessionHeading
                          .copyWith(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('start a session from here to see it appear',
                      style: AppTypography.sessionBody),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (_, i) => _LiveSessionCard(session: sessions[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.coral,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('new session',
            style: AppTypography.labelMedium.copyWith(color: Colors.white)),
        onPressed: () => _showCreateSessionDialog(context, ref),
      ),
    );
  }

  void _showCreateSessionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CreateSessionDialog(ref: ref),
    );
  }
}

class _LiveSessionCard extends ConsumerWidget {
  const _LiveSessionCard({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(
      StreamProvider.family<double, String>(
        (ref, id) => ref
            .watch(sessionRepositoryProvider)
            .watchLatestSynchrony(id)
            .map((w) => w?.groupIndex ?? 0.0),
      )(session.id),
    );

    final syncIndex = syncAsync.valueOrNull ?? session.latestSyncIndex ?? 0.0;

    final elapsed = session.startedAtMs != null
        ? Duration(
            milliseconds:
                DateTime.now().millisecondsSinceEpoch - session.startedAtMs!)
        : null;
    final elapsedLabel = elapsed != null
        ? '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s'
        : 'not started';

    return GestureDetector(
      onTap: () => context.go('/admin/session/${session.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sessionSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            SyncRing(
              syncIndex: syncIndex,
              size: 64,
              strokeWidth: 5,
              showLabel: false,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusDot(status: session.status),
                      const SizedBox(width: 6),
                      Text(session.status.name,
                          style: AppTypography.labelSmall
                              .copyWith(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(syncIndex * 100).round()}% sync · $elapsedLabel',
                    style: AppTypography.sessionBody.copyWith(fontSize: 14),
                  ),
                  Text(
                    '${session.memberUids.length} members',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final SessionStatus status;

  Color get _color {
    switch (status) {
      case SessionStatus.task:
        return AppColors.signalGood;
      case SessionStatus.calibrating:
        return AppColors.signalNoisy;
      case SessionStatus.survey:
      case SessionStatus.breakTime:
        return AppColors.mustard;
      default:
        return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
    );
  }
}

class _CreateSessionDialog extends StatefulWidget {
  const _CreateSessionDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  final _teamIdCtrl = TextEditingController();
  final _uid1Ctrl = TextEditingController();
  final _uid2Ctrl = TextEditingController();
  final _uid3Ctrl = TextEditingController();
  final _taskIdCtrl = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _teamIdCtrl.dispose();
    _uid1Ctrl.dispose();
    _uid2Ctrl.dispose();
    _uid3Ctrl.dispose();
    _taskIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('create session', style: AppTypography.headingSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _teamIdCtrl,
              decoration:
                  const InputDecoration(hintText: 'team ID (e.g. team-A)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _uid1Ctrl,
              decoration:
                  const InputDecoration(hintText: 'participant 1 UID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _uid2Ctrl,
              decoration:
                  const InputDecoration(hintText: 'participant 2 UID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _uid3Ctrl,
              decoration:
                  const InputDecoration(hintText: 'participant 3 UID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskIdCtrl,
              decoration: const InputDecoration(hintText: 'task ID'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating
              ? null
              : () async {
                  setState(() => _isCreating = true);
                  final memberUids = [
                    _uid1Ctrl.text.trim(),
                    _uid2Ctrl.text.trim(),
                    _uid3Ctrl.text.trim(),
                  ].where((s) => s.isNotEmpty).toList();

                  final nav = Navigator.of(context);
                  await widget.ref.read(sessionRepositoryProvider).createSession(
                        teamId: _teamIdCtrl.text.trim(),
                        memberUids: memberUids,
                        taskId: _taskIdCtrl.text.trim(),
                      );
                  if (mounted) nav.pop();
                },
          child: _isCreating
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('create'),
        ),
      ],
    );
  }
}
