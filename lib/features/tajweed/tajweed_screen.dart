import 'package:flutter/material.dart';
import 'package:itqan/features/mushaf/qcf_quran_screen.dart';

/// Tajweed learning entry point. The project Mushaf uses the existing QCF
/// Quran renderer, which includes the verified Tajweed presentation.
class TajweedScreen extends StatelessWidget {
  const TajweedScreen({super.key});
  @override
  Widget build(BuildContext context) => const QcfQuranScreen();
}
