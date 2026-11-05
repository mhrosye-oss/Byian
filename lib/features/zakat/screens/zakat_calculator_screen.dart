import 'package:flutter/material.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // العملة
  String _selectedCurrency = 'ر.س';
  final List<String> _currencies = [
    'ر.س', 'د.إ', 'ج.م', 'د.ك', 'ر.ق', 'د.أ', 'د.ل', 'ر.ع', 'د.ب', 
    'USD', 'EUR', 'GBP', 'TRY'
  ];
  
  // 1. الأموال والنقود
  final _cashController = TextEditingController();
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _stocksController = TextEditingController();
  final _loansController = TextEditingController();
  final _tradeGoodsController = TextEditingController();

  // 2. الزروع والثمار
  final _cropsValueController = TextEditingController();
  bool _isRainWatered = true; 

  // 3. المعادن والركاز
  final _mineralsValueController = TextEditingController();
  final _rikazValueController = TextEditingController();

  // 4. الأنعام
  final _sheepCountController = TextEditingController();
  final _cowsCountController = TextEditingController();
  final _camelsCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _stocksController.dispose();
    _loansController.dispose();
    _tradeGoodsController.dispose();
    _cropsValueController.dispose();
    _mineralsValueController.dispose();
    _rikazValueController.dispose();
    _sheepCountController.dispose();
    _cowsCountController.dispose();
    _camelsCountController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController controller) {
    return double.tryParse(controller.text) ?? 0.0;
  }

  double get _financialZakat {
    double total = _parse(_cashController) + _parse(_goldController) + _parse(_silverController) + 
                   _parse(_stocksController) + _parse(_loansController) + _parse(_tradeGoodsController);
    return total * 0.025;
  }

  double get _cropsZakat {
    double value = _parse(_cropsValueController);
    return value * (_isRainWatered ? 0.10 : 0.05);
  }

  double get _mineralsZakat {
    double minerals = _parse(_mineralsValueController) * 0.025;
    double rikaz = _parse(_rikazValueController) * 0.20;
    return minerals + rikaz;
  }

  double get _totalZakat => _financialZakat + _cropsZakat + _mineralsZakat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('حاسبة الزكاة الشاملة', style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // قائمة اختيار العملة
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              dropdownColor: const Color(0xFF1B5E20),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              items: _currencies.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCurrency = newValue!;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الأموال'),
            Tab(text: 'الزروع'),
            Tab(text: 'المعادن'),
            Tab(text: 'الأنعام'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFinancialTab(theme),
          _buildCropsTab(theme),
          _buildMineralsTab(theme),
          _buildLivestockTab(theme),
        ],
      ),
      bottomNavigationBar: _buildResultCard(theme),
    );
  }

  Widget _buildFinancialTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHint('أدخل قيمة ما تملكه بالعملة المحددة ($_selectedCurrency). تجب الزكاة إذا بلغ المجموع نصاباً (ما يعادل 85 جرام ذهب) وحال عليه الحول.'),
          _buildField('النقد (كاش / بنوك)', _cashController, theme),
          _buildField('قيمة الذهب (للزينة/الادخار/التجارة)', _goldController, theme),
          _buildField('قيمة الفضة', _silverController, theme),
          _buildField('الأسهم والسندات', _stocksController, theme),
          _buildField('الديون المرجوة السداد', _loansController, theme),
          _buildField('عروض التجارة (بضائع، عقارات للبيع)', _tradeGoodsController, theme),
        ],
      ),
    );
  }

  Widget _buildCropsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHint('تجب الزكاة في الحبوب والثمار إذا بلغت النصاب (653 كجم تقريباً).'),
          _buildField('إجمالي قيمة الزروع والثمار ($_selectedCurrency)', _cropsValueController, theme),
          const SizedBox(height: 10),
          Text('طريقة السقيا:', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          RadioListTile<bool>(
            title: const Text('تسقى بماء المطر أو العيون (العشر 10%)'),
            value: true,
            groupValue: _isRainWatered,
            onChanged: (val) => setState(() => _isRainWatered = val!),
          ),
          RadioListTile<bool>(
            title: const Text('تسقى بتكلفة ومؤونة (نصف العشر 5%)'),
            value: false,
            groupValue: _isRainWatered,
            onChanged: (val) => setState(() => _isRainWatered = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildMineralsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHint('المعادن المستخرجة (نفط، ذهب، حديد) فيها ربع العشر (2.5%). الركاز (الكنوز القديمة) فيه الخمس (20%).'),
          _buildField('قيمة المعادن المستخرجة ($_selectedCurrency)', _mineralsValueController, theme),
          _buildField('قيمة الركاز (الكنوز) ($_selectedCurrency)', _rikazValueController, theme),
        ],
      ),
    );
  }

  Widget _buildLivestockTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHint('تجب الزكاة في الأنعام السائمة (التي ترعى معظم السنة بدون علف). الحساب هنا استرشادي.'),
          _buildField('عدد الغنم (الضأن والمعز)', _sheepCountController, theme),
          _buildField('عدد البقر (والجواميس)', _cowsCountController, theme),
          _buildField('عدد الإبل (الجمال)', _camelsCountController, theme),
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    double currentZakat = _totalZakat;
    
    String livestockNote = '';
    if (_tabController.index == 3) {
      livestockNote = 'زكاة الأنعام تُخرج من جنسها (شاة، بقرة، بعير) حسب الجداول الفقهية، وليست مبلغاً مالياً.';
      currentZakat = 0; 
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _tabController.index == 3 ? 'إرشادات زكاة الأنعام' : 'إجمالي الزكاة المستحقة',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          if (_tabController.index == 3)
             Text(livestockNote, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white))
          else
            Text(
              '${currentZakat.toStringAsFixed(2)} $_selectedCurrency',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5)),
    );
  }

  Widget _buildField(String label, TextEditingController controller, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textDirection: TextDirection.rtl,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
          ),
        ),
      ),
    );
  }
}
