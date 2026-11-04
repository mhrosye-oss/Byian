import 'package:flutter/material.dart';
import 'package:itqan/core/theme/colors.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final List<({String text, bool user})> _messages = [
    (text: 'مرحبًا بك! يمكنني مساعدتك في أسئلتك العامة حول القرآن والعبادات. هذه نسخة تجريبية.', user: false),
  ];

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add((text: text, user: true));
      _controller.clear();
    });
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _messages.add((text: 'شكرًا على سؤالك. هذه إجابة تجريبية، وسيتم ربط المساعد بمصدر المعرفة لاحقًا.', user: false)));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(title: const Text('اسأل الذكاء الاصطناعي')),
        body: Column(children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.user ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 310),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.user ? const Color(0xFF1B5E20) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: Text(message.text, textDirection: TextDirection.rtl,
                        style: TextStyle(color: message.user ? Colors.white : ItqanColors.ink, height: 1.5)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(children: [
                Expanded(child: TextField(controller: _controller, textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(hintText: 'اكتب سؤالك…', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _send, icon: const Icon(Icons.send_rounded), tooltip: 'إرسال'),
              ]),
            ),
          ),
        ]),
      );
}
