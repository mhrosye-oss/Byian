import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itqan/core/services/auth_service.dart';
import 'package:itqan/core/theme/colors.dart';
import 'package:itqan/features/circles/application/circle_context_provider.dart';
import 'package:itqan/features/circles/data/circle_api_service.dart';
import 'package:itqan/features/circles/domain/circle_models.dart';

/// نقطة نور تتنفس هادئة تعبر عن وجود همسة روحية
class WhisperBreathingDot extends StatefulWidget {
  final VoidCallback onTap;

  const WhisperBreathingDot({super.key, required this.onTap});

  @override
  State<WhisperBreathingDot> createState() => _WhisperBreathingDotState();
}

class _WhisperBreathingDotState extends State<WhisperBreathingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glowScale = 1.0 + (_controller.value * 0.4);
        final opacity = 0.5 + (_controller.value * 0.45);

        return InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ItqanColors.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37)
                      .withValues(alpha: 0.18 * glowScale),
                  blurRadius: 10 * glowScale,
                  spreadRadius: 2 * _controller.value,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8C87A).withValues(alpha: opacity),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8C87A)
                            .withValues(alpha: opacity * 0.8),
                        blurRadius: 6 * glowScale,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'همسات الدائرة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ItqanColors.ink,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// نافذة الهمسات الروحية الهادئة
class WhispersModalSheet extends ConsumerStatefulWidget {
  final String circleUuid;

  const WhispersModalSheet({super.key, required this.circleUuid});

  @override
  ConsumerState<WhispersModalSheet> createState() => _WhispersModalSheetState();
}

class _WhispersModalSheetState extends ConsumerState<WhispersModalSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(circleWhispersProvider.notifier)
            .loadWhispers(widget.circleUuid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final whispersAsync = ref.watch(circleWhispersProvider);
    final circleContext = ref.watch(activeCircleContextProvider);
    final canSend = circleContext?.can('whispers.send') ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.light_mode_outlined,
                      color: Color(0xFFD4AF37), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'الهمسات الروحية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ItqanColors.ink,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              IconButton(
                icon:
                    const Icon(Icons.close, size: 20, color: ItqanColors.muted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'تواصل روحي هادئ قائم على قوالب الخير.. بلا مؤشرات قراءة أو تتبع',
            style: TextStyle(
              fontSize: 12,
              color: ItqanColors.muted,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 16),
          whispersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: ItqanColors.emerald),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                'تعذر تحميل الهمسات: $e',
                style: const TextStyle(color: ItqanColors.error, fontSize: 13),
              ),
            ),
            data: (whispers) {
              if (whispers.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: const Text(
                    'لا توجد همسات نشطة حالياً.',
                    style: TextStyle(
                        color: ItqanColors.muted, fontFamily: 'Tajawal'),
                  ),
                );
              }

              return Column(
                children:
                    whispers.map((w) => _WhisperCard(whisper: w)).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          if (canSend)
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _openSendDialog(ref),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('إرسال همسة من القوالب المعتمدة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ItqanColors.emerald,
                  side: const BorderSide(color: ItqanColors.emerald),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _openSendDialog(WidgetRef ref) async {
    final api = ref.read(circleApiServiceProvider);
    try {
      final templates = await api.fetchWhisperTemplates();
      if (!mounted) return;
      final members = await api.fetchMembers(widget.circleUuid);
      if (!mounted) return;
      final currentUserId = await AuthService.getUserId();
      if (!mounted) return;
      if (currentUserId == null) {
        throw const CircleApiException(
          401,
          'تعذر تحديد حسابك الحالي. أعد تسجيل الدخول وحاول مجدداً.',
        );
      }
      if (templates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد قوالب همسات متاحة حالياً')),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('اختر قالباً معتمداً للهمسة',
              style: TextStyle(fontFamily: 'Tajawal')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: templates.map((template) {
                return Card(
                  child: ListTile(
                    leading: _buildTemplateIcon(template['icon']?.toString()),
                    title: Text(
                      template['text_ar'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(c);
                      final sent = await _openWhisperSendDialog(
                        context,
                        api,
                        template,
                        members
                            .where((member) =>
                                member.userId != null &&
                                member.userId != currentUserId)
                            .toList(),
                      );
                      if (sent == true && mounted) {
                        await ref
                            .read(circleWhispersProvider.notifier)
                            .loadWhispers(widget.circleUuid);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تم إرسال الهمسة بنجاح')),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل بيانات إرسال الهمسة: $e')),
        );
      }
    }
  }

  Future<bool?> _openWhisperSendDialog(
    BuildContext context,
    CircleApiService api,
    Map<String, dynamic> template,
    List<CircleMemberModel> members,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _WhisperSendDialog(
        template: template,
        members: members.where((member) => member.userId != null).toList(),
        onSend: ({
          required int? recipientUserId,
          required bool isAnonymous,
          required String messageText,
        }) =>
            api.sendWhisper(
          widget.circleUuid,
          templateKey: template['key'].toString(),
          recipientUserId: recipientUserId,
          isAnonymous: isAnonymous,
          messageText: messageText,
        ),
      ),
    );
  }

  Widget _buildTemplateIcon(String? icon) {
    switch (icon?.toLowerCase()) {
      case 'mosque':
      case 'prayer':
        return const Icon(Icons.mosque_rounded);
      case 'heart':
      case 'favorite':
        return const Icon(Icons.favorite_rounded);
      case 'book':
      case 'quran':
        return const Icon(Icons.menu_book_rounded);
      case 'star':
      case 'sparkles':
        return const Icon(Icons.auto_awesome_rounded);
      case 'hands':
      case 'dua':
        return const Icon(Icons.volunteer_activism_rounded);
      default:
        return icon == null || icon.trim().isEmpty
            ? const Icon(Icons.light_mode_outlined)
            : Text(icon, style: const TextStyle(fontSize: 22));
    }
  }
}

class _WhisperSendDialog extends StatefulWidget {
  const _WhisperSendDialog({
    required this.template,
    required this.members,
    required this.onSend,
  });

  final Map<String, dynamic> template;
  final List<CircleMemberModel> members;
  final Future<void> Function({
    required int? recipientUserId,
    required bool isAnonymous,
    required String messageText,
  }) onSend;

  @override
  State<_WhisperSendDialog> createState() => _WhisperSendDialogState();
}

class _WhisperSendDialogState extends State<_WhisperSendDialog> {
  final _messageController = TextEditingController();
  int? _recipientUserId;
  bool _isAnonymous = true;
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await widget.onSend(
        recipientUserId: _recipientUserId,
        isAnonymous: _isAnonymous,
        messageText: _messageController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'تعذر إرسال الهمسة: $error');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إرسال الهمسة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.template['text_ar'].toString(),
              style: const TextStyle(height: 1.5, fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _recipientUserId ?? 0,
              decoration: const InputDecoration(labelText: 'المستلم'),
              items: [
                const DropdownMenuItem(
                    value: 0, child: Text('جميع أعضاء الدائرة')),
                ...widget.members.map(
                  (member) => DropdownMenuItem(
                    value: member.userId,
                    child: Text(
                      member.displayName.trim().isEmpty
                          ? 'مستخدم ${member.userId}'
                          : member.displayName.trim(),
                    ),
                  ),
                ),
              ],
              onChanged: _isSending
                  ? null
                  : (value) => setState(
                        () => _recipientUserId = value == 0 ? null : value,
                      ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('إرسال مجهول الهوية'),
              value: _isAnonymous,
              onChanged: _isSending
                  ? null
                  : (value) => setState(() => _isAnonymous = value),
            ),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'رسالة إضافية (اختيارية)',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: ItqanColors.error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isSending ? null : _send,
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إرسال'),
        ),
      ],
    );
  }
}

class _WhisperCard extends ConsumerWidget {
  final CircleWhisperModel whisper;

  const _WhisperCard({required this.whisper});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ItqanColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ItqanColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote_rounded,
                  color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  whisper.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ItqanColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (whisper.hasResponded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ItqanColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: ItqanColors.emerald, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'تم تسجيل ردك الطيب',
                    style: TextStyle(
                      fontSize: 11,
                      color: ItqanColors.emerald,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              children: whisper.allowedResponses.map((r) {
                return ActionChip(
                  label: Text(r.label,
                      style:
                          const TextStyle(fontSize: 12, fontFamily: 'Tajawal')),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: ItqanColors.border),
                  onPressed: () {
                    ref
                        .read(circleWhispersProvider.notifier)
                        .respond(whisper.uuid, r.key);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
