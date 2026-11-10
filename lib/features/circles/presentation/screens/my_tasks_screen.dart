import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../application/circle_providers.dart';
import '../../data/circle_api_config.dart';
import '../../domain/circle_models.dart';

enum _TaskFilter { all, today, overdue, upcoming }

class MyTasksScreen extends ConsumerStatefulWidget {
  const MyTasksScreen({super.key});

  @override
  ConsumerState<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends ConsumerState<MyTasksScreen> {
  _TaskFilter _filter = _TaskFilter.all;
  final Set<String> _completingTaskUuids = <String>{};

  Future<void> _refresh() async {
    try {
      await ref.refresh(myCircleTasksProvider.future).then<void>((_) {});
    } catch (_) {
      // The provider's error state presents the failure and retry action.
    }
  }

  Future<void> _completeTask(CircleTask task) async {
    if (!task.isPending || _completingTaskUuids.contains(task.uuid)) return;

    setState(() => _completingTaskUuids.add(task.uuid));
    try {
      await ref.read(circleApiClientProvider).completeTask(task.uuid);
      if (!mounted) return;
      ref.invalidate(myCircleTasksProvider);
      _showMessage('تم إنجاز المهمة بنجاح');
    } on CircleApiException catch (error) {
      if (!mounted) return;
      final message = switch (error.statusCode) {
        409 => 'المهمة مكتملة بالفعل',
        403 => 'هذه المهمة غير مسندة إليك',
        _ => error.message.isNotEmpty ? error.message : 'تعذر إنجاز المهمة',
      };
      _showMessage(message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر إنجاز المهمة. حاول مرة أخرى.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _completingTaskUuids.remove(task.uuid));
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textDirection: TextDirection.rtl),
          backgroundColor:
              isError ? const Color(0xFFB3261E) : ItqanColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  List<CircleTask> _filterTasks(List<CircleTask> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return tasks.where((task) {
      final dueAt = task.dueAt?.toLocal();
      switch (_filter) {
        case _TaskFilter.all:
          return true;
        case _TaskFilter.today:
          return dueAt != null &&
              !dueAt.isBefore(today) &&
              dueAt.isBefore(tomorrow);
        case _TaskFilter.overdue:
          return task.isPending && dueAt != null && dueAt.isBefore(today);
        case _TaskFilter.upcoming:
          return dueAt != null && !dueAt.isBefore(tomorrow);
      }
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(myCircleTasksProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(
          title: const Text('مهامي'),
          centerTitle: false,
          backgroundColor: ItqanColors.cream,
          foregroundColor: ItqanColors.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildFilters(),
              Expanded(
                child: tasksAsync.when(
                  loading: _buildLoading,
                  error: (error, _) => _buildError(error),
                  data: (tasks) => _buildTaskList(_filterTasks(tasks)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const filters = <(_TaskFilter, String)>[
      (_TaskFilter.all, 'الكل'),
      (_TaskFilter.today, 'اليوم'),
      (_TaskFilter.overdue, 'متأخرة'),
      (_TaskFilter.upcoming, 'قادمة'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: filters.map((entry) {
          final selected = _filter == entry.$1;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(entry.$2),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _filter = entry.$1),
              selectedColor: ItqanColors.emerald,
              backgroundColor: ItqanColors.surface,
              side: BorderSide(
                color: selected ? ItqanColors.emerald : ItqanColors.border,
              ),
              labelStyle: TextStyle(
                color: selected ? ItqanColors.white : ItqanColors.inkSoft,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildLoading() => RefreshIndicator(
        onRefresh: _refresh,
        color: ItqanColors.emerald,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: CircularProgressIndicator()),
            SizedBox(height: 18),
            Center(
              child: Text(
                'جارٍ تحميل المهام…',
                style: TextStyle(color: ItqanColors.inkSoft),
              ),
            ),
          ],
        ),
      );

  Widget _buildError(Object error) {
    final message = error is CircleApiException && error.message.isNotEmpty
        ? error.message
        : 'تعذر تحميل المهام. تحقق من اتصالك ثم حاول مجددًا.';

    return RefreshIndicator(
      onRefresh: _refresh,
      color: ItqanColors.emerald,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.cloud_off_outlined, size: 48, color: ItqanColors.muted),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ItqanColors.inkSoft, height: 1.6),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: () => ref.invalidate(myCircleTasksProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                backgroundColor: ItqanColors.emerald,
                foregroundColor: ItqanColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<CircleTask> tasks) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: ItqanColors.emerald,
      child: tasks.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: const [
                SizedBox(height: 110),
                Icon(Icons.task_alt, size: 54, color: ItqanColors.muted),
                SizedBox(height: 14),
                Center(
                  child: Text(
                    'لا توجد مهام في هذا التصنيف',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ItqanColors.inkSoft, fontSize: 16),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _TaskCard(
                task: tasks[index],
                isCompleting: _completingTaskUuids.contains(tasks[index].uuid),
                onComplete: () => _completeTask(tasks[index]),
              ),
            ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isCompleting,
    required this.onComplete,
  });

  final CircleTask task;
  final bool isCompleting;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority.toLowerCase()) {
      'high' => const Color(0xFFB3261E),
      'normal' => ItqanColors.emerald,
      'low' => ItqanColors.muted,
      _ => ItqanColors.muted,
    };

    return Card(
      margin: EdgeInsets.zero,
      color: ItqanColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: ItqanColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: ItqanColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _Badge(
                  label: _priorityLabel(task.priority),
                  color: priorityColor,
                  icon: Icons.flag_outlined,
                ),
              ],
            ),
            if (task.description != null &&
                task.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: const TextStyle(
                  color: ItqanColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ],
            if (task.circleName != null &&
                task.circleName!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _MetaLine(icon: Icons.groups_outlined, text: task.circleName!),
            ],
            if (task.dueAt != null) ...[
              const SizedBox(height: 8),
              _MetaLine(
                icon: Icons.calendar_today_outlined,
                text: 'موعد الاستحقاق: ${_formatDate(task.dueAt!.toLocal())}',
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (!task.isPending)
                  _Badge(
                    label: _statusLabel(task.status),
                    color: ItqanColors.inkSoft,
                    icon: Icons.check_circle_outline,
                  ),
                const Spacer(),
                if (task.isPending)
                  FilledButton.icon(
                    onPressed: isCompleting ? null : onComplete,
                    icon: isCompleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ItqanColors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(isCompleting ? 'جارٍ الإنجاز' : 'إنجاز المهمة'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ItqanColors.emerald,
                      foregroundColor: ItqanColors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _priorityLabel(String priority) =>
      switch (priority.toLowerCase()) {
        'high' => 'أولوية عالية',
        'normal' => 'عادية',
        'low' => 'منخفضة',
        _ => 'أولوية',
      };

  static String _statusLabel(String status) => switch (status) {
        'completed' => 'مكتملة',
        'in_progress' => 'قيد التنفيذ',
        _ => status,
      };

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: ItqanColors.muted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: ItqanColors.inkSoft, fontSize: 13),
            ),
          ),
        ],
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
