import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/circle_list_provider.dart';
import '../../domain/circle_models.dart';
import 'circle_dashboard_screen.dart';
import 'create_circle_screen.dart';

class MyCirclesScreen extends ConsumerWidget {
  const MyCirclesScreen({super.key});

  IconData _iconForType(String key) => switch (key) {
        'family' => Icons.home_rounded,
        'classroom' => Icons.school_rounded,
        'study_circle' => Icons.menu_book_rounded,
        'goodness' => Icons.volunteer_activism_rounded,
        'companions' => Icons.groups_rounded,
        _ => Icons.group_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(myCirclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('دوائري')),
      body: circles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('$error', textAlign: TextAlign.center), TextButton(onPressed: () => ref.invalidate(myCirclesProvider), child: const Text('إعادة المحاولة'))]))),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(myCirclesProvider.future),
          child: items.isEmpty
              ? ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(24), children: [const SizedBox(height: 100), Icon(Icons.groups_2_outlined, size: 72, color: Colors.grey.shade400), const SizedBox(height: 16), const Center(child: Text('لم تنضم إلى أي دائرة بعد.')), const SizedBox(height: 16), Center(child: FilledButton.icon(onPressed: () => _create(context, ref), icon: const Icon(Icons.add), label: const Text('إنشاء دائرة')))])
              : ListView(padding: const EdgeInsets.all(16), children: [Align(alignment: Alignment.center, child: FilledButton.icon(onPressed: () => _create(context, ref), icon: const Icon(Icons.add), label: const Text('إنشاء دائرة'))), const SizedBox(height: 12), ...items.map((circle) => _CircleCard(circle: circle, icon: _iconForType(circle.type?.key ?? ''), onOpen: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CircleDashboardScreen(uuid: circle.uuid, name: circle.name))))) ]),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateCircleScreen()));
    if (created == true) ref.invalidate(myCirclesProvider);
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle, required this.icon, required this.onOpen});
  final Circle circle;
  final IconData icon;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(circle.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), _RoleBadge(role: circle.myRole ?? 'member')]),
          if (circle.type?.name.isNotEmpty == true) ...[const SizedBox(height: 6), Text(circle.type!.name, style: Theme.of(context).textTheme.bodySmall)],
          if (circle.description?.isNotEmpty == true) ...[const SizedBox(height: 8), Text(circle.description!)],
          const SizedBox(height: 12), Row(children: [const Icon(Icons.people_outline, size: 18), const SizedBox(width: 6), Text('${circle.membersCount} أعضاء')]),
          const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.login_rounded, size: 20), label: const Text('الدخول مباشرة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), onPressed: onOpen)),
        ])),
      );
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (role) {
      'owner' => ('مالك', Colors.amber.shade100, Colors.amber.shade900),
      'admin' => ('مشرف', Colors.orange.shade100, Colors.orange.shade900),
      'member' => ('عضو', Colors.blue.shade100, Colors.blue.shade900),
      _ => (role, Colors.grey.shade200, Colors.grey.shade700),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: foreground)));
  }
}
