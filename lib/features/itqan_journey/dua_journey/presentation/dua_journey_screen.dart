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
  final Set<String> _completed = {};
  final Set<String> _favorites = {};
  final Map<String, String> _pending = {};
  final Set<String> _submitting = {};
  List<Map<String, dynamic>> _duas = [];
  String? _selectedCategory;
  String? _loadError;
  bool _loading = true;

  String get _dateKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _progressKey => 'journey_duas_$_dateKey';
  static const _favoritesKey = 'journey_duas_favorites';

  String _duaKey(Map<String, dynamic> dua) =>
      '${dua['category'] ?? ''}|${dua['title'] ?? ''}|${dua['reference'] ?? ''}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Set<String> _readStoredIds(dynamic raw, List<Map<String, dynamic>> duas) {
    final result = <String>{};
    if (raw is! List) return result;
    for (final value in raw) {
      if (value is String) {
        result.add(value);
      } else if (value is num) {
        final index = value.toInt();
        if (index >= 0 && index < duas.length) result.add(_duaKey(duas[index]));
      }
    }
    return result;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final duas = await _repository.loadDuas();
      final preferences = await SharedPreferences.getInstance();
      final rawToday = preferences.getString(_progressKey);
      final savedToday = rawToday == null ? null : jsonDecode(rawToday);
      final completed = <String>{};
      final pending = <String, String>{};
      final favorites = <String>{};

      if (savedToday is Map) {
        completed.addAll(_readStoredIds(savedToday['completed'], duas));
        final rawPending = savedToday['pending'];
        if (rawPending is Map) {
          for (final entry in rawPending.entries) {
            pending['${entry.key}'] = '${entry.value}';
          }
        }
      }
      final rawFavorites = preferences.getString(_favoritesKey);
      if (rawFavorites != null) {
        favorites.addAll(_readStoredIds(jsonDecode(rawFavorites), duas));
      } else if (savedToday is Map) {
        // Migrate favorites saved under the previous date-scoped preference.
        favorites.addAll(_readStoredIds(savedToday['favorites'], duas));
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

      if (rawFavorites == null && favorites.isNotEmpty) {
        await preferences.setString(
          _favoritesKey,
          jsonEncode(favorites.toList()),
        );
      }
      if (mounted) {
        setState(() {
          _duas = duas;
          _completed
            ..clear()
            ..addAll(completed);
          _favorites
            ..clear()
            ..addAll(favorites);
          _pending
            ..clear()
            ..addAll(pending);
          if (_selectedCategory != null &&
              !duas.any((dua) => dua['category'] == _selectedCategory)) {
            _selectedCategory = null;
          }
        });
      }
      if (pending.isNotEmpty || completed.isNotEmpty) await _saveProgress();
    } catch (error) {
      if (mounted) setState(() => _loadError = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _progressKey,
      jsonEncode({'completed': _completed.toList(), 'pending': _pending}),
    );
    await preferences.setString(_favoritesKey, jsonEncode(_favorites.toList()));
  }

  Future<void> _toggleFavorite(String key) async {
    setState(() {
      if (!_favorites.add(key)) _favorites.remove(key);
    });
    await _saveProgress();
  }

  Future<void> _complete(String key) async {
    if (_completed.contains(key) || _pending.containsKey(key)) return;
    setState(() => _submitting.add(key));
    try {
      final result = await ref
          .read(itqanJourneyProvider.notifier)
          .recordActivity('dua', sourceType: 'dua');
      _completed.add(key);
      await _saveProgress();
      if (!mounted) return;
      final data = result['data'];
      final xp = data is Map ? data['xp_earned'] ?? 0 : 0;
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('أكد الخادم القراءة • $xp XP')));
    } catch (error) {
      if (error is ItqanJourneyException && error.queued) {
        final id = error.idempotencyKey;
        if (id != null) {
          _pending[key] = id;
          await _saveProgress();
        }
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'حُفظ إكمال الدعاء للمزامنة؛ لا تُمنح نقاط حتى يؤكدها الخادم.',
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تأكيد القراءة؛ يمكنك إعادة المحاولة: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting.remove(key));
    }
  }

  Future<void> _retryPending(String key) async {
    final id = _pending[key];
    if (id == null || _submitting.contains(key)) return;
    setState(() => _submitting.add(key));
    try {
      final api = ref.read(itqanJourneyRepositoryProvider);
      await api.syncPendingActivities();
      if (!await api.hasPendingActivity(id)) {
        _pending.remove(key);
        _completed.add(key);
        await _saveProgress();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('أكد الخادم إكمال الدعاء ومزامنته.')),
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
        ).showSnackBar(SnackBar(content: Text('تعذرت مزامنة الدعاء: $error')));
      }
    } finally {
      if (mounted) setState(() => _submitting.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedToday =
        _duas.where((dua) => _completed.contains(_duaKey(dua))).length;
    final visibleIndexes = [
      for (var index = 0; index < _duas.length; index++)
        if (_selectedCategory == null ||
            _duas[index]['category'] == _selectedCategory)
          index,
    ];
    final categories = _duas
        .map((dua) => '${dua['category'] ?? ''}')
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('أدعية الرحلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل الأدعية المحفوظة في التطبيق.'),
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
              : _duas.isEmpty
                  ? const Center(child: Text('لا توجد أدعية متاحة حالياً.'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory ?? '__all__',
                            decoration: const InputDecoration(
                              labelText: 'تصنيف الأدعية',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '__all__',
                                child: Text('كل التصنيفات'),
                              ),
                              ...categories.map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              ),
                            ],
                            onChanged: (value) => setState(() {
                              _selectedCategory =
                                  value == '__all__' ? null : value;
                            }),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('قراءة اليوم'),
                                      Text('$completedToday / ${_duas.length}'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: _duas.isEmpty
                                        ? 0
                                        : completedToday / _duas.length,
                                  ),
                                  if (_pending.isNotEmpty)
                                    Text(
                                        '${_pending.length} دعاء بانتظار المزامنة'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: visibleIndexes.isEmpty
                              ? const Center(
                                  child: Text('لا توجد أدعية في هذا التصنيف.'),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: visibleIndexes.length,
                                  itemBuilder: (context, visibleIndex) {
                                    final originalIndex =
                                        visibleIndexes[visibleIndex];
                                    final dua = _duas[originalIndex];
                                    final key = _duaKey(dua);
                                    final completed = _completed.contains(key);
                                    final pending = _pending.containsKey(key);
                                    final favorite = _favorites.contains(key);
                                    final submitting =
                                        _submitting.contains(key);
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${dua['category'] ?? ''} • ${dua['title'] ?? ''}',
                                                    textDirection:
                                                        TextDirection.rtl,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: favorite
                                                      ? 'إزالة من المفضلة'
                                                      : 'إضافة إلى المفضلة',
                                                  onPressed: () =>
                                                      _toggleFavorite(key),
                                                  icon: Icon(
                                                    favorite
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(),
                                            Text(
                                              '${dua['text'] ?? ''}',
                                              textDirection: TextDirection.rtl,
                                              textAlign: TextAlign.right,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall,
                                            ),
                                            if ('${dua['reference'] ?? ''}'
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(
                                                  '${dua['reference']}',
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            if (pending)
                                              OutlinedButton.icon(
                                                onPressed: submitting
                                                    ? null
                                                    : () => _retryPending(key),
                                                icon: const Icon(Icons.sync),
                                                label: Text(
                                                  submitting
                                                      ? 'جارٍ المزامنة…'
                                                      : 'بانتظار المزامنة • إعادة المحاولة',
                                                ),
                                              )
                                            else
                                              FilledButton(
                                                onPressed:
                                                    completed || submitting
                                                        ? null
                                                        : () => _complete(key),
                                                child: Text(
                                                  completed
                                                      ? 'سُجلت قراءة اليوم'
                                                      : submitting
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
                        ),
                      ],
                    ),
    );
  }
}
