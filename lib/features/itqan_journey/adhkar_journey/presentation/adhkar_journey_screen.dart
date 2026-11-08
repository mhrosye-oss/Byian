import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const _categories = <String, String>{
    'morning_evening': 'أذكار الصباح والمساء',
    'sleep_wake': 'أذكار النوم والاستيقاظ',
    'wudu_prayer': 'الوضوء والصلاة',
    'mosque': 'المسجد',
    'food_drink': 'الطعام والشراب',
    'travel': 'السفر',
    'sadness': 'الهم والكرب',
    'istikharah': 'الاستخارة',
    'sickness': 'المرض',
    'debt': 'قضاء الدين',
    'marriage': 'الزواج',
    'rain': 'المطر',
    'home': 'المنزل',
    'clothing': 'اللباس',
    'misc': 'أذكار متنوعة',
  };

  final _repository = JourneyContentRepository();
  final Map<int, int> _counts = {};
  final Set<int> _completed = {};
  final Map<int, String> _pending = {};
  List<Map<String, dynamic>> _items = [];
  String _category = 'morning_evening';
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;

  String get _progressKey => 'journey_adhkar_${_todayKey}_$_category';
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final rows = await _repository.loadAdhkar(_category);
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_progressKey);
      final saved = raw == null ? null : jsonDecode(raw);
      final counts = <int, int>{};
      final completed = <int>{};
      final pending = <int, String>{};
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
              counts[index] = count.toInt().clamp(0, _targetFor(rows[index]));
            }
          }
        }
        final rawCompleted = saved['completed'];
        if (rawCompleted is List) {
          completed.addAll(
            rawCompleted
                .map((value) => int.tryParse('$value'))
                .whereType<int>()
                .where((index) => index >= 0 && index < rows.length),
          );
        }
        final rawPending = saved['pending'];
        if (rawPending is Map) {
          for (final entry in rawPending.entries) {
            final index = int.tryParse('${entry.key}');
            if (index != null && index >= 0 && index < rows.length) {
              pending[index] = '${entry.value}';
            }
          }
        }
      }

      if (pending.isNotEmpty) {
        final api = ref.read(itqanJourneyRepositoryProvider);
        await api.syncPendingActivities();
        for (final entry in pending.entries.toList()) {
          if (!await api.hasPendingActivity(entry.value)) {
            completed.add(entry.key);
            pending.remove(entry.key);
          }
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
            ..addAll(completed);
          _pending
            ..clear()
            ..addAll(pending);
        });
        await _saveProgress();
      }
    } catch (error) {
      if (mounted) setState(() => _loadError = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _targetFor(Map<String, dynamic> item) {
    final rawTarget = item['count'];
    return rawTarget is num ? rawTarget.toInt().clamp(1, 1000) : 1;
  }

  Future<void> _saveProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _progressKey,
      jsonEncode({
        'counts': _counts.map((key, value) => MapEntry('$key', value)),
        'completed': _completed.toList(),
        'pending': _pending.map((key, value) => MapEntry('$key', value)),
      }),
    );
  }

  Future<void> _setCount(int index, int value) async {
    final next = value.clamp(0, _targetFor(_items[index]));
    setState(() => _counts[index] = next);
    await _saveProgress();
  }

  Future<void> _submit(int index, int count) async {
    if (_completed.contains(index) || _pending.containsKey(index)) return;
    setState(() => _submitting = true);
    try {
      final result =
          await ref.read(itqanJourneyProvider.notifier).recordActivity(
                'adhkar',
                metadata: {'count': count},
                sourceType: 'adhkar',
              );
      _completed.add(index);
      await _saveProgress();
      if (!mounted) return;
      setState(() {});
      final data = result['data'];
      final xp = data is Map ? data['xp_earned'] ?? 0 : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أكد الخادم تسجيل الذكر • $xp XP')),
      );
    } catch (error) {
      if (error is ItqanJourneyException && error.queued) {
        final id = error.idempotencyKey;
        if (id != null) {
          _pending[index] = id;
          await _saveProgress();
        }
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'بلغت الهدف وحُفظ النشاط للمزامنة؛ لا تُمنح نقاط حتى يؤكده الخادم.',
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تأكيد الذكر؛ يمكنك إعادة المحاولة: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _retryPending(int index) async {
    final id = _pending[index];
    if (id == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final api = ref.read(itqanJourneyRepositoryProvider);
      await api.syncPendingActivities();
      if (!await api.hasPendingActivity(id)) {
        _pending.remove(index);
        _completed.add(index);
        await _saveProgress();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('أكد الخادم إكمال الذكر ومزامنته.')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ما زال النشاط بانتظار الاتصال بالخادم.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذرت مزامنة الذكر: $error')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('أذكار الرحلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل الأذكار المحفوظة في التطبيق.'),
                        Text(_loadError!, textDirection: TextDirection.rtl),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'تصنيف الأذكار',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null || value == _category) return;
                          setState(() {
                            _category = value;
                            _counts.clear();
                            _completed.clear();
                            _pending.clear();
                          });
                          _load();
                        },
                      ),
                    ),
                    Expanded(
                      child: rows.isEmpty
                          ? const Center(
                              child: Text('لا توجد أذكار في هذا التصنيف.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: rows.length,
                              itemBuilder: (context, index) {
                                final item = rows[index];
                                final target = _targetFor(item);
                                final count = _counts[index] ?? 0;
                                final done = _completed.contains(index);
                                final pending = _pending.containsKey(index);
                                final atTarget = count >= target;
                                final progress =
                                    (count / target).clamp(0.0, 1.0);

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          '${item['text'] ?? ''}',
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.right,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        if ('${item['reference'] ?? ''}'
                                            .isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              '${item['reference']}',
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                        LinearProgressIndicator(
                                            value: progress),
                                        const SizedBox(height: 5),
                                        Text(
                                          'الهدف: $count / $target',
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              tooltip: 'إنقاص العدّ',
                                              onPressed: done ||
                                                      pending ||
                                                      _submitting ||
                                                      count == 0
                                                  ? null
                                                  : () => _setCount(
                                                      index, count - 1),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'تصفير العدّ',
                                              onPressed: done ||
                                                      pending ||
                                                      _submitting ||
                                                      count == 0
                                                  ? null
                                                  : () => _setCount(index, 0),
                                              icon:
                                                  const Icon(Icons.restart_alt),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 92,
                                              height: 92,
                                              child: FilledButton(
                                                style: FilledButton.styleFrom(
                                                  shape: const CircleBorder(),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                onPressed: _submitting
                                                    ? null
                                                    : pending
                                                        ? () =>
                                                            _retryPending(index)
                                                        : done
                                                            ? null
                                                            : atTarget
                                                                ? () => _submit(
                                                                    index,
                                                                    target)
                                                                : () async {
                                                                    HapticFeedback
                                                                        .selectionClick();
                                                                    final next =
                                                                        count +
                                                                            1;
                                                                    await _setCount(
                                                                      index,
                                                                      next,
                                                                    );
                                                                    if (next >=
                                                                        target) {
                                                                      await _submit(
                                                                        index,
                                                                        target,
                                                                      );
                                                                    }
                                                                  },
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '$count',
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      pending
                                                          ? 'مزامنة'
                                                          : done
                                                              ? 'مكتمل'
                                                              : atTarget
                                                                  ? 'إعادة'
                                                                  : 'تسبيح',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (pending)
                                          const Text(
                                            'بلغت الهدف؛ النشاط محفوظ للمزامنة ولا تُحتسب مكافأة حتى إقرار الخادم.',
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.center,
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
