import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/circles_api.dart';
import '../../data/models/circle_task.dart';
import '../../../mushaf/mushaf_page_screen.dart';
import '../circle_tasbih_screen.dart';
import 'priority_badge.dart';

class TaskTile extends StatefulWidget {
  final CircleTask task;
  final int? currentUserId;
  final Future<bool> Function({String? evidenceUrl})? onComplete;
  final Future<void> Function()? onIncrement;
  final Future<Map<String, dynamic>> Function()? onIncrementWithResult;
  final bool showCircleName;
  final VoidCallback? onTap;

  const TaskTile({
    super.key,
    required this.task,
    this.currentUserId,
    this.onComplete,
    this.onIncrement,
    this.onIncrementWithResult,
    this.showCircleName = false,
    this.onTap,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool _isCompleting = false;
  int? _optimisticProgress;

  @override
  void didUpdateWidget(covariant TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.progressValue != widget.task.progressValue) {
      _optimisticProgress = widget.task.progressValue;
    }
  }

  bool get _canComplete {
    // Button only appears if assigned to current user and pending
    final isAssigned = widget.task.hasCurrentUserAssignment &&
        (widget.currentUserId == null ||
            widget.task.assignedToUserId == null ||
            widget.task.assignedToUserId == widget.currentUserId);
    return isAssigned && !widget.task.isCompleted;
  }

  Future<bool> _handleComplete() async {
    if (_isCompleting || widget.onComplete == null) return false;
    setState(() => _isCompleting = true);
    try {
      String? evidenceUrl;
      if (widget.task.evidenceRequired) {
        evidenceUrl = await _requestEvidenceUrl();
        if (evidenceUrl == null) return false;
      }
      return await widget.onComplete!(evidenceUrl: evidenceUrl);
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<String?> _requestEvidenceUrl() {
    var evidenceUrl = '';
    var errorText = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('رابط دليل الإنجاز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('هذه المهمة تتطلب رابطاً يثبت إتمامها.'),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'رابط الدليل',
                  hintText: 'https://...',
                ),
                onChanged: (value) => evidenceUrl = value.trim(),
              ),
              if (errorText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  errorText,
                  style: const TextStyle(color: ItqanColors.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final uri = Uri.tryParse(evidenceUrl);
                if (uri == null ||
                    !{'http', 'https'}.contains(uri.scheme) ||
                    uri.host.isEmpty) {
                  setDialogState(
                    () => errorText = 'أدخل رابطاً صحيحاً يبدأ بـ https://',
                  );
                  return;
                }
                Navigator.pop(dialogContext, evidenceUrl);
              },
              child: const Text('متابعة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTextTask() async {
    final completed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.task.taskType == 'dua' ? 'الدعاء' : 'الذكر'),
        content: SingleChildScrollView(
          child: Text(
            (widget.task.description?.trim().isNotEmpty ?? false)
                ? widget.task.description!
                : widget.task.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 1.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إغلاق'),
          ),
          FilledButton(
            onPressed: _isCompleting
                ? null
                : () async {
                    final success = await _handleComplete();
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, success);
                    }
                  },
            child: const Text('تم'),
          ),
        ],
      ),
    );
    if (completed == false) return;
  }

  Future<void> _openTasbih() async {
    final task = widget.task;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CircleTasbihScreen(
          task: task,
          canIncrement: _canComplete && widget.onIncrement != null,
          onIncrement: widget.onIncrement ?? () async {},
        ),
      ),
    );
  }

  Future<void> _openQuranTask() async {
    final task = widget.task;
    if (!_canComplete ||
        (widget.onComplete == null &&
            widget.onIncrementWithResult == null &&
            widget.onIncrement == null) ||
        _isCompleting) {
      return;
    }

    final startPage = (task.quranStartPage ?? 1).clamp(1, 604);
    var progress = task.progressValue;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MushafPageScreen(
          startPage: startPage,
          taskCurrentProgress: progress,
          taskTarget: task.targetValue,
          onTaskPageCompleted: (_) async {
            final result = widget.onIncrementWithResult;
            Map<String, dynamic> response = const {};
            if (result != null) {
              response = await result();
            } else if (widget.onIncrement != null) {
              await widget.onIncrement!();
            } else {
              return false;
            }
            progress++;
            final wasAlreadyCompleted =
                response['was_already_completed'] == true;
            final completed = response['completed'] == true ||
                response['is_completed'] == true ||
                wasAlreadyCompleted;
            if (completed) return true;

            if (task.targetValue != null &&
                progress >= task.targetValue! &&
                widget.onComplete != null) {
              try {
                return await _handleComplete();
              } on CirclesApiException catch (error) {
                if (error.statusCode == 409) return true;
                rethrow;
              }
            }
            return false;
          },
        ),
      ),
    );
  }

  void _handleTaskTap() {
    switch (widget.task.taskType.toLowerCase()) {
      case 'tasbih':
      case 'counter':
        _openTasbih();
        return;
      default:
        widget.onTap?.call();
    }
  }

  Widget _buildTaskAction(CircleTask task) {
    switch (task.taskType.toLowerCase()) {
      case 'quran':
        return OutlinedButton.icon(
          onPressed: _canComplete &&
                  (widget.onComplete != null ||
                      widget.onIncrement != null ||
                      widget.onIncrementWithResult != null)
              ? _openQuranTask
              : null,
          icon: const Icon(Icons.menu_book_rounded, size: 17),
          label: const Text('اقرأ الآن'),
        );
      case 'adhkar':
      case 'dua':
        return ElevatedButton.icon(
          onPressed: _canComplete ? _showTextTask : null,
          icon: const Icon(Icons.auto_awesome_rounded, size: 17),
          label: Text(task.taskType == 'dua' ? 'عرض الدعاء' : 'عرض الذكر'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ItqanColors.emerald,
            foregroundColor: ItqanColors.white,
          ),
        );
      case 'tasbih':
      case 'counter':
        final progress = _optimisticProgress ?? task.progressValue;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.targetValue == null
                  ? '$progress تسبيحة'
                  : '$progress / ${task.targetValue}',
              style: const TextStyle(
                fontSize: 12,
                color: ItqanColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _canComplete ? _openTasbih : null,
              icon: const Icon(Icons.spa_rounded, size: 17),
              label: Text(
                task.taskType.toLowerCase() == 'tasbih'
                    ? 'افتح المسبحة'
                    : 'افتح العدّاد',
              ),
            ),
          ],
        );
      case 'custom':
      default:
        return SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: _canComplete ? _handleComplete : null,
            icon: _isCompleting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ItqanColors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 16),
            label: const Text(
              'إنجاز',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ItqanColors.emerald,
              foregroundColor: ItqanColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildTargetTypeChip(String targetType) {
    final label = switch (targetType) {
      'individual' => 'فردي',
      'collective' => 'جماعي',
      'chain' => 'سلسلة',
      _ => null,
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ItqanColors.emerald.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: ItqanColors.emerald,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Material(
      color: ItqanColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _handleTaskTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: ItqanColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: task.isCompleted
                  ? ItqanColors.correct.withValues(alpha: 0.3)
                  : ItqanColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: ItqanColors.ink.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTargetTypeChip(task.targetType),
                    const SizedBox(width: 8),
                    PriorityBadge(priority: task.priority, compact: true),
                    const SizedBox(width: 8),
                    if (widget.showCircleName && task.circleName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ItqanColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.circleName!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ItqanColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    _buildStatusChip(task.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color:
                        task.isCompleted ? ItqanColors.muted : ItqanColors.ink,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.targetValue != null && task.targetValue! > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.taskType.toLowerCase() == 'quran'
                        ? 'المطلوب: ${task.targetValue} ${task.targetUnit ?? 'صفحة'}'
                        : 'التقدم: ${task.progressValue} / ${task.targetValue} ${task.targetUnit ?? ''}'
                            .trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: ItqanColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: (task.progressValue / task.targetValue!)
                        .clamp(0.0, 1.0),
                    backgroundColor: ItqanColors.border,
                    color: ItqanColors.emerald,
                  ),
                  if (task.taskType.toLowerCase() == 'quran') ...[
                    const SizedBox(height: 4),
                    Text(
                      '${task.progressValue} / ${task.targetValue}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: ItqanColors.inkSoft,
                      ),
                    ),
                  ],
                ],
                if (task.description != null &&
                    task.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ItqanColors.inkSoft,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: ItqanColors.border),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (task.isCompleted) ...[
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: ItqanColors.correct),
                      const SizedBox(width: 6),
                      const Text(
                        'تم الإنجاز بنجاح',
                        style: TextStyle(
                          fontSize: 12,
                          color: ItqanColors.correct,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (task.dueAt != null) ...[
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: ItqanColors.inkSoft),
                      const SizedBox(width: 6),
                      Text(
                        'الاستحقاق: ${_formatDate(task.dueAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ItqanColors.inkSoft,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.timer_outlined,
                          size: 14, color: ItqanColors.muted),
                      const SizedBox(width: 6),
                      const Text(
                        'مهمة دورية',
                        style:
                            TextStyle(fontSize: 12, color: ItqanColors.muted),
                      ),
                    ],
                    const Spacer(),
                    if (_canComplete ||
                        task.taskType.toLowerCase() == 'quran' ||
                        task.taskType.toLowerCase() == 'adhkar' ||
                        task.taskType.toLowerCase() == 'dua' ||
                        task.taskType.toLowerCase() == 'tasbih' ||
                        task.taskType.toLowerCase() == 'counter')
                      _buildTaskAction(task),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
