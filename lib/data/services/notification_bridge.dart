import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/notification_item.dart';

class NotificationBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.example.ben/notifications');
  static const EventChannel _eventChannel = EventChannel('com.example.ben/notification_stream');

  /// Checks if user has enabled Android Notification Listener permission.
  static Future<bool> isNotificationAccessGranted() async {
    if (kIsWeb) return false;
    try {
      final bool? granted = await _methodChannel.invokeMethod<bool>('isNotificationAccessGranted');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system Android Notification Listener Settings page.
  static Future<void> openNotificationSettings() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  /// Fetches all active notifications currently sitting in the Android status bar/notification shade.
  static Future<List<Map<String, dynamic>>> getActiveNotifications() async {
    if (kIsWeb) return [];
    try {
      final List? list = await _methodChannel.invokeMethod<List>('getActiveNotifications');
      if (list != null) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Listens to live notification events from the native Android NotificationListenerService.
  static Stream<Map<String, dynamic>> get incomingNotificationStream {
    if (kIsWeb) return const Stream.empty();
    try {
      return _eventChannel.receiveBroadcastStream().map((event) {
        if (event is Map) {
          return Map<String, dynamic>.from(event);
        }
        return <String, dynamic>{};
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Helper to convert incoming platform event map to NotificationItem model.
  static NotificationItem? parseNotificationEvent(
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    try {
      final appName = data['app_name'] as String? ?? 'Unknown';
      final packageName = data['package_name'] as String?;
      final sourceKey = data['source_key'] as String?;
      final senderName = data['sender_name'] as String?;
      final title = data['title'] as String?;
      final body = data['body'] as String?;
      final timestamp = data['timestamp'] as int? ?? DateTime.now().toUtc().millisecondsSinceEpoch;

      return NotificationItem.create(
        id: '${sourceKey ?? packageName}_$timestamp',
        ownerUserId: currentUserId,
        appName: appName,
        packageName: packageName,
        sourceKey: sourceKey,
        senderName: senderName,
        title: title,
        body: body,
        receivedAt: timestamp,
      );
    } catch (_) {
      return null;
    }
  }
}
