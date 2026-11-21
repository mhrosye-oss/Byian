import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../domain/circles_providers.dart';

class InviteByEmailDialog extends ConsumerStatefulWidget {
  final String circleUuid;

  const InviteByEmailDialog({super.key, required this.circleUuid});

  @override
  ConsumerState<InviteByEmailDialog> createState() =>
      _InviteByEmailDialogState();
}

class _InviteByEmailDialogState extends ConsumerState<InviteByEmailDialog> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _users = const [];
  Map<String, dynamic>? _user;
  bool _isSearching = false;
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'أدخل بريدًا إلكترونيًا صالحًا');
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
      _users = const [];
      _user = null;
    });
    try {
      final results = await ref.read(circlesApiProvider).searchCircleUsers(
            widget.circleUuid,
            email: email,
          );
      final users = <Map<String, dynamic>>[];
      for (final result in results) {
        final rawId = result['id'] ?? result['user_id'];
        final userId =
            rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
        if (userId != null) users.add({...result, 'id': userId});
      }
      if (mounted) {
        setState(() {
          _users = users;
          if (users.isEmpty) {
            _error = 'لم يتم العثور على حساب بهذا البريد.';
          } else {
            _user = users.first;
          }
        });
      }
    } on CirclesApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر البحث: $error');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _send() async {
    final userId = _user?['id'];
    if (userId is! int || _isSending) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await ref.read(circlesApiProvider).sendDirectInvitation(
            circleUuid: widget.circleUuid,
            userId: userId,
            message: _messageController.text,
          );
      if (mounted) Navigator.pop(context, true);
    } on CirclesApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر إرسال الدعوة: $error');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('دعوة عبر البريد الإلكتروني'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                suffixIcon: IconButton(
                  tooltip: 'بحث',
                  onPressed: _isSearching ? null : _search,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: ItqanColors.error,
                  fontSize: 13,
                ),
              ),
            ],
            if (_users.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final user in _users) _userTile(user),
            ],
            if (_user != null &&
                _user?['is_member'] != true &&
                _user?['has_pending_invitation'] != true) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _messageController,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'رسالة اختيارية',
                ),
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
        if (_user != null &&
            _user?['is_member'] != true &&
            _user?['has_pending_invitation'] != true)
          ElevatedButton(
            onPressed: _isSending ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: ItqanColors.emerald,
              foregroundColor: ItqanColors.white,
            ),
            child: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ItqanColors.white,
                    ),
                  )
                : const Text('إرسال الدعوة'),
          ),
      ],
    );
  }

  Widget _userTile(Map<String, dynamic> user) {
    final isMember = user['is_member'] == true;
    final hasPendingInvitation = user['has_pending_invitation'] == true;
    final selected = _user?['id'] == user['id'];
    final name = user['name']?.toString().trim();
    final maskedEmail = user['email_masked']?.toString().trim();
    final email = user['email']?.toString().trim();
    final displayName = name?.isNotEmpty == true
        ? name!
        : maskedEmail?.isNotEmpty == true
            ? maskedEmail!
            : email?.isNotEmpty == true
                ? email!
                : 'مستخدم';
    final status = isMember
        ? 'عضو بالفعل في الدائرة'
        : hasPendingInvitation
            ? 'لديه دعوة معلّقة بالفعل'
            : user['email_masked']?.toString() ??
                user['email']?.toString() ??
                '';

    return Card(
      color: selected ? ItqanColors.emerald.withValues(alpha: 0.08) : null,
      child: ListTile(
        selected: selected,
        enabled: !isMember && !hasPendingInvitation,
        onTap: isMember || hasPendingInvitation
            ? null
            : () => setState(() {
                  _user = user;
                  _error = null;
                }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: CircleAvatar(
          child: Icon(
            isMember
                ? Icons.check_rounded
                : hasPendingInvitation
                    ? Icons.hourglass_top_rounded
                    : Icons.person_outline_rounded,
          ),
        ),
        title: Text(
          displayName,
          textDirection:
              displayName.contains('@') ? TextDirection.ltr : TextDirection.rtl,
        ),
        subtitle: Text(
          status,
          textDirection: isMember || hasPendingInvitation
              ? TextDirection.rtl
              : TextDirection.ltr,
        ),
        trailing: selected ? const Icon(Icons.check_circle_rounded) : null,
      ),
    );
  }
}
