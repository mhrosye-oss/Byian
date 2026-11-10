import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/circle_list_provider.dart';
import '../../domain/circle_models.dart';

class CircleWhispersSheet extends ConsumerStatefulWidget {
  const CircleWhispersSheet({super.key, required this.circleUuid});
  final String circleUuid;

  static Future<void> show(BuildContext context, String circleUuid) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => CircleWhispersSheet(circleUuid: circleUuid),
      );

  @override
  ConsumerState<CircleWhispersSheet> createState() =>
      _CircleWhispersSheetState();
}

class _CircleWhispersSheetState extends ConsumerState<CircleWhispersSheet> {
  late Future<List<CircleWhisper>> _whispers;

  @override
  void initState() {
    super.initState();
    _whispers = _load();
  }

  Future<List<CircleWhisper>> _load() async =>
      (await ref.read(circleApiServiceProvider).getWhispers(widget.circleUuid))
          .map(CircleWhisper.fromJson)
          .toList(growable: false);

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _whispers = future);
    await future;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                const Icon(Icons.forum_outlined, color: Colors.pink),
                const SizedBox(width: 10),
                Text('همسات الدائرة',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold))
              ])),
          const Divider(height: 1),
          Expanded(
              child: FutureBuilder<List<CircleWhisper>>(
            future: _whispers,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('تعذر تحميل الهمسات: ${snapshot.error}',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          TextButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'))
                        ])));
              }
              final whispers = snapshot.data ?? const <CircleWhisper>[];
              if (whispers.isEmpty) {
                return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.forum_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('لا توجد همسات بعد',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600))
                    ]));
              }
              return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: whispers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final whisper = whispers[index];
                        return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.pink.shade100)),
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(children: [
                                  CircleAvatar(
                                      backgroundColor: Colors.pink.shade50,
                                      child: Icon(Icons.forum,
                                          color: Colors.pink.shade400)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            whisper.messageText ??
                                                whisper.templateKey ??
                                                '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(_formatDate(whisper.createdAt),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600))
                                      ]))
                                ])));
                      }));
            },
          )),
        ]),
      );
}

// Compatibility helper retained at the feature boundary.
Future<void> openWhispersSheet(BuildContext context, String circleUuid) =>
    CircleWhispersSheet.show(context, circleUuid);
