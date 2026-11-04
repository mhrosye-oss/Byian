import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdhkarDetailScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;
  const AdhkarDetailScreen({super.key, required this.categoryId, required this.categoryTitle});

  @override
  State<AdhkarDetailScreen> createState() => _AdhkarDetailScreenState();
}

class _AdhkarDetailScreenState extends State<AdhkarDetailScreen> {
  List<dynamic> _adhkar = [];
  bool _isLoading = true;
  final Map<int, int> _counters = {};

  @override
  void initState() {
    super.initState();
    _loadAdhkar();
  }

  Future<void> _loadAdhkar() async {
    try {
      final String response = await rootBundle.loadString('assets/data/adhkar_data.json');
      final data = json.decode(response);
      setState(() {
        _adhkar = data[widget.categoryId] ?? [];
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
      appBar: AppBar(title: Text(widget.categoryTitle), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _adhkar.length,
              itemBuilder: (context, index) {
                final item = _adhkar[index];
                final currentCount = _counters[index] ?? 0;
                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(item['text'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.8, color: theme.textTheme.bodyLarge?.color), textDirection: TextDirection.rtl, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(item['reference'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('التكرار: ${item['count']}', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() => _counters[index] = currentCount + 1);
                              },
                              child: Text('$currentCount', style: const TextStyle(color: Colors.white, fontSize: 18)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
