import 'package:flutter/material.dart';
import 'itqan_bottom_nav_bar.dart';

/// فوتر تطبيق إتقان (إعادة تصدير ومطابقة للشريط المخصص الجديد)
class FooterBar extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenMushaf;
  final VoidCallback? onOpenPrayer;
  final VoidCallback? onOpenTasbih;

  const FooterBar({
    super.key,
    this.onOpenDrawer,
    this.onOpenMushaf,
    this.onOpenPrayer,
    this.onOpenTasbih,
  });

  @override
  Widget build(BuildContext context) {
    return ItqanBottomNavBar(
      selectedIndex: 0,
      onOpenDrawer: () {
        if (onOpenDrawer != null) {
          onOpenDrawer!();
        } else {
          Scaffold.of(context).openDrawer();
        }
      },
      onOpenMushaf: onOpenMushaf ?? () {},
      onOpenPrayer: onOpenPrayer ?? () {},
      onOpenTasbih: onOpenTasbih ?? () {},
    );
  }
}
