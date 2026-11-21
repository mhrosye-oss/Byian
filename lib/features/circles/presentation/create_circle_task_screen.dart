import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../domain/circles_providers.dart';

class CreateCircleTaskScreen extends ConsumerStatefulWidget {
  final String circleUuid;
  final List<CircleMember> members;

  const CreateCircleTaskScreen({
    super.key,
    required this.circleUuid,
    required this.members,
  });

  @override
  ConsumerState<CreateCircleTaskScreen> createState() =>
      _CreateCircleTaskScreenState();
}

class _CreateCircleTaskScreenState
    extends ConsumerState<CreateCircleTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitController = TextEditingController(text: 'times');
  final _quranStartPageController = TextEditingController(text: '1');
  final _quranEndPageController = TextEditingController(text: '1');

  String _taskType = 'custom';
  String _priority = 'normal';
  final Set<int> _assignedUserIds = {};
  DateTime? _dueAt;
  bool _isSecret = false;
  bool _isSaving = false;

  List<CircleMember> get _assignableMembers =>
      widget.members.where((member) => member.userId != null).toList();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    _quranStartPageController.dispose();
    _quranEndPageController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null && mounted) {
      setState(() => _dueAt = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final hasCounter = _taskType == 'tasbih' || _taskType == 'counter';
      final isQuran = _taskType == 'quran';
      final quranStart =
          isQuran ? int.tryParse(_quranStartPageController.text.trim()) : null;
      final quranEnd =
          isQuran ? int.tryParse(_quranEndPageController.text.trim()) : null;
      final target = hasCounter
          ? int.tryParse(_targetController.text.trim())
          : isQuran && quranStart != null && quranEnd != null
              ? quranEnd - quranStart + 1
              : null;
      final notes = _descriptionController.text.trim();
      final description = isQuran && quranStart != null && quranEnd != null
          ? [
              'نطاق قراءة المصحف: الصفحات $quranStart إلى $quranEnd',
              if (notes.isNotEmpty) notes,
            ].join('\n')
          : notes;
      await ref.read(circlesApiProvider).createTask(
            circleUuid: widget.circleUuid,
            title: _titleController.text.trim(),
            description: description,
            taskType: _taskType,
            priority: _priority,
            assignedTo: _assignedUserIds.toList(),
            targetValue: target,
            targetUnit: hasCounter
                ? _unitController.text.trim()
                : isQuran
                    ? 'pages'
                    : null,
            dueAt: _dueAt,
            isSecret: _isSecret,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on CirclesApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('تعذر إنشاء المهمة: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ItqanColors.error,
        behavior: SnackBarBehavior.floating,
      ),
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
          'إنشاء مهمة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ItqanColors.ink,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _sectionLabel('تفاصيل المهمة'),
            TextFormField(
              controller: _titleController,
              maxLength: 150,
              decoration: _decoration('عنوان المهمة', Icons.title_rounded),
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? 'عنوان المهمة مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _decoration('وصف اختياري', Icons.notes_rounded),
            ),
            const SizedBox(height: 18),
            _sectionLabel('النوع والأولوية'),
            DropdownButtonFormField<String>(
              initialValue: _taskType,
              decoration: _decoration('نوع المهمة', Icons.category_outlined),
              items: const [
                DropdownMenuItem(value: 'quran', child: Text('قرآن')),
                DropdownMenuItem(value: 'adhkar', child: Text('أذكار')),
                DropdownMenuItem(value: 'dua', child: Text('دعاء')),
                DropdownMenuItem(value: 'tasbih', child: Text('تسبيح')),
                DropdownMenuItem(value: 'counter', child: Text('عدّاد')),
                DropdownMenuItem(value: 'custom', child: Text('مخصص')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _taskType = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: _decoration('الأولوية', Icons.flag_outlined),
              items: const [
                DropdownMenuItem(value: 'high', child: Text('عالية')),
                DropdownMenuItem(value: 'normal', child: Text('عادية')),
                DropdownMenuItem(value: 'low', child: Text('منخفضة')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            if (_taskType == 'tasbih' || _taskType == 'counter') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration:
                    _decoration('العدد المستهدف', Icons.numbers_rounded),
                validator: (value) {
                  if (_taskType != 'tasbih' && _taskType != 'counter') {
                    return null;
                  }
                  final target = int.tryParse(value?.trim() ?? '');
                  return target == null || target < 1
                      ? 'أدخل عددًا صحيحًا أكبر من صفر'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _unitController.text,
                decoration: _decoration('وحدة العد', Icons.edit_outlined),
                items: const [
                  DropdownMenuItem(value: 'times', child: Text('مرات')),
                  DropdownMenuItem(value: 'pages', child: Text('صفحات')),
                  DropdownMenuItem(value: 'minutes', child: Text('دقائق')),
                ],
                onChanged: (value) {
                  if (value != null) _unitController.text = value;
                },
              ),
            ],
            if (_taskType == 'quran') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quranStartPageController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(
                        'من صفحة',
                        Icons.first_page_rounded,
                      ),
                      validator: (value) {
                        if (_taskType != 'quran') return null;
                        final page = int.tryParse(value?.trim() ?? '');
                        return page == null || page < 1 || page > 604
                            ? 'أدخل صفحة من 1 إلى 604'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _quranEndPageController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(
                        'إلى صفحة',
                        Icons.last_page_rounded,
                      ),
                      validator: (value) {
                        if (_taskType != 'quran') return null;
                        final start = int.tryParse(
                          _quranStartPageController.text.trim(),
                        );
                        final end = int.tryParse(value?.trim() ?? '');
                        return end == null || end < (start ?? 1) || end > 604
                            ? 'النهاية بعد البداية وحتى 604'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'سيتم فتح المصحف على هذا النطاق فقط عند أداء المهمة.',
                style: TextStyle(fontSize: 12, color: ItqanColors.inkSoft),
              ),
            ],
            const SizedBox(height: 18),
            _sectionLabel('التكليف'),
            if (_assignableMembers.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _assignableMembers.map((member) {
                  final userId = member.userId!;
                  final selected = _assignedUserIds.contains(userId);
                  return FilterChip(
                    label: Text(member.displayName),
                    selected: selected,
                    onSelected: _isSaving
                        ? null
                        : (value) => setState(() {
                              if (value) {
                                _assignedUserIds.add(userId);
                              } else {
                                _assignedUserIds.remove(userId);
                              }
                            }),
                    selectedColor: ItqanColors.emerald.withValues(alpha: 0.15),
                  );
                }).toList(),
              ),
            if (_assignableMembers.isEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                'لا تتوفر معرفات الأعضاء لإسناد المهمة؛ يمكنك إنشاؤها بدون تكليف محدد.',
                style: TextStyle(fontSize: 12, color: ItqanColors.inkSoft),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('مهمة خفية'),
              subtitle:
                  const Text('إخفاء هوية من أنجز المهمة عند دعم ذلك من الخادم'),
              value: _isSecret,
              activeThumbColor: ItqanColors.emerald,
              onChanged: (value) => setState(() => _isSecret = value),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectDueDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                _dueAt == null
                    ? 'تحديد موعد استحقاق (اختياري)'
                    : 'الاستحقاق: ${_formatDate(_dueAt!)}',
              ),
            ),
            if (_dueAt != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => setState(() => _dueAt = null),
                  child: const Text('إزالة الموعد'),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ItqanColors.white,
                        ),
                      )
                    : const Icon(Icons.add_task_rounded),
                label: Text(_isSaving ? 'جارٍ الإنشاء...' : 'إنشاء المهمة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ItqanColors.emerald,
                  foregroundColor: ItqanColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: ItqanColors.ink,
          ),
        ),
      );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: ItqanColors.emerald),
        filled: true,
        fillColor: ItqanColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ItqanColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ItqanColors.border),
        ),
      );

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
