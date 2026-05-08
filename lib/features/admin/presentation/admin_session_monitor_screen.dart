import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../../shared/widgets/sync_ring.dart';
import '../../session/domain/session_model.dart';
import '../../session/domain/intervention_model.dart';

class AdminSessionMonitorScreen extends ConsumerStatefulWidget {
  const AdminSessionMonitorScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<AdminSessionMonitorScreen> createState() =>
      _AdminSessionMonitorScreenState();
}

class _AdminSessionMonitorScreenState
    extends ConsumerState<AdminSessionMonitorScreen> {
  final _manualMessageController = TextEditingController();
  String _selectedRuleId = 'R_MANUAL';
  bool _isSendingIntervention = false;

  @override
  void dispose() {
    _manualMessageController.dispose();
    super.dispose();
  }

  Future<void> _sendManualIntervention(String adminUid) async {
    final message = _manualMessageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSendingIntervention = true);
    try {
      await ref.read(sessionRepositoryProvider).sendManualIntervention(
            sessionId: widget.sessionId,
            message: message,
            ruleId: _selectedRuleId,
            adminUid: adminUid,
          );
      _manualMessageController.clear();
    } finally {
      if (mounted) setState(() => _isSendingIntervention = false);
    }
  }

  Future<void> _advance(SessionStatus newStatus) async {
    await ref.read(sessionRepositoryProvider).advanceSessionStatus(
          sessionId: widget.sessionId,
          newStatus: newStatus,
        );
  }

  Future<void> _toggleAi(bool enabled) async {
    await ref
        .read(sessionRepositoryProvider)
        .toggleAi(sessionId: widget.sessionId, enabled: enabled);
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(
      StreamProvider.family<SessionModel?, String>(
        (ref, id) => ref.watch(sessionRepositoryProvider).watchSession(id),
      )(widget.sessionId),
    );
    final interventionsAsync = ref.watch(
      StreamProvider.family<List<InterventionModel>, String>(
        (ref, id) =>
            ref.watch(sessionRepositoryProvider).watchInterventions(id),
      )(widget.sessionId),
    );
    final syncAsync = ref.watch(
      StreamProvider.family<double, String>(
        (ref, id) => ref
            .watch(sessionRepositoryProvider)
            .watchLatestSynchrony(id)
            .map((w) => w?.groupIndex ?? 0.0),
      )(widget.sessionId),
    );
    final currentUser = ref.watch(currentUserModelProvider).valueOrNull;

    final syncIndex = syncAsync.valueOrNull ?? 0.0;
    final session = sessionAsync.valueOrNull;
    final interventions = interventionsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.sessionDarker,
      appBar: AppBar(
        backgroundColor: AppColors.sessionDarker,
        foregroundColor: Colors.white,
        title: Text('live monitor',
            style: AppTypography.sessionHeading.copyWith(fontSize: 16)),
        actions: [
          if (session != null)
            Row(
              children: [
                Text('AI',
                    style:
                        AppTypography.caption.copyWith(color: Colors.white60)),
                Switch(
                  value: session.aiEnabled,
                  onChanged: _toggleAi,
                  activeThumbColor: AppColors.teal,
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync overview
            Row(
              children: [
                SyncRing(syncIndex: syncIndex, size: 90, strokeWidth: 8),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('group sync index',
                          style: AppTypography.caption
                              .copyWith(color: Colors.white38)),
                      Text('${(syncIndex * 100).round()}%',
                          style: AppTypography.sessionNumeric
                              .copyWith(fontSize: 32)),
                      const SizedBox(height: 4),
                      _StatusChip(status: session?.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Session control buttons
            if (session != null) _SessionControls(session: session, onAdvance: _advance),
            const SizedBox(height: 20),

            // Member HRV stats (static for now — real impl watches per-member RTDB nodes)
            Text('MEMBER STATS',
                style: AppTypography.caption
                    .copyWith(color: Colors.white38, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _MemberStatsRow(sessionId: widget.sessionId, session: session),
            const SizedBox(height: 20),

            // Live HRV waveform chart
            Text('HRV WAVEFORM',
                style: AppTypography.caption
                    .copyWith(color: Colors.white38, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _HrvChart(sessionId: widget.sessionId),
            const SizedBox(height: 20),

            // Manual intervention panel
            Text('SEND INTERVENTION',
                style: AppTypography.caption
                    .copyWith(color: Colors.white38, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _ManualInterventionPanel(
              controller: _manualMessageController,
              selectedRuleId: _selectedRuleId,
              onRuleChanged: (r) => setState(() => _selectedRuleId = r),
              onSend: () =>
                  _sendManualIntervention(currentUser?.uid ?? 'admin'),
              isSending: _isSendingIntervention,
            ),
            const SizedBox(height: 20),

            // Intervention feed
            Text('INTERVENTION FEED',
                style: AppTypography.caption
                    .copyWith(color: Colors.white38, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            ...interventions.reversed.take(10).map(
                  (i) => _InterventionFeedItem(intervention: i),
                ),
          ],
        ),
      ),
    );
  }
}

class _SessionControls extends StatelessWidget {
  const _SessionControls({required this.session, required this.onAdvance});
  final SessionModel session;
  final Future<void> Function(SessionStatus) onAdvance;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (session.status == SessionStatus.waiting)
            _ControlButton(
              label: 'start calibration',
              icon: Icons.radar_rounded,
              color: AppColors.teal,
              onTap: () => onAdvance(SessionStatus.calibrating),
            ),
          if (session.status == SessionStatus.calibrating)
            _ControlButton(
              label: 'begin task',
              icon: Icons.play_arrow_rounded,
              color: AppColors.sage,
              onTap: () => onAdvance(SessionStatus.task),
            ),
          if (session.status == SessionStatus.task) ...[
            _ControlButton(
              label: 'send to survey',
              icon: Icons.assignment_rounded,
              color: AppColors.mustard,
              onTap: () => onAdvance(SessionStatus.survey),
            ),
            const SizedBox(width: 8),
            _ControlButton(
              label: 'break',
              icon: Icons.pause_rounded,
              color: AppColors.lavender,
              onTap: () => onAdvance(SessionStatus.breakTime),
            ),
          ],
          if (session.status == SessionStatus.breakTime)
            _ControlButton(
              label: 'resume task',
              icon: Icons.play_arrow_rounded,
              color: AppColors.sage,
              onTap: () => onAdvance(SessionStatus.task),
            ),
          if (session.status == SessionStatus.survey)
            _ControlButton(
              label: 'end session',
              icon: Icons.stop_rounded,
              color: AppColors.coral,
              onTap: () => onAdvance(SessionStatus.complete),
            ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.caption
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({this.status});
  final SessionStatus? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    final isLive = status == SessionStatus.task ||
        status == SessionStatus.calibrating;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.signalGood.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isLive ? AppColors.signalGood : Colors.white24,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: AppColors.signalGood, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status!.name,
            style: AppTypography.caption.copyWith(
              color: isLive ? AppColors.signalGood : Colors.white60,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberStatsRow extends StatelessWidget {
  const _MemberStatsRow({required this.sessionId, this.session});
  final String sessionId;
  final SessionModel? session;

  static const _colors = [AppColors.teal, AppColors.lavender, AppColors.sage];

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return const SizedBox.shrink();
    }
    // Shows placeholder tiles per member — real BPM/RMSSD come from
    // per-member RTDB streams in a more complete implementation.
    return Row(
      children: List.generate(session!.memberUids.length, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < session!.memberUids.length - 1 ? 8 : 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _colors[i % 3].withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _colors[i % 3].withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.signalGood, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('M-${i + 1}',
                        style: AppTypography.caption
                            .copyWith(color: Colors.white54, fontSize: 9)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('—',
                    style: AppTypography.sessionNumeric
                        .copyWith(fontSize: 22, color: Colors.white)),
                Text('bpm', style: AppTypography.caption.copyWith(fontSize: 9)),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _HrvChart extends ConsumerWidget {
  const _HrvChart({required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          minY: 40,
          maxY: 120,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
            getDrawingVerticalLine: (_) =>
                FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineBarsData: [
            _bar([const FlSpot(0, 68), const FlSpot(1, 70), const FlSpot(2, 66)],
                AppColors.teal),
            _bar([const FlSpot(0, 72), const FlSpot(1, 74), const FlSpot(2, 71)],
                AppColors.lavender),
            _bar([const FlSpot(0, 65), const FlSpot(1, 63), const FlSpot(2, 67)],
                AppColors.sage),
          ],
        ),
      ),
    );
  }

  LineChartBarData _bar(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        color: color,
        barWidth: 1.5,
        isCurved: true,
        dotData: const FlDotData(show: false),
      );
}

class _ManualInterventionPanel extends StatelessWidget {
  const _ManualInterventionPanel({
    required this.controller,
    required this.selectedRuleId,
    required this.onRuleChanged,
    required this.onSend,
    required this.isSending,
  });
  final TextEditingController controller;
  final String selectedRuleId;
  final ValueChanged<String> onRuleChanged;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lavender.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['R_MANUAL', 'R1', 'R2', 'R3', 'R4'].map((r) {
                final active = selectedRuleId == r;
                return GestureDetector(
                  onTap: () => onRuleChanged(r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.lavender.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: active ? AppColors.lavender : Colors.white24,
                      ),
                    ),
                    child: Text(r,
                        style: AppTypography.caption.copyWith(
                          color: active ? AppColors.lavender : Colors.white38,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            style: AppTypography.sessionBody,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'message to send to the team...',
              hintStyle:
                  AppTypography.sessionBody.copyWith(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSending ? null : onSend,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.lavender),
              child: isSending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('send to team →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterventionFeedItem extends StatelessWidget {
  const _InterventionFeedItem({required this.intervention});
  final InterventionModel intervention;

  @override
  Widget build(BuildContext context) {
    final isAi = intervention.source == InterventionSource.ai;
    final borderColor =
        isAi ? AppColors.interventionAi : AppColors.interventionAdmin;
    final ts =
        DateTime.fromMillisecondsSinceEpoch(intervention.timestampMs);
    final timeLabel =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 2.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isAi ? "🤖" : "👩‍🔬"} ${intervention.ruleId} · $timeLabel',
            style: AppTypography.caption
                .copyWith(color: borderColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(intervention.message, style: AppTypography.sessionBody),
        ],
      ),
    );
  }
}
