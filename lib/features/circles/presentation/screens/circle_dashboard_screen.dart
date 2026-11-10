import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:itqan/features/adhkar/screens/adhkar_screen.dart';
import 'package:itqan/features/adhkar/screens/duas_screen.dart';
import 'package:itqan/features/khatmah/screens/khatmah_screen.dart';
import 'package:itqan/features/mushaf/mushaf_screen.dart';
import 'package:itqan/features/tasbih/screens/smart_tasbih_screen.dart';

import '../../application/circle_list_provider.dart';
import 'circle_members_screen.dart';

class CircleDashboardScreen extends ConsumerStatefulWidget {
  const CircleDashboardScreen({super.key, required this.uuid, this.name});
  final String uuid;
  final String? name;

  @override
  ConsumerState<CircleDashboardScreen> createState() =>
      _CircleDashboardScreenState();
}

class _CircleDashboardScreenState extends ConsumerState<CircleDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboard;
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    _dashboard = ref.read(circleApiServiceProvider).getDashboard(widget.uuid);
  }

  Future<void> _refresh() async {
    final future = ref.read(circleApiServiceProvider).getDashboard(widget.uuid);
    setState(() => _dashboard = future);
    await future;
  }

  void _openWhispers() => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('ستتوفر الهمسات قريبًا.')));

  Future<void> _showInviteDialog() async {
    setState(() => _inviting = true);
    try {
      final result =
          await ref.read(circleApiServiceProvider).generateInvite(widget.uuid);
      if (!mounted) return;
      final code = result['code']?.toString() ?? '';
      final expiresAt = result['expires_at']?.toString() ?? '';
      if (code.isEmpty) {
        throw const FormatException('لم يصل كود الدعوة من الخادم.');
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('دعوة إلى ${widget.name ?? 'الدائرة'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: code,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                if (expiresAt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'صالح حتى: ${_formatDate(expiresAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الكود.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ'),
            ),
            TextButton.icon(
              onPressed: () => Share.share(
                'انضم إلى دائرتي على تطبيق إتقان\nكود الدعوة: $code',
                subject: 'دعوة للانضمام',
              ),
              icon: const Icon(Icons.share_rounded),
              label: const Text('مشاركة'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر إنشاء الدعوة: $error')));
      }
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _openService(String label) {
    final Widget? page = switch (label) {
      'مصحف' => const MushafScreen(),
      'تسبيح' => const SmartTasbihScreen(),
      'أذكار' => const AdhkarScreen(),
      'أدعية' => const DuasScreen(),
      'ختمة' => const KhatmahScreen(),
      _ => null,
    };
    if (page == null) {
      _openWhispers();
    } else {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.name ?? 'لوحة الدائرة')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _inviting ? null : _showInviteDialog,
          icon: _inviting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.person_add_rounded),
          label: const Text('دعوة'),
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _dashboard,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تعذر تحميل الدائرة: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final data = snapshot.data ?? const <String, dynamic>{};
            final members = data['members'] is List
                ? List<Map<String, dynamic>>.from(
                    (data['members'] as List).whereType<Map>().map(
                          (e) => Map<String, dynamic>.from(e),
                        ),
                  )
                : <Map<String, dynamic>>[];
            final activities = data['activities'] is List
                ? List<Map<String, dynamic>>.from(
                    (data['activities'] as List).whereType<Map>().map(
                          (e) => Map<String, dynamic>.from(e),
                        ),
                  )
                : <Map<String, dynamic>>[];
            final name = '${data['name'] ?? widget.name ?? 'الدائرة'}';
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  _buildHeader(context, name, data, members.length),
                  _buildServicesGrid(context),
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'الأعضاء',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CircleMembersScreen(circleUuid: widget.uuid),
                            ),
                          ),
                          child: const Text('عرض الكل'),
                        ),
                      ],
                    ),
                  ),
                  if (members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد معلومات أعضاء للعرض.'),
                    )
                  else
                    ...members.take(4).map(
                          (member) => ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(
                              '${member['name'] ?? member['user']?['name'] ?? 'عضو'}',
                            ),
                            subtitle: Text(
                              _roleLabel('${member['role'] ?? 'member'}'),
                            ),
                          ),
                        ),
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'آخر الأنشطة',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (activities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد أنشطة بعد.'),
                    )
                  else
                    ...activities.take(5).map(
                          (activity) => ListTile(
                            leading: const Icon(Icons.auto_awesome_outlined),
                            title: Text(
                              '${activity['description'] ?? activity['event_type'] ?? 'نشاط جديد'}',
                            ),
                            subtitle: Text(
                              _formatDate('${activity['created_at'] ?? ''}'),
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      );

  Widget _buildHeader(
    BuildContext context,
    String name,
    Map<String, dynamic> data,
    int memberCount,
  ) =>
      Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: Icon(Icons.groups_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${data['type'] is Map ? data['type']['name'] ?? '' : data['type'] ?? ''} · $memberCount أعضاء',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildServicesGrid(BuildContext context) {
    final services = <_ServiceItem>[
      _ServiceItem(Icons.menu_book_rounded, 'مصحف', const Color(0xFF0A7A49)),
      _ServiceItem(Icons.fingerprint_rounded, 'تسبيح', Colors.amber.shade800),
      _ServiceItem(Icons.auto_awesome_rounded, 'أذكار', Colors.teal),
      _ServiceItem(Icons.pan_tool_rounded, 'أدعية', Colors.indigo),
      _ServiceItem(Icons.auto_stories_rounded, 'ختمة', Colors.purple),
      _ServiceItem(Icons.forum_rounded, 'همسات', Colors.pink),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'خدمات الدائرة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: services.length,
          itemBuilder: (context, i) => _buildServiceCard(context, services[i]),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, _ServiceItem item) => InkWell(
        onTap: () => _openService(item.label),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 34, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.color,
                ),
              ),
            ],
          ),
        ),
      );

  String _roleLabel(String role) => switch (role) {
        'owner' => 'مالك',
        'admin' => 'مشرف',
        _ => 'عضو',
      };
}

class _ServiceItem {
  const _ServiceItem(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}
