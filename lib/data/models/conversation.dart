import '../../core/utils/retention_policy.dart';

/// Represents a conversation session between user and Ben.
class Conversation {
  final String id;
  final String ownerUserId;
  final String? title;
  final int createdAt; // epoch milliseconds UTC
  final int updatedAt; // epoch milliseconds UTC
  final int expiresAt; // epoch milliseconds UTC (createdAt + 36h, fixed)

  Conversation({
    required this.id,
    required this.ownerUserId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  factory Conversation.create({
    required String id,
    required String ownerUserId,
    String? title,
    int? createdAt,
    int? updatedAt,
    int? expiresAt,
  }) {
    final now = createdAt ?? RetentionPolicy.currentTimestamp();
    return Conversation(
      id: id,
      ownerUserId: ownerUserId,
      title: title,
      createdAt: now,
      updatedAt: updatedAt ?? now,
      expiresAt: expiresAt ?? RetentionPolicy.calculateExpiration(now),
    );
  }

  bool get isExpired => RetentionPolicy.isExpired(expiresAt);

  Conversation copyWith({
    String? id,
    String? ownerUserId,
    String? title,
    int? createdAt,
    int? updatedAt,
    int? expiresAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'title': title,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'expires_at': expiresAt,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      ownerUserId: map['owner_user_id'] as String,
      title: map['title'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      expiresAt: map['expires_at'] as int,
    );
  }
}
