import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/smart_tasbih_service.dart';

class SmartTasbihScreen extends StatefulWidget {
  const SmartTasbihScreen({super.key});
  @override
  State<SmartTasbihScreen> createState() => _SmartTasbihScreenState();
}

class _SmartTasbihScreenState extends State<SmartTasbihScreen> {
  SmartTasbihState _state = SmartTasbihState.initial();
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadState(); }
  Future<void> _loadState() async {
    final state = await SmartTasbihService.load();
    setState(() { _state = state; _loading = false; });
  }
  Future<void> _increment() async {
    final nextCount = await SmartTasbihService.increment();
    setState(() { _state = SmartTasbihState(count: nextCount, target: _state.target, updatedAt: DateTime.now()); });
    HapticFeedback.lightImpact();
  }
  Future<void> _reset() async {
    await SmartTasbihService.reset();
    setState(() { _state = SmartTasbihState.initial(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('المسبحة', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 22), textDirection: TextDirection.rtl), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Color(0xFF1A1A1A))),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))) : Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6))]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 90, height: 90, decoration: BoxDecoration(color: const Color(0xFFD32F2F).withOpacity(0.12), borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.favorite_rounded, color: Color(0xFFD32F2F), size: 40)),
                const SizedBox(height: 18),
                const Text('سبحان الله', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)), textDirection: TextDirection.rtl),
                const SizedBox(height: 14),
                Text('${_state.count} / ${_state.target}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFFD32F2F)), textDirection: TextDirection.rtl),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _increment,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  icon: const Icon(Icons.touch_app_rounded),
                  label: const Text('تسبيح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة ضبط', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
