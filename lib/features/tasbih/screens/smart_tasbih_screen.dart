import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/widgets/itqan_points_icon.dart';

class SmartTasbihScreen extends StatefulWidget {
  const SmartTasbihScreen({super.key});

  @override
  State<SmartTasbihScreen> createState() => _SmartTasbihScreenState();
}

class _SmartTasbihScreenState extends State<SmartTasbihScreen> {
  static const List<String> _adhkarList = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
  ];

  static const List<int> _targetOptions = [33, 100, 1000, 0]; // 0 تعني حر/مفتوح

  String _selectedDhikr = 'سُبْحَانَ اللَّهِ';
  int _target = 33;
  int _count = 0;
  int _totalTasbihSession = 0;
  bool _vibrationEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasbihData();
  }

  Future<void> _loadTasbihData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDhikr = prefs.getString('itqan_tasbih_dhikr') ?? 'سُبْحَانَ اللَّهِ';
    final savedTarget = prefs.getInt('itqan_tasbih_target') ?? 33;
    final savedCount = prefs.getInt('itqan_tasbih_count_$savedDhikr') ?? 0;
    final savedTotal = prefs.getInt('itqan_tasbih_total_session') ?? 0;
    final savedVibrate = prefs.getBool('itqan_tasbih_vibrate') ?? true;

    if (mounted) {
      setState(() {
        _selectedDhikr = savedDhikr;
        _target = savedTarget;
        _count = savedCount;
        _totalTasbihSession = savedTotal;
        _vibrationEnabled = savedVibrate;
        _loading = false;
      });
    }
  }

  Future<void> _saveTasbihData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('itqan_tasbih_dhikr', _selectedDhikr);
    await prefs.setInt('itqan_tasbih_target', _target);
    await prefs.setInt('itqan_tasbih_count_$_selectedDhikr', _count);
    await prefs.setInt('itqan_tasbih_total_session', _totalTasbihSession);
    await prefs.setBool('itqan_tasbih_vibrate', _vibrationEnabled);
  }

  void _increment() {
    setState(() {
      _count++;
      _totalTasbihSession++;
    });

    if (_vibrationEnabled) {
      if (_target > 0 && _count % _target == 0) {
        HapticFeedback.heavyImpact(); // اهتزاز ملحوظ عند إتمام الهدف
      } else {
        HapticFeedback.lightImpact();
      }
    }

    _saveTasbihData();
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تصفير العداد',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'هل تريد إعادة ضبط عداد الذكر الحالي إلى الصفر؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A5C36),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _count = 0);
              _saveTasbihData();
            },
            child: const Text('نعم، تصفير'),
          ),
        ],
      ),
    );
  }

  void _selectDhikr(String dhikr) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCount = prefs.getInt('itqan_tasbih_count_$dhikr') ?? 0;
    setState(() {
      _selectedDhikr = dhikr;
      _count = savedCount;
    });
    _saveTasbihData();
  }

  void _selectTarget(int target) {
    setState(() => _target = target);
    _saveTasbihData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F6F0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36))),
      );
    }

    final remaining = _target > 0 ? (_target - _count).clamp(0, _target) : null;
    final progress = _target > 0 ? (_count / _target).clamp(0.0, 1.0) : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text(
          'مسبحة إتقان الإلكترونية',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _vibrationEnabled ? 'تعطيل الاهتزاز' : 'تفعيل الاهتزاز',
            icon: Icon(
              _vibrationEnabled ? Icons.vibration_rounded : Icons.smartphone_rounded,
              color: const Color(0xFF0A5C36),
            ),
            onPressed: () {
              setState(() => _vibrationEnabled = !_vibrationEnabled);
              _saveTasbihData();
            },
          ),
          IconButton(
            tooltip: 'تصفير العداد',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8A8C83)),
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // قائمة اختيار الأذكار الأفقية
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _adhkarList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final dhikr = _adhkarList[index];
                  final isSelected = dhikr == _selectedDhikr;
                  return ChoiceChip(
                    selected: isSelected,
                    onSelected: (_) => _selectDhikr(dhikr),
                    label: Text(dhikr),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF202B24),
                      fontFamily: 'NotoNaskhArabic',
                    ),
                    selectedColor: const Color(0xFF0A5C36),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0A5C36) : const Color(0xFFE7E0D5),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // شريط خيارات الهدف المستهدف
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                const Text(
                  'الهدف: ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5F685F)),
                ),
                ..._targetOptions.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => _selectTarget(t),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: t == _target ? const Color(0xFFD4AF37) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: t == _target ? const Color(0xFFD4AF37) : const Color(0xFFE7E0D5),
                        ),
                      ),
                      child: Text(
                        t == 0 ? 'مفتوح' : '$t',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: t == _target ? FontWeight.w700 : FontWeight.w500,
                          color: t == _target ? Colors.white : const Color(0xFF202B24),
                        ),
                      ),
                    ),
                  ),
                )),
              ],
            ),
            const Spacer(),

            // بطاقة الذكر والعداد الكبير
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    _selectedDhikr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A5C36),
                      fontFamily: 'NotoNaskhArabic',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_target > 0)
                    Text(
                      'المتبقي لإتمام الدورة: $remaining',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8A8C83)),
                      textDirection: TextDirection.rtl,
                    ),
                  const SizedBox(height: 24),

                  // زر التسبيح التفاعلي الضخم
                  GestureDetector(
                    onTap: _increment,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // حلقة التقدم
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFE7E0D5),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                          ),
                        ),
                        // القرص الدائري الرئيسي
                        Container(
                          width: 194,
                          height: 194,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFF0E693E), Color(0xFF0A5C36)],
                              center: Alignment.topLeft,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0A5C36).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_count',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (_target > 0)
                                Text(
                                  'من $_target',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFFFF4D0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              const Icon(
                                Icons.touch_app_rounded,
                                color: Color(0xFFD4AF37),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // شريط إحصائيات الجلسة
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7E0D5)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$_totalTasbihSession',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF202B24)),
                      ),
                      const Text(
                        'إجمالي تسبيحات الجلسة',
                        style: TextStyle(fontSize: 11, color: Color(0xFF5F685F)),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE7E0D5)),
                  Column(
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          const ItqanPointsIcon(size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${(_totalTasbihSession / 10).floor()}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0A5C36)),
                          ),
                        ],
                      ),
                      const Text(
                        'نقاط إتقان المستحقة',
                        style: TextStyle(fontSize: 11, color: Color(0xFF5F685F)),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
