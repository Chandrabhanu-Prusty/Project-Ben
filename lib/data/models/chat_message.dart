import '../../core/utils/retention_policy.dart';

/// Represents a message within a conversation (role: 'user' or 'assistant').
class ChatMessage {
  final String id;
  final String conversationId;
  final String ownerUserId;
  final String role; // 'user' or 'assistant'
  final String content;
  final int createdAt; // epoch milliseconds UTC
  final int expiresAt; // epoch milliseconds UTC

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.ownerUserId,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ChatMessage.create({
    required String id,
    required String conversationId,
    required String ownerUserId,
    required String role,
    required String content,
    int? createdAt,
    int? expiresAt,
  }) {
    final now = createdAt ?? RetentionPolicy.currentTimestamp();
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      ownerUserId: ownerUserId,
      role: role,
      content: content,
      createdAt: now,
      expiresAt: expiresAt ?? RetentionPolicy.calculateExpiration(now),
    );
  }

  bool get isUser => role.toLowerCase() == 'user';
  bool get isAssistant => role.toLowerCase() == 'assistant';
  bool get isExpired => RetentionPolicy.isExpired(expiresAt);

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? ownerUserId,
    String? role,
    String? content,
    int? createdAt,
    int? expiresAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'owner_user_id': ownerUserId,
      'role': role,
      'content': content,
      'created_at': createdAt,
      'expires_at': expiresAt,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      ownerUserId: map['owner_user_id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      createdAt: map['created_at'] as int,
      expiresAt: map['expires_at'] as int,
    );
  }
}
