import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../data/circle_fcm_service.dart';
import '../../domain/circle_models.dart';
import 'circle_dashboard_screen.dart';

class CircleNotificationsScreen extends StatelessWidget {
  const CircleNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الإشعارات')),
        body: ValueListenableBuilder<List<RemoteMessage>>(
          valueListenable: CircleFcmService.instance.recentMessages,
          builder: (context, messages, _) {
            if (messages.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 90),
                  Icon(Icons.notifications_none_rounded,
                      size: 62, color: ItqanColors.muted),
                  SizedBox(height: 14),
                  Center(
                    child: Text(
                      'ستظهر هنا الإشعارات التي تصل إلى هذا الجهاز.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ItqanColors.inkSoft, height: 1.5),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final message = messages[index];
                final title = message.notification?.title ??
                    message.data['title']?.toString() ??
                    'إشعار من إتقان';
                final body = message.notification?.body ??
                    message.data['body']?.toString() ??
                    'وصل تحديث جديد.';
                final template = message.data['template']?.toString() ?? '';
                final circleUuid = message.data['circle_uuid']?.toString();
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE7F1EB),
                      foregroundColor: ItqanColors.emerald,
                      child: Icon(Icons.notifications_active_outlined),
                    ),
                    title: Text(title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(body,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: template.startsWith('task_')
                        ? const Icon(Icons.task_alt_rounded)
                        : const Icon(Icons.chevron_left_rounded),
                    onTap: circleUuid == null || circleUuid.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CircleDashboardScreen(
                                  circle: Circle(
                                    id: 0,
                                    uuid: circleUuid,
                                    name: message.data['circle_name']
                                            ?.toString() ??
                                        'الدائرة',
                                  ),
                                ),
                              ),
                            ),
                  ),
                );
              },
            );
          },
        ),
      );
}
