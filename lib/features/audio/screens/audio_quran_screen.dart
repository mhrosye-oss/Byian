import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:itqan/core/theme/colors.dart';

class AudioQuranScreen extends StatefulWidget {
  const AudioQuranScreen({super.key});
  @override
  State<AudioQuranScreen> createState() => _AudioQuranScreenState();
}

class _AudioQuranScreenState extends State<AudioQuranScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  String? _error;
  static const _stream = 'https://Qurango.net/radio/tarateel';

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    try {
      if (_playing) {
        await _player.pause();
      } else {
        await _player.setUrl(_stream);
        await _player.play();
      }
      if (mounted) setState(() { _playing = !_playing; _error = null; });
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تشغيل البث. تحقق من اتصال الإنترنت.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(title: const Text('القرآن الصوتي')),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(22),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.headphones_rounded, size: 72, color: Color(0xFF1B5E20)),
                const SizedBox(height: 20),
                const Text('تلاوة القرآن الكريم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('استماع مباشر', style: TextStyle(color: ItqanColors.inkSoft)),
                const SizedBox(height: 22),
                FilledButton.icon(onPressed: _toggle,
                    icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(_playing ? 'إيقاف مؤقت' : 'تشغيل')),
                if (_error != null) ...[const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))],
              ]),
            ),
          ),
        ),
      );
}
