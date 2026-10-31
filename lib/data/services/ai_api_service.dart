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

  static String _getWeekday(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  static String _getMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  /// Requests notification summary or answers ANY general/notification question.
  Future<Map<String, dynamic>> requestAiResponse({
    required String action, // 'summarize' or 'ask'
    String? query,
    required List<NotificationItem> notifications,
    String honorific = 'Master',
  }) async {
    // 1. If Supabase is configured and user is authenticated, call the ben-ai Edge Function
    if (_supabase != null && _supabase.auth.currentSession != null) {
      try {
        final payload = {
          'action': action,
          'query': query,
          'honorific': honorific,
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

    // 2. Direct Groq API fallback
    if (AppConfig.groqApiKey.isNotEmpty) {
      final directResult = await _callGroqDirectly(
        action: action,
        query: query,
        notifications: notifications,
        honorific: honorific,
      );
      if (directResult.isNotEmpty) return directResult;
    }

    // 3. Local resilient fallback when completely offline
    return _generateLocalSummary(
      action: action,
      query: query,
      notifications: notifications,
      honorific: honorific,
    );
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
    String honorific = 'Master',
  }) async {
    try {
      final notifJson = notifications.map((n) => {
        'app_name': n.appName,
        'sender_name': n.senderName,
        'title': n.title,
        'body': n.body,
        'received_at': n.receivedAt,
      }).toList();

      final now = DateTime.now();
      final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final ampm = now.hour >= 12 ? 'PM' : 'AM';
      final timeStr = "$hour12:${now.minute.toString().padLeft(2, '0')} $ampm";
      final dateStr = "${_getWeekday(now.weekday)}, ${_getMonth(now.month)} ${now.day}, ${now.year}";

      final prompt = '''
You are Ben, an intelligent, personal AI assistant with a loyal, sharp, sophisticated personality (similar to JARVIS or Siri).
Current local device time: $timeStr ($dateStr).
User's preferred title: $honorific.

Always address the user respectfully using phrases like "Right away, $honorific", "Certainly, $honorific", "As requested, $honorific", "Here is what you missed, $honorific".

Capabilities:
1. General Assistant: You are NOT restricted to notifications. Answer ANY question the user asks (current time, date, simple math, general knowledge, advice, explanations, friendly greetings). If the user asks for the time or date, use the provided local time ($timeStr, $dateStr).
2. Notifications & Emails: You have real-time access to the user's intercepted mobile notifications and emails below. If the user asks about emails, look for Gmail, Outlook, or Mail apps and tell them what emails they received, who sent them, and what the subjects are.

Notifications & Emails context:
${jsonEncode(notifJson)}

User query:
${query ?? "Summarize what notifications and emails I missed and highlight what needs attention."}

Instructions:
1. Provide a direct, conversational, spoken-friendly response addressing the user as $honorific.
2. Return STRICTLY valid JSON with format:
{
  "summary": "conversational summary string addressing the user as $honorific",
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
            {
              'role': 'system',
              'content': 'You are Ben, a personal AI assistant. Always address the user respectfully as $honorific and respond in JSON.'
            },
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.3,
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

  /// Local resilient fallback when completely offline.
  Map<String, dynamic> _generateLocalSummary({
    required String action,
    String? query,
    required List<NotificationItem> notifications,
    String honorific = 'Master',
  }) {
    final now = DateTime.now();
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "$hour12:${now.minute.toString().padLeft(2, '0')} $ampm";
    final dateStr = "${_getWeekday(now.weekday)}, ${_getMonth(now.month)} ${now.day}, ${now.year}";

    final q = (query ?? '').toLowerCase().trim();

    // 1. Time query
    if (q.contains('time') || q.contains('clock') || q.contains('what is the time')) {
      return {
        'summary': 'It is currently $timeStr, $honorific.',
        'priorities': [],
        'groups': [],
      };
    }

    // 2. Date query
    if (q.contains('date') || q.contains('today') || q.contains('day is it')) {
      return {
        'summary': 'Today is $dateStr, $honorific.',
        'priorities': [],
        'groups': [],
      };
    }

    // 3. Email query
    if (q.contains('email') || q.contains('mail') || q.contains('gmail') || q.contains('outlook')) {
      final emails = notifications.where((n) {
        final app = n.appName.toLowerCase();
        return app.contains('mail') || app.contains('gmail') || app.contains('outlook');
      }).toList();

      if (emails.isEmpty) {
        return {
          'summary': 'You do not have any new email notifications at the moment, $honorific.',
          'priorities': [],
          'groups': [],
        };
      } else {
        final emailDetails = emails.take(3).map((e) => '${e.senderName ?? e.appName}: ${e.title ?? e.body ?? ""}').join('. ');
        return {
          'summary': 'You have ${emails.length} email notifications, $honorific. Latest: $emailDetails',
          'priorities': [],
          'groups': [],
        };
      }
    }

    // 4. Greeting query
    if (q.contains('hello') || q.contains('hi') || q.contains('hey') || q.contains('who are you')) {
      return {
        'summary': 'Greetings, $honorific. I am Ben, your personal assistant. How may I serve you today?',
        'priorities': [],
        'groups': [],
      };
    }

    if (notifications.isEmpty) {
      return {
        'summary': "You have no new notifications right now, $honorific. You're completely caught up!",
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
          'You have $total new notifications, $honorific: $appBreakdown. At least ${highPriority.length} appear urgent in ${sample.appName}.';
    } else {
      summaryText =
          'You have $total new notifications, $honorific: $appBreakdown. None currently appear urgent.';
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
