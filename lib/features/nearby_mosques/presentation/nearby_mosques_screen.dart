import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';

/// شاشة "مساجد قريبة"
/// تكتشف موقع المستخدم عبر GPS ثم تستعلم عن المساجد الحقيقية القريبة
/// من OpenStreetMap (Overpass API) — بدون أي بيانات تجريبية.
class NearbyMosquesScreen extends StatefulWidget {
  const NearbyMosquesScreen({super.key});

  @override
  State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

class _Mosque {
  final String name;
  final double distanceMeters;
  final double lat;
  final double lon;
  final List<String> facilities;
  final String osmId;

  const _Mosque({
    required this.name,
    required this.distanceMeters,
    required this.lat,
    required this.lon,
    required this.facilities,
    required this.osmId,
  });

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} متر';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} كم';
  }

  String get timeToWalk {
    final minutes = (distanceMeters / 80).ceil(); // ~80 م/د مشياً
    if (minutes < 1) return 'أقل من دقيقة مشياً';
    return '$minutes دقيقة مشياً';
  }
}

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  bool _isLoading = true;
  bool _isFetchingMosques = false;
  String? _errorMessage;
  Position? _currentPosition;
  List<_Mosque> _mosques = [];

  /// خوادم Overpass بالترتيب — عند فشل أحدها نجرّب التالي
  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mosques = [];
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'يرجى تشغيل خدمة تحديد الموقع (GPS) للبحث عن أقرب المساجد.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'تم رفض إذن الوصول للموقع. يُرجى منحه لعرض المساجد القريبة منك.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'إذن الموقع مرفوض بشكل دائم، يُرجى تمكينه من إعدادات الجهاز.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isFetchingMosques = true;
      });

      await _fetchNearbyMosques(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحديد موقعك الحالي، تأكد من تفعيل GPS ثم أعد المحاولة.';
          _isLoading = false;
          _isFetchingMosques = false;
        });
      }
    }
  }

  /// استعلام حقيقي عن المساجد من OpenStreetMap Overpass API
  Future<void> _fetchNearbyMosques(double lat, double lon, {int radiusMeters = 3000}) async {
    final query = '''
[out:json][timeout:25];
nwr["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lon);
out center 40;
''';

    Object? lastError;
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              body: {'data': query},
              headers: {'User-Agent': 'ByianApp/1.0 (nearby mosques)'},
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final elements = (data['elements'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();

          final mosques = <_Mosque>[];
          for (final el in elements) {
            final tags = (el['tags'] as Map<String, dynamic>? ?? {});
            // إحداثيات العنصر: للعقدة lat/lon مباشرة، وللمضلعات نقطة center
            final elLat = (el['lat'] ?? el['center']?['lat']) as num?;
            final elLon = (el['lon'] ?? el['center']?['lon']) as num?;
            if (elLat == null || elLon == null) continue;

            final name = (tags['name'] as String?)?.trim();
            if (name == null || name.isEmpty) continue; // تجاهل غير المسماة

            final d = Geolocator.distanceBetween(lat, lon, elLat.toDouble(), elLon.toDouble());

            mosques.add(_Mosque(
              name: name,
              distanceMeters: d,
              lat: elLat.toDouble(),
              lon: elLon.toDouble(),
              facilities: _facilitiesFromTags(tags),
              osmId: '${el['type'] ?? 'node'}/${el['id'] ?? ''}',
            ));
          }

          mosques.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

          // إذا لم نجد شيئاً بنطاق ضيق نوسّع البحث إلى 8 كم مرة واحدة
          if (mosques.isEmpty && radiusMeters < 8000) {
            await _fetchNearbyMosques(lat, lon, radiusMeters: 8000);
            return;
          }

          if (!mounted) return;
          setState(() {
            _mosques = mosques;
            _isFetchingMosques = false;
            _isLoading = false;
            if (mosques.isEmpty) {
              _errorMessage = 'لم نجد مساجد مسجّلة قرب موقعك في خرائط OpenStreetMap. يمكنك إضافتها لاحقاً من الموقع نفسه.';
            }
          });
          return;
        }
        lastError = 'HTTP ${response.statusCode} من $endpoint';
      } catch (e) {
        lastError = e;
      }
    }

    if (!mounted) return;
    setState(() {
      _isFetchingMosques = false;
      _isLoading = false;
      _errorMessage = 'تعذر الاتصال بخدمة خرائط OpenStreetMap حالياً، حاول مرة أخرى بعد قليل.';
    });
    debugPrint('NearbyMosques: فشل كل خوادم Overpass — آخر خطأ: $lastError');
  }

  /// توليد وسائل المسجد من وسوم OpenStreetMap
  List<String> _facilitiesFromTags(Map<String, dynamic> tags) {
    final facilities = <String>[];
    if (tags['wheelchair'] == 'yes' || tags['wheelchair'] == 'designated') {
      facilities.add('ميسّر لذوي الاحتياجات');
    }
    if (tags['toilets'] == 'yes') facilities.add('دورة مياه');
    if (tags['female'] == 'yes' || tags['women'] == 'yes') facilities.add('مصلى نساء');
    if (tags['parking'] == 'yes' || tags['amenity'] == 'parking') facilities.add('مواقف سيارات');
    if (tags['wudu'] == 'yes' || tags['ablution'] == 'yes') facilities.add('مكان وضوء');
    return facilities;
  }

  Future<void> _openInMaps(_Mosque m) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${m.lat},${m.lon}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _distanceRowLabel(_Mosque m) => '${m.distanceLabel} • ${m.timeToWalk}';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(
          backgroundColor: const Color(0xFF064E3B),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Row(
            children: [
              Icon(Icons.mosque_rounded, size: 24, color: Color(0xFFFBBF24)),
              SizedBox(width: 10),
              Text(
                'مساجد قريبة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location_rounded),
              tooltip: 'تحديث موقعي',
              onPressed: _isLoading ? null : _determinePosition,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF064E3B)),
                    SizedBox(height: 16),
                    Text(
                      'جارٍ تحديد موقعك والبحث عن أقرب المساجد...',
                      style: TextStyle(fontFamily: 'Tajawal', color: ItqanColors.ink),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFF064E3B),
                onRefresh: _determinePosition,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.amber),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: TextButton.icon(
                          onPressed: _determinePosition,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],

                    // بطاقة رأسية للموقع الحالي
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF0A5C46)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFFBBF24),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentPosition != null ? 'موقعك الجغرافي نشط' : 'بانتظار تحديد موقعك…',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentPosition != null
                                      ? 'خط العرض: ${_currentPosition!.latitude.toStringAsFixed(3)} • خط الطول: ${_currentPosition!.longitude.toStringAsFixed(3)}'
                                      : 'لم يتم الحصول على الموقع بعد',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_isFetchingMosques)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: Color(0xFF064E3B)),
                              SizedBox(height: 12),
                              Text(
                                'جارٍ البحث عن المساجد القريبة منك…',
                                style: TextStyle(fontFamily: 'Tajawal', color: ItqanColors.ink),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_mosques.isNotEmpty) ...[
                      // عنوان القائمة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المساجد والجوامع القريبة (${_mosques.length})',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ItqanColors.ink,
                            ),
                          ),
                          const Text(
                            'الأقرب أولاً',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Color(0xFF064E3B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      ..._mosques.map(_buildMosqueCard),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMosqueCard(_Mosque m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: Color(0xFF064E3B),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ItqanColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 13,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _distanceRowLabel(m),
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'الاتجارات في الخرائط',
                icon: const Icon(
                  Icons.map_rounded,
                  color: Color(0xFF064E3B),
                ),
                onPressed: () => _openInMaps(m),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'المصدر: OpenStreetMap • ${m.osmId}',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          if (m.facilities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: m.facilities.map((fac) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    fac,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
