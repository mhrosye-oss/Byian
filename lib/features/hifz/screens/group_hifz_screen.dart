import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

enum HifzView { intro, create, join, result }

class GroupHifzScreen extends StatefulWidget {
  const GroupHifzScreen({super.key});

  @override
  State<GroupHifzScreen> createState() => _GroupHifzScreenState();
}

class _GroupHifzScreenState extends State<GroupHifzScreen> {
  HifzView _currentView = HifzView.intro;
  bool _isLoading = false;

  final String apiUrl = 'https://blueviolet-viper-439935.hostingersite.com/api.php';
  final String apiToken = 'MySecretToken123!';

  final TextEditingController _challengeNameController = TextEditingController();
  final List<TextEditingController> _participantControllers = [];
  int _participantCount = 3;
  
  // بيانات السور (للتجربة، يمكن توسيعها)
  final List<String> _surahsList = ['الفاتحة', 'البقرة', 'آل عمران', 'يس', 'الملك', 'الكهف', 'مريم', 'الرحمن', 'الواقعة', 'المزمل'];
  final Set<String> _selectedSurahs = {};

  final TextEditingController _joinCodeController = TextEditingController();
  List<dynamic> _resultMembers = [];

  @override
  void initState() {
    super.initState();
    _updateParticipantFields();
  }

  void _updateParticipantFields() {
    while (_participantControllers.length < _participantCount) {
      _participantControllers.add(TextEditingController());
    }
    while (_participantControllers.length > _participantCount) {
      final controller = _participantControllers.removeLast();
      controller.dispose();
    }
  }

  Future<void> _createHifzApi() async {
    if (_challengeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسم التحدي')));
      return;
    }
    if (_selectedSurahs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار سورة واحدة على الأقل')));
      return;
    }
    for (var controller in _participantControllers) {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال جميع الأسماء')));
        return;
      }
    }

    setState(() => _isLoading = true);
    List<String> members = _participantControllers.map((c) => c.text.trim()).toList();

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'create_hifz',
          'name': _challengeNameController.text.trim(),
          'creator': 'أنا',
          'members': members,
          'surahs': _selectedSurahs.toList(),
        }),
      );

      var data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        setState(() {
          _resultMembers = data['members'];
          _currentView = HifzView.result;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'حدث خطأ')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاتصال: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinHifzApi() async {
    if (_joinCodeController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'join_hifz_by_code', 'member_code': _joinCodeController.text.trim()}),
      );

      var data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مرحباً ${data['data']['member_name']}، مهمتك حفظ: ${data['data']['assigned_surah']}')));
        setState(() => _currentView = HifzView.intro);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'الكود غير صحيح')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاتصال: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _challengeNameController.dispose();
    _joinCodeController.dispose();
    for (var c in _participantControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('تحدي الحفظ الجماعي', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _currentView != HifzView.intro && _currentView != HifzView.result && !_isLoading
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentView = HifzView.intro))
            : null,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentView(theme),
          ),
    );
  }

  Widget _buildCurrentView(ThemeData theme) {
    switch (_currentView) {
      case HifzView.intro: return _buildIntroView(theme);
      case HifzView.create: return _buildCreateView(theme);
      case HifzView.join: return _buildJoinView(theme);
      case HifzView.result: return _buildResultView(theme);
    }
  }

  Widget _buildIntroView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology_rounded, size: 100, color: Color(0xFF1B5E20)),
          const SizedBox(height: 20),
          Text('تحدي الحفظ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 16),
          Text('تحدَّ نفسك مع أصدقائك لحفظ سور القرآن. التطبيق سيقسم السور عليكم، ويختبر حفظكم.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.6, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => setState(() => _currentView = HifzView.create), icon: const Icon(Icons.add_circle_outline, color: Colors.white), label: const Text('إنشاء تحدي جديد', style: TextStyle(fontSize: 18, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => setState(() => _currentView = HifzView.join), icon: const Icon(Icons.login_rounded, color: Color(0xFF1B5E20)), label: const Text('الانضمام بكود شخصي', style: TextStyle(fontSize: 18, color: Color(0xFF1B5E20))), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Color(0xFF1B5E20), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
        ],
      ),
    );
  }

  Widget _buildCreateView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _challengeNameController, decoration: InputDecoration(hintText: 'اسم التحدي (مثلاً: تحدي حفظ جزء تبارك)', filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 20),
          Text('اختر السور المطلوبة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _surahsList.map((surah) {
              final isSelected = _selectedSurahs.contains(surah);
              return FilterChip(
                label: Text(surah),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedSurahs.add(surah);
                    } else {
                      _selectedSurahs.remove(surah);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('عدد المشاركين:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                Row(
                  children: [
                    IconButton(onPressed: () { if (_participantCount > 1) { setState(() { _participantCount--; _updateParticipantFields(); }); } }, icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
                    Text('$_participantCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    IconButton(onPressed: () { if (_participantCount < 10) { setState(() { _participantCount++; _updateParticipantFields(); }); } }, icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B5E20))),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _participantCount,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(controller: _participantControllers[index], decoration: InputDecoration(hintText: 'اسم المشارك ${index + 1}', prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1B5E20)), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _createHifzApi, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('إنشاء التحدي وتوليد الأكواد', style: TextStyle(fontSize: 18, color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildJoinView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vpn_key_rounded, size: 80, color: Color(0xFF1B5E20)),
          const SizedBox(height: 20),
          Text('الانضمام بكود شخصي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 10),
          Text('اطلب من صديقك كودك الشخصي الخاص بك (يبدأ بحرف H) واكتبه هنا.', textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 30),
          TextField(controller: _joinCodeController, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: 'H-1234', filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _joinHifzApi, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('انضمام', style: TextStyle(fontSize: 18, color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildResultView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            color: const Color(0xFF1B5E20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text('تم إنشاء التحدي بنجاح', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('أرسل الكود الخاص لكل شخص:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _resultMembers.length,
              itemBuilder: (context, index) {
                final member = _resultMembers[index];
                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1), child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold))),
                    title: Text(member['name'], style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    subtitle: Text('المهمة: ${member['assigned_surah']}', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(member['code'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 16)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Colors.grey, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: member['code']));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ كود ${member['name']}')));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => setState(() => _currentView = HifzView.intro), style: ElevatedButton.styleFrom(backgroundColor: theme.cardColor, side: const BorderSide(color: Color(0xFF1B5E20)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('العودة للرئيسية', style: TextStyle(fontSize: 16, color: Color(0xFF1B5E20))))),
        ],
      ),
    );
  }
}
