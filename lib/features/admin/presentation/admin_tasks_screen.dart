import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../session/domain/task_model.dart';

final _tasksProvider = StreamProvider<List<TaskModel>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchTasks();
});

class AdminTasksScreen extends ConsumerWidget {
  const AdminTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_tasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('tasks', style: AppTypography.headingMedium),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.coral,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('add task',
            style: AppTypography.labelMedium.copyWith(color: Colors.white)),
        onPressed: () => _showTaskDialog(context, ref, null),
      ),
      body: tasksAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.coral)),
        error: (e, _) =>
            Center(child: Text('failed to load tasks', style: AppTypography.bodySmall)),
        data: (tasks) {
          if (tasks.isEmpty) {
            return _EmptyTasksView(onAdd: () => _showTaskDialog(context, ref, null));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _TaskCard(
              task: tasks[i],
              onEdit: () => _showTaskDialog(context, ref, tasks[i]),
              onDelete: () => _confirmDelete(context, ref, tasks[i]),
            ),
          );
        },
      ),
    );
  }

  void _showTaskDialog(BuildContext context, WidgetRef ref, TaskModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TaskFormSheet(existing: existing, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('delete task?', style: AppTypography.headingSmall),
        content: Text('this will remove "${task.title}" from the task list.',
            style: AppTypography.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(sessionRepositoryProvider).deleteTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('delete', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  const _TaskCard({required this.task, required this.onEdit, required this.onDelete});
  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.mustardLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.task.orderIndex + 1}',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.mustard),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.task.title,
                            style: AppTypography.labelMedium),
                        Text(
                          '${widget.task.durationSec ~/ 60} min',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.warm,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.task.description,
                      style: AppTypography.bodyMedium),
                  if (widget.task.hint != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mustardLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded,
                              size: 14, color: AppColors.mustard),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('hint: ${widget.task.hint}',
                                style: AppTypography.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('edit'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 14, color: AppColors.coral),
                        label: Text('delete',
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.coral)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.coral)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskFormSheet extends StatefulWidget {
  const _TaskFormSheet({this.existing, required this.ref});
  final TaskModel? existing;
  final WidgetRef ref;

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _hintCtrl;
  late final TextEditingController _answerCtrl;
  late int _durationMin;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _descCtrl =
        TextEditingController(text: widget.existing?.description ?? '');
    _hintCtrl = TextEditingController(text: widget.existing?.hint ?? '');
    _answerCtrl =
        TextEditingController(text: widget.existing?.answerKey ?? '');
    _durationMin = (widget.existing?.durationSec ?? 600) ~/ 60;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _hintCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final task = TaskModel(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      hint: _hintCtrl.text.trim().isEmpty ? null : _hintCtrl.text.trim(),
      answerKey:
          _answerCtrl.text.trim().isEmpty ? null : _answerCtrl.text.trim(),
      durationSec: _durationMin * 60,
      orderIndex: widget.existing?.orderIndex ?? 999,
    );

    if (widget.existing != null) {
      await widget.ref.read(sessionRepositoryProvider).updateTask(task);
    } else {
      await widget.ref.read(sessionRepositoryProvider).createTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing != null ? 'edit task' : 'new task',
                style: AppTypography.headingMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration:
                  const InputDecoration(hintText: 'task title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'task description shown to participants'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _hintCtrl,
              decoration: const InputDecoration(
                  hintText: 'optional hint (shown to participants if stuck)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _answerCtrl,
              decoration: const InputDecoration(
                  hintText: 'answer key (admin only — not shown to participants)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('duration: $_durationMin min',
                    style: AppTypography.labelMedium),
                Expanded(
                  child: Slider(
                    value: _durationMin.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 5,
                    activeColor: AppColors.coral,
                    onChanged: (v) =>
                        setState(() => _durationMin = v.round()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.existing != null ? 'save changes' : 'create task'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTasksView extends StatelessWidget {
  const _EmptyTasksView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt_rounded, size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text('no tasks yet', style: AppTypography.headingSmall),
          const SizedBox(height: 6),
          Text('add your first task to get started',
              style: AppTypography.bodySmall),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('add task'),
          ),
        ],
      ),
    );
  }
}
