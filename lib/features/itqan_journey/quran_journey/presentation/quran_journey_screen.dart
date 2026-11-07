import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../mushaf/mushaf_page_screen.dart';
import '../../../mushaf/providers/reading_position_provider.dart';

/// Opens the existing page-based Mushaf and resumes the last locally saved page.
class QuranJourneyScreen extends ConsumerWidget {
  const QuranJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(lastReadingPositionProvider);
    return position.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('قرآن الرحلة')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تعذر استعادة موضع القراءة المحفوظ.'),
              TextButton(
                onPressed: () => ref.invalidate(lastReadingPositionProvider),
                child: const Text('إعادة المحاولة'),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const MushafPageScreen(startPage: 1),
                  ),
                ),
                child: const Text('ابدأ من أول صفحة'),
              ),
            ],
          ),
        ),
      ),
      data: (saved) => MushafPageScreen(
        startPage: (saved?.pageNumber ?? 1).clamp(1, 604),
      ),
    );
  }
}
