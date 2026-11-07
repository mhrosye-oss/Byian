import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/itqan_journey_provider.dart';
import '../../data/journey_content_repository.dart';

class AdhkarJourneyScreen extends ConsumerStatefulWidget {
  const AdhkarJourneyScreen({super.key});

  @override
  ConsumerState<AdhkarJourneyScreen> createState() =>
      _AdhkarJourneyScreenState();
}

class _AdhkarJourneyScreenState extends ConsumerState<AdhkarJourneyScreen> {
  final _repository = JourneyContentRepository();
  final Map<int, int> _counts = {};
  final Set<int> _completed = {};
  List<Map<String, dynamic>> _items = [];
  String _category = 'morning_evening';
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _progressKey => 'journey_adhkar_${_todayKey}_$_category';
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _repository.loadAdhkar(_category);
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_progressKey);
      final saved = raw == null ? null : jsonDecode(raw);
      final counts = <int, int>{};
      final completed = <int>{};
      if (saved is Map) {
        final rawCounts = saved['counts'];
        if (rawCounts is Map) {
          for (final entry in rawCounts.entries) {
            final index = int.tryParse('${entry.key}');
            final count = entry.value;
            if (index != null &&
                count is num &&
                index >= 0 &&
                index < rows.length) {
              counts[index] = count.toInt().clamp(0, 100000);
            }
          }
        }
        final rawCompleted = saved['completed'];
        if (rawCompleted is List) {
          completed.addAll(rawCompleted
              .map((value) => int.tryParse('$value'))
              .whereType<int>());
        }
      }
      if (mounted) {
        setState(() {
          _items = rows;
          _counts
            ..clear()
            ..addAll(counts);
          _completed
            ..clear()
            ..addAll(
                completed.where((index) => index >= 0 && index < rows.length));
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل الأذكار: $error')),
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
        'counts': _counts.map((key, value) => MapEntry('$key', value)),
        'completed': _completed.toList(),
      }),
    );
  }

  void _setCount(int index, int value) {
    final rawTarget = _items[index]['count'];
    final target = rawTarget is num ? rawTarget.toInt().clamp(1, 100000) : 1;
    final next = value.clamp(0, target);
    setState(() => _counts[index] = next);
    _saveProgress();
  }

  Future<void> _submit(int index, int count) async {
    setState(() => _submitting = true);
    try {
      final result =
          await ref.read(itqanJourneyProvider.notifier).recordActivity(
        'adhkar',
        metadata: {'count': count},
      );
      if (mounted) setState(() => _completed.add(index));
      await _saveProgress();
      if (!mounted) return;
      final data = result['data'];
      final xp = data is Map ? data['xp_earned'] ?? 0 : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أكد الخادم تسجيل الذكر • $xp XP')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تعذر تأكيد الذكر. يمكنك إعادة المحاولة: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أذكار الرحلة')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _category,
              items: const [
                DropdownMenuItem(
                  value: 'morning_evening',
                  child: Text('أذكار الصباح والمساء'),
                ),
                DropdownMenuItem(value: 'misc', child: Text('أذكار متنوعة')),
              ],
              onChanged: (value) {
                if (value == null || value == _category) return;
                setState(() {
                  _category = value;
                  _counts.clear();
                  _completed.clear();
                });
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final rawTarget = item['count'];
                      final target = rawTarget is num
                          ? rawTarget.toInt().clamp(1, 100000)
                          : 1;
                      final count = _counts[index] ?? 0;
                      final done = _completed.contains(index);
                      final atTarget = count >= target;
                      final progress = (count / target).clamp(0.0, 1.0);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${item['text'] ?? ''}',
                                textDirection: TextDirection.rtl,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if ('${item['reference'] ?? ''}'.isNotEmpty)
                                Text('${item['reference']}'),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(value: progress),
                              const SizedBox(height: 4),
                              Text('$count / $target',
                                  textAlign: TextAlign.center),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'إنقاص العدّ',
                                    onPressed: done || _submitting || count == 0
                                        ? null
                                        : () => _setCount(index, count - 1),
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                  ),
                                  IconButton(
                                    tooltip: 'تصفير العدّ',
                                    onPressed: done || _submitting || count == 0
                                        ? null
                                        : () => _setCount(index, 0),
                                    icon: const Icon(Icons.restart_alt),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: done || _submitting
                                        ? null
                                        : atTarget
                                            ? () => _submit(index, target)
                                            : () {
                                                final next = count + 1;
                                                _setCount(index, next);
                                                if (next >= target) {
                                                  _submit(index, target);
                                                }
                                              },
                                    child: Text(
                                      done
                                          ? 'مكتمل'
                                          : atTarget
                                              ? 'إعادة المحاولة'
                                              : 'تسبيح',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
