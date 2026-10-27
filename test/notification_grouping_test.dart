import 'package:flutter_test/flutter_test.dart';
import 'package:ben/data/models/notification_item.dart';
import 'package:ben/data/services/notification_bridge.dart';
import 'package:ben/state/notification_state.dart';

void main() {
  group('Notification Priority & Grouping Heuristics Tests', () {
    test('Heuristic priority classifier accurately flags urgent messages as high', () {
      expect(
        NotificationStateController.classifyLocalPriority(
          'Assignment Submission',
          'Urgent deadline due today by 5 PM',
        ),
        'high',
      );

      expect(
        NotificationStateController.classifyLocalPriority(
          'Bank Alert',
          'Security alert: New sign in detected with OTP 492812',
        ),
        'high',
      );

      expect(
        NotificationStateController.classifyLocalPriority(
          'Invoice Notice',
          'Your bill is overdue: payment due immediately',
        ),
        'high',
      );
    });

    test('Heuristic priority classifier flags promotional messages as low', () {
      expect(
        NotificationStateController.classifyLocalPriority(
          'Amazon Deals',
          'Mega sale! Flat 50% discount with free shipping coupon',
        ),
        'low',
      );

      expect(
        NotificationStateController.classifyLocalPriority(
          'Zomato',
          'Claim your cashback on tonight dinner promo',
        ),
        'low',
      );
    });

    test('Heuristic priority classifier defaults routine messages to normal', () {
      expect(
        NotificationStateController.classifyLocalPriority(
          'College Group',
          'Class tomorrow starts at 10 AM in Room 302',
        ),
        'normal',
      );

      expect(
        NotificationStateController.classifyLocalPriority(
          'Alice',
          'Hey, are we still meeting for lunch?',
        ),
        'normal',
      );
    });

    test('NotificationBridge parses platform notification event maps safely', () {
      final data = {
        'app_name': 'WhatsApp',
        'package_name': 'com.whatsapp',
        'source_key': 'notif_key_101',
        'sender_name': 'Study Group',
        'title': 'Exam syllabus',
        'body': 'Unit 3 is included in the test',
        'timestamp': 1700000000000,
      };

      final item = NotificationBridge.parseNotificationEvent(data, 'user_123');

      expect(item, isNotNull);
      expect(item!.appName, 'WhatsApp');
      expect(item.packageName, 'com.whatsapp');
      expect(item.sourceKey, 'notif_key_101');
      expect(item.senderName, 'Study Group');
      expect(item.title, 'Exam syllabus');
      expect(item.ownerUserId, 'user_123');
      expect(item.expiresAt, item.receivedAt + (36 * 3600 * 1000));
    });

    test('NotificationItem copyWith preserves or overrides properties', () {
      final original = NotificationItem.create(
        id: '1',
        ownerUserId: 'u1',
        appName: 'Slack',
        priority: 'normal',
      );

      final updated = original.copyWith(priority: 'high', body: 'New alert');
      expect(updated.priority, 'high');
      expect(updated.body, 'New alert');
      expect(updated.appName, 'Slack');
      expect(updated.ownerUserId, 'u1');
    });
  });
}
