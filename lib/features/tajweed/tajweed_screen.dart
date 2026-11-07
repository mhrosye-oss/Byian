import 'package:flutter/material.dart';
import 'package:itqan/features/mushaf/mushaf_screen.dart';

/// Tajweed learning entry point with surah selection and colour-coded reading.
class TajweedScreen extends StatelessWidget {
  const TajweedScreen({super.key});

  @override
  Widget build(BuildContext context) => const MushafScreen(tajweedMode: true);
}
