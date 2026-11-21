import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';
import '../data/models/circle_task.dart';

class CircleTasbihScreen extends StatefulWidget {
  const CircleTasbihScreen({
    super.key,
    required this.task,
    required this.canIncrement,
    required this.onIncrement,
  });

  final CircleTask task;
  final bool canIncrement;
  final Future<void> Function() onIncrement;

  @override
  State<CircleTasbihScreen> createState() => _CircleTasbihScreenState();
}

class _CircleTasbihScreenState extends State<CircleTasbihScreen> {
  late int _count;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _count = widget.task.progressValue;
  }

  Future<void> _increment() async {
    final target = widget.task.targetValue;
    if (_isSending ||
        !widget.canIncrement ||
        widget.task.isCompleted ||
        (target != null && target > 0 && _count >= target)) {
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
      _count++;
    });
    HapticFeedback.selectionClick();

    try {
      await widget.onIncrement();
    } catch (error) {
      if (mounted) {
        setState(() {
          _count--;
          _error = error.toString();
        });
        HapticFeedback.vibrate();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.task.targetValue;
    final hasTarget = target != null && target > 0;
    final progress = hasTarget ? (_count / target).clamp(0.0, 1.0) : 0.0;
    final completed =
        widget.task.isCompleted || (hasTarget && _count >= target);
    final dhikr = widget.task.description?.trim().isNotEmpty == true
        ? widget.task.description!.trim()
        : widget.task.title;

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: Text(
          widget.task.taskType == 'tasbih'
              ? 'التسبيح الجماعي'
              : 'العداد الجماعي',
          style: TextStyle(
            color: ItqanColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 36),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: ItqanColors.emerald.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: ItqanColors.emerald,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.task.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ItqanColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dhikr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ItqanColors.emeraldDark,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      height: 1.7,
                      fontFamily: 'NotoNaskhArabic',
                    ),
                  ),
                  const SizedBox(height: 30),
                  Semantics(
                    button: true,
                    label:
                        'عداد التسبيح $_count${hasTarget ? ' من $target' : ''}',
                    child: GestureDetector(
                      onTap:
                          widget.canIncrement && !completed ? _increment : null,
                      child: SizedBox(
                        width: 264,
                        height: 264,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.square(
                              dimension: 264,
                              child: CircularProgressIndicator(
                                value: hasTarget ? progress : null,
                                strokeWidth: 9,
                                strokeCap: StrokeCap.round,
                                backgroundColor: ItqanColors.border,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                            Container(
                              width: 230,
                              height: 230,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  center: Alignment(-0.45, -0.55),
                                  radius: 0.95,
                                  colors: [
                                    Color(0xFF188254),
                                    ItqanColors.emerald,
                                    ItqanColors.emeraldDark,
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37)
                                      .withValues(alpha: 0.75),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: ItqanColors.emerald
                                        .withValues(alpha: 0.24),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 62,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    hasTarget ? 'من $target' : 'تسبيحة',
                                    style: const TextStyle(
                                      color: Color(0xFFFFF1C7),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Icon(
                                    completed
                                        ? Icons.check_circle_rounded
                                        : Icons.touch_app_rounded,
                                    color: const Color(0xFFD4AF37),
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    completed
                        ? 'أحسنت، اكتمل العدد المطلوب'
                        : widget.canIncrement
                            ? 'المتبقي: ${hasTarget ? (target - _count).clamp(0, target) : '—'}'
                            : 'هذه المهمة غير مسندة إليك',
                    style: TextStyle(
                      color:
                          completed ? ItqanColors.emerald : ItqanColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isSending) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      color: ItqanColors.emerald,
                      backgroundColor: ItqanColors.border,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'جارٍ حفظ التسبيحة...',
                      style:
                          TextStyle(fontSize: 12, color: ItqanColors.inkSoft),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'تعذر حفظ التسبيحة: $_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: ItqanColors.error),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _SessionStat(
                          icon: Icons.flag_rounded,
                          label: 'الهدف',
                          value: hasTarget ? '$target' : 'مفتوح',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SessionStat(
                          icon: Icons.spa_rounded,
                          label: 'التقدم',
                          value: hasTarget
                              ? '${(progress * 100).round()}%'
                              : '$_count',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed:
                          widget.canIncrement && !completed && !_isSending
                              ? _increment
                              : null,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        completed ? 'اكتملت المهمة' : 'سبّح',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: ItqanColors.emerald,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            ItqanColors.emerald.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  const _SessionStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
      decoration: BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ItqanColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: ItqanColors.emerald),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(fontSize: 11, color: ItqanColors.inkSoft),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
