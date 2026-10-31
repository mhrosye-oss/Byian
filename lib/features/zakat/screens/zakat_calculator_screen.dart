import 'package:flutter/material.dart';

class ZakatInput {
  final double cash;
  final double gold;
  final double silver;
  final double savings;
  final double investments;
  final double liabilities;

  const ZakatInput({required this.cash, required this.gold, required this.silver, required this.savings, required this.investments, required this.liabilities});
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
    _cashController.dispose(); _goldController.dispose(); _silverController.dispose();
    _savingsController.dispose(); _investmentsController.dispose(); _liabilitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = ZakatInput(
      cash: double.tryParse(_cashController.text) ?? 0, gold: double.tryParse(_goldController.text) ?? 0,
      silver: double.tryParse(_silverController.text) ?? 0, savings: double.tryParse(_savingsController.text) ?? 0,
      investments: double.tryParse(_investmentsController.text) ?? 0, liabilities: double.tryParse(_liabilitiesController.text) ?? 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('حاسبة الزكاة', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 22), textDirection: TextDirection.rtl), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Color(0xFF1A1A1A))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 6))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المبلغ القابل للزكاة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)), textDirection: TextDirection.rtl),
                  const SizedBox(height: 14),
                  _buildField('النقد', _cashController), const SizedBox(height: 12),
                  _buildField('الذهب', _goldController), const SizedBox(height: 12),
                  _buildField('الفضة', _silverController), const SizedBox(height: 12),
                  _buildField('التوفير', _savingsController), const SizedBox(height: 12),
                  _buildField('الاستثمارات', _investmentsController), const SizedBox(height: 12),
                  _buildField('الالتزامات', _liabilitiesController),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إجمالي الزكاة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white), textDirection: TextDirection.rtl),
                  const SizedBox(height: 8),
                  Text('${input.zakatDue.toStringAsFixed(2)} ر.س', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white), textDirection: TextDirection.rtl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return TextField(
      controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), textDirection: TextDirection.rtl,
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Color(0xFF1A1A1A)), filled: true, fillColor: const Color(0xFF1A1A1A).withOpacity(0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
    );
  }
}
