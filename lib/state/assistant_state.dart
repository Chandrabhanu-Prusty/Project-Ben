import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/chat_message.dart';
import '../data/models/conversation.dart';
import '../data/models/notification_item.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/services/ai_api_service.dart';
import '../data/services/audio_recording_service.dart';
import '../data/services/speech_service.dart';

class AssistantStateController extends ChangeNotifier {
  final ConversationRepository _conversationRepository;
  final AiApiService _aiApiService;
  final AudioRecordingService _recordingService;
  final SpeechService _speechService;

  String? _currentUserId;
  Conversation? _activeConversation;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isRecordingVoice = false;
  String? _errorMessage;
  String _honorific = 'Master';

  AssistantStateController({
    ConversationRepository? conversationRepository,
    AiApiService? aiApiService,
    AudioRecordingService? recordingService,
    SpeechService? speechService,
  })  : _conversationRepository = conversationRepository ?? ConversationRepository(),
        _aiApiService = aiApiService ?? AiApiService(),
        _recordingService = recordingService ?? AudioRecordingService(),
        _speechService = speechService ?? SpeechService() {
    _loadHonorific();
  }

  Conversation? get activeConversation => _activeConversation;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isRecordingVoice => _isRecordingVoice;
  String? get errorMessage => _errorMessage;
  bool get isSpeaking => _speechService.isSpeaking;
  String get honorific => _honorific;

  Future<void> _loadHonorific() async {
    final prefs = await SharedPreferences.getInstance();
    _honorific = prefs.getString('user_honorific') ?? 'Master';
    notifyListeners();
  }

  Future<void> setHonorific(String newHonorific) async {
    _honorific = newHonorific;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_honorific', newHonorific);
    notifyListeners();
  }

  void setUserId(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _activeConversation = null;
    _messages = [];
    notifyListeners();
  }

  /// Starts a fresh conversation session.
  Future<void> startNewConversation({String? initialTitle}) async {
    if (_currentUserId == null) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final conv = Conversation.create(
      id: 'conv_$now',
      ownerUserId: _currentUserId!,
      title: initialTitle ?? 'Notification Query',
    );
    await _conversationRepository.saveConversation(conv);
    _activeConversation = conv;
    _messages = [];
    notifyListeners();
  }

  /// Reopens an existing non-expired conversation from History.
  Future<void> loadConversation(String conversationId) async {
    if (_currentUserId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final conv = await _conversationRepository.getConversationById(
        conversationId,
        _currentUserId!,
      );
      if (conv != null && !conv.isExpired) {
        _activeConversation = conv;
        _messages = await _conversationRepository.getMessages(
          conversationId: conversationId,
          ownerUserId: _currentUserId!,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a user message, calls AI, speaks the response aloud automatically, and stores both in local SQLite.
  Future<void> sendMessage(String text, List<NotificationItem> notifications) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _currentUserId == null) return;

    if (_activeConversation == null) {
      await startNewConversation(
        initialTitle: trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed,
      );
    }

    final convId = _activeConversation!.id;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // 1. Save and display user message
    final userMsg = ChatMessage.create(
      id: 'msg_${now}_user',
      conversationId: convId,
      ownerUserId: _currentUserId!,
      role: 'user',
      content: trimmed,
    );
    _messages.add(userMsg);
    await _conversationRepository.addMessage(userMsg);

    _isLoading = true;
    notifyListeners();

    try {
      // 2. Call AI backend / local heuristic with honorific
      final aiResult = await _aiApiService.requestAiResponse(
        action: 'ask',
        query: trimmed,
        notifications: notifications,
        honorific: _honorific,
      );

      final replyContent = aiResult['summary'] as String? ??
          'I could not generate a response. Please try again.';

      // 3. Save and display assistant response
      final assistantMsg = ChatMessage.create(
        id: 'msg_${DateTime.now().toUtc().millisecondsSinceEpoch}_assistant',
        conversationId: convId,
        ownerUserId: _currentUserId!,
        role: 'assistant',
        content: replyContent,
      );
      _messages.add(assistantMsg);
      await _conversationRepository.addMessage(assistantMsg);

      // 4. Auto-speak the response immediately for voice-to-voice flow!
      await _speechService.speak(replyContent);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles microphone audio recording for voice input.
  Future<void> toggleVoiceRecording(List<NotificationItem> currentNotifications) async {
    if (_isRecordingVoice) {
      // Stop recording and transcribe
      _isRecordingVoice = false;
      notifyListeners();

      final audioPath = await _recordingService.stopRecording();
      if (audioPath != null) {
        _isLoading = true;
        notifyListeners();

        try {
          final transcript = await _aiApiService.transcribeAudio(audioPath);
          _recordingService.cleanupAudioFile();
          if (transcript.isNotEmpty) {
            await sendMessage(transcript, currentNotifications);
          }
        } catch (_) {
          _recordingService.cleanupAudioFile();
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      }
    } else {
      // Stop any active speech before recording starts
      _speechService.stop();
      final started = await _recordingService.startRecording();
      if (started) {
        _isRecordingVoice = true;
        notifyListeners();
      }
    }
  }

  /// Reads out assistant response using native TTS.
  void readAloud(String text) {
    if (_speechService.isSpeaking) {
      _speechService.stop();
    } else {
      _speechService.speak(text);
    }
  }

  void stopSpeaking() {
    _speechService.stop();
  }
}
