import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../data/circle_api_client.dart';
import '../../data/circle_auth_service.dart';
import '../../data/circle_fcm_service.dart';
import '../../domain/circle_models.dart';

class CircleProfileScreen extends StatefulWidget {
  const CircleProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<CircleProfileScreen> createState() => _CircleProfileScreenState();
}

class _CircleProfileScreenState extends State<CircleProfileScreen> {
  bool _busy = false;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من دوائر إتقان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    final api = CircleApiClient.instance;
    try {
      await CircleFcmService.instance.unregisterBeforeLogout(api);
      try {
        await api.logout();
      } catch (error) {
        debugPrint('Backend logout failed; clearing the local session: $error');
      }
      try {
        await CircleFirebaseAuthService.instance.signOut();
      } catch (error) {
        debugPrint(
            'Firebase sign-out failed; clearing the local session: $error');
      }
    } finally {
      await api.sessionStore.clear();
      if (mounted) {
        setState(() => _busy = false);
        widget.onLogout();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 42,
              backgroundColor: ItqanColors.emerald.withValues(alpha: .10),
              foregroundColor: ItqanColors.emerald,
              child: Text(
                widget.user.name.isEmpty
                    ? '؟'
                    : widget.user.name.characters.first,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.user.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.user.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ItqanColors.inkSoft,
                  ),
            ),
            const SizedBox(height: 22),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.stars_rounded,
                        color: ItqanColors.emerald),
                    title: const Text('المستوى'),
                    trailing: Text(
                        '${widget.user.levelTitle ?? 'مبتدئ'} · ${widget.user.level}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bolt_rounded,
                        color: ItqanColors.roseGold),
                    title: const Text('نقاط الخبرة'),
                    trailing: Text('${widget.user.totalXp} XP'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.toll_rounded,
                        color: ItqanColors.emerald),
                    title: const Text('العملات'),
                    trailing: Text('${widget.user.totalCoins}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _busy ? null : _logout,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: const Text('تسجيل الخروج'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB3261E),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      );
}
