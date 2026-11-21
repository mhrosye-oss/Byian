import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:itqan/core/theme/colors.dart';

class FamilyGardenWidget extends StatefulWidget {
  final int activeActivitiesCount;
  final VoidCallback? onGardenTapped;

  const FamilyGardenWidget({
    super.key,
    this.activeActivitiesCount = 1,
    this.onGardenTapped,
  });

  @override
  State<FamilyGardenWidget> createState() => _FamilyGardenWidgetState();
}

class _FamilyGardenWidgetState extends State<FamilyGardenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onGardenTapped,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF4EDE2), Color(0xFFE9F3EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ItqanColors.border),
          boxShadow: [
            BoxShadow(
              color: ItqanColors.ink.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // رسم الشجرة الهادئة والمتنفسة
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _breathingController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _GardenPainter(
                        animationValue: _breathingController.value,
                        leavesDensity: math.min(5, widget.activeActivitiesCount + 2),
                      ),
                    );
                  },
                ),
              ),

              // بطاقة المعنى الهادئ في أعلى البستان
              Positioned(
                top: 14,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ItqanColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.park_rounded, size: 14, color: ItqanColors.emerald),
                      SizedBox(width: 4),
                      Text(
                        'بستان العائلة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ItqanColors.emerald,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // رسالة المرافقة الروحية في أسفل البستان
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ItqanColors.border.withValues(alpha: 0.6)),
                    ),
                    child: const Text(
                      'مساحة نمو هادئة.. تجمعنا على السكينة والمودة بلا مقارنة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: ItqanColors.inkSoft,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GardenPainter extends CustomPainter {
  final double animationValue;
  final int leavesDensity;

  _GardenPainter({required this.animationValue, required this.leavesDensity});

  @override
  void paint(Canvas canvas, Size size) {
    final hillPaint = Paint()
      ..color = const Color(0xFFD7EAD9).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // تلة هادئة
    final hillPath = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.75 + (animationValue * 4),
        size.width,
        size.height,
      )
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    final trunkPaint = Paint()
      ..color = const Color(0xFF7A6855).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final centerX = size.width * 0.5;
    final trunkBaseY = size.height * 0.85;
    final trunkTopY = size.height * 0.38 + (animationValue * 3);

    // جذع الشجرة
    final trunkPath = Path()
      ..moveTo(centerX, trunkBaseY)
      ..quadraticBezierTo(centerX - 4, (trunkBaseY + trunkTopY) / 2, centerX, trunkTopY);
    canvas.drawPath(trunkPath, trunkPaint);

    // فروع الشجرة
    trunkPaint.strokeWidth = 3.5;
    canvas.drawLine(
      Offset(centerX, trunkTopY + 20),
      Offset(centerX - 35 - (animationValue * 3), trunkTopY - 10),
      trunkPaint,
    );
    canvas.drawLine(
      Offset(centerX, trunkTopY + 15),
      Offset(centerX + 35 + (animationValue * 3), trunkTopY - 12),
      trunkPaint,
    );

    // أوراق الشجرة الخضراء المتنفسة
    final leafPaint = Paint()..style = PaintingStyle.fill;
    final leafColors = [
      const Color(0xFF2E7D32).withValues(alpha: 0.75),
      const Color(0xFF43A047).withValues(alpha: 0.8),
      const Color(0xFF81C784).withValues(alpha: 0.85),
      const Color(0xFF0A5C36).withValues(alpha: 0.9),
      const Color(0xFFB76E79).withValues(alpha: 0.7), // زهرات خفيفة
    ];

    final breathScale = 1.0 + (animationValue * 0.08);

    final leafClusters = [
      Offset(centerX, trunkTopY - 12),
      Offset(centerX - 35, trunkTopY - 15),
      Offset(centerX + 35, trunkTopY - 18),
      Offset(centerX - 18, trunkTopY - 35),
      Offset(centerX + 18, trunkTopY - 32),
      Offset(centerX, trunkTopY - 45),
    ];

    for (int i = 0; i < leafClusters.length; i++) {
      leafPaint.color = leafColors[i % leafColors.length];
      final radius = (18.0 + (i % 3) * 4) * breathScale;
      canvas.drawCircle(leafClusters[i], radius, leafPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GardenPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.leavesDensity != leavesDensity;
}
