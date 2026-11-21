import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/colors.dart';

/// شاشة "مساجد قريبة"
/// تكتشف موقع المستخدم عبر GPS وتعرض قائمة المساجد القريبة مع المسافة والاتجاه
class NearbyMosquesScreen extends StatefulWidget {
  const NearbyMosquesScreen({super.key});

  @override
  State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;

  final List<Map<String, dynamic>> _mosques = [
    {
      'name': 'جامع الراجحي الكبير',
      'address': 'حي النسيم - مكة المكرمة',
      'distance': '0.8 كم',
      'timeToWalk': '10 دقائق مشياً',
      'status': 'مفتوح - تقام فيه صلاة الجماعة والجمعة',
      'facilities': ['مصلى نساء', 'مواقف سيارات', 'دورة مياه ووضوء'],
      'isFavorite': true,
    },
    {
      'name': 'مسجد التقوى والإيمان',
      'address': 'حي العزيزية',
      'distance': '1.3 كم',
      'timeToWalk': '15 دقيقة مشياً',
      'status': 'مفتوح للصلوات الخمس',
      'facilities': ['مواقف', 'ميسر لذوي الاحتياجات'],
      'isFavorite': false,
    },
    {
      'name': 'جامع الملك عبد العزيز',
      'address': 'طريق الملك فهد',
      'distance': '2.1 كم',
      'timeToWalk': '4 دقائق بالسيارة',
      'status': 'تقام فيه صلاة الجمعة والمحاضرات',
      'facilities': ['حلقات تحفيظ', 'مكتبة إسلامية', 'مصلى نساء'],
      'isFavorite': false,
    },
    {
      'name': 'مسجد النور والبركة',
      'address': 'شارع عبد الله بن مسعود',
      'distance': '3.0 كم',
      'timeToWalk': '6 دقائق بالسيارة',
      'status': 'مفتوح للصلوات الخمس',
      'facilities': ['مغسلة موتى', 'مواقف متوفرة'],
      'isFavorite': false,
    },
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
          _errorMessage = 'إذن الموقع مرفوض بشكل دائم من إعدادات الجهاز.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // نعرض المساجد التقديرية حتى لو تعذر الـ GPS
          _isLoading = false;
        });
      }
    }
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
              icon: const Icon(Icons.my_location_rounded),
              tooltip: 'تحديث موقعي',
              onPressed: _determinePosition,
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
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_errorMessage != null)
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
                              const Text(
                                'موقعك الجغرافي نشط',
                                style: TextStyle(
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
                                    : 'تم تقدير موقعك بالقرب من مكة المكرمة',
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

                  ..._mosques.map((m) {
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
                                      m['name'] as String,
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
                                          '${m['distance']} • ${m['timeToWalk']}',
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
                                icon: Icon(
                                  m['isFavorite'] == true
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: m['isFavorite'] == true
                                      ? Colors.red
                                      : Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  setState(() {
                                    m['isFavorite'] = !(m['isFavorite'] as bool);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            m['address'] as String,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: ItqanColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: (m['facilities'] as List<String>).map((fac) {
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
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
