import 'package:flutter/material.dart';

class KidsModeScreen extends StatelessWidget {
  const KidsModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // أزرق فاتح مبهج
      appBar: AppBar(
        title: const Text('ركن الأطفال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.orange, // برتقالي مبهج
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.1,
        children: [
          _buildKidsCard(context, 'تعلم الحروف', Icons.sort_by_alpha, Colors.purple, () {}),
          _buildKidsCard(context, 'قصص الأنبياء', Icons.auto_stories, Colors.green, () {}),
          _buildKidsCard(context, 'ألعاب وألغاز', Icons.extension, Colors.blue, () {}),
          _buildKidsCard(context, 'قصار السور', Icons.menu_book, Colors.red, () {}),
        ],
      ),
    );
  }

  Widget _buildKidsCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: color, width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
