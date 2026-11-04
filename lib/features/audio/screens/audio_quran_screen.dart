import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioQuranScreen extends StatefulWidget {
  const AudioQuranScreen({super.key});

  @override
  State<AudioQuranScreen> createState() => _AudioQuranScreenState();
}

class _AudioQuranScreenState extends State<AudioQuranScreen> {
  static const Color _green = Color(0xFF1B5E20);

  static const List<_Reciter> _reciters = [
    _Reciter(
      name: 'مشاري العفاسي',
      serverFolder: 'https://server8.mp3quran.net/afs',
      downloadSize: '50.9',
    ),
    _Reciter(
      name: 'عبد الباسط عبد الصمد',
      serverFolder: 'https://server7.mp3quran.net/basit',
      downloadSize: '72.4',
    ),
    _Reciter(
      name: 'ماهر المعيقلي',
      serverFolder: 'https://server12.mp3quran.net/maher',
      downloadSize: '48.6',
    ),
    _Reciter(
      name: 'عبد الرحمن السديس',
      serverFolder: 'https://server11.mp3quran.net/sds',
      downloadSize: '51.2',
    ),
    _Reciter(
      name: 'سعود الشريم',
      serverFolder: 'https://server11.mp3quran.net/shur',
      downloadSize: '49.8',
    ),
    _Reciter(
      name: 'سعد الغامدي',
      serverFolder: 'https://server6.mp3quran.net/ghamdi',
      downloadSize: '47.3',
    ),
    _Reciter(
      name: 'محمد صديق المنشاوي',
      serverFolder: 'https://server10.mp3quran.net/minsh',
      downloadSize: '69.5',
    ),
    _Reciter(
      name: 'محمود خليل الحصري',
      serverFolder: 'https://server5.mp3quran.net/hsry',
      downloadSize: '62.1',
    ),
    _Reciter(
      name: 'أبو بكر الشاطري',
      serverFolder: 'https://server4.mp3quran.net/shatri',
      downloadSize: '48.2',
    ),
    _Reciter(
      name: 'ياسر الدوسري',
      serverFolder: 'https://server11.mp3quran.net/dosri',
      downloadSize: '50.4',
    ),
    _Reciter(
      name: 'فارس عباد',
      serverFolder: 'https://server8.mp3quran.net/frs_a',
      downloadSize: '46.7',
    ),
    _Reciter(
      name: 'إدريس أبكر',
      serverFolder: 'https://server11.mp3quran.net/abkr',
      downloadSize: '45.9',
    ),
    _Reciter(
      name: 'ناصر القطامي',
      serverFolder: 'https://server6.mp3quran.net/qtm',
      downloadSize: '49.6',
    ),
    _Reciter(
      name: 'عبد الله بصفر',
      serverFolder: 'https://server7.mp3quran.net/bsfr',
      downloadSize: '52.8',
    ),
    _Reciter(
      name: 'محمد أيوب',
      serverFolder: 'https://server8.mp3quran.net/ayoub',
      downloadSize: '55.1',
    ),
  ];

  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();

  late final StreamSubscription<PlayerState> _playerStateSubscription;

  String _searchQuery = '';
  int? _selectedReciterIndex;
  int? _loadingReciterIndex;

  List<_Reciter> get _filteredReciters {
    final query = _searchQuery.trim();
    if (query.isEmpty) return _reciters;

    return _reciters
        .where((reciter) => reciter.name.contains(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    unawaited(_playerStateSubscription.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  String _audioUrl(_Reciter reciter) {
    final folder = reciter.serverFolder.trim();
    return '$folder/001.mp3';
  }

  Future<void> _togglePlayback(_Reciter reciter) async {
    final index = _reciters.indexOf(reciter);

    if (_selectedReciterIndex == index && _player.playing) {
      await _player.pause();
      return;
    }

    if (_selectedReciterIndex == index &&
        _player.processingState != ProcessingState.idle &&
        _player.processingState != ProcessingState.completed) {
      await _player.play();
      return;
    }

    setState(() => _loadingReciterIndex = index);

    try {
      await _player.setUrl(_audioUrl(reciter));
      if (!mounted) return;

      setState(() {
        _selectedReciterIndex = index;
        _loadingReciterIndex = null;
      });

      unawaited(_player.play());
    } catch (error) {
      if (!mounted) return;

      setState(() => _loadingReciterIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تشغيل تلاوة ${reciter.name}. تحقق من اتصال الإنترنت.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  void _showVoiceSearchMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'يمكنك البحث بكتابة اسم القارئ.',
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final reciters = _filteredReciters;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('القرآن الصوتي'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'ابحث عن قارئ',
                prefixIcon: IconButton(
                  tooltip: 'البحث الصوتي',
                  onPressed: _showVoiceSearchMessage,
                  icon: const Icon(Icons.mic_none_rounded, color: _green),
                ),
                suffixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: reciters.isEmpty
                ? Center(
                    child: Text(
                      'لا يوجد قارئ بهذا الاسم',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: reciters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final reciter = reciters[index];
                      final originalIndex = _reciters.indexOf(reciter);
                      final isLoading =
                          _loadingReciterIndex == originalIndex;
                      final isSelected =
                          _selectedReciterIndex == originalIndex;
                      final isPlaying = isSelected && _player.playing;

                      return Card(
                        color: theme.cardColor,
                        elevation: 2,
                        shadowColor: _green.withOpacity(.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsetsDirectional.fromSTEB(
                            14,
                            8,
                            10,
                            8,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x141B5E20),
                            child: Icon(
                              Icons.person_rounded,
                              color: _green,
                            ),
                          ),
                          title: Text(
                            reciter.name,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            'تحميل الصوت (MB ${reciter.downloadSize})',
                            textDirection: TextDirection.rtl,
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: IconButton.filledTonal(
                            tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                            onPressed:
                                isLoading ? null : () => _togglePlayback(reciter),
                            style: IconButton.styleFrom(
                              foregroundColor: _green,
                            ),
                            icon: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _green,
                                    ),
                                  )
                                : Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                          ),
                          onTap: () => _togglePlayback(reciter),
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

class _Reciter {
  const _Reciter({
    required this.name,
    required this.serverFolder,
    required this.downloadSize,
  });

  final String name;
  final String serverFolder;
  final String downloadSize;
}
