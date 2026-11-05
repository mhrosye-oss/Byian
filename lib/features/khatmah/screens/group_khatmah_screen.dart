import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum KhatmahView { intro, create, join, result }

class GroupKhatmahScreen extends StatefulWidget {
  const GroupKhatmahScreen({super.key});

  @override
  State<GroupKhatmahScreen> createState() => _GroupKhatmahScreenState();
}

class _GroupKhatmahScreenState extends State<GroupKhatmahScreen> {
  KhatmahView _currentView = KhatmahView.intro;
  bool _isLoading = false;

  // إعدادات الـ API
  final String apiUrl = 'https://blueviolet-viper-439935.hostingersite.com/api.php';
  final String apiToken = 'MySecretToken123!'; // نفس التوكن في api.php

  // بيانات الإنشاء
  final TextEditingController _customGroupNameController = TextEditingController();
  String? _selectedGroupType;
  final List<String> _groupTypes = [
    'أصدقاء المسجد', 'أفراد العائلة', 'أصدقاء العمل', 'أصدقاء الحارة', 'أخرى...'
  ];
  
  int _participantCount = 3;
  final List<TextEditingController> _participantControllers = [];

  // بيانات الانضمام والنتيجة
  final TextEditingController _joinCodeController = TextEditingController();
  String _generatedCode = "";
  int _pagesPerPerson = 0;

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

  // ---------------- دالة إنشاء الختمة من السيرفر ----------------
  Future<void> _createKhatmahApi() async {
    String finalName = _selectedGroupType == 'أخرى...' ? _customGroupNameController.text : _selectedGroupType;
    if (finalName == null || finalName.trim().isEmpty) {
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
        body: jsonEncode({
          'action': 'create_khatmah',
          'name': finalName,
          'creator': 'أنا',
          'members': members,
        }),
      );

      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          _generatedCode = data['code'];
          _pagesPerPerson = (604 / members.length).ceil();
          _currentView = KhatmahView.result;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'حدث خطأ')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاتصال: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------- دالة الانضمام من السيرفر ----------------
  Future<void> _joinKhatmahApi() async {
    if (_joinCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال الكود')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'join_khatmah',
          'code': _joinCodeController.text.trim(),
          'member_name': 'مستخدم جديد', // للتجربة
        }),
      );

      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الانضمام بنجاح!')));
        setState(() => _currentView = KhatmahView.intro);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'الكود غير صحيح')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاتصال: $e')));
    } finally {
      setState(() => _isLoading = false);
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

  // 1. الشاشة التعريفية
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
          Text('اجمع أصدقاءك أو عائلتك لتقسيم المصحف بينكم. التطبيق سيقوم بتوزيع الصفحات تلقائياً بالتساوي.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.6, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => setState(() => _currentView = KhatmahView.create), icon: const Icon(Icons.add_circle_outline, color: Colors.white), label: const Text('إنشاء مجموعة جديدة', style: TextStyle(fontSize: 18, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => setState(() => _currentView = KhatmahView.join), icon: const Icon(Icons.login_rounded, color: Color(0xFF1B5E20)), label: const Text('الانضمام لمجموعة (بكود)', style: TextStyle(fontSize: 18, color: Color(0xFF1B5E20))), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Color(0xFF1B5E20), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
        ],
      ),
    );
  }

  // 2. شاشة إنشاء مجموعة
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
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _createKhatmahApi, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('إنشاء الختمة (حفظ في السيرفر)', style: TextStyle(fontSize: 18, color: Colors.white)))),
        ],
      ),
    );
  }

  // 3. شاشة الانضمام
  Widget _buildJoinView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vpn_key_rounded, size: 80, color: Color(0xFF1B5E20)),
          const SizedBox(height: 20),
          Text('الانضمام لمجموعة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 10),
          Text('اطلب الكود من صديقك الذي أنشأ الختمة، واكتبه هنا.', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          const SizedBox(height: 30),
          TextField(controller: _joinCodeController, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: 'KH-1234', filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _joinKhatmahApi, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('انضمام', style: TextStyle(fontSize: 18, color: Colors.white)))),
        ],
      ),
    );
  }

  // 4. شاشة النتيجة
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
                  const Text('كود الانضمام (شاركه مع أصدقائك):', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(_generatedCode, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4)),
                  const SizedBox(height: 10),
                  Text('حصة كل شخص: $_pagesPerPerson صفحة', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _participantCount,
              itemBuilder: (context, index) {
                final startPage = index * _pagesPerPerson + 1;
                final endPage = (index + 1) * _pagesPerPerson > 604 ? 604 : (index + 1) * _pagesPerPerson;
                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1), child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold))),
                    title: Text(_participantControllers[index].text, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    subtitle: Text('من صفحة $startPage إلى $endPage', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
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
