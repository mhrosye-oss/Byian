import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../data/circle_api_client.dart';
import '../../data/circle_api_config.dart';
import '../../domain/circle_models.dart';

class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  List<CircleType> _types = const [];
  int? _typeId;
  bool _loadingTypes = true;
  bool _submitting = false;
  String? _loadError;
  final CircleApiClient _api = CircleApiClient.instance;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    setState(() {
      _loadingTypes = true;
      _loadError = null;
    });
    try {
      final types = await _api.getCircleTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        _loadingTypes = false;
        if (_typeId == null && types.isNotEmpty) _typeId = types.first.id;
        if (types.isEmpty) _loadError = 'لا تتوفر أنواع دوائر حاليًا.';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadingTypes = false;
          _loadError = 'تعذر تحميل أنواع الدوائر: $error';
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _typeId == null) return;
    setState(() => _submitting = true);
    try {
      await _api.createCircle({
        'type_id': _typeId,
        'name': _name.text.trim(),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on CircleApiException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('تعذر إنشاء الدائرة. حاول مجددًا.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('إنشاء دائرة')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('ابدأ مساحة تجمع من تحب على الخير والتعلّم.'),
                const SizedBox(height: 20),
                if (_loadingTypes)
                  const Center(child: CircularProgressIndicator())
                else if (_loadError != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(_loadError!),
                      trailing: IconButton(
                        onPressed: _loadTypes,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _typeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'نوع الدائرة',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _types
                        .map(
                          (type) => DropdownMenuItem<int>(
                            value: type.id,
                            child: Text(type.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _typeId = value),
                    validator: (value) =>
                        value == null ? 'اختر نوع الدائرة' : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'اسم الدائرة',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اكتب اسم الدائرة'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'وصف مختصر (اختياري)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submitting || _loadingTypes || _types.isEmpty
                      ? null
                      : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(_submitting ? 'جارٍ الإنشاء…' : 'إنشاء الدائرة'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ItqanColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
