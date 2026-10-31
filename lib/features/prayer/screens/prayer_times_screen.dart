import 'package:flutter/material.dart';
import '../services/prayer_times_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});
  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late Future<List<PrayerTime>> _future;
  @override
  void initState() { super.initState(); _future = PrayerTimesService.getTodayPrayerTimes(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('مواقيت الصلاة', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 22), textDirection: TextDirection.rtl), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Color(0xFF1A1A1A))),
      body: FutureBuilder<List<PrayerTime>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
          if (snapshot.hasError) return Center(child: Text('تعذر جلب المواقيت: ${snapshot.error}', style: const TextStyle(color: Colors.red), textDirection: TextDirection.rtl));
          final prayers = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: prayers.length,
            itemBuilder: (context, index) {
              final p = prayers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4))]),
                child: Row(
                  children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFD32F2F).withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.access_time, color: Color(0xFFD32F2F))),
                    const SizedBox(width: 14),
                    Expanded(child: Text(p.labelAr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl)),
                    Text('${p.time.hour.toString().padLeft(2, '0')}:${p.time.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 18, color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
