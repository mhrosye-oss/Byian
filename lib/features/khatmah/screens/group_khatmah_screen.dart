import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'my_khatmah_task_screen.dart'; // للنسخ

enum KhatmahView { intro, create, join, result }

class GroupKhatmahScreen extends StatefulWidget {
  const GroupKhatmahScreen({super.key});

  @override
  State<GroupKhatmahScreen> createState() => _GroupKhatmahScreenState();
}

class _GroupKhatmahScreenState extends State<GroupKhatmahScreen> {
  KhatmahView _currentView = KhatmahView.intro;
  bool _isLoading = false;

  final String apiUrl = 'https://blueviolet-viper-439935.hostingersite.com/api.php';
  final String apiToken = 'MySecretToken123!';

  final TextEditingController _customGroupNameController = TextEditingController();
  String? _selectedGroupType;
  final List<String> _groupTypes = ['أصدقاء المسجد', 'أفراد العائلة', 'أصدقاء العمل', 'أصدقاء الحارة', 'أخرى...'];
  
  int _participantCount = 3;
  final List<TextEditingController> _participantControllers = [];

  final TextEditingController _joinCodeController = TextEditingController();
  
  // لحفظ نتيجة الإنشاء
  String _groupCode = "";
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

  Future<void> _createKhatmahApi() async {
    String finalName = _selectedGroupType == 'أخرى...' ? _customGroupNameController.text : (_selectedGroupType ?? '');
    if (finalName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد اسم المجموعة')));
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
        body: jsonEncode({'action': 'create_khatmah', 'name': finalName, 'creator': 'أنا', 'members': members}),
      );

      var data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        setState(() {
          _groupCode = data['group_code'];
          _resultMembers = data['members'];
          _currentView = KhatmahView.result;
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

  Future<void> _joinKhatmahApi() async {
    if (_joinCodeController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'join_by_personal_code', 'member_code': _joinCodeController.text.trim()}),
      );

      var data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        // الانتقال لصفحة المهام الخاصة بالشخص
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyKhatmahTaskScreen(
              memberName: data['data']['member_name'],
              startPage: int.parse(data['data']['start_page'].toString()),
              endPage: int.parse(data['data']['end_page'].toString()),
            ),
          ),
        );
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
    _customGroupNameController.dispose();
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
        title: const Text('الختمة الجماعية', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _currentView != KhatmahView.intro && _currentView != KhatmahView.result && !_isLoading
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentView = KhatmahView.intro))
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
      case KhatmahView.intro: return _buildIntroView(theme);
      case KhatmahView.create: return _buildCreateView(theme);
      case KhatmahView.join: return _buildJoinView(theme);
      case KhatmahView.result: return _buildResultView(theme);
    }
  }

  Widget _buildIntroView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_rounded, size: 100, color: Color(0xFF1B5E20)),
          const SizedBox(height: 20),
          Text('ختمة جماعية', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 16),
          Text('اجمع أصدقاءك أو عائلتك لتقسيم المصحف بينكم. كل شخص سيحصل على كود خاص به.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.6, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => setState(() => _currentView = KhatmahView.create), icon: const Icon(Icons.add_circle_outline, color: Colors.white), label: const Text('إنشاء مجموعة جديدة', style: TextStyle(fontSize: 18, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => setState(() => _currentView = KhatmahView.join), icon: const Icon(Icons.login_rounded, color: Color(0xFF1B5E20)), label: const Text('الانضمام بكود شخصي', style: TextStyle(fontSize: 18, color: Color(0xFF1B5E20))), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Color(0xFF1B5E20), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
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
          Text('نوع المجموعة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedGroupType,
            decoration: InputDecoration(filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            hint: const Text('اختر نوع المجموعة'),
            items: _groupTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedGroupType = val;
                if (val != 'أخرى...') _customGroupNameController.clear();
              });
            },
          ),
          if (_selectedGroupType == 'أخرى...') ...[
            const SizedBox(height: 12),
            TextField(controller: _customGroupNameController, decoration: InputDecoration(hintText: 'اكتب اسم المجموعة', filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          ],
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
                    IconButton(onPressed: () { if (_participantCount < 30) { setState(() { _participantCount++; _updateParticipantFields(); }); } }, icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B5E20))),
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
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _createKhatmahApi, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('إنشاء الختمة وتوليد الأكواد', style: TextStyle(fontSize: 18, color: Colors.white)))),
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
          Text('اطلب من صديقك كودك الشخصي الخاص بك (يبدأ بحرف M) واكتبه هنا.', textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 30),
          TextField(controller: _joinCodeController, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: 'M-1234', filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _joinKhatmahApi, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('انضمام', style: TextStyle(fontSize: 18, color: Colors.white)))),
        ],
      ),
    );
  }

  // عرض النتيجة مع أيقونة النسخ
  Widget _buildResultView(ThemeData theme) {
    String groupName = _selectedGroupType == 'أخرى...' ? _customGroupNameController.text : (_selectedGroupType ?? 'المجموعة');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            color: const Color(0xFF1B5E20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text('تم إنشاء: $groupName', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('كود المجموعة: $_groupCode', style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
                    subtitle: Text('صفحات ${member['start_page']} إلى ${member['end_page']}', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
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
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => setState(() => _currentView = KhatmahView.intro), style: ElevatedButton.styleFrom(backgroundColor: theme.cardColor, side: const BorderSide(color: Color(0xFF1B5E20)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('العودة للرئيسية', style: TextStyle(fontSize: 16, color: Color(0xFF1B5E20))))),
        ],
      ),
    );
  }
}
