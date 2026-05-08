import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../../shared/widgets/sync_ring.dart';
import '../../../shared/widgets/monster_avatar.dart';
import '../../../shared/widgets/intervention_toast.dart';
import '../../auth/domain/user_model.dart';
import '../domain/session_model.dart';
import '../domain/hrv_sample.dart';
import '../domain/intervention_model.dart';

final _sessionStreamProvider = StreamProvider.family<SessionModel?, String>(
  (ref, sessionId) =>
      ref.watch(sessionRepositoryProvider).watchSession(sessionId),
);

final _syncStreamProvider = StreamProvider.family<double, String>(
  (ref, sessionId) => ref
      .watch(sessionRepositoryProvider)
      .watchLatestSynchrony(sessionId)
      .map((w) => w?.groupIndex ?? 0.0),
);

final _interventionsStreamProvider =
    StreamProvider.family<List<InterventionModel>, String>(
  (ref, sessionId) =>
      ref.watch(sessionRepositoryProvider).watchInterventions(sessionId),
);

final _hrvStreamProvider = StreamProvider.family<HrvSample?,
    ({String sessionId, String userId})>(
  (ref, args) => ref.watch(sessionRepositoryProvider).watchLiveHrv(
        sessionId: args.sessionId,
        userId: args.userId,
      ),
);

class SessionRoomScreen extends ConsumerStatefulWidget {
  const SessionRoomScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<SessionRoomScreen> createState() => _SessionRoomScreenState();
}

class _SessionRoomScreenState extends ConsumerState<SessionRoomScreen> {
  final _answerController = TextEditingController();
  bool _answerSubmitted = false;

  // 60 samples at 5s each = 5 minutes of sparkline history.
  // Keeps the list bounded — no need for a circular buffer at this scale.
  final List<FlSpot> _syncHistory = [];
  int _syncTick = 0;

  final Set<String> _shownInterventionIds = {};

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(_sessionStreamProvider(widget.sessionId));
    final syncAsync = ref.watch(_syncStreamProvider(widget.sessionId));
    final interventionsAsync =
        ref.watch(_interventionsStreamProvider(widget.sessionId));
    final currentUser = ref.watch(currentUserModelProvider).valueOrNull;

    final syncIndex = syncAsync.valueOrNull ?? 0.0;

    // Append to sparkline whenever a new synchrony value arrives
    ref.listen(_syncStreamProvider(widget.sessionId), (_, next) {
      next.whenData((value) {
        if (mounted) {
          setState(() {
            if (_syncHistory.length >= 60) _syncHistory.removeAt(0);
            _syncHistory.add(FlSpot(_syncTick.toDouble(), value));
            _syncTick++;
          });
        }
      });
    });

    // React to session status changes driven by the admin
    ref.listen(_sessionStreamProvider(widget.sessionId), (_, next) {
      next.whenData((session) {
        if (session == null) return;
        switch (session.status) {
          case SessionStatus.survey:
            context.go('/session/${widget.sessionId}/survey');
          case SessionStatus.breakTime:
            context.go('/session/${widget.sessionId}/break');
          case SessionStatus.complete:
            context.go('/session/${widget.sessionId}/results');
          default:
            break;
        }
      });
    });

    return sessionAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.sessionDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.sessionDark,
        body: Center(
            child: Text('could not load session',
                style: AppTypography.sessionBody)),
      ),
      data: (session) {
        if (session == null) {
          return Scaffold(
            backgroundColor: AppColors.sessionDark,
            body: Center(
                child:
                    Text('session not found', style: AppTypography.sessionBody)),
          );
        }

        // Show calibration view during baseline phase
        if (session.status == SessionStatus.calibrating ||
            session.status == SessionStatus.waiting) {
          return _CalibrationView(session: session);
        }

        final interventions = interventionsAsync.valueOrNull ?? [];
        final newInterventions =
            interventions.where((i) => !_shownInterventionIds.contains(i.id)).toList();

        return Scaffold(
          backgroundColor: AppColors.sessionDark,
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SessionHeader(session: session),
                      const SizedBox(height: 20),
                      SyncRing(syncIndex: syncIndex, size: 160),
                      const SizedBox(height: 20),
                      _TeamRow(
                        sessionId: widget.sessionId,
                        session: session,
                        currentUser: currentUser,
                      ),
                      const SizedBox(height: 16),
                      if (_syncHistory.length > 2)
                        _SyncSparkline(syncHistory: _syncHistory),
                      const SizedBox(height: 16),
                      _TaskCard(session: session),
                      const SizedBox(height: 16),
                      if (!_answerSubmitted)
                        _AnswerSection(
                          sessionId: widget.sessionId,
                          userId: currentUser?.uid ?? '',
                          taskId: session.currentTaskId ?? '',
                          controller: _answerController,
                          onSubmitted: () =>
                              setState(() => _answerSubmitted = true),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                if (newInterventions.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: InterventionToast(
                      intervention: newInterventions.last,
                      onDismiss: () {
                        if (mounted) {
                          setState(() =>
                              _shownInterventionIds.add(newInterventions.last.id));
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shown during the 90s baseline calibration phase.
/// The breathing animation gives participants something to focus on while
/// the sensor records resting RMSSD — it also helps actually lower arousal.
class _CalibrationView extends StatefulWidget {
  const _CalibrationView({required this.session});
  final SessionModel session;

  @override
  State<_CalibrationView> createState() => _CalibrationViewState();
}

class _CalibrationViewState extends State<_CalibrationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  @override
  void initState() {
    super.initState();
    // 4s inhale, 4s exhale — a simple paced-breathing cue that's been
    // shown to reduce HRV noise during resting baseline capture.
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathScale = Tween(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWaiting = widget.session.status == SessionStatus.waiting;

    return Scaffold(
      backgroundColor: AppColors.sessionDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _breathScale,
                builder: (_, child) => Transform.scale(
                  scale: _breathScale.value,
                  child: child,
                ),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.teal.withValues(alpha: 0.15),
                    border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: AppColors.teal, size: 48),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isWaiting ? 'waiting for session to start' : 'establishing your baseline',
                style: AppTypography.sessionHeading.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isWaiting
                    ? 'the researcher will begin shortly — sit back and relax'
                    : 'breathe in... and out... stay calm and still\nthis takes about 90 seconds',
                style: AppTypography.sessionBody,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionHeader extends ConsumerWidget {
  const _SessionHeader({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('session · ${session.status.name}',
            style: AppTypography.sessionBody),
        _SessionTimer(startedAtMs: session.startedAtMs),
      ],
    );
  }
}

class _SessionTimer extends StatefulWidget {
  const _SessionTimer({this.startedAtMs});
  final int? startedAtMs;

  @override
  State<_SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends State<_SessionTimer> {
  late final Stream<Duration> _tick;

  @override
  void initState() {
    super.initState();
    _tick = Stream.periodic(const Duration(seconds: 1), (_) {
      if (widget.startedAtMs == null) return Duration.zero;
      return Duration(
          milliseconds:
              DateTime.now().millisecondsSinceEpoch - widget.startedAtMs!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: _tick,
      builder: (_, snap) {
        final elapsed = snap.data ?? Duration.zero;
        final m = elapsed.inMinutes.toString().padLeft(2, '0');
        final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
        return Text('$m:$s', style: AppTypography.sessionNumeric);
      },
    );
  }
}

class _TeamRow extends ConsumerWidget {
  const _TeamRow({
    required this.sessionId,
    required this.session,
    this.currentUser,
  });
  final String sessionId;
  final SessionModel session;
  final UserModel? currentUser;

  static const _variantCycle = [
    MonsterVariant.octopus,
    MonsterVariant.dragon,
    MonsterVariant.fox,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(session.memberUids.length, (i) {
        final uid = session.memberUids[i];
        final isMe = uid == currentUser?.uid;
        final variant = isMe
            ? (currentUser?.monsterVariant ?? _variantCycle[i % 3])
            : _variantCycle[i % 3];

        return _MemberTile(
          sessionId: sessionId,
          userId: uid,
          variant: variant,
          pseudonym: isMe ? 'you' : 'teammate',
          baselineRmssd:
              isMe ? currentUser?.baselineRmssdMs : null,
        );
      }),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.sessionId,
    required this.userId,
    required this.variant,
    required this.pseudonym,
    this.baselineRmssd,
  });
  final String sessionId;
  final String userId;
  final MonsterVariant variant;
  final String pseudonym;
  final double? baselineRmssd;

  MonsterMood _moodFromHrv(HrvSample? s, double? baseline) {
    if (s?.rmssdMs == null || baseline == null) return MonsterMood.neutral;
    final drop = (baseline - s!.rmssdMs!) / baseline;
    if (drop > 0.40) return MonsterMood.stressed;
    if (drop > 0.20) return MonsterMood.neutral;
    return MonsterMood.happy;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hrvAsync = ref
        .watch(_hrvStreamProvider((sessionId: sessionId, userId: userId)));
    final hrv = hrvAsync.valueOrNull;
    final bpm = hrv?.bpm;

    return Column(
      children: [
        MonsterAvatar(
          variant: variant,
          mood: _moodFromHrv(hrv, baselineRmssd),
          size: 56,
          showPulse: bpm != null,
          bpm: bpm,
        ),
        const SizedBox(height: 6),
        Text(pseudonym, style: AppTypography.caption),
        if (bpm != null)
          Text(
            '${bpm.round()} bpm',
            style: AppTypography.caption.copyWith(
              color: AppColors.signalGood,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                    color: AppColors.signalNoisy, shape: BoxShape.circle),
              ),
              const SizedBox(width: 3),
              Text('waiting',
                  style: AppTypography.caption.copyWith(fontSize: 9)),
            ],
          ),
      ],
    );
  }
}

class _SyncSparkline extends StatelessWidget {
  const _SyncSparkline({required this.syncHistory});
  final List<FlSpot> syncHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.sessionSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: syncHistory,
              isCurved: true,
              color: AppColors.teal,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.teal.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sessionSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('your task',
              style: AppTypography.caption
                  .copyWith(color: Colors.white38, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(
            // Task content is loaded separately in production — see TaskModel.
            // For the study prototype, the admin sets task text in Firestore
            // and this widget would watch a tasks/{currentTaskId} document.
            // Keeping it simple here so session doc stays lean.
            'Task details load here from the Firestore task document.\n'
            'Task ID: ${session.currentTaskId ?? 'not set'}',
            style: AppTypography.sessionBody,
          ),
        ],
      ),
    );
  }
}

class _AnswerSection extends ConsumerWidget {
  const _AnswerSection({
    required this.sessionId,
    required this.userId,
    required this.taskId,
    required this.controller,
    required this.onSubmitted,
  });
  final String sessionId;
  final String userId;
  final String taskId;
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          style: AppTypography.sessionBody,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "your team's answer...",
            hintStyle: AppTypography.sessionBody.copyWith(color: Colors.white24),
            filled: true,
            fillColor: AppColors.sessionSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.trim().isEmpty) return;
            await ref.read(sessionRepositoryProvider).submitAnswer(
                  sessionId: sessionId,
                  userId: userId,
                  answer: controller.text.trim(),
                  taskId: taskId,
                );
            onSubmitted();
          },
          child: const Text('submit answer'),
        ),
      ],
    );
  }
}
