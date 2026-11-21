import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itqan/core/theme/colors.dart';
import 'package:itqan/features/circles/application/circle_context_provider.dart';
import 'package:itqan/features/circles/domain/circle_models.dart';
import '../invitations/circle_invite_qr_screen.dart';

class CircleMembersScreen extends ConsumerWidget {
  final String circleUuid;
  final String circleName;

  const CircleMembersScreen({
    super.key,
    required this.circleUuid,
    required this.circleName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(circleMembersProvider);
    final circleContext = ref.watch(activeCircleContextProvider);
    final currentUserId = ref.watch(circleCurrentUserIdProvider).valueOrNull;
    final canInvite = circleContext?.can('members.invite') ?? false;
    final isOwner = const {'owner', 'leader'}
        .contains(circleContext?.circle.myRoleKey?.toLowerCase());

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        title: Text('أعضاء $circleName',
            style: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        backgroundColor: ItqanColors.cream,
        elevation: 0,
      ),
      body: membersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: ItqanColors.emerald)),
        error: (e, _) => Center(
            child: Text('تعذر تحميل الأعضاء: $e',
                style: const TextStyle(color: ItqanColors.error))),
        data: (members) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (circleContext != null && !isOwner) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _leaveCircle(context, ref),
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('مغادرة الدائرة'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (canInvite) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openInviteDialog(context, ref),
                        icon: const Icon(Icons.person_add_alt_1_rounded,
                            size: 18),
                        label: const Text('دعوة عضو (كود / QR)',
                            style: TextStyle(fontFamily: 'Tajawal')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ItqanColors.emerald,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openAddChildDialog(context, ref),
                        icon: const Icon(Icons.child_care_rounded, size: 18),
                        label: const Text('إضافة طفل',
                            style: TextStyle(fontFamily: 'Tajawal')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ItqanColors.emerald,
                          side: const BorderSide(color: ItqanColors.emerald),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'الأعضاء (${members.length})',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ItqanColors.ink,
                    fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 12),
              ...members.map(
                (member) => _MemberCard(
                  member: member,
                  isOwner: isOwner,
                  isCurrentUser:
                      currentUserId != null && member.userId == currentUserId,
                  onManage: isOwner &&
                          currentUserId != null &&
                          currentUserId != member.userId &&
                          member.userId != null
                      ? (action) => _manageMember(context, ref, member, action)
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _leaveCircle(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مغادرة الدائرة'),
        content: Text('هل تريد مغادرة دائرة "$circleName"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(circleApiServiceProvider).leaveCircle(circleUuid);
      ref.invalidate(myCirclesProvider);
      ref.read(activeCircleContextProvider.notifier).clearContext();
      if (context.mounted) Navigator.pop(context, true);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  Future<void> _manageMember(
    BuildContext context,
    WidgetRef ref,
    CircleMemberModel member,
    String action,
  ) async {
    final userId = member.userId;
    if (userId == null) return;

    final actionLabel = switch (action) {
      'remove' => 'إزالة ${member.displayName} من الدائرة',
      'promote' => 'ترقية ${member.displayName} إلى مشرف',
      'transfer' => 'نقل ملكية الدائرة إلى ${member.displayName}',
      _ => '',
    };
    if (actionLabel.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الإجراء'),
        content: Text('هل تريد $actionLabel؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final api = ref.read(circleApiServiceProvider);
      switch (action) {
        case 'remove':
          await api.removeCircleMember(circleUuid, userId);
          break;
        case 'promote':
          await api.updateCircleMemberRole(
            circleUuid,
            userId: userId,
            role: 'admin',
          );
          break;
        case 'transfer':
          await api.transferCircleOwnership(
            circleUuid,
            newOwnerId: userId,
          );
          break;
      }
      await ref.read(circleMembersProvider.notifier).loadMembers(circleUuid);
      if (action == 'transfer') {
        await ref
            .read(activeCircleContextProvider.notifier)
            .selectCircle(circleUuid);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  void _openInviteDialog(BuildContext context, WidgetRef ref) async {
    final roleCtrl = TextEditingController(text: 'member');
    final relCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('توليد دعوة انضمام',
            style: TextStyle(fontFamily: 'Tajawal')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: relCtrl,
              decoration: const InputDecoration(
                labelText: 'العلاقة / الصلة (مثال: ابن، طالب، رفيق)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              try {
                final api = ref.read(circleApiServiceProvider);
                final inv = await api.createInvitation(
                  circleUuid,
                  role: roleCtrl.text,
                  relationship: relCtrl.text.isNotEmpty ? relCtrl.text : null,
                );
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CircleInviteQrScreen(
                      circleName: circleName,
                      code: inv['token'] ?? '',
                      expiresAt: inv['expires_at'] ?? '',
                    ),
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: ItqanColors.emerald,
                foregroundColor: Colors.white),
            child: const Text('توليد الكود'),
          ),
        ],
      ),
    );
  }

  void _openAddChildDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController(text: 'son');

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('إضافة ملف طفل للعائلة',
            style: TextStyle(fontFamily: 'Tajawal')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم الطفل المعروض',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relCtrl,
              decoration: const InputDecoration(
                labelText: 'العلاقة (مثال: ابن، ابنة)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(c);
              try {
                final api = ref.read(circleApiServiceProvider);
                await api.createManagedProfile(
                  circleUuid,
                  displayName: nameCtrl.text.trim(),
                  ageGroup: 'child',
                  relationship: relCtrl.text.trim(),
                );
                ref
                    .read(circleMembersProvider.notifier)
                    .loadMembers(circleUuid);
                ref.invalidate(myCirclesProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: ItqanColors.emerald,
                foregroundColor: Colors.white),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final CircleMemberModel member;
  final bool isOwner;
  final bool isCurrentUser;
  final ValueChanged<String>? onManage;

  const _MemberCard({
    required this.member,
    required this.isOwner,
    required this.isCurrentUser,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final isChild = member.isManagedProfile || member.ageGroup == 'child';
    final displayName = member.displayName.trim();
    final avatarInitial = displayName.isNotEmpty ? displayName[0] : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ItqanColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isChild
                ? const Color(0xFFFFF4D0)
                : ItqanColors.emerald.withValues(alpha: 0.12),
            child: Text(
              avatarInitial,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isChild ? const Color(0xFFD4AF37) : ItqanColors.emerald,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: ItqanColors.ink,
                      fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (member.relationshipName != null) ...[
                      Text(
                        member.relationshipName!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: ItqanColors.emerald,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Tajawal'),
                      ),
                      const SizedBox(width: 8),
                      const Text('•',
                          style: TextStyle(color: ItqanColors.muted)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      member.roleNames.join('، '),
                      style: const TextStyle(
                          fontSize: 12,
                          color: ItqanColors.muted,
                          fontFamily: 'Tajawal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isCurrentUser && isOwner)
            const Text(
              'أنت المالك',
              style: TextStyle(
                color: ItqanColors.emerald,
                fontWeight: FontWeight.bold,
              ),
            )
          else if (onManage != null)
            PopupMenuButton<String>(
              onSelected: onManage,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'remove',
                  child: Text('إزالة العضو'),
                ),
                PopupMenuItem(
                  value: 'promote',
                  child: Text('ترقية إلى مشرف'),
                ),
                PopupMenuItem(
                  value: 'transfer',
                  child: Text('نقل الملكية'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
