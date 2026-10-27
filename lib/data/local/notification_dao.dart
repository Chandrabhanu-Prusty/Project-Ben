import 'package:sqflite/sqflite.dart';
import '../../core/utils/retention_policy.dart';
import '../models/notification_item.dart';
import 'app_database.dart';

class NotificationDao {
  final AppDatabase _dbProvider;

  NotificationDao({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  /// Inserts or replaces a notification item.
  Future<void> upsertNotification(NotificationItem item) async {
    final db = await _db;

    // Check if a notification with the same source_key already exists for this user
    if (item.sourceKey != null && item.sourceKey!.isNotEmpty) {
      final existing = await db.query(
        'notifications',
        where: 'owner_user_id = ? AND source_key = ?',
        whereArgs: [item.ownerUserId, item.sourceKey],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // Update existing notification
        final existingId = existing.first['id'] as String;
        await db.update(
          'notifications',
          item.copyWith(id: existingId).toMap(),
          where: 'id = ?',
          whereArgs: [existingId],
        );
        return;
      }
    }

    await db.insert(
      'notifications',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Marks a notification as removed from the system shade when dismissed.
  Future<void> markRemovedFromShade(
    String id,
    String ownerUserId,
    int removedTimestamp,
  ) async {
    final db = await _db;
    await db.update(
      'notifications',
      {
        'removed_at': removedTimestamp,
        'updated_at': RetentionPolicy.currentTimestamp(),
      },
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, ownerUserId],
    );
  }

  /// Retrieves non-expired notifications for the authenticated user.
  /// If [activeOnly] is true, only returns notifications not yet removed from shade.
  Future<List<NotificationItem>> getNotifications({
    required String ownerUserId,
    bool activeOnly = false,
    String? priorityFilter,
    String? appNameFilter,
    int? limit,
  }) async {
    final db = await _db;
    final now = RetentionPolicy.currentExpiryCutoff();

    final whereClauses = <String>[
      'owner_user_id = ?',
      'expires_at > ?',
    ];
    final whereArgs = <dynamic>[ownerUserId, now];

    if (activeOnly) {
      whereClauses.add('removed_at IS NULL');
    }

    if (priorityFilter != null) {
      whereClauses.add('priority = ?');
      whereArgs.add(priorityFilter.toLowerCase());
    }

    if (appNameFilter != null) {
      whereClauses.add('app_name = ?');
      whereArgs.add(appNameFilter);
    }

    final results = await db.query(
      'notifications',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'received_at DESC',
      limit: limit,
    );

    return results.map((m) => NotificationItem.fromMap(m)).toList();
  }

  /// Gets a single non-expired notification by ID.
  Future<NotificationItem?> getNotificationById(
    String id,
    String ownerUserId,
  ) async {
    final db = await _db;
    final now = RetentionPolicy.currentExpiryCutoff();

    final results = await db.query(
      'notifications',
      where: 'id = ? AND owner_user_id = ? AND expires_at > ?',
      whereArgs: [id, ownerUserId, now],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return NotificationItem.fromMap(results.first);
  }

  /// Counts non-expired notifications for user.
  Future<int> getNotificationCount({
    required String ownerUserId,
    bool activeOnly = false,
    String? priorityFilter,
  }) async {
    final db = await _db;
    final now = RetentionPolicy.currentExpiryCutoff();

    final whereClauses = <String>[
      'owner_user_id = ?',
      'expires_at > ?',
    ];
    final whereArgs = <dynamic>[ownerUserId, now];

    if (activeOnly) {
      whereClauses.add('removed_at IS NULL');
    }

    if (priorityFilter != null) {
      whereClauses.add('priority = ?');
      whereArgs.add(priorityFilter.toLowerCase());
    }

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE ${whereClauses.join(' AND ')}',
      whereArgs,
    );

    return Sqflite.firstIntValue(countResult) ?? 0;
  }

  /// Counts notifications grouped by app_name.
  Future<Map<String, int>> getCountsByApp({
    required String ownerUserId,
    bool activeOnly = false,
  }) async {
    final db = await _db;
    final now = RetentionPolicy.currentExpiryCutoff();

    final whereClauses = <String>[
      'owner_user_id = ?',
      'expires_at > ?',
    ];
    final whereArgs = <dynamic>[ownerUserId, now];

    if (activeOnly) {
      whereClauses.add('removed_at IS NULL');
    }

    final results = await db.rawQuery('''
      SELECT app_name, COUNT(*) as count
      FROM notifications
      WHERE ${whereClauses.join(' AND ')}
      GROUP BY app_name
      ORDER BY count DESC
    ''', whereArgs);

    final map = <String, int>{};
    for (final row in results) {
      final app = row['app_name'] as String;
      final count = row['count'] as int;
      map[app] = count;
    }
    return map;
  }

  /// Updates priority classification for a notification.
  Future<void> updatePriority({
    required String id,
    required String ownerUserId,
    required String priority,
  }) async {
    final db = await _db;
    await db.update(
      'notifications',
      {
        'priority': priority.toLowerCase(),
        'updated_at': RetentionPolicy.currentTimestamp(),
      },
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, ownerUserId],
    );
  }

  /// Deletes a specific notification.
  Future<void> deleteNotification(String id, String ownerUserId) async {
    final db = await _db;
    await db.delete(
      'notifications',
      where: 'id = ? AND owner_user_id = ?',
      whereArgs: [id, ownerUserId],
    );
  }

  /// Clears all notifications for the owner.
  Future<void> clearAllForUser(String ownerUserId) async {
    final db = await _db;
    await db.delete(
      'notifications',
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
    );
  }
}
