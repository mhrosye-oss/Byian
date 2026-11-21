import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../domain/circles_providers.dart';
import 'task_details_screen.dart';
import 'widgets/task_tile.dart';

class MyTasksScreen extends ConsumerStatefulWidget {
  const MyTasksScreen({super.key});

  @override
  ConsumerState<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends ConsumerState<MyTasksScreen> {
  String _selectedFilter = 'all'; // 'all', 'today', 'overdue', 'upcoming'

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(myTasksProvider);
    final currentUserId = ref.watch(currentUserIdProvider).valueOrNull;

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: const Text(
          'مهامي في الدوائر',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ItqanColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: ItqanColors.cream,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'الكل'),
                  const SizedBox(width: 8),
                  _buildFilterChip('today', 'اليوم'),
                  const SizedBox(width: 8),
                  _buildFilterChip('overdue', 'متأخرة'),
                  const SizedBox(width: 8),
                  _buildFilterChip('upcoming', 'قادمة'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: ItqanColors.border),

          // Body
          Expanded(
            child: tasksState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: ItqanColors.emerald),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: ItqanColors.error),
                      const SizedBox(height: 16),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ItqanColors.inkSoft),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(myTasksProvider.notifier).refresh(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ItqanColors.emerald,
                          foregroundColor: ItqanColors.white,
                        ),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (tasks) {
                final filtered = _filterTasks(tasks);

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    color: ItqanColors.emerald,
                    onRefresh: () =>
                        ref.read(myTasksProvider.notifier).refresh(),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    ItqanColors.emerald.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.task_alt_rounded,
                                color: ItqanColors.emerald,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'لا توجد مهام مسندة إليك حالياً',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ItqanColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'ستظهر هنا جميع المهام المسندة إليك في دوائرك المختلفة.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: ItqanColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: ItqanColors.emerald,
                  onRefresh: () => ref.read(myTasksProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      return TaskTile(
                        task: task,
                        currentUserId: currentUserId,
                        showCircleName: true,
                        onComplete: ({String? evidenceUrl}) => _handleComplete(
                            task.uuid,
                            evidenceUrl: evidenceUrl),
                        onIncrement: () => ref
                            .read(myTasksProvider.notifier)
                            .incrementTask(task.uuid),
                        onIncrementWithResult: () => ref
                            .read(myTasksProvider.notifier)
                            .incrementTask(task.uuid),
                        onTap: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailsScreen(task: task),
                            ),
                          );
                          if (changed == true && mounted) {
                            await ref.read(myTasksProvider.notifier).refresh();
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = key);
      },
      selectedColor: ItqanColors.emerald,
      backgroundColor: ItqanColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? ItqanColors.white : ItqanColors.ink,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? ItqanColors.emerald : ItqanColors.border,
        ),
      ),
    );
  }

  List<CircleTask> _filterTasks(List<CircleTask> tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    switch (_selectedFilter) {
      case 'today':
        return tasks.where((t) {
          if (t.dueAt == null) return false;
          return t.dueAt!.isAfter(todayStart) && t.dueAt!.isBefore(todayEnd);
        }).toList();
      case 'overdue':
        return tasks.where((t) {
          if (t.dueAt == null || t.isCompleted) return false;
          return t.dueAt!.isBefore(todayStart);
        }).toList();
      case 'upcoming':
        return tasks.where((t) {
          if (t.dueAt == null || t.isCompleted) return true;
          return t.dueAt!.isAfter(todayEnd);
        }).toList();
      case 'all':
      default:
        return tasks;
    }
  }

  Future<bool> _handleComplete(
    String taskUuid, {
    String? evidenceUrl,
  }) async {
    try {
      final success = await ref
          .read(myTasksProvider.notifier)
          .completeTask(taskUuid, evidenceUrl: evidenceUrl);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إنجاز المهمة بنجاح'),
            backgroundColor: ItqanColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return success;
    } on CirclesApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor:
                e.statusCode == 409 ? ItqanColors.warning : ItqanColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ، حاول مرة أخرى'),
            backgroundColor: ItqanColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }
}
