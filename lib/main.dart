import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تثبيت اتجاه الشاشة عمودياً
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // إعادة غلاف Riverpod الأساسي (ضروري جداً لمنع الانهيار)
  runApp(const ProviderScope(child: ItqanApp()));
}
