import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../quran/models/ayah.dart';
import '../../quran/models/surah.dart';
import '../../quran/services/quran_service.dart';

/// Loads the unchanged, locally licensed Tanzil assets through the established
/// Quran service; progress uses a private Hive namespace for this feature.
class JourneyQuranRepository {
  JourneyQuranRepository({QuranService? service}) : _service = service ?? QuranService();
  final QuranService _service;
  static const _boxName = 'itqan_journey_quran';
  Future<List<Surah>> surahs() => _service.getSurahs();
  Future<List<Ayah>> ayahs(int surah) => _service.getAyahs(surah);
  Future<int> lastSurah() async { final box=await _box(); return box.get('last_surah',defaultValue:1) as int; }
  Future<int> lastAyah() async { final box=await _box(); return box.get('last_ayah',defaultValue:1) as int; }
  Future<void> savePosition(int surah,int ayah) async {final box=await _box();await box.put('last_surah',surah);await box.put('last_ayah',ayah);}
  Future<Box> _box() async {if(!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);return Hive.box(_boxName);}
}

class JourneyContentRepository {
  Future<List<Map<String,dynamic>>> loadDuas() async {final raw=await rootBundle.loadString('assets/data/duas_data.json');return (jsonDecode(raw) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();}
  Future<List<Map<String,dynamic>>> loadAdhkar(String category) async {final raw=await rootBundle.loadString('assets/data/adhkar_data.json');final data=Map<String,dynamic>.from(jsonDecode(raw) as Map);return ((data[category] as List?)??const []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();}
}
