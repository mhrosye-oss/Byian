import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class CircleInviteQrScreen extends StatelessWidget {
  const CircleInviteQrScreen({
    super.key,
    required this.code,
    this.circleName,
    this.expiresAt,
  });
  final String code;
  final String? circleName;
  final String? expiresAt;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('دعوة إلى الدائرة')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  circleName ?? 'الدائرة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 18),
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                if (expiresAt?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('صالح حتى: $expiresAt'),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ الكود.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('نسخ'),
                    ),
                    FilledButton.icon(
                      onPressed: () => Share.share(
                        'انضم إلى دائرتي على تطبيق إتقان\nكود الدعوة: $code',
                        subject: 'دعوة للانضمام',
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
