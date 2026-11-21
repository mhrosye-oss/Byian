import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../domain/circles_providers.dart';
import 'circle_community_features_screen.dart';
import 'circle_khatmah_screen.dart';
import 'create_circle_task_screen.dart';
import 'invite_by_email_dialog.dart';
import 'screens/invitations/circle_invite_qr_screen.dart';
import 'task_details_screen.dart';
import 'widgets/task_tile.dart';

class CircleDashboardScreen extends ConsumerStatefulWidget {
  final Circle circle;
  final int initialTab;

  const CircleDashboardScreen({
    super.key,
    required this.circle,
    this.initialTab = 0,
  });

  @override
  ConsumerState<CircleDashboardScreen> createState() =>
      _CircleDashboardScreenState();
}

class _CircleDashboardScreenState extends ConsumerState<CircleDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    )..addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _handleCompleteTask(
    String taskUuid, {
    String? evidenceUrl,
  }) async {
    try {
      final success = await ref
          .read(circleDashboardProvider(widget.circle.uuid).notifier)
          .completeTask(taskUuid, evidenceUrl: evidenceUrl);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إنجاز المهمة بنجاح! بارك الله فيك'),
            backgroundColor: ItqanColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return success;
    } on CirclesApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor:
                e.statusCode == 409 ? ItqanColors.warning : ItqanColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ، حاول مرة أخرى'),
            backgroundColor: ItqanColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _handleLeaveCircle() async {
    if (widget.circle.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكنك مغادرة الدائرة كمالك وحيد'),
          backgroundColor: ItqanColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد مغادرة الدائرة'),
        content: Text(
          'هل أنت متأكد من مغادرة دائرة "${widget.circle.name}"؟ لن تتمكن من الوصول لمهامها وأنشطتها حتى يُعاد دعوتك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ItqanColors.error,
              foregroundColor: ItqanColors.white,
            ),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLeaving = true);
    try {
      final success = await ref
          .read(circleDashboardProvider(widget.circle.uuid).notifier)
          .leaveCircle();

      if (success && mounted) {
        ref.read(myCirclesProvider.notifier).removeCircle(widget.circle.uuid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت مغادرة الدائرة بنجاح'),
            backgroundColor: ItqanColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on CirclesApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: ItqanColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء المغادرة، حاول ثانية'),
            backgroundColor: ItqanColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLeaving = false);
      }
    }
  }

  Future<void> _showInviteModal() async {
    try {
      final invitation = await ref
          .read(circlesApiProvider)
          .createInvitation(widget.circle.uuid);
      final code =
          (invitation['code'] ?? invitation['token'])?.toString() ?? '';
      if (code.isEmpty) {
        throw const FormatException('لم يتضمن رد الخادم رمز الدعوة');
      }
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => CircleInviteQrScreen(
            circleName: widget.circle.name,
            code: code,
            expiresAt: invitation['expires_at']?.toString() ?? '',
          ),
        ),
      );
    } on CirclesApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: ItqanColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إنشاء الدعوة: $error'),
          backgroundColor: ItqanColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showEmailInviteDialog() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => InviteByEmailDialog(circleUuid: widget.circle.uuid),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الدعوة بالبريد'),
          backgroundColor: ItqanColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync =
        ref.watch(circleDashboardProvider(widget.circle.uuid));
    final currentUserIdAsync = ref.watch(currentUserIdProvider);
    final currentUserId = currentUserIdAsync.valueOrNull;

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: Text(
          widget.circle.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ItqanColors.ink,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ItqanColors.emerald,
          unselectedLabelColor: ItqanColors.inkSoft,
          indicatorColor: ItqanColors.emerald,
          indicatorWeight: 3,
          tabs: const [
            Tab(
                icon: Icon(Icons.analytics_outlined, size: 20),
                text: 'نظرة عامة'),
            Tab(icon: Icon(Icons.people_outline, size: 20), text: 'الأعضاء'),
            Tab(
                icon: Icon(Icons.check_circle_outline, size: 20),
                text: 'المهام'),
            Tab(
                icon: Icon(Icons.chat_bubble_outline, size: 20),
                text: 'الهمسات'),
          ],
        ),
      ),
      floatingActionButton: widget.circle.isOwner && _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateTask(dashboardAsync.valueOrNull),
              backgroundColor: ItqanColors.emerald,
              foregroundColor: ItqanColors.white,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('إنشاء مهمة'),
            )
          : null,
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ItqanColors.emerald),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: ItqanColors.error),
                const SizedBox(height: 16),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ItqanColors.inkSoft),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref
                      .read(
                          circleDashboardProvider(widget.circle.uuid).notifier)
                      .refresh(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ItqanColors.emerald,
                    foregroundColor: ItqanColors.white,
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (dashboard) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Overview
              _buildOverviewTab(dashboard),

              // Tab 2: Members
              _buildMembersTab(dashboard),

              // Tab 3: Tasks
              _buildTasksTab(dashboard, currentUserId),

              // Tab 4: Whispers
              _buildWhispersTab(dashboard),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreateTask(CircleDashboardData? dashboard) async {
    if (dashboard == null) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCircleTaskScreen(
          circleUuid: widget.circle.uuid,
          members: dashboard.members,
        ),
      ),
    );
    if (created == true && mounted) {
      await ref
          .read(circleDashboardProvider(widget.circle.uuid).notifier)
          .refresh();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1: OVERVIEW
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOverviewTab(CircleDashboardData dashboard) {
    final circle = dashboard.circle;
    final isOwner = circle.isOwner;

    return RefreshIndicator(
      color: ItqanColors.emerald,
      onRefresh: () => ref
          .read(circleDashboardProvider(widget.circle.uuid).notifier)
          .refresh(),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Circle Card Info
          Container(
            padding: const EdgeInsets.all(18),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ItqanColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        circle.type.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ItqanColors.emerald,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ItqanColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        circle.privacyLabel,
                        style: const TextStyle(
                            fontSize: 11, color: ItqanColors.inkSoft),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? ItqanColors.roseGold.withValues(alpha: 0.15)
                            : ItqanColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOwner ? 'أنت المالك' : 'عضو في الدائرة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOwner
                              ? ItqanColors.roseGold
                              : ItqanColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  circle.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ItqanColors.ink,
                  ),
                ),
                if (circle.description != null &&
                    circle.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    circle.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ItqanColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'الأعضاء',
                  count: '${dashboard.membersCount}',
                  icon: Icons.people_outline_rounded,
                  color: ItqanColors.emerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'المهام النشطة',
                  count: '${dashboard.tasksCount}',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'المهام المنجزة',
                  count: '${dashboard.completedTasksCount}',
                  icon: Icons.check_circle_outline_rounded,
                  color: ItqanColors.correct,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Card(
            color: ItqanColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: ItqanColors.border),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1A16835B),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: ItqanColors.emerald,
                ),
              ),
              title: const Text(
                'الختمة الجماعية',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.ink,
                ),
              ),
              subtitle: const Text('تابع الأجزاء وسجّل إنجازك'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CircleKhatmahScreen(
                      circleUuid: widget.circle.uuid,
                      canCreate: isOwner,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          Card(
            color: ItqanColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: ItqanColors.border),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1A16835B),
                child: Icon(
                  Icons.diversity_3_rounded,
                  color: ItqanColors.emerald,
                ),
              ),
              title: const Text(
                'أنشطة الدائرة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.ink,
                ),
              ),
              subtitle: const Text('الدعاء، سؤال اليوم، وجلسات الدراسة'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CircleCommunityFeaturesScreen(
                      circleUuid: widget.circle.uuid,
                      canManage: dashboard.circle.isAdmin,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Recent Activities / Highlights
          const Text(
            'آخر النشاطات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ItqanColors.ink,
            ),
          ),
          const SizedBox(height: 12),

          if (dashboard.recentActivities.isEmpty &&
              dashboard.tasks.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ItqanColors.border),
              ),
              child: const Center(
                child: Text(
                  'لا توجد نشاطات مسجلة بعد في هذه الدائرة',
                  style: TextStyle(color: ItqanColors.inkSoft, fontSize: 13),
                ),
              ),
            ),
          ] else ...[
            ...dashboard.recentActivities.take(5).map((act) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: ItqanColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ItqanColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: ItqanColors.roseGold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        act['title']?.toString() ??
                            act['action']?.toString() ??
                            'نشاط إيماني',
                        style: const TextStyle(
                            fontSize: 13, color: ItqanColors.ink),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 36),

          // Leave Circle Button
          // Disabled for owner, enabled for member
          Tooltip(
            message: isOwner
                ? 'أنت مالك الدائرة — لا يمكنك مغادرتها'
                : 'مغادرة الدائرة',
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: (isOwner || _isLeaving) ? null : _handleLeaveCircle,
                icon: _isLeaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ItqanColors.error,
                        ),
                      )
                    : const Icon(Icons.exit_to_app_rounded, size: 20),
                label: Text(
                  isOwner ? 'أنت المالك (لا يمكن المغادرة)' : 'مغادرة الدائرة',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ItqanColors.error,
                  disabledForegroundColor: ItqanColors.muted,
                  side: BorderSide(
                    color: isOwner ? ItqanColors.border : ItqanColors.error,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ItqanColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: ItqanColors.inkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2: MEMBERS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMembersTab(CircleDashboardData dashboard) {
    final members = dashboard.members;
    final isOwner = dashboard.circle.isOwner;
    final canInviteByEmail = dashboard.circle.isAdmin;

    return RefreshIndicator(
      color: ItqanColors.emerald,
      onRefresh: () => ref
          .read(circleDashboardProvider(widget.circle.uuid).notifier)
          .refresh(),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Email invitations are available to circle owners and admins.
          Row(
            children: [
              Text(
                'أعضاء الدائرة (${members.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.ink,
                ),
              ),
              const Spacer(),
              if (canInviteByEmail)
                IconButton(
                  tooltip: 'دعوة بالبريد الإلكتروني',
                  onPressed: _showEmailInviteDialog,
                  icon: const Icon(
                    Icons.email_outlined,
                    color: ItqanColors.emerald,
                  ),
                ),
              if (isOwner)
                ElevatedButton.icon(
                  onPressed: _showInviteModal,
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('دعوة عضو'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ItqanColors.emerald,
                    foregroundColor: ItqanColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (members.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ItqanColors.border),
              ),
              child: const Center(
                child: Text(
                  'لا يوجد أعضاء مسجلون حالياً',
                  style: TextStyle(color: ItqanColors.inkSoft),
                ),
              ),
            ),
          ] else ...[
            ...members.map((member) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: ItqanColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ItqanColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: member.isOwner
                            ? ItqanColors.roseGold.withValues(alpha: 0.15)
                            : ItqanColors.emerald.withValues(alpha: 0.1),
                        child: Text(
                          member.displayName.isNotEmpty
                              ? member.displayName.substring(0, 1)
                              : 'ع',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: member.isOwner
                                ? ItqanColors.roseGold
                                : ItqanColors.emerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: ItqanColors.ink,
                              ),
                            ),
                            if (member.relationshipLabel != null)
                              Text(
                                member.relationshipLabel!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ItqanColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: member.isOwner
                              ? ItqanColors.roseGold.withValues(alpha: 0.15)
                              : ItqanColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          member.roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: member.isOwner
                                ? ItqanColors.roseGold
                                : ItqanColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 3: TASKS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTasksTab(CircleDashboardData dashboard, int? currentUserId) {
    final tasks = dashboard.tasks;

    return RefreshIndicator(
      color: ItqanColors.emerald,
      onRefresh: () => ref
          .read(circleDashboardProvider(widget.circle.uuid).notifier)
          .refresh(),
      child: tasks.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: ItqanColors.emerald.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: ItqanColors.emerald,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد مهام حالياً في الدائرة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ItqanColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ستظهر هنا مهام التلاوة والذكر وحفظ الآيات الخاصة بأعضاء الدائرة.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, color: ItqanColors.inkSoft),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskTile(
                  task: task,
                  currentUserId: currentUserId,
                  onComplete: ({String? evidenceUrl}) =>
                      _handleCompleteTask(task.uuid, evidenceUrl: evidenceUrl),
                  onIncrement: () => ref
                      .read(
                          circleDashboardProvider(widget.circle.uuid).notifier)
                      .incrementTask(task.uuid),
                  onIncrementWithResult: () => ref
                      .read(
                          circleDashboardProvider(widget.circle.uuid).notifier)
                      .incrementTask(task.uuid),
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsScreen(
                          task: task,
                          circleUuid: widget.circle.uuid,
                        ),
                      ),
                    );
                    if (changed == true && mounted) {
                      await ref
                          .read(circleDashboardProvider(widget.circle.uuid)
                              .notifier)
                          .refresh();
                    }
                  },
                );
              },
            ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 4: WHISPERS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildWhispersTab(CircleDashboardData dashboard) {
    final whispers = dashboard.whispers;

    return RefreshIndicator(
      color: ItqanColors.emerald,
      onRefresh: () => ref
          .read(circleDashboardProvider(widget.circle.uuid).notifier)
          .refresh(),
      child: whispers.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: ItqanColors.roseGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: ItqanColors.roseGold,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد همسات واردة بعد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ItqanColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'الهمسات هي رسائل تذكيرية لطيفة بدون إحراج لتشجيع الإخوة والأهل على الطاعة.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, color: ItqanColors.inkSoft),
                    ),
                    const SizedBox(height: 24),
                    Tooltip(
                      message: 'ميزة إرسال الهمسات التلقائية تعمل داخل الدوائر',
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الهمسات متاحة عبر قوالب الدائرة'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('إرسال همسة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ItqanColors.emerald,
                          foregroundColor: ItqanColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: whispers.length,
              itemBuilder: (context, index) {
                final w = whispers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ItqanColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ItqanColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ItqanColors.roseGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: ItqanColors.roseGold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w['content']?.toString() ??
                                  w['text']?.toString() ??
                                  'همسة إيمانية هادئة',
                              style: const TextStyle(
                                fontSize: 14,
                                color: ItqanColors.ink,
                                height: 1.4,
                              ),
                            ),
                            if (w['created_at'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                w['created_at'].toString().split('T').first,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ItqanColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
