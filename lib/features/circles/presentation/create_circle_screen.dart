import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../domain/circles_providers.dart';

class CreateCircleScreen extends ConsumerStatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  ConsumerState<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends ConsumerState<CreateCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  CircleType? _selectedType;
  String _privacyMode = 'private'; // 'private' or 'public'
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      setState(() => _errorMessage = 'يرجى اختيار نوع الدائرة');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(circlesApiProvider);
      final newCircle = await api.createCircle(
        name: _nameController.text.trim(),
        type: _selectedType!,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        privacyMode: _privacyMode,
      );

      if (mounted) {
        ref.read(myCirclesProvider.notifier).addCircle(newCircle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إنشاء الدائرة بنجاح'),
            backgroundColor: ItqanColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on CirclesApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: ItqanColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ، حاول مرة أخرى';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(circleTypesProvider);

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ItqanColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ItqanColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: ItqanColors.ink, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إنشاء دائرة جديدة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ItqanColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Intro card ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      ItqanColors.emerald.withValues(alpha: 0.10),
                      ItqanColors.emerald.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: ItqanColors.emerald.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ItqanColors.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.diversity_1_rounded,
                          color: ItqanColors.emerald, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'أنشئ دائرة تجمعك بمن تحب في مساحة طاعة وتنافس حميد على فعل الخير.',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: ItqanColors.emeraldDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Error banner ─────────────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ItqanColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: ItqanColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: ItqanColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: ItqanColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── 1. Circle Name ────────────────────────────────────────────
              _SectionLabel(label: 'اسم الدائرة *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'مثال: عائلة الهدى، حلقة الفجر، أصدقاء القرآن',
                  prefixIcon: const Icon(Icons.title_rounded,
                      color: ItqanColors.emerald, size: 20),
                  filled: true,
                  fillColor: ItqanColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: ItqanColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: ItqanColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: ItqanColors.emerald, width: 1.5),
                  ),
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'اسم الدائرة مطلوب';
                  }
                  if (text.length < 3) {
                    return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                  }
                  if (text.length > 100) {
                    return 'الاسم يجب ألا يتجاوز 100 حرف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── 2. Circle Type ────────────────────────────────────────────
              _SectionLabel(label: 'نوع الدائرة *'),
              const SizedBox(height: 8),
              typesAsync.when(
                loading: () => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: ItqanColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ItqanColors.border),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ItqanColors.emerald,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'جاري جلب أنواع الدوائر المعتمدة...',
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: ItqanColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                error: (err, _) => Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'تعذر تحميل أنواع الدوائر',
                        style: TextStyle(color: ItqanColors.error),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(circleTypesProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
                data: (types) {
                  return DropdownButtonFormField<CircleType>(
                    initialValue: _selectedType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'اختر نوع الدائرة',
                      filled: true,
                      fillColor: ItqanColors.surface,
                      prefixIcon: const Icon(Icons.category_rounded,
                          color: ItqanColors.emerald, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: ItqanColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: ItqanColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: ItqanColors.emerald, width: 1.5),
                      ),
                    ),
                    items: types.map((type) {
                      return DropdownMenuItem<CircleType>(
                        value: type,
                        child: Text(
                          type.name,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: ItqanColors.ink,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (selected) {
                      setState(() {
                        _selectedType = selected;
                      });
                    },
                    validator: (val) =>
                        val == null ? 'يرجى اختيار نوع الدائرة' : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // ── 3. Description ────────────────────────────────────────────
              _SectionLabel(label: 'الوصف (اختياري)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'أضف وصفاً مختصراً لأهداف الدائرة وأنشطتها...',
                  filled: true,
                  fillColor: ItqanColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: ItqanColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: ItqanColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: ItqanColors.emerald, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 4. Privacy Mode ───────────────────────────────────────────
              _SectionLabel(label: 'الخصوصية *'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildPrivacyOption(
                      title: 'خاصة',
                      subtitle: 'بالدعوة فقط',
                      icon: Icons.lock_outline_rounded,
                      value: 'private',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPrivacyOption(
                      title: 'عامة',
                      subtitle: 'متاحة للجميع',
                      icon: Icons.public_rounded,
                      value: 'public',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── Submit button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ItqanColors.emerald, ItqanColors.emeraldDark],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: ItqanColors.emerald.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: ItqanColors.white,
                            ),
                          )
                        : const Text(
                            'إنشاء الدائرة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ItqanColors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _privacyMode == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _privacyMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? ItqanColors.emerald.withValues(alpha: 0.08)
                : ItqanColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? ItqanColors.emerald.withValues(alpha: 0.5)
                  : ItqanColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ItqanColors.emerald.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ItqanColors.emerald.withValues(alpha: 0.15)
                      : ItqanColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? ItqanColors.emerald : ItqanColors.inkSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? ItqanColors.emerald : ItqanColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: ItqanColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: ItqanColors.emerald, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: ItqanColors.ink,
        ),
      );
}
