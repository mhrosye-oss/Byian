import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/circle_list_provider.dart';
import '../../domain/circle_models.dart';

class CreateCircleScreen extends ConsumerStatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  ConsumerState<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends ConsumerState<CreateCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<CircleType> _types = const [];
  int? _selectedTypeId;
  bool _loadingTypes = true;
  bool _isSubmitting = false;
  String? _typeError;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await ref.read(circleApiServiceProvider).getTypes();
      if (!mounted) return;
      setState(() {
        _types = types.map(CircleType.fromJson).toList(growable: false);
        _loadingTypes = false;
        _typeError = _types.isEmpty ? 'لا تتوفر أنواع للدوائر حاليًا.' : null;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _loadingTypes = false;
          _typeError = '$error';
        });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedTypeId == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(circleApiServiceProvider).createCircle(
            typeId: _selectedTypeId!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          );
      ref.invalidate(myCirclesProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر إنشاء الدائرة: $error')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  IconData _iconForType(String key) => switch (key) {
        'family' => Icons.home_rounded,
        'classroom' => Icons.school_rounded,
        'study_circle' => Icons.menu_book_rounded,
        'goodness' => Icons.volunteer_activism_rounded,
        'companions' => Icons.groups_rounded,
        _ => Icons.group_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء دائرة')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('ابدأ دائرة تجمع من تحب على الخير والتعلّم.',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              if (_loadingTypes)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator()))
              else if (_typeError != null)
                Card(
                    child: ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: Text(_typeError!),
                        trailing: IconButton(
                            onPressed: _loadTypes,
                            icon: const Icon(Icons.refresh))))
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedTypeId,
                  decoration: InputDecoration(
                    labelText: 'نوع الدائرة',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _types
                      .map((type) => DropdownMenuItem<int>(
                            value: type.id,
                            child: Row(children: [
                              Icon(_iconForType(type.key),
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 12),
                              Flexible(
                                  child: Text(type.name,
                                      overflow: TextOverflow.ellipsis)),
                            ]),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedTypeId = value),
                  validator: (value) =>
                      value == null ? 'يرجى اختيار نوع الدائرة' : null,
                  isExpanded: true,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                    labelText: 'اسم الدائرة',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'يرجى كتابة اسم الدائرة'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: 'وصف مختصر (اختياري)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: !_isSubmitting &&
                          _selectedTypeId != null &&
                          _nameController.text.trim().isNotEmpty
                      ? _submit
                      : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.rocket_launch_rounded),
                  label: const Text('إنشاء الدائرة والانطلاق'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
