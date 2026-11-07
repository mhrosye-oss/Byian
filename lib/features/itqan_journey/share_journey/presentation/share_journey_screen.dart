import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareJourneyScreen extends StatefulWidget {
  const ShareJourneyScreen({super.key});

  @override
  State<ShareJourneyScreen> createState() => _ShareJourneyScreenState();
}

class _ShareJourneyScreenState extends State<ShareJourneyScreen> {
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<String?> _validatedText() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل محتوى المشاركة أولاً')),
      );
      return null;
    }
    return text;
  }

  Future<void> _copy() async {
    final text = await _validatedText();
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم نسخ النص. لا يُحتسب النسخ مشاركة مؤكدة.')),
      );
    }
  }

  Future<void> _shareByEmail() async {
    final text = await _validatedText();
    if (text == null) return;
    setState(() => _sending = true);
    try {
      final uri = Uri(scheme: 'mailto', queryParameters: {'body': text});
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('تعذر فتح تطبيق البريد');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'فُتح تطبيق البريد؛ لا يمكن تأكيد الإرسال، لذلك لم يُسجّل إنجاز.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذرت المشاركة: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مشاركة الخير')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('اكتب فائدة أو ذكراً أو دعاءً موثوقاً لمشاركته.'),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            minLines: 4,
            maxLines: 8,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'أدخل المحتوى الذي تريد مشاركته',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _shareByEmail,
            icon: const Icon(Icons.email_outlined),
            label:
                Text(_sending ? 'جارٍ فتح تطبيق البريد' : 'مشاركة عبر البريد'),
          ),
          OutlinedButton.icon(
            onPressed: _sending ? null : _copy,
            icon: const Icon(Icons.copy_outlined),
            label: const Text('نسخ النص'),
          ),
          const SizedBox(height: 8),
          Text(
            'فتح تطبيق خارجي أو نسخ النص لا يؤكد إرساله؛ لن تُمنح نقاط من هذه الواجهة.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
