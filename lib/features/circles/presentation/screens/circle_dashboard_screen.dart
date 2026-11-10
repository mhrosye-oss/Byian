import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itqan/features/adhkar/screens/adhkar_screen.dart';
import 'package:itqan/features/adhkar/screens/duas_screen.dart';
import 'package:itqan/features/khatmah/screens/khatmah_screen.dart';
import 'package:itqan/features/mushaf/mushaf_screen.dart';
import 'package:itqan/features/tasbih/screens/smart_tasbih_screen.dart';

import '../../../../core/services/auth_service.dart';
import '../../application/circle_list_provider.dart';
import '../../domain/circle_api_errors.dart';
import 'whispers_sheet.dart';

class CircleDashboardScreen extends ConsumerStatefulWidget {
  const CircleDashboardScreen({super.key, required this.uuid, this.name});

  final String uuid;
  final String? name;

  @override
  ConsumerState<CircleDashboardScreen> createState() =>
      _CircleDashboardScreenState();
}

class _CircleDashboardScreenState extends ConsumerState<CircleDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboard;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _dashboard = _loadDashboard();
    _loadCurrentUserId();
  }

  Future<Map<String, dynamic>> _loadDashboard() =>
      ref.read(circleApiServiceProvider).getDashboard(widget.uuid);

  Future<void> _loadCurrentUserId() async {
    final userId = await AuthService.getUserId();
    if (mounted) setState(() => _currentUserId = userId);
  }

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() => _dashboard = future);
    await future;
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _tasks(Map<String, dynamic> data) {
    final rawTasks =
        data['assigned_tasks'] ?? data['tasks'] ?? data['my_tasks'];
    return _mapList(rawTasks);
  }

  int? _assignedUserId(Map<String, dynamic> task) {
    dynamic assigned = task['assigned_to_user_id'] ??
        task['assigned_user_id'] ??
        task['assignee_id'] ??
        task['user_id'];
    assigned ??=
        task['assigned_to'] ?? task['assigned_user'] ?? task['assignee'];
    if (assigned is Map) {
      assigned = assigned['user_id'] ?? assigned['id'];
    }
    if (assigned is num) return assigned.toInt();
    return int.tryParse('$assigned');
  }

  bool _isCompleted(Map<String, dynamic> task) {
    if (task['completed_at'] != null || task['is_completed'] == true) {
      return true;
    }
    final status = '${task['status'] ?? ''}'.toLowerCase();
    return const {
      'done',
      'completed',
      'complete',
      'مكتملة',
      'مكتمل',
    }.contains(status);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _completeTask(Map<String, dynamic> task) async {
    final taskId = '${task['id'] ?? task['uuid'] ?? ''}';
    if (taskId.isEmpty) {
      _showMessage('تعذر تحديد المهمة.');
      return;
    }
    try {
      await ref.read(circleApiServiceProvider).completeTask(taskId);
      if (mounted) {
        _showMessage('تم إنجاز المهمة بنجاح.');
        await _refresh();
      }
    } on CircleApiException catch (error) {
      if (!mounted) return;
      _showMessage(switch (error.statusCode) {
        409 => 'المهمة مكتملة بالفعل',
        403 => 'هذه المهمة غير مسندة إليك',
        _ => 'تعذر إنجاز المهمة (${error.statusCode}).',
      });
    } catch (_) {
      if (mounted) _showMessage('تعذر إنجاز المهمة.');
    }
  }

  Future<void> _confirmLeaveCircle() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مغادرة الدائرة؟'),
        content: const Text('هل تريد مغادرة هذه الدائرة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
    if (shouldLeave != true || !mounted) return;

    try {
      await ref.read(circleApiServiceProvider).leaveCircle(widget.uuid);
      ref.invalidate(myCirclesProvider);
      if (mounted) {
        _showMessage('تمت مغادرة الدائرة.');
        Navigator.pop(context);
      }
    } on CircleApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.statusCode == 409
          ? 'لا يمكنك مغادرة الدائرة كمالك وحيد'
          : 'تعذر مغادرة الدائرة (${error.statusCode}).');
    } catch (_) {
      if (mounted) _showMessage('تعذر مغادرة الدائرة.');
    }
  }

  void _openService(String label) {
    if (label == 'همسات') {
      CircleWhispersSheet.show(context, widget.uuid);
      return;
    }

    final Widget? page = switch (label) {
      'مصحف' => const MushafScreen(),
      'تسبيح' => const SmartTasbihScreen(),
      'أذكار' => const AdhkarScreen(),
      'أدعية' => const DuasScreen(),
      'ختمة' => const KhatmahScreen(),
      _ => null,
    };
    if (page == null) {
      _showMessage('قريباً');
      return;
    }
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.name ?? 'الدائرة')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _dashboard,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تعذر تحميل الدائرة: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data ?? const <String, dynamic>{};
            final members = _mapList(data['members']);
            final activities = _mapList(data['activities']);
            final tasks = _tasks(data);
            final role = _dashboardRole(data, members);
            final name = '${data['name'] ?? widget.name ?? 'الدائرة'}';
            final type = data['type'] is Map
                ? '${data['type']['name'] ?? ''}'
                : '${data['type'] ?? ''}';
            final memberCount = _asInt(data['members_count']) ?? members.length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildHeader(name, type, memberCount, role),
                  _buildServicesGrid(),
                  const SizedBox(height: 12),
                  _sectionTitle('المهام'),
                  if (tasks.isEmpty)
                    _emptyState('لا توجد مهام حالياً')
                  else
                    ...tasks.map(_buildTaskCard),
                  const SizedBox(height: 8),
                  _sectionTitle('أعضاء الدائرة'),
                  if (members.isEmpty)
                    _emptyState('لا توجد معلومات أعضاء للعرض.')
                  else
                    ...members.map(_buildMemberTile),
                  const SizedBox(height: 8),
                  _sectionTitle('آخر الأحداث'),
                  if (activities.isEmpty)
                    _emptyState('لا توجد أحداث بعد.')
                  else
                    ...activities.take(5).map(_buildActivityTile),
                  const SizedBox(height: 20),
                  if (role != 'owner')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton.icon(
                        onPressed: _confirmLeaveCircle,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('مغادرة الدائرة'),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );

  String _dashboardRole(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> members,
  ) {
    final direct = data['my_role'] ?? data['role'];
    if (direct != null && '$direct'.isNotEmpty) return '$direct'.toLowerCase();
    for (final member in members) {
      if (_asInt(member['user_id']) == _currentUserId) {
        return '${member['role'] ?? 'member'}'.toLowerCase();
      }
    }
    return 'member';
  }

  Widget _buildHeader(
    String name,
    String type,
    int memberCount,
    String role,
  ) => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.groups_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$type · $memberCount أعضاء',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _roleLabel(role),
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildServicesGrid() {
    final services = <_ServiceItem>[
      _ServiceItem(Icons.menu_book_rounded, 'مصحف', const Color(0xFF0A7A49)),
      _ServiceItem(Icons.fingerprint_rounded, 'تسبيح', Colors.amber.shade800),
      _ServiceItem(Icons.auto_awesome_rounded, 'أذكار', Colors.teal),
      _ServiceItem(Icons.volunteer_activism_rounded, 'أدعية', Colors.indigo),
      _ServiceItem(Icons.auto_stories_rounded, 'ختمة', Colors.purple),
      _ServiceItem(Icons.forum_rounded, 'همسات', Colors.pink),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('خدمات الدائرة'),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) => _buildServiceCard(services[index]),
        ),
      ],
    );
  }

  Widget _buildServiceCard(_ServiceItem item) => InkWell(
        onTap: () => _openService(item.label),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Color.lerp(item.color, Colors.transparent, 0.92)!,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.lerp(item.color, Colors.transparent, 0.75)!,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 34, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.color,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = '${task['title'] ?? task['name'] ?? 'مهمة'}';
    final target =
        '${task['target'] ?? task['target_description'] ?? task['description'] ?? '—'}';
    final priority = '${task['priority'] ?? 'normal'}'.toLowerCase();
    final priorityColor = switch (priority) {
      'high' || 'urgent' || 'عالية' || 'عاجلة' => Colors.red,
      'medium' || 'متوسطة' => Colors.orange,
      _ => Colors.green,
    };
    final canComplete = !_isCompleted(task) &&
        _currentUserId != null &&
        _assignedUserId(task) == _currentUserId;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(target, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                _statusBadge(task),
                const Spacer(),
                if (canComplete)
                  FilledButton.tonalIcon(
                    onPressed: () => _completeTask(task),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('إنجاز'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(Map<String, dynamic> task) {
    final completed = _isCompleted(task);
    final color = completed ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        completed ? 'مكتملة' : 'معلقة',
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final rawUser = member['user'];
    final user = rawUser is Map ? Map<String, dynamic>.from(rawUser) : const {};
    final name = '${member['name'] ?? user['name'] ?? 'عضو'}';
    final initial = name.trim().isEmpty ? '؟' : name.trim()[0];
    final role = '${member['role'] ?? member['my_role'] ?? 'member'}';
    return ListTile(
      leading: CircleAvatar(child: Text(initial)),
      title: Text(name),
      subtitle: Text(_roleLabel(role)),
      dense: true,
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final description =
        '${activity['description'] ?? activity['event_type'] ?? 'حدث جديد'}';
    final time = _timeAgo('${activity['created_at'] ?? ''}');
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(_activityIcon('${activity['event_type'] ?? ''}'), size: 18),
      ),
      title: Text(description),
      subtitle: Text(time),
      dense: true,
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );

  Widget _emptyState(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );

  int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  String _roleLabel(String role) => switch (role.toLowerCase()) {
        'owner' => 'مالك',
        'admin' => 'مشرف',
        _ => 'عضو',
      };

  IconData _activityIcon(String type) {
    final value = type.toLowerCase();
    if (value.contains('member') || value.contains('join')) {
      return Icons.person_add_alt_1_rounded;
    }
    if (value.contains('task')) return Icons.task_alt_rounded;
    if (value.contains('invite')) return Icons.mail_outline_rounded;
    return Icons.auto_awesome_outlined;
  }

  String _timeAgo(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.isNegative || difference.inSeconds < 60) return 'الآن';
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} د';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} س';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} ي';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ServiceItem {
  const _ServiceItem(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;
}
