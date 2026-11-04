import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});
  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  List<dynamic> _duas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  Future<void> _loadDuas() async {
    try {
      final String response = await rootBundle.loadString('assets/data/duas_data.json');
      setState(() {
        _duas = json.decode(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('مكتبة الأدعية'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _duas.length,
              itemBuilder: (context, index) {
                final dua = _duas[index];
                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dua['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: dua['text'] ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
                              },
                            )
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(dua['text'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.8, color: theme.textTheme.bodyLarge?.color), textDirection: TextDirection.rtl),
                        const SizedBox(height: 12),
                        Text(dua['reference'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
