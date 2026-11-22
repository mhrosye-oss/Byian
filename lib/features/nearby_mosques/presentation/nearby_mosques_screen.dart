import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';

/// شاشة "مساجد قريبة"
/// تكتشف موقع المستخدم عبر GPS ثم تستعلم عن المساجد الحقيقية القريبة
/// من OpenStreetMap (Overpass API) — بدون أي بيانات تجريبية.
/// تعرض النتائج في قائمة أو خريطة تفاعلية (تبديل من شريط التطبيق).
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

  LatLng get point => LatLng(lat, lon);

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
  bool _showMap = false;
  String? _errorMessage;
  Position? _currentPosition;
  List<_Mosque> _mosques = [];
  final MapController _mapController = MapController();

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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mosques = [];
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'يرجى تشغيل خدمة تحديد الموقع (GPS) للبحث عن أقرب المساجد.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 45));
        if (!mounted) return;
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
      ).timeout(const Duration(seconds: 18));

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isFetchingMosques = true;
        _isLoading = false;
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
            .timeout(const Duration(seconds: 15));

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

  void _showMosqueSheet(_Mosque m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.mosque_rounded, color: Color(0xFF064E3B)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m.name,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ItqanColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.near_me_rounded, size: 15, color: Color(0xFF059669)),
                      const SizedBox(width: 5),
                      Text(
                        '${m.distanceLabel} • ${m.timeToWalk}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  if (m.facilities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: m.facilities
                          .map((f) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  f,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text(
                        'الاتجاهات في خرائط جوجل',
                        style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openInMaps(m);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleView() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يمكن عرض الخريطة قبل تحديد موقعك. تأكد من تفعيل GPS ثم أعد المحاولة.',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      );
      return;
    }
    setState(() => _showMap = !_showMap);
  }

  void _centerOnUser() {
    final pos = _currentPosition;
    if (pos == null) return;
    _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
  }

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
              icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
              tooltip: _showMap ? 'عرض كقائمة' : 'عرض على الخريطة',
              onPressed: _isLoading || _isFetchingMosques ? null : _toggleView,
            ),
            IconButton(
              icon: const Icon(Icons.my_location_rounded),
              tooltip: 'تحديث موقعي',
              onPressed: _isLoading || _isFetchingMosques
                  ? null
                  : _determinePosition,
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
                child: _showMap && _currentPosition != null
                    ? _buildMapView()
                    : _buildListView(),
              ),
      ),
    );
  }

  // ======================= عرض الخريطة =======================

  Widget _buildMapView() {
    final pos = _currentPosition!;
    final userPoint = LatLng(pos.latitude, pos.longitude);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userPoint,
            initialZoom: 14,
            minZoom: 10,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'app.byian.itqan',
            ),
            MarkerLayer(
              markers: [
                // موقع المستخدم
                Marker(
                  point: userPoint,
                  width: 26,
                  height: 26,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                  ),
                ),
                // المساجد
                ..._mosques.map((m) {
                  return Marker(
                    point: m.point,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _showMosqueSheet(m),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF064E3B),
                          border: Border.all(color: const Color(0xFFFBBF24), width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 5),
                          ],
                        ),
                        child: const Icon(
                          Icons.mosque_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                const TextSourceAttribution('بيانات الخرائط © مساهمو OpenStreetMap'),
              ],
            ),
          ],
        ),

        // عدّاد النتائج + زر التوسيط
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    _mosques.isEmpty
                        ? 'لا توجد مساجد قريبة معروضة على الخريطة'
                        : '${_mosques.length} مسجد ضمن نطاق بحثك — اضغط على أي علامة للتفاصيل',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'centerUserBtn',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF064E3B),
                onPressed: _centerOnUser,
                child: const Icon(Icons.center_focus_strong_rounded),
              ),
            ],
          ),
        ),

        if (_isFetchingMosques)
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Chip(
                backgroundColor: Colors.white,
                label: Text(
                  'جارٍ البحث عن المساجد القريبة…',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ======================= عرض القائمة =======================

  Widget _buildListView() {
    return ListView(
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
                          '${m.distanceLabel} • ${m.timeToWalk}',
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
                tooltip: 'الموقع على الخريطة',
                icon: const Icon(
                  Icons.map_rounded,
                  color: Color(0xFF064E3B),
                ),
                onPressed: () => _openMapAt(m),
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

  /// يفتح عرض الخريطة ويوسّطها على مسجد محدد
  Future<void> _openMapAt(_Mosque m) async {
    if (_currentPosition == null) {
      await _openInMaps(m);
      return;
    }
    setState(() => _showMap = true);
    // ننتظر إطاراً حتى تُبنى الخريطة ثم نوسّطها مع تكبير مناسب
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(m.point, 16);
    });
  }
}
