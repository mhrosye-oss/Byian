import 'package:flutter/material.dart';

class ZakatInput {
  final double cash;
  final double gold;
  final double silver;
  final double savings;
  final double investments;
  final double liabilities;

  const ZakatInput({
    required this.cash,
    required this.gold,
    required this.silver,
    required this.savings,
    required this.investments,
    required this.liabilities,
  });

  double get totalAssets => cash + gold + silver + savings + investments - liabilities;
  double get zakatDue => totalAssets > 0 ? totalAssets * 0.025 : 0;
}

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _cashController = TextEditingController(text: '0');
  final _goldController = TextEditingController(text: '0');
  final _silverController = TextEditingController(text: '0');
  final _savingsController = TextEditingController(text: '0');
  final _investmentsController = TextEditingController(text: '0');
  final _liabilitiesController = TextEditingController(text: '0');

  @override
  void dispose() {
    _cashController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _savingsController.dispose();
    _investmentsController.dispose();
    _liabilitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final input = ZakatInput(
      cash: double.tryParse(_cashController.text) ?? 0,
      gold: double.tryParse(_goldController.text) ?? 0,
      silver: double.tryParse(_silverController.text) ?? 0,
      savings: double.tryParse(_savingsController.text) ?? 0,
      investments: double.tryParse(_investmentsController.text) ?? 0,
      liabilities: double.tryParse(_liabilitiesController.text) ?? 0,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('حاسبة الزكاة', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: theme.cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المبلغ القابل للزكاة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildField('النقد', _cashController, theme),
                    _buildField('الذهب', _goldController, theme),
                    _buildField('الفضة', _silverController, theme),
                    _buildField('التوفير', _savingsController, theme),
                    _buildField('الاستثمارات', _investmentsController, theme),
                    _buildField('الالتزامات (الديون)', _liabilitiesController, theme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20), // اللون الأخضر للتطبيق
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إجمالي الزكاة المستحقة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${input.zakatDue.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        onChanged: (value) => setState(() {}), // لتحديث الحساب فوراً
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: theme.scaffoldBackgroundColor,
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
