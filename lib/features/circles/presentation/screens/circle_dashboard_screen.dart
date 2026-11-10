import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../application/circle_providers.dart';
import '../../data/circle_api_client.dart';
import '../../data/circle_api_config.dart';
import '../../domain/circle_models.dart';

class CircleDashboardScreen extends ConsumerStatefulWidget {
  const CircleDashboardScreen({super.key, required this.circle});

  final Circle circle;

  @override
  ConsumerState<CircleDashboardScreen> createState() =>
      _CircleDashboardScreenState();
}

class _CircleDashboardScreenState extends ConsumerState<CircleDashboardScreen> {
  late Future<_CircleBundle> _bundle;
  bool _leaving = false;
  bool _inviting = false;

  CircleApiClient get _api => ref.read(circleApiClientProvider);

  @override
  void initState() {
    super.initState();
    _bundle = _load();
  }

  Future<_CircleBundle> _load() async {
    final uuid = widget.circle.uuid;
    final values = await Future.wait<dynamic>([
      _api.getCircle(uuid),
      _api.getMembers(uuid),
      _api.getActivities(uuid),
      _api.getCircleTasks(uuid),
      _api.getWhispers(uuid),
    ]);
    return _CircleBundle(
      details: values[0] as Map<String, dynamic>,
      members: (values[1] as List<Map<String, dynamic>>)
          .map(CircleMember.fromJson)
          .toList(growable: false),
      activities: (values[2] as List<Map<String, dynamic>>)
          .map(CircleActivity.fromJson)
          .toList(growable: false),
      taskJson: values[3] as List<Map<String, dynamic>>,
      whispers: (values[4] as List<Map<String, dynamic>>)
          .map(CircleWhisper.fromJson)
          .toList(growable: false),
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _bundle = future);
    try {
      await future;
    } catch (_) {
      // The FutureBuilder below shows the error and retry action.
    }
  }

  Future<void> _leaveCircle() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مغادرة الدائرة'),
        content: Text('هل تريد مغادرة «${widget.circle.name}»؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _leaving = true);
    try {
      await _api.leaveCircle(widget.circle.uuid);
      ref.invalidate(myCirclesProvider);
      if (mounted) {
        _message('غادرت الدائرة.');
        Navigator.of(context).pop();
      }
    } on CircleApiException catch (error) {
      _message(
        error.statusCode == 409
            ? 'لا يمكنك مغادرة الدائرة كمالك وحيد'
            : error.message,
        error: true,
      );
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  Future<void> _generateInvite() async {
    setState(() => _inviting = true);
    try {
      final invite = await _api.generateInvitation(widget.circle.uuid);
      if (!mounted) return;
      final responseText = const JsonEncoder.withIndent('  ').convert(invite);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('بيانات الدعوة'),
          content: SingleChildScrollView(
            child:
                SelectableText(responseText, textDirection: TextDirection.ltr),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: responseText));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _message('تم نسخ بيانات الدعوة.');
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } on CircleApiException catch (error) {
      _message(error.message, error: true);
    } catch (_) {
      _message('تعذر إنشاء الدعوة.', error: true);
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  Future<void> _completeTask(Map<String, dynamic> task) async {
    final uuid = task['uuid']?.toString();
    if (uuid == null || uuid.isEmpty) return;
    try {
      await _api.completeTask(uuid);
      await _refresh();
      if (mounted) _message('تم إنجاز المهمة بنجاح.');
    } on CircleApiException catch (error) {
      _message(
        switch (error.statusCode) {
          409 => 'المهمة مكتملة بالفعل',
          403 => 'هذه المهمة غير مسندة إليك',
          _ => error.message,
        },
        error: true,
      );
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor:
              error ? const Color(0xFFB3261E) : ItqanColors.emerald,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isMember = widget.circle.myRole == 'member';
    final userId = ref.watch(currentCircleUserProvider)?.id;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.circle.name,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            if (isMember)
              IconButton(
                tooltip: 'مغادرة الدائرة',
                onPressed: _leaving ? null : _leaveCircle,
                icon: _leaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
              ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.insights_outlined), text: 'نظرة عامة'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'الأعضاء'),
              Tab(icon: Icon(Icons.task_alt_outlined), text: 'المهام'),
              Tab(icon: Icon(Icons.forum_outlined), text: 'الهمسات'),
            ],
          ),
        ),
        body: FutureBuilder<_CircleBundle>(
          future: _bundle,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _LoadError(
                error: snapshot.error,
                onRetry: _refresh,
              );
            }
            final data = snapshot.data!;
            return TabBarView(
              children: [
                _OverviewTab(
                    circle: widget.circle, bundle: data, onRefresh: _refresh),
                _MembersTab(
                  members: data.members,
                  role: widget.circle.myRole ??
                      data.details['my_role']?.toString(),
                  onInvite: _generateInvite,
                  isInviting: _inviting,
                ),
                _TasksTab(
                  tasks: data.taskJson,
                  currentUserId: userId,
                  onComplete: _completeTask,
                  owner: widget.circle.myRole == 'owner' ||
                      data.details['my_role'] == 'owner',
                ),
                _WhispersTab(whispers: data.whispers),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CircleBundle {
  const _CircleBundle({
    required this.details,
    required this.members,
    required this.activities,
    required this.taskJson,
    required this.whispers,
  });

  final Map<String, dynamic> details;
  final List<CircleMember> members;
  final List<CircleActivity> activities;
  final List<Map<String, dynamic>> taskJson;
  final List<CircleWhisper> whispers;
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.circle,
    required this.bundle,
    required this.onRefresh,
  });

  final Circle circle;
  final _CircleBundle bundle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ItqanColors.emerald,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circle.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${circle.type?.name ?? bundle.details['type'] ?? 'دائرة'} · ${bundle.members.length} أعضاء',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if ((circle.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(circle.description!,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'الأعضاء',
                        value: bundle.members.length,
                        icon: Icons.groups_rounded)),
                const SizedBox(width: 9),
                Expanded(
                    child: _StatCard(
                        label: 'المهام',
                        value: bundle.taskJson.length,
                        icon: Icons.task_alt_rounded)),
                const SizedBox(width: 9),
                Expanded(
                    child: _StatCard(
                        label: 'الهمسات',
                        value: bundle.whispers.length,
                        icon: Icons.forum_rounded)),
              ],
            ),
            const SizedBox(height: 22),
            Text('النشاط الأخير',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (bundle.activities.isEmpty)
              const _EmptyLine(text: 'لا يوجد نشاط حديث بعد.')
            else
              ...bundle.activities.take(8).map(
                    (activity) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE7F1EB),
                        child: Icon(Icons.bolt_rounded,
                            size: 18, color: ItqanColors.emerald),
                      ),
                      title: Text(
                          activity.description ?? activity.type ?? 'نشاط جديد'),
                      subtitle: activity.actorName == null
                          ? null
                          : Text(activity.actorName!),
                    ),
                  ),
          ],
        ),
      );
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.members,
    required this.role,
    required this.onInvite,
    required this.isInviting,
  });
  final List<CircleMember> members;
  final String? role;
  final VoidCallback onInvite;
  final bool isInviting;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (role == 'owner') ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isInviting ? null : onInvite,
                  icon: isInviting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('دعوة عضو'),
                ),
              ),
            ),
          ],
          if (members.isEmpty)
            const _EmptyLine(text: 'لا توجد بيانات للأعضاء.')
          else
            ...members.map(
              (member) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ItqanColors.emerald.withValues(alpha: .10),
                    foregroundColor: ItqanColors.emerald,
                    child: Text(
                      (member.name?.isNotEmpty ?? false)
                          ? member.name!.characters.first
                          : '؟',
                    ),
                  ),
                  title: Text(member.name ?? 'عضو'),
                  subtitle: member.relationship == null ||
                          member.relationship!.isEmpty
                      ? null
                      : Text(member.relationship!),
                  trailing: _RolePill(role: member.role ?? 'member'),
                ),
              ),
            ),
        ],
      );
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({
    required this.tasks,
    required this.currentUserId,
    required this.onComplete,
    required this.owner,
  });

  final List<Map<String, dynamic>> tasks;
  final int? currentUserId;
  final ValueChanged<Map<String, dynamic>> onComplete;
  final bool owner;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (owner)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Tooltip(
                    message: 'يتطلب مخطط طلب إنشاء المهمة المؤكد من وثيقة API.',
                    child: FilledButton.icon(
                      onPressed: null,
                      icon: Icon(Icons.add_task_rounded),
                      label: Text('إضافة مهمة'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'زر الإنشاء معطّل حتى يتوفر payload موثق من الخادم.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ItqanColors.inkSoft,
                        ),
                  ),
                ],
              ),
            ),
          if (tasks.isEmpty)
            const _EmptyLine(text: 'لا توجد مهام في هذه الدائرة.')
          else
            ...tasks.map((task) {
              final title = task['title']?.toString() ?? 'مهمة';
              final status = task['status']?.toString() ?? 'pending';
              final priority = task['priority']?.toString() ?? 'normal';
              final canComplete = status == 'pending' &&
                  currentUserId != null &&
                  _isAssignedTo(task, currentUserId!);
              final dueAt = DateTime.tryParse('${task['due_at'] ?? ''}');
              final uuid = task['uuid']?.toString() ?? '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))),
                          _PriorityPill(priority: priority),
                        ],
                      ),
                      if (task['description'] != null) ...[
                        const SizedBox(height: 6),
                        Text('${task['description']}',
                            style: const TextStyle(color: ItqanColors.inkSoft)),
                      ],
                      if (dueAt != null) ...[
                        const SizedBox(height: 6),
                        Text('الاستحقاق: ${_date(dueAt.toLocal())}',
                            style: const TextStyle(
                                color: ItqanColors.muted, fontSize: 12)),
                      ],
                      if (canComplete && uuid.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FilledButton.icon(
                            onPressed: () => onComplete(task),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('إنجاز'),
                          ),
                        ),
                      ] else if (status != 'pending') ...[
                        const SizedBox(height: 8),
                        Text(_status(status),
                            style: const TextStyle(color: ItqanColors.inkSoft)),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      );

  static bool _isAssignedTo(Map<String, dynamic> task, int userId) {
    final assignedId = task['assigned_to_user_id'];
    if (assignedId != null && int.tryParse('$assignedId') == userId) {
      return true;
    }
    final assignment = task['assignment'];
    if (assignment is Map &&
        int.tryParse('${assignment['user_id']}') == userId) {
      return assignment['status'] == 'pending';
    }
    final assignments = task['assignments'];
    if (assignments is List) {
      return assignments.whereType<Map>().any((item) {
        final mapped = Map<String, dynamic>.from(item);
        return int.tryParse('${mapped['user_id']}') == userId &&
            mapped['status'] == 'pending';
      });
    }
    return false;
  }

  static String _status(String status) => switch (status) {
        'completed' => 'مكتملة',
        'in_progress' => 'قيد التنفيذ',
        _ => status,
      };

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

class _WhispersTab extends StatelessWidget {
  const _WhispersTab({required this.whispers});
  final List<CircleWhisper> whispers;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Tooltip(
            message: 'يتطلب مخطط طلب إرسال الهمسة المؤكد من وثيقة API.',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: Icon(Icons.send_rounded),
                label: Text('إرسال همسة'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'عرض الهمسات متاح، وإرسالها ينتظر مخطط الطلب المؤكد من الخادم.',
              style: TextStyle(color: ItqanColors.inkSoft),
            ),
          ),
          if (whispers.isEmpty)
            const _EmptyLine(text: 'لا توجد همسات بعد.')
          else
            ...whispers.map(
              (whisper) => Card(
                child: ListTile(
                  leading: const Icon(Icons.forum_outlined,
                      color: ItqanColors.roseGold),
                  title: Text(
                      whisper.messageText ?? whisper.templateKey ?? 'همسة'),
                  subtitle: Text(_date(whisper.createdAt)),
                  trailing: whisper.isAnonymous
                      ? const Icon(Icons.visibility_off_outlined, size: 18)
                      : null,
                ),
              ),
            ),
        ],
      );

  static String _date(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: ItqanColors.emerald),
              const SizedBox(height: 5),
              Text('$value',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
              Text(label,
                  style: const TextStyle(
                      color: ItqanColors.inkSoft, fontSize: 12)),
            ],
          ),
        ),
      );
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isOwner
            ? ItqanColors.emerald.withValues(alpha: .10)
            : ItqanColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(isOwner
          ? 'قائد'
          : role == 'admin'
              ? 'مشرف'
              : 'عضو'),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      'high' => ('عالية', const Color(0xFFB3261E)),
      'low' => ('منخفضة', ItqanColors.muted),
      _ => ('عادية', ItqanColors.emerald),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: .25)),
      backgroundColor: color.withValues(alpha: .08),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ItqanColors.inkSoft)),
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: ItqanColors.muted),
              const SizedBox(height: 12),
              Text('تعذر تحميل بيانات الدائرة: $error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}
