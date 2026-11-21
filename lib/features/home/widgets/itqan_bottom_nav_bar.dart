import 'package:flutter/material.dart';

/// شريط الفوتر العائم المخصص لتطبيق إتقان
/// مطابق للتصميم المرفق بالصورة بدقة:
/// [الرئيسية (كبسولة خضراء)] - [الصلاة (هلال)] - [المصحف (مربع ذهبي بارز)] - [التسبيح (بصمة)] - [المزيد (شبكة)]
class ItqanBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenMushaf;
  final VoidCallback onOpenPrayer;
  final VoidCallback onOpenTasbih;

  const ItqanBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    this.onTabSelected,
    required this.onOpenDrawer,
    required this.onOpenMushaf,
    required this.onOpenPrayer,
    required this.onOpenTasbih,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl, // الترتيب من اليمين لليسار حسب الصورة
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. زر "الرئيسية" (كبسولة خضراء بارزة)
              _buildHomeTab(context),

              // 2. زر "الصلاة" (أيقونة الهلال)
              _buildNavTab(
                label: 'الصلاة',
                icon: Icons.mode_night_outlined,
                isSelected: selectedIndex == 1,
                onTap: onOpenPrayer,
              ),

              // 3. زر "المصحف" الأوسط (مربع ذهبي/برتقالي عائم)
              _buildCenterMushafButton(context),

              // 4. زر "التسبيح" (أيقونة البصمة)
              _buildNavTab(
                label: 'التسبيح',
                icon: Icons.fingerprint_rounded,
                isSelected: selectedIndex == 3,
                onTap: onOpenTasbih,
              ),

              // 5. زر "المزيد" (أيقونة الشبكة، يفتح اللوحة الجانبية)
              _buildNavTab(
                label: 'المزيد',
                icon: Icons.grid_view_rounded,
                isSelected: false,
                onTap: onOpenDrawer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// كبسولة الزر النشط "الرئيسية" باللون الأخضر الداكن
  Widget _buildHomeTab(BuildContext context) {
    final isHome = selectedIndex == 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTabSelected?.call(0);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isHome ? const Color(0xFF064E3B) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_rounded,
                color: isHome ? Colors.white : const Color(0xFF5B7065),
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                'الرئيسية',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isHome ? Colors.white : const Color(0xFF5B7065),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// زر المصحف المركزي الذهبي البارز
  Widget _buildCenterMushafButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenMushaf,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFBBF24),
                Color(0xFFF59E0B),
                Color(0xFFD97706),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF0F2E22), // لون خط الآيقونة غامق مطابق للصورة
              size: 27,
            ),
          ),
        ),
      ),
    );
  }

  /// زر تنقل اعتيادي (الصلاة، التسبيح، المزيد)
  Widget _buildNavTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const defaultColor = Color(0xFF5B7065);
    const activeColor = Color(0xFF064E3B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : defaultColor,
                size: 23,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : defaultColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
