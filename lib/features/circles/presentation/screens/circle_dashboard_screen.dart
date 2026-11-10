import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itqan/features/adhkar/screens/adhkar_screen.dart';
import 'package:itqan/features/adhkar/screens/duas_screen.dart';
import 'package:itqan/features/khatmah/screens/khatmah_screen.dart';
import 'package:itqan/features/mushaf/mushaf_screen.dart';
import 'package:itqan/features/tasbih/screens/smart_tasbih_screen.dart';

import '../../application/circle_list_provider.dart';
import 'circle_members_screen.dart';

class CircleDashboardScreen extends ConsumerStatefulWidget {
  const CircleDashboardScreen({super.key, required this.uuid, this.name});
  final String uuid;
  final String? name;

  @override
  ConsumerState<CircleDashboardScreen> createState() => _CircleDashboardScreenState();
}

class _CircleDashboardScreenState extends ConsumerState<CircleDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = ref.read(circleApiServiceProvider).getDashboard(widget.uuid);
  }

  Future<void> _refresh() async {
    final future = ref.read(circleApiServiceProvider).getDashboard(widget.uuid);
    setState(() => _dashboard = future);
    await future;
  }

  void _openService(String label) {
    final Widget? page = switch (label) {
      'مصحف' => const MushafScreen(),
      'تسبيح' => const SmartTasbihScreen(),
      'أذكار' => const AdhkarScreen(),
      'أدعية' => const DuasScreen(),
      'ختمة' => const KhatmahScreen(),
      _ => null,
    };
    if (page != null) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ستتوفر الهمسات قريبًا.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.name ?? 'لوحة الدائرة')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _dashboard,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('تعذر تحميل الدائرة: ${snapshot.error}', textAlign: TextAlign.center), TextButton(onPressed: _refresh, child: const Text('إعادة المحاولة'))]));
            final data = snapshot.data ?? const <String, dynamic>{};
            final members = data['members'] is List ? List<Map<String, dynamic>>.from((data['members'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e))) : <Map<String, dynamic>>[];
            final activities = data['activities'] is List ? List<Map<String, dynamic>>.from((data['activities'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e))) : <Map<String, dynamic>>[];
            return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              _header(context, '${data['name'] ?? widget.name ?? 'الدائرة'}', data, members.length),
              _services(context),
              const Divider(height: 32),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Expanded(child: Text('الأعضاء', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CircleMembersScreen(circleUuid: widget.uuid))), child: const Text('عرض الكل'))])),
              if (members.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد معلومات أعضاء للعرض.')) else ...members.take(4).map((member) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text('${member['name'] ?? 'عضو'}'), subtitle: Text('${member['role'] ?? 'member'}'))),
              const Divider(height: 24),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('آخر الأنشطة', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              if (activities.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد أنشطة بعد.')) else ...activities.take(5).map((item) => ListTile(leading: const Icon(Icons.auto_awesome_outlined), title: Text('${item['description'] ?? item['event_type'] ?? 'نشاط جديد'}'), subtitle: Text('${item['created_at'] ?? ''}'))),
            ]));
          },
        ),
      );

  Widget _header(BuildContext context, String name, Map<String, dynamic> data, int count) => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.groups_rounded, color: Colors.white, size: 30)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text('${data['type'] is Map ? data['type']['name'] ?? '' : data['type'] ?? ''} · $count أعضاء', style: const TextStyle(color: Colors.white70))]))]),
      );

  Widget _services(BuildContext context) {
    final services = <_ServiceItem>[
      const _ServiceItem(Icons.menu_book_rounded, 'مصحف', Color(0xFF0A7A49)),
      _ServiceItem(Icons.fingerprint_rounded, 'تسبيح', Colors.amber.shade800),
      const _ServiceItem(Icons.auto_awesome_rounded, 'أذكار', Colors.teal),
      const _ServiceItem(Icons.pan_tool_rounded, 'أدعية', Colors.indigo),
      const _ServiceItem(Icons.auto_stories_rounded, 'ختمة', Colors.purple),
      const _ServiceItem(Icons.forum_rounded, 'همسات', Colors.pink),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('خدمات الدائرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      GridView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1), itemCount: services.length, itemBuilder: (context, index) => InkWell(onTap: () => _openService(services[index].label), borderRadius: BorderRadius.circular(16), child: Container(decoration: BoxDecoration(color: services[index].color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: services[index].color.withValues(alpha: 0.25), width: 1.5)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(services[index].icon, size: 34, color: services[index].color), const SizedBox(height: 8), Text(services[index].label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: services[index].color))])))),
    ]);
  }
}

class _ServiceItem {
  const _ServiceItem(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}
