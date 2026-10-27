import '../local/notification_dao.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  final NotificationDao _notificationDao;

  NotificationRepository({NotificationDao? notificationDao})
      : _notificationDao = notificationDao ?? NotificationDao();

  Future<void> saveNotification(NotificationItem item) async {
    await _notificationDao.upsertNotification(item);
  }

  Future<void> markRemoved(String id, String ownerUserId, int timestamp) async {
    await _notificationDao.markRemovedFromShade(id, ownerUserId, timestamp);
  }

  Future<List<NotificationItem>> getNotifications({
    required String ownerUserId,
    bool activeOnly = false,
    String? priorityFilter,
    String? appNameFilter,
    int? limit,
  }) async {
    return await _notificationDao.getNotifications(
      ownerUserId: ownerUserId,
      activeOnly: activeOnly,
      priorityFilter: priorityFilter,
      appNameFilter: appNameFilter,
      limit: limit,
    );
  }

  Future<NotificationItem?> getNotificationById(
    String id,
    String ownerUserId,
  ) async {
    return await _notificationDao.getNotificationById(id, ownerUserId);
  }

  Future<int> getNotificationCount({
    required String ownerUserId,
    bool activeOnly = false,
    String? priorityFilter,
  }) async {
    return await _notificationDao.getNotificationCount(
      ownerUserId: ownerUserId,
      activeOnly: activeOnly,
      priorityFilter: priorityFilter,
    );
  }

  Future<Map<String, int>> getCountsByApp({
    required String ownerUserId,
    bool activeOnly = false,
  }) async {
    return await _notificationDao.getCountsByApp(
      ownerUserId: ownerUserId,
      activeOnly: activeOnly,
    );
  }

  /// Groups non-expired notifications by application name.
  Future<Map<String, List<NotificationItem>>> getGroupedNotifications({
    required String ownerUserId,
    bool activeOnly = false,
  }) async {
    final list = await _notificationDao.getNotifications(
      ownerUserId: ownerUserId,
      activeOnly: activeOnly,
    );

    final grouped = <String, List<NotificationItem>>{};
    for (final item in list) {
      grouped.putIfAbsent(item.appName, () => []).add(item);
    }
    return grouped;
  }

  Future<void> updatePriority({
    required String id,
    required String ownerUserId,
    required String priority,
  }) async {
    await _notificationDao.updatePriority(
      id: id,
      ownerUserId: ownerUserId,
      priority: priority,
    );
  }

  Future<void> deleteNotification(String id, String ownerUserId) async {
    await _notificationDao.deleteNotification(id, ownerUserId);
  }

  Future<void> clearAll(String ownerUserId) async {
    await _notificationDao.clearAllForUser(ownerUserId);
  }
}
