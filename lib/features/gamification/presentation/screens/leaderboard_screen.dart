import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/itqan_points_icon.dart';
import '../../application/gamification_provider.dart';
import '../../domain/models/gamification_models.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(gamificationProvider.notifier).refreshLeaderboard());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gamificationProvider);
    final data = state.leaderboard;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text(
          'لوحة المتصدرين في إتقان',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0A5C36),
        onRefresh: () =>
            ref.read(gamificationProvider.notifier).refreshLeaderboard(),
        child: data == null
            ? ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: state.error != null
                        ? Column(
                            children: [
                              Text(state.error!),
                              TextButton(
                                onPressed: () => ref
                                    .read(gamificationProvider.notifier)
                                    .refreshLeaderboard(),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(color: Color(0xFF0A5C36)),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // بطاقة تقديمية
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A5C36), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(Icons.emoji_events_rounded, color: Color(0xFFD4AF37), size: 36),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'العشرة الأوائل في الخير والإتقان',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'وفي ذلك فليتنافس المتنافسون',
                                style: TextStyle(color: Color(0xFFFFF4D0), fontSize: 12),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (data.top.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('لا توجد نتائج لعرضها حالياً'),
                      ),
                    ),

                  // عرض العشرة الأوائل
                  ...data.top.map((entry) => _buildLeaderboardTile(context, entry, data.me.userId)),

                  const SizedBox(height: 14),

                  // بطاقة موقع المستخدم الحالي
                  if (data.me.rank == null)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: const ListTile(
                        leading: Icon(Icons.info_outline, color: Color(0xFF0A5C36)),
                        title: Text('لم تسجل نشاطاً بعد؛ ابدأ مهامك لتظهر في اللوحة!'),
                      ),
                    ),

                  if (data.me.rank != null && !data.me.inTop)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0A5C36), width: 1.5),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF0A5C36),
                            child: Text(
                              '${data.me.rank}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مركزك الحالي: #${data.me.rank}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  textDirection: TextDirection.rtl,
                                ),
                                Text(
                                  'المستوى ${data.me.level} • ${data.me.levelTitle}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F685F)),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                          ItqanPointsBadge(points: data.me.score),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _buildLeaderboardTile(BuildContext context, LeaderboardEntry entry, int me) {
    final isMe = entry.userId == me;
    final isTopThree = entry.rank <= 3;

    Color rankColor;
    IconData? rankIcon;
    if (entry.rank == 1) {
      rankColor = const Color(0xFFD4AF37); // ذهبي
      rankIcon = Icons.military_tech_rounded;
    } else if (entry.rank == 2) {
      rankColor = const Color(0xFF9E9E9E); // فضي
      rankIcon = Icons.military_tech_rounded;
    } else if (entry.rank == 3) {
      rankColor = const Color(0xFFCD7F32); // برونزي
      rankIcon = Icons.military_tech_rounded;
    } else {
      rankColor = const Color(0xFF0A5C36);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? const Color(0xFF0A5C36)
              : (isTopThree ? rankColor.withValues(alpha: 0.5) : const Color(0xFFE7E0D5)),
          width: isMe || isTopThree ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isTopThree ? rankColor.withValues(alpha: 0.15) : const Color(0xFFF9F6F0),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 1.5),
            ),
            child: Center(
              child: isTopThree
                  ? Icon(rankIcon, color: rankColor, size: 20)
                  : Text(
                      '${entry.rank}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                        color: const Color(0xFF202B24),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A5C36),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'أنت',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'المستوى ${entry.level} • ${entry.levelTitle}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5F685F)),
                ),
              ],
            ),
          ),
          ItqanPointsBadge(points: entry.score),
        ],
      ),
    );
  }
}
