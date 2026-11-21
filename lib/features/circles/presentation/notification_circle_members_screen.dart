import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../application/circle_context_provider.dart';
import 'screens/members/circle_members_screen.dart';

class NotificationCircleMembersScreen extends ConsumerStatefulWidget {
  const NotificationCircleMembersScreen({
    super.key,
    required this.circleUuid,
  });

  final String circleUuid;

  @override
  ConsumerState<NotificationCircleMembersScreen> createState() =>
      _NotificationCircleMembersScreenState();
}

class _NotificationCircleMembersScreenState
    extends ConsumerState<NotificationCircleMembersScreen> {
  String? _circleName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCircle();
  }

  Future<void> _loadCircle() async {
    setState(() => _error = null);
    try {
      await ref
          .read(activeCircleContextProvider.notifier)
          .selectCircle(widget.circleUuid);
      if (!mounted) return;
      final circleName =
          ref.read(activeCircleContextProvider)?.circle.name.trim() ?? '';
      if (circleName.isEmpty) {
        throw StateError('لم يتضمن رد الدائرة اسمها');
      }
      await ref
          .read(circleMembersProvider.notifier)
          .loadMembers(widget.circleUuid);
      if (!mounted) return;
      setState(() => _circleName = circleName);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final circleName = _circleName;
    if (circleName != null) {
      return CircleMembersScreen(
        circleUuid: widget.circleUuid,
        circleName: circleName,
      );
    }

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator(color: ItqanColors.emerald)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تعذر فتح أعضاء الدائرة: $_error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadCircle,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
