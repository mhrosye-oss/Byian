import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

const _primaryGreen = Color(0xFF1B5E20);
const _cream = Color(0xFFF9F6F0);
const _softText = Color(0xFF687268);

class AudioQuranScreen extends StatefulWidget {
  const AudioQuranScreen({super.key});

  @override
  State<AudioQuranScreen> createState() => _AudioQuranScreenState();
}

class _Reciter {
  const _Reciter({required this.name, required this.folder, required this.server, required this.size});

  final String name;
  final String folder;
  final int server;
  final String size;

  String get audioUrl => 'https://server$server.mp3quran.net/$folder/001.mp3';
}

class _AudioQuranScreenState extends State<AudioQuranScreen> {
  static const _reciters = <_Reciter>[
    _Reciter(name: 'مشاري العفاسي', folder: 'afs', server: 8, size: '50.9'),
    _Reciter(name: 'عبد الباسط عبد الصمد', folder: 'basit', server: 7, size: '46.2'),
    _Reciter(name: 'ماهر المعيقلي', folder: 'maher', server: 12, size: '42.8'),
    _Reciter(name: 'عبد الرحمن السديس', folder: 'sds', server: 11, size: '48.1'),
    _Reciter(name: 'سعود الشريم', folder: 'shur', server: 11, size: '44.6'),
    _Reciter(name: 'سعد الغامدي', folder: 's_gmd', server: 6, size: '39.7'),
    _Reciter(name: 'محمد صديق المنشاوي', folder: 'minsh', server: 10, size: '52.4'),
    _Reciter(name: 'محمود خليل الحصري', folder: 'husr', server: 13, size: '47.3'),
    _Reciter(name: 'ياسر الدوسري', folder: 'yasser', server: 11, size: '45.8'),
    _Reciter(name: 'أبو بكر الشاطري', folder: 'shatri', server: 11, size: '41.5'),
    _Reciter(name: 'أحمد العجمي', folder: 'ajm', server: 6, size: '43.9'),
    _Reciter(name: 'فارس عباد', folder: 'faisal', server: 6, size: '40.6'),
    _Reciter(name: 'إدريس أبكر', folder: 'abkr', server: ಿಗಳಿಗೆ, size: '42.1'),
    _Reciter(name: 'ناصر القطامي', folder: 'qatami', server: 8, size: '44.2'),
    _Reciter(name: 'محمد أيوب', folder: 'ayyub', server: 11, size: '46.7'),
  ];

  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _currentReciter;
  bool _isPlaying = false;
  bool _isLoading = false;

  List<_Reciter> get _filteredReciters => _reciters
      .where((reciter) => reciter.name.contains(_query.trim()))
      .toList(growable: false);

  @override
  void dispose() {
    _searchController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playReciter(_Reciter reciter) async {
    final isCurrent = _currentReciter == reciter.name;
    if (isCurrent && _isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _currentReciter = reciter.name;
    });
    try {
      if (!isCurrent) await _player.setUrl(reciter.audioUrl);
      unawaited(_player.play());
      if (mounted) setState(() { _isPlaying = true; _isLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isPlaying = false; _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تشغيل التلاوة. تحقق من اتصال الإنترنت.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reciters = _filteredReciters;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('القرآن الصوتي'),
        centerTitle: true,
        backgroundColor: _cream,
        foregroundColor: _primaryGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'ابحث عن قارئك المفضل',
                prefixIcon: const Icon(Icons.mic_none_rounded, color: _primaryGreen),
                suffixIcon: const Icon(Icons.search_rounded, color: _softText),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE7E0D5))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: _primaryGreen)),
              ),
            ),
          ),
          Expanded(
            child: reciters.isEmpty
                ? const Center(child: Text('لا يوجد قارئ بهذا الاسم', textDirection: TextDirection.rtl))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: reciters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final reciter = reciters[index];
                      final isCurrent = _currentReciter == reciter.name;
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        shadowColor: _primaryGreen.withOpacity(.08),
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: const CircleAvatar(
                            radius: 27,
                            backgroundColor: Color(0xFFE8F0E7),
                            child: Icon(Icons.person_rounded, color: _primaryGreen, size: 30),
                          ),
                          title: Text(reciter.name, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF263329))),
                          subtitle: Text('تحميل الصوت (MB ${reciter.size})', textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 12, color: _softText)),
                          trailing: IconButton(
                            tooltip: isCurrent && _isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                            onPressed: _isLoading && isCurrent ? null : () => _playReciter(reciter),
                            color: _primaryGreen,
                            icon: _isLoading && isCurrent
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen))
                                : Icon(isCurrent && _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 34),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
