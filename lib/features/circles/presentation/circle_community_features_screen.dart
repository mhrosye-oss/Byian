import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../application/circle_context_provider.dart';
import '../domain/circles_providers.dart';
import 'circle_lessons_screen.dart';

class CircleCommunityFeaturesScreen extends StatelessWidget {
  final String circleUuid;
  final bool canManage;

  const CircleCommunityFeaturesScreen({
    super.key,
    required this.circleUuid,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(
          backgroundColor: ItqanColors.cream,
          elevation: 0,
          title: const Text(
            'أنشطة الدائرة',
            style: TextStyle(
              color: ItqanColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: ItqanColors.emerald,
            unselectedLabelColor: ItqanColors.inkSoft,
            indicatorColor: ItqanColors.emerald,
            tabs: [
              Tab(icon: Icon(Icons.volunteer_activism), text: 'الدعاء'),
              Tab(icon: Icon(Icons.quiz_outlined), text: 'سؤال اليوم'),
              Tab(icon: Icon(Icons.menu_book_outlined), text: 'الدراسة'),
              Tab(icon: Icon(Icons.bolt_outlined), text: 'النشاط'),
              Tab(icon: Icon(Icons.ondemand_video_outlined), text: 'الدروس'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DuaRequestsTab(
              circleUuid: circleUuid,
            ),
            _DailyQuestionTab(
              circleUuid: circleUuid,
              canManage: canManage,
            ),
            _StudySessionsTab(
              circleUuid: circleUuid,
              canManage: canManage,
            ),
            _CircleActivitiesTab(circleUuid: circleUuid),
            CircleLessonsScreen(
              circleUuid: circleUuid,
              canManage: canManage,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleActivitiesTab extends ConsumerStatefulWidget {
  const _CircleActivitiesTab({required this.circleUuid});

  final String circleUuid;

  @override
  ConsumerState<_CircleActivitiesTab> createState() =>
      _CircleActivitiesTabState();
}

class _CircleActivitiesTabState extends ConsumerState<_CircleActivitiesTab> {
  static const _filters = <String, String>{
    'all': 'الكل',
    'dua': 'الدعاء',
    'question': 'السؤال',
    'study': 'الدراسة',
    'task': 'المهام',
    'whisper': 'الهمسات',
    'member': 'الأعضاء',
    'khatmah': 'الختمات',
    'invitation': 'الدعوات',
  };

  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() => ref
      .read(circleActivitiesProvider.notifier)
      .loadActivities(widget.circleUuid);

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(circleActivitiesProvider);
    return activitiesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: ItqanColors.emerald),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعذر تحميل النشاطات: $error', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      ),
      data: (activities) {
        final filtered = _selectedFilter == 'all'
            ? activities
            : activities
                .where((activity) => activity.tabType == _selectedFilter)
                .toList();
        return RefreshIndicator(
          color: ItqanColors.emerald,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: _selectedFilter == entry.key,
                            onSelected: (_) =>
                                setState(() => _selectedFilter = entry.key),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('لا توجد نشاطات في هذا التصنيف')),
                )
              else
                ...filtered.map(
                  (activity) => Card(
                    color: ItqanColors.surface,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x1A16835B),
                        child: Icon(Icons.bolt, color: ItqanColors.emerald),
                      ),
                      title: Text(
                        activity.title.isNotEmpty
                            ? activity.title
                            : activity.typeName,
                      ),
                      subtitle: Text([
                        if (activity.message?.trim().isNotEmpty == true)
                          activity.message!.trim(),
                        if (activity.userName?.trim().isNotEmpty == true)
                          activity.userName!.trim(),
                        if (activity.createdAt?.trim().isNotEmpty == true)
                          activity.createdAt!.trim(),
                      ].join(' • ')),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DuaRequestsTab extends ConsumerStatefulWidget {
  final String circleUuid;

  const _DuaRequestsTab({required this.circleUuid});

  @override
  ConsumerState<_DuaRequestsTab> createState() => _DuaRequestsTabState();
}

class _DuaRequestsTabState extends ConsumerState<_DuaRequestsTab> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  final Set<String> _working = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(circlesApiProvider)
          .fetchDuaRequests(widget.circleUuid);
      if (mounted) setState(() => _requests = result);
    } on CirclesApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر تحميل الطلبات: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final request = await showDialog<_DuaRequestDraft>(
      context: context,
      builder: (_) => const _DuaRequestDialog(),
    );
    if (request == null || !mounted) return;
    try {
      await ref.read(circlesApiProvider).createDuaRequest(
            circleUuid: widget.circleUuid,
            requestText: request.text,
            isAnonymous: request.isAnonymous,
          );
      if (mounted) await _load();
    } on CirclesApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('تعذر إرسال الطلب: $error');
    }
  }

  Future<void> _act(
    String uuid,
    Future<void> Function() action,
  ) async {
    if (!mounted || uuid.isEmpty || !_working.add(uuid)) return;
    setState(() {});
    try {
      await action();
      if (mounted) await _load();
    } on CirclesApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('تعذر تحديث الطلب: $error');
    } finally {
      _working.remove(uuid);
      if (mounted) setState(() {});
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: ItqanColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureListFrame(
      loading: _loading,
      error: _error,
      onRetry: _load,
      onRefresh: _load,
      emptyText: 'لا توجد طلبات دعاء في هذه الدائرة',
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        backgroundColor: ItqanColors.emerald,
        foregroundColor: ItqanColors.white,
        child: const Icon(Icons.add_rounded),
      ),
      children: _requests.map((request) {
        final uuid = request['uuid']?.toString() ?? '';
        final status = request['status']?.toString() ?? 'open';
        final isAnswered = status == 'answered';
        final alreadyPrayed = request['has_prayed'] == true ||
            request['has_prayed'] == 1 ||
            request['has_prayed'] == '1';
        final count = _intValue(request['prayer_count']) ?? 0;
        final ownerId = _intValue(request['created_by'] ?? request['user_id']);
        final currentUserId = ref.watch(currentUserIdProvider).valueOrNull;
        final canMarkAnswered =
            !isAnswered && currentUserId != null && ownerId == currentUserId;
        return Card(
          color: ItqanColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['request_text']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    color: ItqanColors.ink,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAnswered ? 'تمت الإجابة' : '$count دعاء',
                  style: const TextStyle(color: ItqanColors.inkSoft),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isAnswered && !alreadyPrayed)
                      TextButton.icon(
                        onPressed: _working.contains(uuid)
                            ? null
                            : () => _act(
                                  uuid,
                                  () => ref
                                      .read(circlesApiProvider)
                                      .prayForRequest(uuid),
                                ),
                        icon: const Icon(Icons.favorite_border_rounded),
                        label: const Text('آمين'),
                      ),
                    if (canMarkAnswered)
                      TextButton(
                        onPressed: _working.contains(uuid)
                            ? null
                            : () => _act(
                                  uuid,
                                  () => ref
                                      .read(circlesApiProvider)
                                      .markDuaAnswered(uuid),
                                ),
                        child: const Text('تمت الإجابة'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DuaRequestDraft {
  const _DuaRequestDraft({
    required this.text,
    required this.isAnonymous,
  });

  final String text;
  final bool isAnonymous;
}

class _DuaRequestDialog extends StatefulWidget {
  const _DuaRequestDialog();

  @override
  State<_DuaRequestDialog> createState() => _DuaRequestDialogState();
}

class _DuaRequestDialogState extends State<_DuaRequestDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnonymous = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(
      context,
      _DuaRequestDraft(text: text, isAnonymous: _isAnonymous),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('طلب دعاء'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLength: 500,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'اكتب طلب الدعاء',
              alignLabelWithHint: true,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('إخفاء اسمي'),
            value: _isAnonymous,
            onChanged: (value) => setState(() => _isAnonymous = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}

class _DailyQuestionTab extends ConsumerStatefulWidget {
  final String circleUuid;
  final bool canManage;

  const _DailyQuestionTab({
    required this.circleUuid,
    required this.canManage,
  });

  @override
  ConsumerState<_DailyQuestionTab> createState() => _DailyQuestionTabState();
}

class _DailyQuestionTabState extends ConsumerState<_DailyQuestionTab> {
  Map<String, dynamic>? _question;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _answer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final question = await ref
          .read(circlesApiProvider)
          .fetchTodayQuestion(widget.circleUuid);
      if (mounted) {
        final existingAnswer = question?['my_answer'] ?? question?['answer'];
        setState(() {
          _question = question;
          _answer = existingAnswer is Map
              ? Map<String, dynamic>.from(existingAnswer)
              : null;
        });
      }
    } on CirclesApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر تحميل سؤال اليوم: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _options {
    final raw = _question?['options'];
    if (raw is List) return raw.map((item) => item.toString()).toList();
    if (raw is String) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is List) {
          return parsed.map((item) => item.toString()).toList();
        }
      } on FormatException {
        return [];
      }
    }
    return [];
  }

  Future<void> _answerQuestion(int index) async {
    final uuid = _question?['uuid']?.toString() ?? '';
    if (!mounted || uuid.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(circlesApiProvider)
          .answerDailyQuestion(questionUuid: uuid, chosenIndex: index);
      if (mounted) setState(() => _answer = result);
    } on CirclesApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('تعذر إرسال الإجابة: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createQuestion() async {
    final questionController = TextEditingController();
    final optionControllers = List.generate(4, (_) => TextEditingController());
    final explanationController = TextEditingController();
    var correctIndex = 0;
    final valid = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إنشاء سؤال اليوم'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    maxLength: 500,
                    decoration: const InputDecoration(labelText: 'السؤال'),
                  ),
                  ...List.generate(
                    optionControllers.length,
                    (index) => TextField(
                      controller: optionControllers[index],
                      decoration: InputDecoration(
                        labelText: 'الخيار ${index + 1}',
                      ),
                    ),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: correctIndex,
                    decoration: const InputDecoration(
                      labelText: 'الإجابة الصحيحة',
                    ),
                    items: List.generate(
                      optionControllers.length,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text('الخيار ${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => correctIndex = value);
                      }
                    },
                  ),
                  TextField(
                    controller: explanationController,
                    decoration:
                        const InputDecoration(labelText: 'التوضيح (اختياري)'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'حدد الإجابة الصحيحة من القائمة.',
                    style: TextStyle(fontSize: 12, color: ItqanColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final options =
                    optionControllers.map((item) => item.text.trim()).toList();
                if (questionController.text.trim().isNotEmpty &&
                    options.every((item) => item.isNotEmpty)) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('نشر السؤال'),
            ),
          ],
        ),
      ),
    );
    if (valid == true && mounted) {
      try {
        await ref.read(circlesApiProvider).createDailyQuestion(
              circleUuid: widget.circleUuid,
              question: questionController.text,
              options:
                  optionControllers.map((item) => item.text.trim()).toList(),
              correctIndex: correctIndex,
              explanation: explanationController.text,
            );
        if (mounted) await _load();
      } on CirclesApiException catch (error) {
        _showError(error.message);
      } catch (error) {
        _showError('تعذر نشر السؤال: $error');
      }
    }
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
    explanationController.dispose();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: ItqanColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    return _FeatureListFrame(
      loading: _loading,
      error: _error,
      onRetry: _load,
      onRefresh: _load,
      emptyText: 'لم ينشر القائد سؤال اليوم بعد',
      floatingActionButton: widget.canManage
          ? FloatingActionButton(
              onPressed: _createQuestion,
              backgroundColor: ItqanColors.emerald,
              foregroundColor: ItqanColors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      children: _question == null
          ? const []
          : [
              Card(
                color: ItqanColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _question?['question']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: ItqanColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(options.length, (index) {
                        final selected = _answer?['chosen_index'] == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton(
                            onPressed: _answer != null || _submitting
                                ? null
                                : () => _answerQuestion(index),
                            style: OutlinedButton.styleFrom(
                              alignment: AlignmentDirectional.centerStart,
                              backgroundColor: selected
                                  ? ItqanColors.emerald.withValues(alpha: .08)
                                  : null,
                              padding: const EdgeInsets.all(14),
                            ),
                            child: Text(options[index]),
                          ),
                        );
                      }),
                      if (_submitting)
                        const Center(child: CircularProgressIndicator()),
                      if (_answer != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _answer?['is_correct'] == true ||
                                  _answer?['is_correct'] == 1 ||
                                  _answer?['is_correct'] == '1' ||
                                  _answer?['is_correct'] == 'true'
                              ? 'إجابة صحيحة، أحسنت!'
                              : 'تم تسجيل إجابتك',
                          style: const TextStyle(
                            color: ItqanColors.emerald,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if ((_question?['explanation']?.toString() ?? '')
                            .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_question!['explanation'].toString()),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
    );
  }
}

class _StudySessionsTab extends ConsumerStatefulWidget {
  final String circleUuid;
  final bool canManage;

  const _StudySessionsTab({
    required this.circleUuid,
    required this.canManage,
  });

  @override
  ConsumerState<_StudySessionsTab> createState() => _StudySessionsTabState();
}

class _StudySessionsTabState extends ConsumerState<_StudySessionsTab> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  final Set<String> _working = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await ref
          .read(circlesApiProvider)
          .fetchStudySessions(widget.circleUuid);
      if (mounted) setState(() => _sessions = sessions);
    } on CirclesApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر تحميل الجلسات: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSession() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController(text: '25');
    final valid = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء جلسة دراسة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
              ),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'وصف اختياري'),
              ),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المدة بالدقائق'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final duration = int.tryParse(durationController.text);
              if (titleController.text.trim().isNotEmpty &&
                  duration != null &&
                  duration > 0) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
    if (valid == true && mounted) {
      try {
        await ref.read(circlesApiProvider).createStudySession(
              circleUuid: widget.circleUuid,
              title: titleController.text,
              description: descriptionController.text,
              durationMinutes: int.parse(durationController.text),
            );
        if (mounted) await _load();
      } on CirclesApiException catch (error) {
        _showError(error.message);
      } catch (error) {
        _showError('تعذر إنشاء الجلسة: $error');
      }
    }
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
  }

  Future<void> _toggleParticipation(
    String uuid,
    bool joined,
  ) async {
    if (!mounted || uuid.isEmpty || !_working.add(uuid)) return;
    setState(() {});
    try {
      final api = ref.read(circlesApiProvider);
      if (joined) {
        await api.leaveStudySession(uuid);
      } else {
        await api.joinStudySession(uuid);
      }
      if (mounted) await _load();
    } on CirclesApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('تعذر تحديث المشاركة: $error');
    } finally {
      _working.remove(uuid);
      if (mounted) setState(() {});
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: ItqanColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider).valueOrNull;
    return _FeatureListFrame(
      loading: _loading,
      error: _error,
      onRetry: _load,
      onRefresh: _load,
      emptyText: 'لا توجد جلسات دراسة مجدولة',
      floatingActionButton: widget.canManage
          ? FloatingActionButton(
              onPressed: _createSession,
              backgroundColor: ItqanColors.emerald,
              foregroundColor: ItqanColors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      children: _sessions.map((session) {
        final uuid = session['uuid']?.toString() ?? '';
        final participants = session['participants'] is List
            ? session['participants'] as List
            : const [];
        final joined = participants.any((participant) {
          if (participant is! Map) return false;
          return _intValue(participant['user_id']) == currentUserId &&
              participant['left_at'] == null;
        });
        final status = session['status']?.toString() ?? 'scheduled';
        final isCompleted = status == 'completed';
        final duration = _intValue(session['duration_minutes']) ?? 25;
        return Card(
          color: ItqanColors.surface,
          child: ListTile(
            title: Text(
              session['title']?.toString() ?? 'جلسة دراسة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${session['description'] ?? 'جلسة تركيز جماعي'}\n$duration دقيقة · $status',
              ),
            ),
            isThreeLine: true,
            trailing: isCompleted
                ? const Text('مكتملة')
                : TextButton(
                    onPressed: _working.contains(uuid)
                        ? null
                        : () => _toggleParticipation(uuid, joined),
                    child: Text(joined ? 'مغادرة' : 'انضمام'),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class _FeatureListFrame extends StatelessWidget {
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefresh;
  final String emptyText;
  final List<Widget> children;
  final Widget? floatingActionButton;

  const _FeatureListFrame({
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onRefresh,
    required this.emptyText,
    required this.children,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final content = loading
        ? const Center(
            child: CircularProgressIndicator(color: ItqanColors.emerald),
          )
        : error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: onRetry,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: ItqanColors.emerald,
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: children.isEmpty
                      ? [
                          const SizedBox(height: 130),
                          Text(
                            emptyText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: ItqanColors.inkSoft),
                          ),
                        ]
                      : children,
                ),
              );

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      body: content,
      floatingActionButton: floatingActionButton,
    );
  }
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
