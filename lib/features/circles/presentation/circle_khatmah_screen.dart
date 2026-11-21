import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../mushaf/mushaf_page_screen.dart';
import '../domain/circles_providers.dart';

class CircleKhatmahScreen extends ConsumerStatefulWidget {
  final String circleUuid;
  final bool canCreate;

  const CircleKhatmahScreen({
    super.key,
    required this.circleUuid,
    required this.canCreate,
  });

  @override
  ConsumerState<CircleKhatmahScreen> createState() =>
      _CircleKhatmahScreenState();
}

class _CircleKhatmahScreenState extends ConsumerState<CircleKhatmahScreen> {
  List<Map<String, dynamic>> _khatmahs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKhatmahs();
  }

  Future<void> _loadKhatmahs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(circlesApiProvider)
          .fetchCircleKhatmahs(widget.circleUuid);
      if (mounted) {
        setState(
          () => _khatmahs = items.where((item) {
            final status = item['status']?.toString().toLowerCase();
            return status == null || status == 'active';
          }).toList(),
        );
      }
    } on CirclesApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر تحميل الختمات: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createKhatmah() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? deadlineAt;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('إنشاء ختمة جماعية'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    autofocus: true,
                    maxLength: 100,
                    decoration:
                        const InputDecoration(labelText: 'عنوان الختمة'),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'عنوان الختمة مطلوب'
                        : null,
                  ),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'وصف اختياري'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final firstDate =
                          DateTime(now.year, now.month, now.day + 1);
                      final selected = await showDatePicker(
                        context: dialogContext,
                        initialDate: deadlineAt ?? firstDate,
                        firstDate: firstDate,
                        lastDate: DateTime(now.year + 5),
                      );
                      if (selected != null) {
                        setDialogState(() => deadlineAt = selected);
                      }
                    },
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(
                      deadlineAt == null
                          ? 'موعد نهائي (اختياري)'
                          : 'الموعد: ${_formatDate(deadlineAt!)}',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: const Text('إنشاء'),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true && mounted) {
        await ref.read(circlesApiProvider).createCircleKhatmah(
              circleUuid: widget.circleUuid,
              title: titleController.text,
              description: descriptionController.text,
              deadlineAt: deadlineAt,
            );
        await _loadKhatmahs();
      }
    } on CirclesApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('تعذر إنشاء الختمة: $error');
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: ItqanColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: const Text(
          'الختمات النشطة',
          style: TextStyle(
            color: ItqanColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.canCreate)
            IconButton(
              tooltip: 'إنشاء ختمة',
              onPressed: _createKhatmah,
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ItqanColors.emerald),
            )
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadKhatmahs)
              : RefreshIndicator(
                  color: ItqanColors.emerald,
                  onRefresh: _loadKhatmahs,
                  child: _khatmahs.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(28),
                          children: [
                            const SizedBox(height: 100),
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 60,
                              color: ItqanColors.emerald,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد ختمات نشطة حالياً',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: ItqanColors.ink,
                              ),
                            ),
                            if (widget.canCreate) ...[
                              const SizedBox(height: 18),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _createKhatmah,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('إنشاء ختمة'),
                                ),
                              ),
                            ],
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _khatmahs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final khatmah = _khatmahs[index];
                            return _KhatmahCard(
                              khatmah: khatmah,
                              onTap: () async {
                                final uuid = khatmah['uuid']?.toString();
                                if (uuid == null || uuid.isEmpty) {
                                  _showError('الختمة لا تحتوي على معرف صالح');
                                  return;
                                }
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CircleKhatmahDetailsScreen(
                                      khatmahUuid: uuid,
                                    ),
                                  ),
                                );
                                if (mounted) await _loadKhatmahs();
                              },
                            );
                          },
                        ),
                ),
      floatingActionButton: widget.canCreate && _khatmahs.isNotEmpty
          ? FloatingActionButton(
              onPressed: _createKhatmah,
              backgroundColor: ItqanColors.emerald,
              foregroundColor: ItqanColors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class CircleKhatmahDetailsScreen extends ConsumerStatefulWidget {
  final String khatmahUuid;

  const CircleKhatmahDetailsScreen({super.key, required this.khatmahUuid});

  @override
  ConsumerState<CircleKhatmahDetailsScreen> createState() =>
      _CircleKhatmahDetailsScreenState();
}

class _CircleKhatmahDetailsScreenState
    extends ConsumerState<CircleKhatmahDetailsScreen> {
  Map<String, dynamic>? _khatmah;
  bool _isLoading = true;
  String? _error;
  String? _completingAssignment;

  @override
  void initState() {
    super.initState();
    _loadKhatmah();
  }

  Future<void> _loadKhatmah() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(circlesApiProvider).fetchKhatmah(widget.khatmahUuid);
      if (mounted) setState(() => _khatmah = result);
    } on CirclesApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر تحميل التفاصيل: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeAssignment(
      int partNumber, String assignmentUuid) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MushafPageScreen(startPage: _juzStartPage(partNumber)),
      ),
    );
    if (!mounted) return;

    final completedReading = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('إكمال الجزء $partNumber'),
        content: const Text('هل أتممت قراءة هذا الجزء؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ليس بعد'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تحديد الجزء كمكتمل'),
          ),
        ],
      ),
    );
    if (completedReading != true) return;
    if (assignmentUuid.isEmpty) {
      _showError('تعذر إكمال الجزء: لم يرد معرّف الإسناد من الخادم');
      return;
    }

    setState(() => _completingAssignment = assignmentUuid);
    try {
      await ref
          .read(circlesApiProvider)
          .completeKhatmahAssignment(assignmentUuid);
      await _loadKhatmah();
    } on CirclesApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('تعذر تسجيل إكمال الجزء: $error');
    } finally {
      if (mounted) setState(() => _completingAssignment = null);
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
    final assignments = _khatmah?['assignments'] is List
        ? (_khatmah!['assignments'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];
    const total = 30;
    final completed = _asInt(_khatmah?['completed_parts']) ??
        assignments.where((item) => item['status'] == 'completed').length;
    final assignmentsByPart = <int, Map<String, dynamic>>{};
    for (final assignment in assignments) {
      final partNumber = _asInt(assignment['part_number']);
      if (partNumber != null && partNumber >= 1 && partNumber <= total) {
        assignmentsByPart[partNumber] = assignment;
      }
    }
    final currentUserId = ref.watch(currentUserIdProvider).valueOrNull;
    final myParts = currentUserId == null
        ? <int>[]
        : assignments
            .where(
              (assignment) =>
                  _asInt(assignment['assigned_to'] ?? assignment['user_id']) ==
                  currentUserId,
            )
            .map((assignment) => _asInt(assignment['part_number']))
            .whereType<int>()
            .toList()
      ..sort();
    final assignmentRange = _assignmentRange(myParts);

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: const Text('تفاصيل الختمة'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ItqanColors.emerald),
            )
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadKhatmah)
              : RefreshIndicator(
                  color: ItqanColors.emerald,
                  onRefresh: _loadKhatmah,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18),
                    children: [
                      Text(
                        _khatmah?['title']?.toString() ?? 'ختمة جماعية',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: ItqanColors.ink,
                        ),
                      ),
                      if ((_khatmah?['description']?.toString() ?? '')
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _khatmah!['description'].toString(),
                          style: const TextStyle(color: ItqanColors.inkSoft),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _ProgressCard(
                        completed: completed,
                        total: total,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ItqanColors.emerald.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_pin_circle_rounded,
                              color: ItqanColors.emerald,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                assignmentRange == null
                                    ? 'لا توجد أجزاء مسندة إليك'
                                    : assignmentRange.contains('،')
                                        ? 'الأجزاء المسندة إليك: $assignmentRange'
                                        : 'أنت مسؤول عن الأجزاء $assignmentRange',
                                style: const TextStyle(
                                  color: ItqanColors.emeraldDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'الأجزاء المسندة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ItqanColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: total,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.94,
                        ),
                        itemBuilder: (context, index) {
                          final partNumber = index + 1;
                          final assignment = assignmentsByPart[partNumber];
                          final isComplete =
                              assignment?['status']?.toString().toLowerCase() ==
                                  'completed';
                          final assignmentUuid =
                              assignment?['uuid']?.toString() ?? '';
                          final assignedUserId = _asInt(
                            assignment?['assigned_to'] ??
                                assignment?['user_id'],
                          );
                          final isMine = currentUserId != null &&
                              assignedUserId == currentUserId;
                          final canRead = !isComplete &&
                              isMine &&
                              _khatmah?['status']?.toString() != 'completed';
                          final isBusy =
                              _completingAssignment == assignmentUuid &&
                                  assignmentUuid.isNotEmpty;
                          final userName =
                              assignment?['user_name']?.toString() ??
                                  'غير مسند';
                          return Card(
                            margin: EdgeInsets.zero,
                            color: isComplete
                                ? const Color(0xFF16835B)
                                : isMine
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFECEFF1),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: canRead && !isBusy
                                  ? () => _completeAssignment(
                                        partNumber,
                                        assignmentUuid,
                                      )
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'الجزء $partNumber',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isComplete
                                            ? Colors.white
                                            : ItqanColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isComplete
                                            ? Colors.white70
                                            : ItqanColors.inkSoft,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (isBusy)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      Icon(
                                        isComplete
                                            ? Icons.check_circle_rounded
                                            : canRead
                                                ? Icons.touch_app_rounded
                                                : Icons.schedule_rounded,
                                        size: 18,
                                        color: isComplete
                                            ? Colors.white
                                            : isMine
                                                ? ItqanColors.emerald
                                                : ItqanColors.inkSoft,
                                      ),
                                    Text(
                                      isComplete
                                          ? 'مكتمل'
                                          : canRead
                                              ? 'افتح المصحف'
                                              : 'قيد القراءة',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isComplete
                                            ? Colors.white
                                            : ItqanColors.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}

int _juzStartPage(int juzNumber) {
  const startPages = [
    1,
    22,
    42,
    62,
    82,
    102,
    121,
    142,
    162,
    182,
    201,
    222,
    242,
    262,
    282,
    302,
    322,
    342,
    362,
    382,
    402,
    422,
    442,
    462,
    482,
    502,
    522,
    542,
    562,
    582,
  ];
  return startPages[juzNumber.clamp(1, 30) - 1];
}

String? _assignmentRange(List<int> partNumbers) {
  if (partNumbers.isEmpty) return null;
  final uniqueParts = partNumbers.toSet().toList()..sort();
  final contiguous =
      uniqueParts.last - uniqueParts.first + 1 == uniqueParts.length;
  if (contiguous) {
    return 'من ${uniqueParts.first} إلى ${uniqueParts.last}';
  }
  return uniqueParts.join('، ');
}

class _KhatmahCard extends StatelessWidget {
  final Map<String, dynamic> khatmah;
  final VoidCallback onTap;

  const _KhatmahCard({required this.khatmah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = _asInt(khatmah['total_parts']) ?? 30;
    final completed = _asInt(khatmah['completed_parts']) ?? 0;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    return Card(
      color: ItqanColors.surface,
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0x1A16835B),
          child: Icon(Icons.menu_book_rounded, color: ItqanColors.emerald),
        ),
        title: Text(
          khatmah['title']?.toString() ?? 'ختمة جماعية',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress,
                color: ItqanColors.emerald,
                backgroundColor: ItqanColors.border,
              ),
              const SizedBox(height: 5),
              Text('$completed / $total جزءًا'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int completed;
  final int total;

  const _ProgressCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ItqanColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'تقدم الختمة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text('$completed / $total'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: ItqanColors.emerald,
              backgroundColor: ItqanColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: ItqanColors.error, size: 42),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
