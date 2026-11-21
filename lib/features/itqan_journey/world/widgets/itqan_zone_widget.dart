import 'package:flutter/material.dart';
import '../../domain/itqan_tasks_registry.dart';
import '../../../../shared/widgets/itqan_points_icon.dart';

class ItqanZoneWidget extends StatelessWidget {
  final ItqanZone zone;
  final bool isSelected;
  final VoidCallback onTap;
  final List<ItqanTaskDefinition> tasks;
  final Function(ItqanTaskDefinition) onTaskTap;

  const ItqanZoneWidget({
    super.key,
    required this.zone,
    required this.isSelected,
    required this.onTap,
    required this.tasks,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? zone.primaryColor : const Color(0xFFE7E0D5),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? zone.primaryColor.withValues(alpha: 0.12) : const Color(0x0D000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس المنطقة
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: zone.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(zone.icon, color: zone.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: zone.primaryColor,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          zone.description,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5F685F)),
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF8A8C83),
                  ),
                ],
              ),
            ),
          ),

          // قائمة المهام الخاصة بالمنطقة عند الفتح
          if (isSelected) ...[
            const Divider(height: 1, color: Color(0xFFF2EEE7)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskRow(context, task);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskRow(BuildContext context, ItqanTaskDefinition task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E0D5).withValues(alpha: 0.6)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(task.visualIcon, color: zone.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task.number}. ${task.title}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202B24),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5F685F)),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ItqanPointsBadge(points: '+${task.pointsReward}', iconSize: 13),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => onTaskTap(task),
                style: ElevatedButton.styleFrom(
                  backgroundColor: zone.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('انطلق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

