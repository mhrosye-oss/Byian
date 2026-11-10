import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/circle_list_provider.dart';

class JoinCircleScreen extends ConsumerStatefulWidget {
  const JoinCircleScreen({super.key});

  @override
  ConsumerState<JoinCircleScreen> createState() => _JoinCircleScreenState();
}

class _JoinCircleScreenState extends ConsumerState<JoinCircleScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('أدخل كود الدعوة أولًا.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(circleApiServiceProvider);
      final preview = await api.previewInvitation(code);
      if (!mounted) return;
      final type = preview['circle_type'];
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تأكيد الانضمام'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الدائرة: ${preview['circle_name'] ?? '—'}'),
              const SizedBox(height: 8),
              Text(
                'النوع: ${type is Map ? type['name'] ?? type['key'] : type ?? '—'}',
              ),
              const SizedBox(height: 8),
              Text('الداعي: ${preview['invited_by'] ?? '—'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('انضمام'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await api.redeemInvitation(code);
      ref.invalidate(myCirclesProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل الانضمام: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الانضمام إلى دائرة')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.group_add_outlined, size: 64),
            const SizedBox(height: 12),
            const Text(
              'أدخل كود الدعوة الذي وصلك، ثم راجع التفاصيل قبل الانضمام.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _busy ? null : _join(),
              decoration: InputDecoration(
                labelText: 'كود الدعوة',
                hintText: 'ITQ-XXXX-XXXX',
                prefixIcon: const Icon(Icons.key_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _join,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Text('معاينة والانضمام'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      );
}
