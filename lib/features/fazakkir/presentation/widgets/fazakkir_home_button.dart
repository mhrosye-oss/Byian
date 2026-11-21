import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../screens/fazakkir_dashboard_screen.dart';

/// Simple placeholder for the Fazakkir home button used on the main HomeScreen.
/// It matches the visual style of other service chips.
class FazakkirHomeButton extends StatelessWidget {
  const FazakkirHomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () {
        // Navigate to the Fazakkir dashboard screen.
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => FazakkirDashboardScreen()));
      },
      avatar: Icon(Icons.notifications_active_rounded, size: 17, color: ItqanColors.emerald),
      label: const Text('فَذَكِّر'),
      labelStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(color: Theme.of(context).dividerColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
