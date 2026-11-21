import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/models/circle.dart';

class CircleCard extends StatelessWidget {
  final Circle circle;
  final VoidCallback onTap;
  final VoidCallback onDashboardTap;
  final VoidCallback onMembersTap;
  final VoidCallback onTasksTap;
  final VoidCallback onWhispersTap;

  const CircleCard({
    super.key,
    required this.circle,
    required this.onTap,
    required this.onDashboardTap,
    required this.onMembersTap,
    required this.onTasksTap,
    required this.onWhispersTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = circle.isOwner;
    final isAdmin = circle.isAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ItqanColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: ItqanColors.ink.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Type badge + privacy + role badge
                Row(
                  children: [
                    // Type Badge (from API)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ItqanColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_outlined,
                              size: 13, color: ItqanColors.emerald),
                          const SizedBox(width: 5),
                          Text(
                            circle.type.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ItqanColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Privacy badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ItqanColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            circle.isPrivate
                                ? Icons.lock_outline_rounded
                                : Icons.public_rounded,
                            size: 12,
                            color: ItqanColors.inkSoft,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            circle.privacyLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: ItqanColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? ItqanColors.roseGold.withValues(alpha: 0.15)
                            : isAdmin
                                ? const Color(0xFFE0E7FF)
                                : ItqanColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOwner
                            ? 'مالك'
                            : isAdmin
                                ? 'مشرف'
                                : 'عضو',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOwner
                              ? ItqanColors.roseGold
                              : isAdmin
                                  ? const Color(0xFF4F46E5)
                                  : ItqanColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Circle Name
                Text(
                  circle.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ItqanColors.ink,
                  ),
                ),

                if (circle.description != null &&
                    circle.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    circle.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ItqanColors.inkSoft,
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Members count info
                Row(
                  children: [
                    const Icon(Icons.group_outlined,
                        size: 16, color: ItqanColors.inkSoft),
                    const SizedBox(width: 6),
                    Text(
                      '${circle.membersCount} ${circle.membersCount == 1 ? "عضو" : "أعضاء"}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: ItqanColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (circle.myRelationship != null &&
                        circle.myRelationship!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: ItqanColors.border,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'صلتك: ${circle.myRelationship}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ItqanColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: ItqanColors.border),
                const SizedBox(height: 12),

                // Role-based action buttons
                Row(
                  children: [
                    if (isOwner || isAdmin) ...[
                      // Owner / Admin Buttons: [لوحة التحكم] [الأعضاء]
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDashboardTap,
                          icon: const Icon(Icons.dashboard_rounded, size: 16),
                          label: const Text('لوحة التحكم'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ItqanColors.emerald,
                            side: const BorderSide(color: ItqanColors.emerald),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onMembersTap,
                          icon: const Icon(Icons.people_outline_rounded,
                              size: 16),
                          label: const Text('الأعضاء'),
                          style: TextButton.styleFrom(
                            foregroundColor: ItqanColors.ink,
                            backgroundColor: ItqanColors.surfaceSoft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Member Buttons: [عرض المهام] [الهمسات]
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onTasksTap,
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 16),
                          label: const Text('عرض المهام'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ItqanColors.emerald,
                            side: const BorderSide(color: ItqanColors.emerald),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onWhispersTap,
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 16),
                          label: const Text('الهمسات'),
                          style: TextButton.styleFrom(
                            foregroundColor: ItqanColors.ink,
                            backgroundColor: ItqanColors.surfaceSoft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

