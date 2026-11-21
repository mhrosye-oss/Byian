import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../domain/circles_providers.dart';

class InvitationsScreen extends ConsumerStatefulWidget {
  const InvitationsScreen({super.key});

  @override
  ConsumerState<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends ConsumerState<InvitationsScreen> {
  bool _busy = false;

  void _showActionError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: ItqanColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _acceptInvite(Map<String, dynamic> invite) async {
    final id = (invite['uuid'] ?? invite['id'])?.toString();
    if (id == null || id.isEmpty) return;

    setState(() => _busy = true);
    try {
      final success =
          await ref.read(myInvitationsProvider.notifier).acceptInvitation(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم قبول الدعوة بنجاح'),
              backgroundColor: ItqanColors.emerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر قبول الدعوة، حاول مرة أخرى'),
              backgroundColor: ItqanColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) _showActionError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _declineInvite(Map<String, dynamic> invite) async {
    final id = (invite['uuid'] ?? invite['id'])?.toString();
    if (id == null || id.isEmpty) return;

    setState(() => _busy = true);
    try {
      final success =
          await ref.read(myInvitationsProvider.notifier).declineInvitation(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض الدعوة'),
              backgroundColor: ItqanColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر رفض الدعوة، حاول مرة أخرى'),
              backgroundColor: ItqanColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) _showActionError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(myInvitationsProvider);

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: const Text(
          'دعواتي',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ItqanColors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ItqanColors.emerald),
            onPressed: () => ref.read(myInvitationsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: invitesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ItqanColors.emerald),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: ItqanColors.error),
                const SizedBox(height: 16),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(myInvitationsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ItqanColors.emerald,
                    foregroundColor: ItqanColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (invites) {
          if (invites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: ItqanColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.mail_outline_rounded,
                          size: 40, color: ItqanColors.emerald),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'لا توجد دعوات قيد الانتظار',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ItqanColors.ink),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ستظهر هنا الدعوات التي ترسلها لك الدوائر أو الأصدقاء.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ItqanColors.inkSoft),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(myInvitationsProvider.notifier).refresh(),
            color: ItqanColors.emerald,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: invites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final invite = invites[index];
                final circleName = invite['circle_name'] ??
                    invite['circle']?['name'] ??
                    'الدائرة';
                final inviterName = invite['invited_by_name'] ??
                    invite['invited_by']?['name'] ??
                    'مستخدم';
                final message = invite['message'] ?? 'تمت دعوتك للانضمام';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ItqanColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ItqanColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  ItqanColors.emerald.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.group_add_rounded,
                                color: ItqanColors.emerald),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  circleName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: ItqanColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'دعوة من $inviterName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ItqanColors.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ItqanColors.inkSoft,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _busy ? null : () => _declineInvite(invite),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ItqanColors.error,
                                side:
                                    const BorderSide(color: ItqanColors.error),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _busy ? null : () => _acceptInvite(invite),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ItqanColors.emerald,
                                foregroundColor: ItqanColors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('قبول'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
