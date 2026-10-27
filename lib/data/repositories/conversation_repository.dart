import '../local/conversation_dao.dart';
import '../local/message_dao.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

class ConversationRepository {
  final ConversationDao _conversationDao;
  final MessageDao _messageDao;

  ConversationRepository({
    ConversationDao? conversationDao,
    MessageDao? messageDao,
  })  : _conversationDao = conversationDao ?? ConversationDao(),
        _messageDao = messageDao ?? MessageDao();

  Future<void> saveConversation(Conversation conversation) async {
    await _conversationDao.insertConversation(conversation);
  }

  Future<List<Conversation>> getConversations({
    required String ownerUserId,
    int? limit,
  }) async {
    return await _conversationDao.getConversations(
      ownerUserId: ownerUserId,
      limit: limit,
    );
  }

  Future<Conversation?> getConversationById(
    String id,
    String ownerUserId,
  ) async {
    return await _conversationDao.getConversationById(id, ownerUserId);
  }

  Future<void> updateTitle({
    required String id,
    required String ownerUserId,
    required String title,
  }) async {
    await _conversationDao.updateTitle(
      id: id,
      ownerUserId: ownerUserId,
      title: title,
    );
  }

  Future<void> addMessage(ChatMessage message) async {
    // 1. Insert message
    await _messageDao.insertMessage(message);
    // 2. Touch conversation updated_at without extending its 36h expiration
    await _conversationDao.touchUpdatedAt(
      id: message.conversationId,
      ownerUserId: message.ownerUserId,
    );
  }

  Future<List<ChatMessage>> getMessages({
    required String conversationId,
    required String ownerUserId,
  }) async {
    return await _messageDao.getMessages(
      conversationId: conversationId,
      ownerUserId: ownerUserId,
    );
  }

  Future<void> deleteConversation(String id, String ownerUserId) async {
    // SQLite cascade deletes associated messages, but messageDao call ensures consistency
    await _conversationDao.deleteConversation(id, ownerUserId);
  }

  Future<void> clearAllConversations(String ownerUserId) async {
    await _conversationDao.clearAllForUser(ownerUserId);
  }
}
