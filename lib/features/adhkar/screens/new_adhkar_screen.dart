import 'package:flutter/material.dart';

const _green = Color(0xFF1B5E20);
const _cream = Color(0xFFF9F6F0);

class NewAdhkarScreen extends StatelessWidget {
  const NewAdhkarScreen({super.key});

  static const _categories = <({String title, IconData icon})>[
    (title: 'الهم والحزن', icon: Icons.cloud_outlined),
    (title: 'السفر', icon: Icons.flight_takeoff_rounded),
    (title: 'الصلاة والمسجد', icon: Icons.mosque_rounded),
    (title: 'المرض', icon: Icons.healing_rounded),
    (title: 'الحج والعمرة', icon: Icons.kaaba_rounded),
    (title: 'التسبيح والذكر', icon: Icons.auto_awesome_rounded),
    (title: 'النوم والاستيقاظ', icon: Icons.bedtime_outlined),
    (title: 'الأكل والشرب', icon: Icons.restaurant_rounded),
    (title: 'الزواج', icon: Icons.favorite_border_rounded),
    (title: 'الدخول والخروج', icon: Icons.door_front_door_outlined),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          title: const Text('الأذكار', textDirection: TextDirection.rtl),
          backgroundColor: _cream,
          foregroundColor: _green,
          elevation: 0,
          centerTitle: true,
        ),
        body: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.12,
          ),
          itemBuilder: (context, index) {
            final category = _categories[index];
            return Card(
              color: Colors.white,
              elevation: 3,
              shadowColor: _green.withOpacity(.09),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(color: _green.withOpacity(.09), shape: BoxShape.circle),
                      child: Icon(category.icon, color: _green, size: 31),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        category.title,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: _green, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}
