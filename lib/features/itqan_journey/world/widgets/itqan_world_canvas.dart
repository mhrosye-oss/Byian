import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/itqan_tasks_registry.dart';

/// الرسام التفاعلي لعالم إتقان
/// يعكس تطور العالم: ازدهار الحدائق، نمو الواحات، وفتح المسارات مع تقدم المستخدم
class ItqanWorldCanvas extends StatelessWidget {
  final double overallProgress; // من 0.0 إلى 1.0
  final ItqanZone activeZone;
  final Function(ItqanZone) onZoneSelected;

  const ItqanWorldCanvas({
    super.key,
    required this.overallProgress,
    required this.activeZone,
    required this.onZoneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.max(260.0, width * 0.72);

        return GestureDetector(
          onTapUp: (details) {
            final x = details.localPosition.dx / width;
            final y = details.localPosition.dy / height;
            // تحديد أي منطقة تم لمسها
            if (y < 0.35) {
              onZoneSelected(ItqanZone.itqanPeak);
            } else if (x < 0.45 && y < 0.65) {
              onZoneSelected(ItqanZone.quranOasis);
            } else if (x >= 0.45 && y < 0.65) {
              onZoneSelected(ItqanZone.adhkarGarden);
            } else if (x < 0.5) {
              onZoneSelected(ItqanZone.duaOrchard);
            } else {
              onZoneSelected(ItqanZone.goodnessPlaza);
            }
          },
          child: CustomPaint(
            size: Size(width, height),
            painter: _WorldPainter(
              progress: overallProgress,
              selectedZone: activeZone,
            ),
          ),
        );
      },
    );
  }
}

class _WorldPainter extends CustomPainter {
  final double progress;
  final ItqanZone selectedZone;

  _WorldPainter({required this.progress, required this.selectedZone});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. خلفية السماء والتضاريس الطبيعية المتدرجة
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE8F5E9), // سماء خضراء فاتحة نضرة
          Color(0xFFF9F6F0), // أرضية بيج كريمية
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(24)),
      skyPaint,
    );

    // 2. رسم التلال والمستويات
    _drawTerrain(canvas, w, h);

    // 3. رسم الممرات النورانية الموصلة بين المناطق
    _drawPathways(canvas, w, h);

    // 4. رسم معالم المناطق الخمس
    // قمة الإتقان (في الأعلى)
    _drawPeakZone(canvas, Offset(w * 0.5, h * 0.22), selectedZone == ItqanZone.itqanPeak);

    // واحة القرآن (وسط يسار)
    _drawQuranOasis(canvas, Offset(w * 0.25, h * 0.48), selectedZone == ItqanZone.quranOasis);

    // حديقة الأذكار (وسط يمين)
    _drawAdhkarGarden(canvas, Offset(w * 0.75, h * 0.48), selectedZone == ItqanZone.adhkarGarden);

    // بستان الأدعية (أسفل يسار)
    _drawDuaOrchard(canvas, Offset(w * 0.28, h * 0.8), selectedZone == ItqanZone.duaOrchard);

    // ميدان الخير (أسفل يمين)
    _drawGoodnessPlaza(canvas, Offset(w * 0.72, h * 0.8), selectedZone == ItqanZone.goodnessPlaza);

    // إطار خارجي راقٍ
    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(24)),
      borderPaint,
    );
  }

  void _drawTerrain(Canvas canvas, double w, double h) {
    final terrainPaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.18 + (progress * 0.15))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, h * 0.55);
    path.quadraticBezierTo(w * 0.25, h * 0.45, w * 0.5, h * 0.52);
    path.quadraticBezierTo(w * 0.75, h * 0.58, w, h * 0.48);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawPath(path, terrainPaint);
  }

  void _drawPathways(Canvas canvas, double w, double h) {
    final pathPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.4 + (progress * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final road = Path();
    // طريق من ميدان الخير إلى حديقة الأذكار
    road.moveTo(w * 0.72, h * 0.8);
    road.lineTo(w * 0.75, h * 0.48);
    // إلى قمة الإتقان
    road.lineTo(w * 0.5, h * 0.22);
    // من واحة القرآن إلى قمة الإتقان
    road.moveTo(w * 0.25, h * 0.48);
    road.lineTo(w * 0.5, h * 0.22);
    // من بستان الأدعية إلى واحة القرآن
    road.moveTo(w * 0.28, h * 0.8);
    road.lineTo(w * 0.25, h * 0.48);
    // طريق وسطي جامع
    road.moveTo(w * 0.25, h * 0.48);
    road.lineTo(w * 0.75, h * 0.48);

    canvas.drawPath(road, pathPaint);
  }

  void _drawPeakZone(Canvas canvas, Offset center, bool isSelected) {
    // هالة القمة
    final haloPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: isSelected ? 0.35 : 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 28, haloPaint);

    // المنارة / القمة
    final peakPaint = Paint()
      ..color = const Color(0xFF0A5C36)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx, center.dy - 18);
    path.lineTo(center.dx + 14, center.dy + 12);
    path.lineTo(center.dx - 14, center.dy + 12);
    path.close();
    canvas.drawPath(path, peakPaint);

    // هلال القمة
    final crescentPaint = Paint()
      ..color = const Color(0xFFFFF4D0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy - 20), 4, crescentPaint);
  }

  void _drawQuranOasis(Canvas canvas, Offset center, bool isSelected) {
    // واحة خضراء مع نخلتين رمزيتين
    final basePaint = Paint()
      ..color = const Color(0xFF0A5C36).withValues(alpha: isSelected ? 0.9 : 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 22, basePaint);

    // رمز كتاب مفتوح
    final bookPaint = Paint()
      ..color = const Color(0xFFFFF4D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final p = Path();
    p.moveTo(center.dx - 8, center.dy - 5);
    p.lineTo(center.dx, center.dy);
    p.lineTo(center.dx + 8, center.dy - 5);
    p.lineTo(center.dx + 8, center.dy + 5);
    p.lineTo(center.dx, center.dy + 10);
    p.lineTo(center.dx - 8, center.dy + 5);
    p.close();
    canvas.drawPath(p, bookPaint);
  }

  void _drawAdhkarGarden(Canvas canvas, Offset center, bool isSelected) {
    // حديقة أزهار وأوراق خضراء
    final basePaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: isSelected ? 0.9 : 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 22, basePaint);

    // بتلات الوردة النورانية
    final petalPaint = Paint()
      ..color = const Color(0xFFE8F5E9)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi) / 3;
      final offset = Offset(center.dx + 7 * math.cos(angle), center.dy + 7 * math.sin(angle));
      canvas.drawCircle(offset, 4, petalPaint);
    }
    final corePaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawCircle(center, 3.5, corePaint);
  }

  void _drawDuaOrchard(Canvas canvas, Offset center, bool isSelected) {
    // بستان الأدعية
    final basePaint = Paint()
      ..color = const Color(0xFF00796B).withValues(alpha: isSelected ? 0.9 : 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20, basePaint);

    // كفي الدعاء
    final handPaint = Paint()
      ..color = const Color(0xFFE0F2F1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - 4, center.dy), 5, handPaint);
    canvas.drawCircle(Offset(center.dx + 4, center.dy), 5, handPaint);
  }

  void _drawGoodnessPlaza(Canvas canvas, Offset center, bool isSelected) {
    // ميدان الخير والمشاركة
    final basePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: isSelected ? 0.95 : 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20, basePaint);

    // رمز العطاء والنشر
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, starPaint);
  }

  @override
  bool shouldRepaint(covariant _WorldPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.selectedZone != selectedZone;
}

