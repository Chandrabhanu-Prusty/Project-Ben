import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../models/notification_item.dart';

class AiApiService {
  final SupabaseClient? _supabase;

  AiApiService({SupabaseClient? supabase})
      : _supabase = supabase ?? _getSupabaseClient();

  static SupabaseClient? _getSupabaseClient() {
    try {
      if (AppConfig.isConfigured) {
        return Supabase.instance.client;
      }
    } catch (_) {
      // Supabase instance not initialized
    }
    return null;
  }

  /// Requests notification summary or answers a question about current notifications.
  Future<Map<String, dynamic>> requestAiResponse({
    required String action, // 'summarize' or 'ask'
    String? query,
    required List<NotificationItem> notifications,
  }) async {
    // 1. If Supabase is configured and user is authenticated, call the ben-ai Edge Function
    if (_supabase != null && _supabase.auth.currentSession != null) {
      try {
        final payload = {
          'action': action,
          'query': query,
          'notifications': notifications.map((n) => {
            'app_name': n.appName,
            'sender_name': n.senderName,
            'title': n.title,
            'body': n.body,
            'received_at': n.receivedAt,
          }).toList(),
        };

        final response = await _supabase.functions.invoke(
          'ben-ai',
          body: payload,
        );

        if (response.status == 200 && response.data != null) {
          if (response.data is Map) {
            return Map<String, dynamic>.from(response.data);
          } else if (response.data is String) {
            return jsonDecode(response.data);
          }
        }
      } catch (_) {
        // Fall back to direct Groq API or local heuristics
      }
    }

    // 2. Direct Groq API fallback if edge function is not yet deployed
    if (AppConfig.groqApiKey.isNotEmpty) {
      final directResult = await _callGroqDirectly(
        action: action,
        query: query,
        notifications: notifications,
      );
      if (directResult.isNotEmpty) return directResult;
    }

    // 3. Local resilient fallback when completely offline
    return _generateLocalSummary(action: action, query: query, notifications: notifications);
  }

  /// Sends recorded audio to transcribe-audio Edge Function or Groq Whisper directly.
  Future<String> transcribeAudio(String audioFilePath) async {
    if (_supabase != null && _supabase.auth.currentSession != null) {
      try {
        final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/transcribe-audio');
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer ${_supabase.auth.currentSession?.accessToken}';

        request.files.add(await http.MultipartFile.fromPath('file', audioFilePath));

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['text'] as String? ?? '';
        }
      } catch (_) {}
    }

    // Direct Whisper API fallback
    if (AppConfig.groqApiKey.isNotEmpty) {
      final text = await _transcribeWithGroqDirectly(audioFilePath);
      if (text.isNotEmpty) return text;
    }

    return 'What did I miss?';
  }

  /// Direct Groq API chat completions call
  Future<Map<String, dynamic>> _callGroqDirectly({
    required String action,
    String? query,
    required List<NotificationItem> notifications,
  }) async {
    try {
      final notifJson = notifications.map((n) => {
        'app_name': n.appName,
        'sender_name': n.senderName,
        'title': n.title,
        'body': n.body,
        'received_at': n.receivedAt,
      }).toList();

      final prompt = '''
You are Ben, an intelligent mobile personal notification assistant with a futuristic Ben 10 personality.
Your task is to summarize the user's notifications and answer their questions without making them open every application.

Notifications context:
${jsonEncode(notifJson)}

User query:
${query ?? "Summarize what notifications I missed and highlight what needs attention."}

Instructions:
1. Provide a concise, conversational summary identifying total counts, app breakdown, and important deadlines/reminders.
2. Return STRICTLY valid JSON with format:
{
  "summary": "conversational summary string",
  "priorities": [
    {
      "source": "App Name",
      "priority": "high" | "normal" | "low",
      "reason": "short explanation"
    }
  ],
  "groups": [
    {
      "source": "App Name",
      "count": 1,
      "summary": "short summary"
    }
  ]
}
''';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'openai/gpt-oss-20b',
          'messages': [
            {'role': 'system', 'content': 'You are Ben, an AI notification assistant. Always respond in JSON.'},
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      }
    } catch (_) {}

    return {};
  }

  /// Direct Whisper audio transcription call
  Future<String> _transcribeWithGroqDirectly(String audioFilePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );
      request.headers['Authorization'] = 'Bearer ${AppConfig.groqApiKey}';
      request.fields['model'] = 'whisper-large-v3-turbo';
      request.fields['response_format'] = 'json';
      request.files.add(await http.MultipartFile.fromPath('file', audioFilePath));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] as String? ?? '';
      }
    } catch (_) {}
    return '';
  }

  /// Local heuristic summary builder guaranteed to work 100% offline.
  Map<String, dynamic> _generateLocalSummary({
    required String action,
    String? query,
    required List<NotificationItem> notifications,
  }) {
    if (notifications.isEmpty) {
      return {
        'summary': "You have no new notifications right now. You're completely caught up!",
        'priorities': [],
        'groups': [],
      };
    }

    final total = notifications.length;
    final highPriority = notifications.where((n) => n.isHighPriority).toList();
    final countsByApp = <String, int>{};

    for (final n in notifications) {
      countsByApp[n.appName] = (countsByApp[n.appName] ?? 0) + 1;
    }

    final appBreakdown = countsByApp.entries
        .map((e) => '${e.value} from ${e.key}')
        .join(', ');

    String summaryText;
    if (highPriority.isNotEmpty) {
      final sample = highPriority.first;
      summaryText =
          'You have $total new notifications: $appBreakdown. At least ${highPriority.length} appear urgent because of keywords in ${sample.appName}. Would you like me to read the important items first?';
    } else {
      summaryText =
          'You have $total new notifications: $appBreakdown. None currently appear urgent. Would you like a detailed breakdown?';
    }

    if (query != null && query.toLowerCase().contains('email')) {
      final emails = notifications.where((n) => n.appName.toLowerCase().contains('mail')).toList();
      if (emails.isEmpty) {
        summaryText = "You don't have any new email notifications at the moment.";
      } else {
        summaryText = "You have ${emails.length} email notifications. ${emails.first.title ?? emails.first.body ?? ''}";
      }
    }

    return {
      'summary': summaryText,
      'priorities': highPriority.map((n) => {
        'source': n.appName,
        'priority': 'high',
        'reason': 'Contains urgent time-sensitive keywords',
      }).toList(),
      'groups': countsByApp.entries.map((e) => {
        'source': e.key,
        'count': e.value,
        'summary': '${e.value} alerts from ${e.key}',
      }).toList(),
    };
  }
}
