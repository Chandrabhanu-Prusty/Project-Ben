import '../../core/utils/retention_policy.dart';

/// Represents a captured notification stored locally in SQLite.
class NotificationItem {
  final String id;
  final String ownerUserId;
  final String appName;
  final String? packageName;
  final String? sourceKey;
  final String? senderName;
  final String? title;
  final String? body;
  final String priority; // 'high', 'normal', 'low'
  final int receivedAt; // epoch milliseconds UTC
  final int updatedAt; // epoch milliseconds UTC
  final int? removedAt; // epoch milliseconds UTC, null if active in shade
  final int expiresAt; // epoch milliseconds UTC (receivedAt + 36h)

  NotificationItem({
    required this.id,
    required this.ownerUserId,
    required this.appName,
    this.packageName,
    this.sourceKey,
    this.senderName,
    this.title,
    this.body,
    this.priority = 'normal',
    required this.receivedAt,
    required this.updatedAt,
    this.removedAt,
    required this.expiresAt,
  });

  /// Factory helper that automatically calculates expiresAt if not explicitly provided.
  factory NotificationItem.create({
    required String id,
    required String ownerUserId,
    required String appName,
    String? packageName,
    String? sourceKey,
    String? senderName,
    String? title,
    String? body,
    String priority = 'normal',
    int? receivedAt,
    int? updatedAt,
    int? removedAt,
    int? expiresAt,
  }) {
    final now = receivedAt ?? RetentionPolicy.currentTimestamp();
    return NotificationItem(
      id: id,
      ownerUserId: ownerUserId,
      appName: appName,
      packageName: packageName,
      sourceKey: sourceKey,
      senderName: senderName,
      title: title,
      body: body,
      priority: priority,
      receivedAt: now,
      updatedAt: updatedAt ?? now,
      removedAt: removedAt,
      expiresAt: expiresAt ?? RetentionPolicy.calculateExpiration(now),
    );
  }

  bool get isExpired => RetentionPolicy.isExpired(expiresAt);
  bool get isHighPriority => priority.toLowerCase() == 'high';
  bool get isNormalPriority => priority.toLowerCase() == 'normal';
  bool get isLowPriority => priority.toLowerCase() == 'low';
  bool get isRemovedFromShade => removedAt != null;

  NotificationItem copyWith({
    String? id,
    String? ownerUserId,
    String? appName,
    String? packageName,
    String? sourceKey,
    String? senderName,
    String? title,
    String? body,
    String? priority,
    int? receivedAt,
    int? updatedAt,
    int? removedAt,
    int? expiresAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      sourceKey: sourceKey ?? this.sourceKey,
      senderName: senderName ?? this.senderName,
      title: title ?? this.title,
      body: body ?? this.body,
      priority: priority ?? this.priority,
      receivedAt: receivedAt ?? this.receivedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      removedAt: removedAt ?? this.removedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'app_name': appName,
      'package_name': packageName,
      'source_key': sourceKey,
      'sender_name': senderName,
      'title': title,
      'body': body,
      'priority': priority,
      'received_at': receivedAt,
      'updated_at': updatedAt,
      'removed_at': removedAt,
      'expires_at': expiresAt,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      ownerUserId: map['owner_user_id'] as String,
      appName: map['app_name'] as String,
      packageName: map['package_name'] as String?,
      sourceKey: map['source_key'] as String?,
      senderName: map['sender_name'] as String?,
      title: map['title'] as String?,
      body: map['body'] as String?,
      priority: (map['priority'] as String?) ?? 'normal',
      receivedAt: map['received_at'] as int,
      updatedAt: map['updated_at'] as int,
      removedAt: map['removed_at'] as int?,
      expiresAt: map['expires_at'] as int,
    );
  }
}
