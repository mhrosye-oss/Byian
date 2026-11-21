import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/theme/colors.dart';
import '../application/circle_context_provider.dart';

class CircleLessonsScreen extends ConsumerStatefulWidget {
  const CircleLessonsScreen({
    super.key,
    required this.circleUuid,
    required this.canManage,
  });

  final String circleUuid;
  final bool canManage;

  @override
  ConsumerState<CircleLessonsScreen> createState() =>
      _CircleLessonsScreenState();
}

class _CircleLessonsScreenState extends ConsumerState<CircleLessonsScreen> {
  List<Map<String, dynamic>> _lessons = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _working = {};

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
      final lessons = await ref
          .read(circleApiServiceProvider)
          .fetchLessons(widget.circleUuid);
      if (mounted) setState(() => _lessons = lessons);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createLesson() async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة درس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'عنوان الدرس'),
            ),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              decoration:
                  const InputDecoration(labelText: 'رابط فيديو YouTube'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final url = urlController.text.trim();
              if (title.isNotEmpty && url.isNotEmpty) {
                Navigator.pop(dialogContext, (title, url));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    titleController.dispose();
    urlController.dispose();
    if (values == null || !mounted) return;

    try {
      await ref.read(circleApiServiceProvider).createLesson(
            widget.circleUuid,
            title: values.$1,
            youtubeUrl: values.$2,
          );
      await _load();
    } catch (error) {
      _showError('$error');
    }
  }

  Future<void> _openLesson(Map<String, dynamic> lesson) async {
    final uuid = lesson['uuid']?.toString();
    if (uuid == null || uuid.isEmpty || !_working.add(uuid)) return;
    setState(() {});
    try {
      final details =
          await ref.read(circleApiServiceProvider).fetchLesson(uuid);
      final videoId = details['youtube_video_id']?.toString() ??
          lesson['youtube_video_id']?.toString() ??
          '';
      if (videoId.isEmpty) {
        _showError('لا يتوفر معرّف فيديو لهذا الدرس.');
        return;
      }
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _LessonPlayerScreen(
            title: details['title']?.toString() ??
                lesson['title']?.toString() ??
                'درس',
            videoId: videoId,
          ),
        ),
      );
    } catch (error) {
      _showError('$error');
    } finally {
      _working.remove(uuid);
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteLesson(Map<String, dynamic> lesson) async {
    final uuid = lesson['uuid']?.toString() ?? '';
    if (uuid.isEmpty || !widget.canManage) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الدرس'),
        content: Text('هل تريد حذف "${lesson['title'] ?? 'هذا الدرس'}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(circleApiServiceProvider).deleteLesson(uuid);
      await _load();
    } catch (error) {
      _showError('$error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: ItqanColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ItqanColors.emerald),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تعذر تحميل الدروس: $_error'),
            TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: ItqanColors.emerald,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.canManage)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _createLesson,
                icon: const Icon(Icons.add),
                label: const Text('إضافة درس'),
              ),
            ),
          if (_lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('لا توجد دروس منشورة')),
            )
          else
            ..._lessons.map(
              (lesson) {
                final uuid = lesson['uuid']?.toString() ?? '';
                return Card(
                  color: ItqanColors.surface,
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.play_arrow_rounded),
                    ),
                    title: Text(lesson['title']?.toString() ?? 'درس'),
                    subtitle: Text(
                      lesson['creator_name']?.toString() ?? 'درس من الدائرة',
                    ),
                    trailing: widget.canManage
                        ? IconButton(
                            tooltip: 'حذف الدرس',
                            onPressed: () => _deleteLesson(lesson),
                            icon: const Icon(Icons.delete_outline),
                          )
                        : _working.contains(uuid)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                    onTap: _working.contains(uuid)
                        ? null
                        : () => _openLesson(lesson),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LessonPlayerScreen extends StatefulWidget {
  const _LessonPlayerScreen({required this.title, required this.videoId});

  final String title;
  final String videoId;

  @override
  State<_LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<_LessonPlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
        ),
      );
}
