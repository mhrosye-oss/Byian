import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const double makkahLat = 21.4225;
  static const double makkahLng = 39.8262;

  final ValueNotifier<double> _headingNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> _qiblaAngleNotifier = ValueNotifier<double>(0);
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier<bool>(true);

  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final position = await _getLocation();
      final qibla = _calculateQibla(position.latitude, position.longitude);

      _qiblaAngleNotifier.value = qibla;
      _loadingNotifier.value = false;
    } catch (_) {
      _loadingNotifier.value = false;
    }

    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final heading = event.heading ?? 0.0;
      _headingNotifier.value = heading;
    });
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('خدمة الموقع غير مفعلة');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('تم رفض صلاحية الموقع بشكل دائم');
    }

    if (permission == LocationPermission.denied) {
      throw Exception('تم رفض صلاحية الموقع');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
  }

  double _calculateQibla(double lat, double lng) {
    final lat1 = lat * math.pi / 180;
    final lat2 = makkahLat * math.pi / 180;
    final lonDiff = (makkahLng - lng) * math.pi / 180;

    final y = math.sin(lonDiff);
    final x =
        math.cos(lat1) * math.tan(lat2) - math.sin(lat1) * math.cos(lonDiff);

    final angle = math.atan2(y, x) * 180 / math.pi;
    return (angle + 360) % 360;
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _headingNotifier.dispose();
    _qiblaAngleNotifier.dispose();
    _loadingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'القبلة',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _loadingNotifier,
        builder: (context, loading, _) {
          if (loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD32F2F),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'اتجاه القبلة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD32F2F),
                                  width: 2,
                                ),
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              top: 18,
                              child: const Text(
                                'N',
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 18,
                              child: const Text(
                                'E',
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 18,
                              child: const Text(
                                'S',
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 18,
                              child: const Text(
                                'W',
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ValueListenableBuilder<double>(
                              valueListenable: _headingNotifier,
                              builder: (context, heading, _) {
                                return Transform.rotate(
                                  angle: -heading * math.pi / 180,
                                  child: SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 2,
                                            height: 180,
                                            color: const Color(0xFF1A1A1A).withOpacity(0.15),
                                          ),
                                        ),
                                        Center(
                                          child: Container(
                                            width: 150,
                                            height: 2,
                                            color: const Color(0xFF1A1A1A).withOpacity(0.15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            ValueListenableBuilder<double>(
                              valueListenable: _qiblaAngleNotifier,
                              builder: (context, qiblaAngle, _) {
                                return ValueListenableBuilder<double>(
                                  valueListenable: _headingNotifier,
                                  builder: (context, heading, _) {
                                    final offset = (qiblaAngle - heading + 360) % 360;
                                    final angle = offset * math.pi / 180;

                                    return Transform.rotate(
                                      angle: angle,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          width: 8,
                                          height: 100,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD32F2F),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الاستدارة الحالية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<double>(
                        valueListenable: _qiblaAngleNotifier,
                        builder: (context, qibla, _) {
                          return Text(
                            '${qibla.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            textDirection: TextDirection.rtl,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
