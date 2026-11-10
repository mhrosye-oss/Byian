import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../application/circle_list_provider.dart';
import '../../domain/circle_models.dart';
import 'circle_dashboard_screen.dart';
import 'create_circle_screen.dart';
import 'join_circle_screen.dart';

class MyCirclesScreen extends ConsumerWidget {
  const MyCirclesScreen({super.key});

  IconData _iconForType(String key) => switch (key) {
        'family' => Icons.home_rounded,
        'classroom' => Icons.school_rounded,
        'study_circle' => Icons.menu_book_rounded,
        'goodness' => Icons.volunteer_activism_rounded,
        'companions' => Icons.groups_rounded,
        _ => Icons.group_rounded,
      };

  Future<void> _startScan(BuildContext context, WidgetRef ref) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _CircleScannerScreen()),
    );
    if (code == null || !context.mounted) return;
    await _previewAndJoin(context, ref, code);
  }

  Future<void> _previewAndJoin(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    try {
      final preview = await ref
          .read(circleApiServiceProvider)
          .previewInvitation(code.trim());
      if (!context.mounted) return;
      final type = preview['circle_type'];
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('دعوة للانضمام'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الدائرة: ${preview['circle_name'] ?? '—'}'),
              const SizedBox(height: 8),
              Text(
                'النوع: ${type is Map ? type['name'] ?? type['key'] : type ?? '—'}',
              ),
              const SizedBox(height: 8),
              Text('الداعي: ${preview['invited_by'] ?? '—'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('انضمام'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await ref.read(circleApiServiceProvider).redeemInvitation(code.trim());
      ref.invalidate(myCirclesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الانضمام إلى الدائرة بنجاح.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر الانضمام: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(myCirclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('دوائري')),
      body: circles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(myCirclesProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(myCirclesProvider.future),
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 100),
                    Icon(
                      Icons.groups_2_outlined,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Center(child: Text('لم تنضم إلى أي دائرة بعد.')),
                    const SizedBox(height: 16),
                    _Actions(
                      onCreate: () => _openCreate(context, ref),
                      onJoin: () => _openJoin(context, ref),
                      onScan: () => _startScan(context, ref),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Actions(
                      onCreate: () => _openCreate(context, ref),
                      onJoin: () => _openJoin(context, ref),
                      onScan: () => _startScan(context, ref),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (circle) => _CircleCard(
                        circle: circle,
                        icon: _iconForType(circle.type?.key ?? ''),
                        onOpen: () => _openDashboard(context, circle),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCircleScreen()),
    );
    if (created == true) ref.invalidate(myCirclesProvider);
  }

  Future<void> _openJoin(BuildContext context, WidgetRef ref) async {
    final joined = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const JoinCircleScreen()),
    );
    if (joined == true) ref.invalidate(myCirclesProvider);
  }

  Future<void> _openDashboard(BuildContext context, Circle circle) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CircleDashboardScreen(uuid: circle.uuid, name: circle.name),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onCreate,
    required this.onJoin,
    required this.onScan,
  });
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء دائرة'),
          ),
          OutlinedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('مسح باركود'),
          ),
          OutlinedButton.icon(
            onPressed: onJoin,
            icon: const Icon(Icons.key_rounded),
            label: const Text('الانضمام بكود'),
          ),
        ],
      );
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({
    required this.circle,
    required this.icon,
    required this.onOpen,
  });
  final Circle circle;
  final IconData icon;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    circle.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _RoleBadge(role: circle.myRole ?? 'member'),
              ],
            ),
            if (circle.type?.name case final typeName?
                when typeName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(typeName, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (circle.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(circle.description!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 6),
                Text('${circle.membersCount} أعضاء'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login_rounded, size: 20),
                label: const Text(
                  'الدخول مباشرة',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: onOpen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (role) {
      'owner' => ('مالك', Colors.amber.shade100, Colors.amber.shade900),
      'admin' => ('مشرف', Colors.orange.shade100, Colors.orange.shade900),
      'member' => ('عضو', Colors.blue.shade100, Colors.blue.shade900),
      _ => (role, Colors.grey.shade200, Colors.grey.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 52),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}

class _CircleScannerScreen extends StatefulWidget {
  const _CircleScannerScreen();
  @override
  State<_CircleScannerScreen> createState() => _CircleScannerScreenState();
}

class _CircleScannerScreenState extends State<_CircleScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مسح كود الدعوة')),
        body: MobileScanner(
          onDetect: (capture) {
            if (_handled || capture.barcodes.isEmpty) return;
            final code = capture.barcodes.first.rawValue;
            if (code == null || code.trim().isEmpty) return;
            _handled = true;
            Navigator.pop(context, code);
          },
        ),
      );
}
