import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// شريط علوي موحد لشاشات معلّم القرآن بتصميم إتقان
class TeacherAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;

  const TeacherAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: ItqanTypography.uiFont,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ItqanColors.ink,
        ),
      ),
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'رجوع',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: ItqanColors.ink,
                    size: 16,
                  ),
                ),
              ),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// بطاقة خدمة موحدة لخدمات معلّم القرآن
class TeacherServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final String? badgeText;
  final Color accentColor;

  const TeacherServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.badgeText,
    this.accentColor = ItqanColors.emerald,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: ItqanColors.ink.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const Spacer(),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontFamily: ItqanTypography.uiFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Theme.of(context).hintColor,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ItqanColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontSize: 12,
                      height: 1.35,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? ItqanColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة إحصاءات ملخصة لتقدم المستخدم في الحفظ والمراجعة
class TeacherStatsBanner extends StatelessWidget {
  final int totalMemorizedSessions;
  final int totalRevisionSessions;
  final String lastSurahName;

  const TeacherStatsBanner({
    super.key,
    required this.totalMemorizedSessions,
    required this.totalRevisionSessions,
    required this.lastSurahName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            ItqanColors.emerald,
            ItqanColors.emeraldDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ItqanColors.emerald.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildItem(
              context,
              label: 'جلسات الحفظ',
              value: '$totalMemorizedSessions',
              icon: Icons.book_rounded,
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _buildItem(
              context,
              label: 'جلسات المراجعة',
              value: '$totalRevisionSessions',
              icon: Icons.replay_rounded,
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _buildItem(
              context,
              label: 'آخر محفوظ',
              value: lastSurahName.isNotEmpty ? lastSurahName : '—',
              icon: Icons.bookmark_added_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: ItqanTypography.uiFont,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontFamily: ItqanTypography.uiFont,
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// مؤشر تحميل موحد
class TeacherLoadingWidget extends StatelessWidget {
  final String? message;

  const TeacherLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: ItqanColors.emerald),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: const TextStyle(
                fontFamily: ItqanTypography.uiFont,
                fontSize: 14,
                color: ItqanColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// حالة فارغة موحدة
class TeacherEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TeacherEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: ItqanColors.emerald.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: ItqanColors.emerald),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: ItqanTypography.uiFont,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: ItqanColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: ItqanTypography.uiFont,
                fontSize: 13,
                color: ItqanColors.muted,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: ItqanColors.emerald,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontFamily: ItqanTypography.uiFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// حالة خطأ موحدة
class TeacherErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TeacherErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: ItqanColors.roseGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: ItqanColors.roseGold,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: ItqanTypography.uiFont,
                fontSize: 14,
                color: ItqanColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: ItqanTypography.uiFont),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ItqanColors.emerald,
                side: const BorderSide(color: ItqanColors.emerald),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Re-export old names for backwards compatibility
typedef BaseAppBar = TeacherAppBar;
typedef ServiceCard = TeacherServiceCard;
typedef LoadingWidget = TeacherLoadingWidget;
typedef EmptyState = TeacherEmptyState;
typedef ErrorState = TeacherErrorState;
