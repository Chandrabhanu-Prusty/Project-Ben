import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/notification_item.dart';
import '../../data/services/speech_service.dart';
import '../../state/notification_state.dart';
import '../../widgets/ben_button.dart';
import '../../widgets/priority_badge.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final String notificationId;

  const NotificationDetailsScreen({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context) {
    final notifState = context.watch<NotificationStateController>();
    final speechService = context.watch<SpeechService>();

    final NotificationItem? item = notifState.notifications.cast<NotificationItem?>().firstWhere(
          (n) => n?.id == notificationId,
          orElse: () => null,
        );

    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(title: const Text('Notification Details')),
        body: const Center(
          child: Text(
            'This notification has expired or was removed.',
            style: TextStyle(color: AppColors.mutedGrey),
          ),
        ),
      );
    }

    final speechText = '${item.appName}. ${item.senderName != null ? 'From ${item.senderName}.' : ''} ${item.title ?? ''}. ${item.body ?? ''}';

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(item.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.alertRed),
            onPressed: () {
              notifState.deleteNotification(item.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.forestCharcoal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: item.isHighPriority ? AppColors.alertRed.withAlpha(90) : AppColors.subtleGreenGrey,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.darkSlateGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.apps_rounded, size: 20, color: AppColors.neonGreen),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item.appName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.softWhite,
                              ),
                            ),
                          ],
                        ),
                        PriorityBadge(priority: item.priority),
                      ],
                    ),
                    if (item.senderName != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: AppColors.neonGreen),
                          const SizedBox(width: 6),
                          Text(
                            item.senderName!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.softWhite,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.subtleGreenGrey),
                    const SizedBox(height: 8),
                    if (item.title != null && item.title!.isNotEmpty) ...[
                      Text(
                        item.title!,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.softWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      item.body != null && item.body!.isNotEmpty ? item.body! : '(No preview content exposed by source app)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.softWhite,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Received: ${DateTime.fromMillisecondsSinceEpoch(item.receivedAt).toLocal()}',
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                    ),
                    Text(
                      'Expires in 36h: ${DateTime.fromMillisecondsSinceEpoch(item.expiresAt).toLocal()}',
                      style: const TextStyle(fontSize: 11, color: AppColors.disabledText),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              BenButton(
                text: speechService.isSpeaking ? 'Stop Reading' : 'Read Aloud (TTS)',
                type: speechService.isSpeaking ? BenButtonType.destructive : BenButtonType.primary,
                icon: speechService.isSpeaking ? Icons.stop : Icons.volume_up_outlined,
                onPressed: () {
                  if (speechService.isSpeaking) {
                    speechService.stop();
                  } else {
                    speechService.speak(speechText);
                  }
                },
              ),

              const SizedBox(height: 12),

              BenButton(
                text: 'Ask Ben About This Alert',
                type: BenButtonType.secondary,
                icon: Icons.chat_bubble_outline,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/assistant',
                    arguments: {'prompt': 'Tell me about the notification from ${item.appName}: ${item.title ?? item.body}'},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
