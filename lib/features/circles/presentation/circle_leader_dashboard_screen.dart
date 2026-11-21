import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../application/circle_context_provider.dart';
import '../data/models/circle.dart';
import 'circle_dashboard_screen.dart';

class CircleLeaderDashboardScreen extends ConsumerStatefulWidget {
  const CircleLeaderDashboardScreen({super.key, required this.circle});

  final Circle circle;

  @override
  ConsumerState<CircleLeaderDashboardScreen> createState() =>
      _CircleLeaderDashboardScreenState();
}

class _CircleLeaderDashboardScreenState
    extends ConsumerState<CircleLeaderDashboardScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(circleApiServiceProvider)
          .fetchLeaderDashboard(widget.circle.uuid);
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(
          title: Text('لوحة ${widget.circle.name}'),
          backgroundColor: ItqanColors.cream,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: ItqanColors.emerald),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('تعذر تحميل لوحة القائد: $_error'),
                        TextButton(
                          onPressed: _load,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _buildDashboard(_data ?? const {}),
      );

  Widget _buildDashboard(Map<String, dynamic> data) {
    final isLeader = data['is_leader'] == true;
    final stats =
        data['stats'] is Map ? Map<String, dynamic>.from(data['stats']) : {};
    final needsAttention = _mapList(data['needs_attention']);
    final recentActivities = _mapList(data['recent_activities']);
    final quickActions = isLeader ? _mapList(data['quick_actions']) : const [];

    return RefreshIndicator(
      color: ItqanColors.emerald,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (stats.isNotEmpty)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.8,
              children: stats.entries.take(4).map((entry) {
                return Card(
                  color: ItqanColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _label(entry.key),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: ItqanColors.inkSoft),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ItqanColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          _buildKhatmahProgress(data['khatmah_progress']),
          if (needsAttention.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'يحتاج إلى متابعة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            ...needsAttention.map(
              (item) => Card(
                color: ItqanColors.surface,
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(
                    item['title']?.toString() ??
                        item['message']?.toString() ??
                        'تنبيه',
                  ),
                  subtitle: item['description'] == null
                      ? null
                      : Text(item['description'].toString()),
                ),
              ),
            ),
          ],
          if (quickActions.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'إجراءات سريعة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickActions.take(4).map((action) {
                final label = action['label']?.toString() ??
                    action['title']?.toString() ??
                    'إدارة الدائرة';
                return FilledButton.tonal(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CircleDashboardScreen(
                          circle: widget.circle,
                        ),
                      ),
                    );
                  },
                  child: Text(label),
                );
              }).toList(),
            ),
          ],
          if (recentActivities.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'النشاطات الأخيرة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            ...recentActivities.take(8).map(
                  (activity) => Card(
                    color: ItqanColors.surface,
                    child: ListTile(
                      leading: const Icon(Icons.bolt_outlined),
                      title: Text(
                        activity['title']?.toString() ??
                            activity['message']?.toString() ??
                            'نشاط',
                      ),
                      subtitle: activity['user_name'] == null
                          ? null
                          : Text(activity['user_name'].toString()),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildKhatmahProgress(dynamic rawProgress) {
    if (rawProgress == null) return const SizedBox.shrink();
    final map = rawProgress is Map
        ? Map<String, dynamic>.from(rawProgress)
        : const <String, dynamic>{};
    final rawValue = map['progress'] ??
        map['percentage'] ??
        map['progress_percentage'] ??
        map['completion_percentage'] ??
        rawProgress;
    final value = rawValue is num
        ? rawValue.toDouble()
        : double.tryParse(rawValue.toString()) ?? 0;
    final ratio = (value > 1 ? value / 100 : value).clamp(0.0, 1.0);
    final completed = map['completed'] ?? map['completed_parts'];
    final total = map['total'] ?? map['total_parts'];
    return Card(
      color: ItqanColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تقدم الختمة${completed != null && total != null ? ' • $completed / $total' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: ratio),
          ],
        ),
      ),
    );
  }

  String _label(String key) {
    const labels = {
      'members': 'الأعضاء',
      'members_count': 'الأعضاء',
      'tasks': 'المهام',
      'tasks_count': 'المهام',
      'completed_tasks': 'المهام المكتملة',
      'completed_tasks_count': 'المهام المكتملة',
      'activities': 'النشاطات',
      'whispers': 'الهمسات',
    };
    return labels[key] ?? key.replaceAll('_', ' ');
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .where((item) => item is Map || item is String)
        .map((item) => item is Map
            ? Map<String, dynamic>.from(item)
            : <String, dynamic>{'label': item.toString()})
        .toList(growable: false);
  }
}
