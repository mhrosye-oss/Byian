import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/colors.dart';
import '../domain/circle_invite_code.dart';
import '../domain/circles_providers.dart';

class JoinCircleScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const JoinCircleScreen({super.key, this.initialCode});

  @override
  ConsumerState<JoinCircleScreen> createState() => _JoinCircleScreenState();
}

class _JoinCircleScreenState extends ConsumerState<JoinCircleScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text =
          parseCircleInviteCode(widget.initialCode!) ?? widget.initialCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode([String? codeToUse]) async {
    final rawCode = codeToUse ?? _codeController.text;
    if (rawCode.trim().isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال رمز الدعوة');
      return;
    }
    final code = parseCircleInviteCode(rawCode);
    if (code == null) {
      setState(
        () => _errorMessage =
            'رمز الدعوة غير صالح. امسح رمز QR الخاص بإتقان أو أدخل رمزاً لا يتجاوز 32 حرفاً.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(circlesApiProvider);
      await api.redeemInvitation(code);

      if (mounted) {
        ref.read(myCirclesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ انضممت للدائرة بنجاح! مرحباً بك'),
            backgroundColor: ItqanColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on CirclesApiException catch (e) {
      if (mounted) {
        String msg = e.message;
        if (e.statusCode == 404) {
          msg = '❌ كود الدعوة غير صحيح أو غير موجود';
        } else if (e.statusCode == 410) {
          msg = '⚠️ انتهت صلاحية كود الدعوة';
        } else if (e.statusCode == 409) {
          msg = 'ℹ️ أنت عضو بالفعل في هذه الدائرة';
        }
        setState(() => _errorMessage = msg);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'حدث خطأ، يرجى المحاولة مرة أخرى');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QrScannerView(
          onCodeScanned: (scannedCode) {
            Navigator.pop(context);
            _codeController.text = scannedCode;
            _redeemCode(scannedCode);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: const Text(
          'الانضمام إلى دائرة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ItqanColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Header illustration icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ItqanColors.emerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.vpn_key_rounded,
                color: ItqanColors.emerald,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'أدخل رمز الدعوة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ItqanColors.ink,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'اطلب رمز الدعوة من قائد الدائرة أو امسح الباركود (QR) للانضمام فوراً.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ItqanColors.inkSoft,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ItqanColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ItqanColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: ItqanColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: ItqanColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Input field
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: ItqanColors.ink,
              ),
              decoration: InputDecoration(
                hintText: 'مثال: FAM-7890 أو رمز الدعوة',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0,
                  color: ItqanColors.muted,
                ),
                filled: true,
                fillColor: ItqanColors.surface,
                prefixIcon:
                    const Icon(Icons.pin_rounded, color: ItqanColors.emerald),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: ItqanColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: ItqanColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: ItqanColors.emerald, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _redeemCode(),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ItqanColors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded, size: 20),
                label: const Text(
                  'انضمام إلى الدائرة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ItqanColors.emerald,
                  foregroundColor: ItqanColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Divider "أو"
            Row(
              children: [
                const Expanded(
                    child: Divider(color: ItqanColors.border, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'أو',
                    style: TextStyle(
                      fontSize: 14,
                      color: ItqanColors.muted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(
                    child: Divider(color: ItqanColors.border, thickness: 1)),
              ],
            ),
            const SizedBox(height: 28),

            // QR Barcode Scanner button using mobile_scanner
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _openQrScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                label: const Text(
                  'مسح رمز الباركود (QR)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ItqanColors.emerald,
                  side:
                      const BorderSide(color: ItqanColors.emerald, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrScannerView extends StatefulWidget {
  final ValueChanged<String> onCodeScanned;

  const _QrScannerView({required this.onCodeScanned});

  @override
  State<_QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<_QrScannerView> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  String? _scanError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    for (final barcode in capture.barcodes) {
      final code = parseCircleInviteCode(barcode.rawValue ?? '');
      if (code != null) {
        _scanned = true;
        widget.onCodeScanned(code);
        break;
      }
      if (mounted &&
          _scanError != 'الرمز غير صالح؛ امسح رمز دعوة إتقان مرة أخرى.') {
        setState(
          () => _scanError = 'الرمز غير صالح؛ امسح رمز دعوة إتقان مرة أخرى.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('مسح كود الدعوة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: ItqanColors.emerald, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _scanError ?? 'وجّه الكاميرا نحو رمز QR لدعوة الدائرة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      _scanError == null ? Colors.white : Colors.orangeAccent,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
