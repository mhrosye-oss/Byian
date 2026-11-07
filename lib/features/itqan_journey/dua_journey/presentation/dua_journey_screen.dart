import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/itqan_journey_provider.dart';
import '../../data/journey_content_repository.dart';

class DuaJourneyScreen extends ConsumerStatefulWidget {
  const DuaJourneyScreen({super.key});

  @override
  ConsumerState<DuaJourneyScreen> createState() => _DuaJourneyScreenState();
}

class _DuaJourneyScreenState extends ConsumerState<DuaJourneyScreen> {
  final _repository = JourneyContentRepository();
  final Set<int> _completed = {};
  final Set<int> _favorites = {};
  final Set<int> _submitting = {};
  List<Map<String, dynamic>> _duas = [];
  bool _loading = true;

  String get _progressKey {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'journey_duas_$date';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final duas = await _repository.loadDuas();
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_progressKey);
      final saved = raw == null ? null : jsonDecode(raw);
      if (saved is Map) {
        final completed = saved['completed'];
        final favorites = saved['favorites'];
        if (completed is List) {
          _completed
            ..clear()
            ..addAll(completed
                .map((value) => int.tryParse('$value'))
                .whereType<int>());
        }
        if (favorites is List) {
          _favorites
            ..clear()
            ..addAll(favorites
                .map((value) => int.tryParse('$value'))
                .whereType<int>());
        }
      }
      if (mounted) setState(() => _duas = duas);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل الأدعية: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _progressKey,
      jsonEncode({
        'completed': _completed.toList(),
        'favorites': _favorites.toList(),
      }),
    );
  }

  Future<void> _toggleFavorite(int index) async {
    setState(() {
      if (!_favorites.add(index)) _favorites.remove(index);
    });
    await _saveProgress();
  }

  Future<void> _complete(int index) async {
    setState(() => _submitting.add(index));
    try {
      final result =
          await ref.read(itqanJourneyProvider.notifier).recordActivity('dua');
      if (mounted) setState(() => _completed.add(index));
      await _saveProgress();
      if (!mounted) return;
      final data = result['data'];
      final xp = data is Map ? data['xp_earned'] ?? 0 : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أكد الخادم القراءة • $xp XP')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تأكيد القراءة: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أدعية الرحلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _duas.isEmpty
              ? const Center(child: Text('لا توجد أدعية متاحة.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _duas.length,
                  itemBuilder: (context, index) {
                    final dua = _duas[index];
                    final completed = _completed.contains(index);
                    final favorite = _favorites.contains(index);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${dua['category'] ?? ''} • ${dua['title'] ?? ''}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                IconButton(
                                  tooltip: favorite
                                      ? 'إزالة من المفضلة'
                                      : 'إضافة إلى المفضلة',
                                  onPressed: () => _toggleFavorite(index),
                                  icon: Icon(favorite
                                      ? Icons.favorite
                                      : Icons.favorite_border),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text(
                              '${dua['text'] ?? ''}',
                              textDirection: TextDirection.rtl,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if ('${dua['reference'] ?? ''}'.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('${dua['reference']}'),
                              ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed:
                                  completed || _submitting.contains(index)
                                      ? null
                                      : () => _complete(index),
                              child: Text(
                                completed
                                    ? 'سُجلت قراءة اليوم'
                                    : _submitting.contains(index)
                                        ? 'جارٍ تأكيد القراءة…'
                                        : 'قرأت الدعاء',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
