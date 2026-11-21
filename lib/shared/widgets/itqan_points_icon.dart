import 'dart:math' as math;
import 'package:flutter/material.dart';

/// الأيقونة الرسمية لنقاط إتقan
/// بديل كامل لأي نص "XP" في واجهات المستخدم
class ItqanPointsIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showShadow;

  const ItqanPointsIcon({
    super.key,
    this.size = 18,
    this.color,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ItqanStarPainter(
        color: color ?? const Color(0xFFD4AF37), // ذهبي إسلامي راقي
        showShadow: showShadow,
      ),
    );
  }
}

class _ItqanStarPainter extends CustomPainter {
  final Color color;
  final bool showShadow;

  _ItqanStarPainter({required this.color, required this.showShadow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.72;

    if (showShadow) {
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(center, radius * 0.9, shadowPaint);
    }

    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.95),
          Color.lerp(color, const Color(0xFF8B6508), 0.35)!,
        ],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFFFF4D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, size.width * 0.05);

    // رسم نجمة ثمانية إسلامية (مربعان متقاطعان بزاوية 45 درجة أو مسار ثماني الأضلاع)
    final path = Path();
    const points = 8;
    final angleStep = (math.pi * 2) / (points * 2);

    for (int i = 0; i < points * 2; i++) {
      final currentRadius = (i % 2 == 0) ? radius : innerRadius;
      final angle = (i * angleStep) - (math.pi / 2);
      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // نقطة نورانية داخلية
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.22, corePaint);
  }

  @override
  bool shouldRepaint(covariant _ItqanStarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.showShadow != showShadow;
}

/// ويدجت مساعد لعرض نقاط إتقان مسبوقة بالأيقونة الرسمية
class ItqanPointsBadge extends StatelessWidget {
  final dynamic points;
  final TextStyle? style;
  final double iconSize;
  final double spacing;
  final MainAxisSize mainAxisSize;

  const ItqanPointsBadge({
    super.key,
    required this.points,
    this.style,
    this.iconSize = 16,
    this.spacing = 5,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    final pointsText = points?.toString() ?? '0';
    return Row(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: CrossAxisAlignment.center,
      textDirection: TextDirection.rtl,
      children: [
        ItqanPointsIcon(size: iconSize),
        SizedBox(width: spacing),
        Text(
          pointsText,
          style: style ??
              const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A5C36),
                fontSize: 14,
              ),
        ),
      ],
    );
  }
}

