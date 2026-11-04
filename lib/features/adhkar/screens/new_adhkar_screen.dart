import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'adhkar_detail_screen.dart';

class NewAdhkarScreen extends StatefulWidget {
  const NewAdhkarScreen({super.key});
  @override
  State<NewAdhkarScreen> createState() => _NewAdhkarScreenState();
}

class _NewAdhkarScreenState extends State<NewAdhkarScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final String response = await rootBundle.loadString('assets/data/adhkar_categories.json');
      setState(() {
        _categories = json.decode(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'wb_sunny': return Icons.wb_sunny;
      case 'bedtime': return Icons.bedtime;
      case 'clean_hands': return Icons.clean_hands;
      case 'mosque': return Icons.mosque;
      case 'restaurant': return Icons.restaurant;
      case 'flight_takeoff': return Icons.flight_takeoff;
      case 'cloud': return Icons.cloud;
      case 'auto_awesome': return Icons.auto_awesome;
      case 'healing': return Icons.healing;
      case 'account_balance': return Icons.account_balance;
      case 'favorite': return Icons.favorite;
      case 'water_drop': return Icons.water_drop;
      case 'home': return Icons.home;
      case 'checkroom': return Icons.checkroom;
      default: return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('الأذكار'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.08,
              ),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Card(
                  color: theme.cardColor,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdhkarDetailScreen(categoryId: cat['id'], categoryTitle: cat['title']))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(color: const Color(0xFF1B5E20).withOpacity(.09), shape: BoxShape.circle),
                            child: Icon(_getIcon(cat['icon']), color: const Color(0xFF1B5E20), size: 31),
                          ),
                          const SizedBox(height: 14),
                          Text(cat['title'], textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
