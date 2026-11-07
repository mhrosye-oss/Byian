import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/itqan_journey_provider.dart';

class ShareJourneyScreen extends ConsumerStatefulWidget {
  const ShareJourneyScreen({super.key});

  @override
  ConsumerState<ShareJourneyScreen> createState() => _ShareJourneyScreenState();
}

class _ShareJourneyScreenState extends ConsumerState<ShareJourneyScreen> {
  static const _appLink =
      'https://play.google.com/store/apps/details?id=com.itqan.itqan';
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(itqanJourneyProvider);
      if (state.tasks == null && !state.loading) {
        ref.read(itqanJourneyProvider.notifier).loadAll();
      }
    });
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<String?> _validatedText() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل محتوى المشاركة أولاً')),
      );
      return null;
    }
    return text;
  }

  Future<void> _shareContent() async {
    final text = await _validatedText();
    if (text == null) return;
    await _share(text);
  }

  Future<void> _shareApplication() async {
    await _share('تعرّف على تطبيق إتقان للقرآن والعبادات اليومية:\n$_appLink');
  }

  Future<void> _share(String text) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final result = await Share.share(text);
      if (!mounted) return;
      if (result.status != ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يؤكد النظام اكتمال المشاركة؛ لم يُسجّل نشاط.'),
          ),
        );
        return;
      }

      try {
        final activity = await ref
            .read(itqanJourneyProvider.notifier)
            .recordActivity('share', sourceType: 'share');
        if (!mounted) return;
        final data = activity['data'];
        final duplicate = activity['duplicate'] == true;
        final xp = data is Map ? data['xp_earned'] ?? 0 : 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              duplicate
                  ? 'المشاركة مسجلة مسبقاً.'
                  : 'أكد الخادم تسجيل المشاركة • $xp XP',
            ),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        final queued = error is ItqanJourneyException && error.queued;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              queued
                  ? 'اكتملت المشاركة وحُفظ نشاطها للمزامنة؛ لا تُمنح نقاط حتى يؤكدها الخادم.'
                  : 'اكتملت المشاركة، لكن تعذر تسجيل النشاط: $error',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذرت مشاركة المحتوى: $error')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _shareTaskProgress(ItqanJourneyState state) {
    if (state.tasks == null) {
      final loading = state.loading || state.error == null;
      return Card(
        child: ListTile(
          title: const Text('تقدم مهمة المشاركة'),
          subtitle: Text(
            loading
                ? 'جارٍ تحميل الهدف من الخادم…'
                : state.error ?? 'تعذر تحميل تقدم المهمة.',
          ),
          trailing: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: 'إعادة تحميل المهام',
                  onPressed: () =>
                      ref.read(itqanJourneyProvider.notifier).loadAll(),
                  icon: const Icon(Icons.refresh),
                ),
        ),
      );
    }

    final rows = state.tasks?['tasks'];
    Map? task;
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) continue;
        final pillar = '${row['pillar'] ?? ''}'.toLowerCase();
        final key = '${row['task_key'] ?? ''}'.toLowerCase();
        final title = '${row['title'] ?? ''}'.toLowerCase();
        if (pillar == 'share' ||
            pillar == 'sharing' ||
            key.contains('share') ||
            title.contains('مشاركة') ||
            title.contains('share')) {
          task = row;
          break;
        }
      }
    }
    if (task == null) {
      return const Card(
        child: ListTile(
          title: Text('تقدم مهمة المشاركة'),
          subtitle: Text('لا تتضمن استجابة المهام هدف مشاركة قابلاً للعرض.'),
        ),
      );
    }

    final progress = task['progress'];
    final target = task['target'];
    final hasProgress = progress is num && target is num && target > 0;
    final ratio = hasProgress
        ? (progress / target).toDouble().clamp(0.0, 1.0)
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${task['title'] ?? 'هدف المشاركة'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if ('${task['description'] ?? ''}'.isNotEmpty)
              Text('${task['description']}'),
            if (ratio != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: ratio),
              Text('$progress / $target'),
            ] else
              const Text('لم يحدد الخادم مقدار التقدم والهدف.'),
            if (task['status'] != null) Text('الحالة: ${task['status']}'),
            Text(
              'المكافأة عند اعتماد الخادم: ${task['xp_reward'] ?? '—'} XP • ${task['coin_reward'] ?? '—'} Coins',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(itqanJourneyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('مشاركة الخير')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('شارك تطبيق إتقان أو فائدة أو دعاءً موثوقاً.'),
          const SizedBox(height: 12),
          _shareTaskProgress(journeyState),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _shareApplication,
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('مشاركة رابط التطبيق'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            minLines: 4,
            maxLines: 8,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'أدخل المحتوى الذي تريد مشاركته',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _shareContent,
            icon: const Icon(Icons.share_outlined),
            label: Text(_sending ? 'جارٍ فتح المشاركة…' : 'مشاركة المحتوى'),
          ),
          const SizedBox(height: 8),
          Text(
            'يُسجّل النشاط فقط إذا أعادت واجهة المشاركة نتيجة نجاح. لا يعني ذلك أن المستلم استلم المحتوى أو فتحه.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
