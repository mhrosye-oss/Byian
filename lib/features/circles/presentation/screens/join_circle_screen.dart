import 'package:flutter/material.dart';

import '../../data/circle_api_client.dart';
import '../../data/circle_api_config.dart';

class JoinCircleScreen extends StatefulWidget {
  const JoinCircleScreen({super.key});

  @override
  State<JoinCircleScreen> createState() => _JoinCircleScreenState();
}

class _JoinCircleScreenState extends State<JoinCircleScreen> {
  final _code = TextEditingController();
  final CircleApiClient _api = CircleApiClient.instance;
  bool _busy = false;
  Map<String, dynamic>? _preview;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _previewInvite() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      _show('أدخل كود الدعوة أولًا.');
      return;
    }
    setState(() {
      _busy = true;
      _preview = null;
    });
    try {
      final result = await _api.previewInvitation(code);
      if (mounted) setState(() => _preview = result);
    } on CircleApiException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('تعذر التحقق من كود الدعوة.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (code.isEmpty || _preview == null) return;
    setState(() => _busy = true);
    try {
      await _api.redeemInvitation(code);
      if (mounted) Navigator.pop(context, true);
    } on CircleApiException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('تعذر الانضمام إلى الدائرة.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الانضمام إلى دائرة')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.group_add_outlined, size: 64),
            const SizedBox(height: 12),
            const Text(
              'أدخل كود الدعوة، ثم راجع تفاصيل الدائرة قبل الانضمام.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _preview = null),
              decoration: const InputDecoration(
                labelText: 'كود الدعوة',
                prefixIcon: Icon(Icons.key_rounded),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _busy ? null : _previewInvite,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              label: const Text('معاينة الدعوة'),
            ),
            if (_preview != null) ...[
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_preview!['circle_name'] ?? 'الدائرة'}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 6),
                      if (_preview!['circle_type'] != null)
                        Text('النوع: ${_typeName(_preview!['circle_type'])}'),
                      if (_preview!['invited_by'] != null)
                        Text('الداعي: ${_preview!['invited_by']}'),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _join,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('تأكيد الانضمام'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  String _typeName(dynamic type) =>
      type is Map ? '${type['name'] ?? type['key'] ?? ''}' : type.toString();
}
