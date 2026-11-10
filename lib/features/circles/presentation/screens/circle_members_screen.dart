import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/circle_list_provider.dart';
import '../../domain/circle_models.dart';

class CircleMembersScreen extends ConsumerStatefulWidget {
  const CircleMembersScreen({super.key, required this.circleUuid});
  final String circleUuid;

  @override
  ConsumerState<CircleMembersScreen> createState() =>
      _CircleMembersScreenState();
}

class _CircleMembersScreenState extends ConsumerState<CircleMembersScreen> {
  late Future<List<CircleMember>> _members;

  @override
  void initState() {
    super.initState();
    _members = _load();
  }

  Future<List<CircleMember>> _load() async =>
      (await ref.read(circleApiServiceProvider).getMembers(widget.circleUuid))
          .map(CircleMember.fromJson)
          .toList(growable: false);

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _members = future);
    await future;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('أعضاء الدائرة')),
        body: FutureBuilder<List<CircleMember>>(
          future: _members,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('تعذر تحميل الأعضاء: ${snapshot.error}'),
                TextButton(
                    onPressed: _refresh, child: const Text('إعادة المحاولة'))
              ]));
            final members = snapshot.data ?? const <CircleMember>[];
            return RefreshIndicator(
                onRefresh: _refresh,
                child: members.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                            SizedBox(height: 140),
                            Icon(Icons.people_outline, size: 56),
                            SizedBox(height: 12),
                            Center(child: Text('لا يوجد أعضاء للعرض.'))
                          ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final title = member.name?.isNotEmpty == true
                              ? member.name!
                              : 'عضو';
                          return Card(
                              child: ListTile(
                                  leading: CircleAvatar(
                                      child: Text(title.characters.first)),
                                  title: Text(title),
                                  subtitle: Text([
                                    _roleLabel(member.role),
                                    if (member.relationship?.isNotEmpty == true)
                                      member.relationship!,
                                    if (member.status?.isNotEmpty == true)
                                      member.status!
                                  ].join(' · ')),
                                  trailing: member.joinedAt == null
                                      ? null
                                      : Text(
                                          '${member.joinedAt!.day}/${member.joinedAt!.month}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall)));
                        }));
          },
        ),
      );

  String _roleLabel(String? role) => switch (role) {
        'owner' => 'مالك',
        'admin' => 'مشرف',
        'member' => 'عضو',
        _ => role ?? 'عضو'
      };
}
