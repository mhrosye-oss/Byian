import 'package:flutter/material.dart';
import 'package:itqan/core/services/auth_service.dart';
import 'package:itqan/features/auth/screens/login_screen.dart';
import 'package:itqan/features/about/screens/about_screen.dart';
import 'package:itqan/features/contributors/screens/hall_of_fame_screen.dart';
import 'package:itqan/features/ai/screens/ai_chat_screen.dart';
import 'package:itqan/features/waqf/screens/waqf_screen.dart';
import 'package:itqan/features/kids/screens/kids_mode_screen.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});
  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  Map<String, String>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    setState(() => _user = null);
  }

  void _goToLogin() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (result == true) _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF1B5E20);
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: green,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 34, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, size: 38, color: green)),
                  const SizedBox(height: 14),
                  if (_user != null) ...[
                    Text(_user!['name']!, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                    Text(_user!['email']!, style: const TextStyle(color: Colors.white70)),
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white70, size: 16),
                      label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    )
                  ] else ...[
                    const Text('مرحباً بك', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _goToLogin,
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text('تسجيل الدخول / حساب جديد', style: TextStyle(color: Colors.white)),
                    )
                  ]
                ],
              ),
            ),
            SwitchListTile(secondary: const Icon(Icons.dark_mode_outlined, color: green), title: const Text('الوضع الداكن'), value: theme.brightness == Brightness.dark, onChanged: (val) {}),
            ListTile(leading: const Icon(Icons.smart_toy_rounded, color: green), title: const Text('المساعد الذكي'), onTap: () => _open(context, const AiChatScreen())),
            ListTile(leading: const Icon(Icons.child_care_rounded, color: green), title: const Text('وضع الأطفال'), onTap: () => _open(context, const KidsModeScreen())),
            ListTile(leading: const Icon(Icons.volunteer_activism_rounded, color: green), title: const Text('الصدقة الجارية'), onTap: () => _open(context, const WaqfScreen())),
            ListTile(leading: const Icon(Icons.info_outline_rounded, color: green), title: const Text('شكراً لمساهمينا'),
              onTap: () => _open(context, const HallOfFameScreen()),
            ),
            ListTile(leading: const Icon(Icons.info_outline_rounded, color: _green),
              title: const Text('من نحن'), onTap: () => _open(context, const AboutScreen())),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
