import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../domain/circles_providers.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final CircleTask task;
  final String? circleUuid;

  const TaskDetailsScreen({
    super.key,
    required this.task,
    this.circleUuid,
  });

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  bool _isUpdating = false;
  late CircleTask _task;

  CircleTask get task => _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _increment() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ref.read(circlesApiProvider).incrementTask(task.uuid);
      if (mounted) {
        setState(() {
          final nextValue = (task.currentValue ?? task.progressValue) + 1;
          final cappedValue = task.targetValue == null
              ? nextValue
              : nextValue.clamp(0, task.targetValue!);
          _task = task.copyWith(
            currentValue: cappedValue,
            progressValue: cappedValue,
          );
        });
      }
      _refreshTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث العداد')),
        );
      }
    } on CirclesApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('تعذر تحديث العداد: $error');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _passChain() async {
    final circleUuid = widget.circleUuid ?? task.circleUuid;
    if (circleUuid == null || circleUuid.isEmpty) {
      _showError('تعذر تحديد الدائرة لتمرير المهمة');
      return;
    }
    final dashboard = ref.read(circleDashboardProvider(circleUuid)).valueOrNull;
    final currentUserId = ref.read(currentUserIdProvider).valueOrNull;
    final members = dashboard?.members
            .where((member) =>
                member.userId != null && member.userId != currentUserId)
            .toList() ??
        [];
    if (members.isEmpty) {
      _showError('لا تتوفر معرفات الأعضاء لتمرير السلسلة');
      return;
    }

    final selectedUserId = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'اختر العضو التالي في السلسلة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            ...members.map(
              (member) => ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person_outline_rounded),
                ),
                title: Text(member.displayName),
                onTap: () => Navigator.pop(context, member.userId),
              ),
            ),
          ],
        ),
      ),
    );
    if (selectedUserId == null || !mounted || _isUpdating) return;

    setState(() => _isUpdating = true);
    try {
      await ref
          .read(circlesApiProvider)
          .passTask(task.uuid, nextUserId: selectedUserId);
      _refreshTasks();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on CirclesApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('تعذر تمرير السلسلة: $error');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _refreshTasks() {
    ref.invalidate(myTasksProvider);
    final circleUuid = widget.circleUuid ?? task.circleUuid;
    if (circleUuid != null && circleUuid.isNotEmpty) {
      ref.invalidate(circleDashboardProvider(circleUuid));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ItqanColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressMax = task.targetValue != null && task.targetValue! > 0
        ? task.targetValue!
        : null;
    final progressValue = task.currentValue ?? task.progressValue;

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: const Text(
          'تفاصيل المهمة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ItqanColors.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ItqanColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ItqanColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.priority.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        task.priority.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: task.priority.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.status.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        task.status.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: task.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ItqanColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                if (task.description != null &&
                    task.description!.trim().isNotEmpty)
                  Text(
                    task.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ItqanColors.inkSoft,
                      height: 1.6,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _infoRow(
            'نوع المهمة',
            task.isSecret ? 'مهمة خفية' : _taskTypeLabel(task.taskType),
          ),
          if (progressMax != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ItqanColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'التقدم:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ItqanColors.inkSoft,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$progressValue / $progressMax',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ItqanColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (progressValue / progressMax).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: ItqanColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.status == TaskStatus.completed
                            ? ItqanColors.correct
                            : ItqanColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            _infoRow('التقدم', '$progressValue'),
          if (task.dueAt != null)
            _infoRow('الاستحقاق', _formatDate(task.dueAt!)),
          if (task.targetUnit != null && task.targetUnit!.trim().isNotEmpty)
            _infoRow('الوحدة', task.targetUnit!),
          if (task.currentValue != null)
            _infoRow('القيمة الحالية', task.currentValue.toString()),
          if (task.taskType.toLowerCase() == 'tasbih' && !task.isCompleted) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _increment,
                icon: _isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ItqanColors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: const Text('إضافة تسبيحة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ItqanColors.emerald,
                  foregroundColor: ItqanColors.white,
                ),
              ),
            ),
          ],
          if (task.taskType.toLowerCase() == 'chain' && !task.isCompleted) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isUpdating ? null : _passChain,
                icon: const Icon(Icons.forward_rounded),
                label: const Text('تمرير سلسلة الخير'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ItqanColors.roseGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _taskTypeHint(task.isSecret ? 'secret' : task.taskType),
              style: const TextStyle(
                fontSize: 13,
                color: ItqanColors.ink,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ItqanColors.border),
      ),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: ItqanColors.inkSoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ItqanColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _taskTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'tasbih':
        return 'عداد تسبيح';
      case 'chain':
        return 'سلسلة خير';
      case 'secret':
      case 'is_secret':
        return 'مهمة خفية';
      case 'general':
      default:
        return 'عامة';
    }
  }

  String _taskTypeHint(String type) {
    switch (type.toLowerCase()) {
      case 'tasbih':
        return 'هذه المهمة من نوع عداد التسبيح؛ الهدف هو تراكم التقدير حتى الوصول إلى الحد المطلوب.';
      case 'chain':
        return 'هذه المهمة من نوع سلسلة خير؛ يمكن تمريرها إلى عضو آخر عند اكتمالها أو عند الحاجة إلى متابعة المهمة.';
      case 'secret':
      case 'is_secret':
        return 'هذه المهمة خفية ولا تظهر تفاصيلها للآخرين إلا عند الحاجة؛ تهدف إلى تشجيع المشاركة دون إبراز الاسم.';
      case 'general':
      default:
        return 'هذه مهمة عامة ضمن الدائرة، ويمكن متابعة تقدمها والتفاعل معها من خلال لوحة الدائرة.';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
