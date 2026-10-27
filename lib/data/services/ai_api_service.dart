import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../models/notification_item.dart';

class AiApiService {
  final SupabaseClient? _supabase;

  AiApiService({SupabaseClient? supabase})
      : _supabase = AppConfig.isConfigured ? Supabase.instance.client : supabase;

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
        // Fall back gracefully to local summary generator
      }
    }

    // 2. Local resilient fallback when Edge Function is offline or unconfigured
    return _generateLocalSummary(action: action, query: query, notifications: notifications);
  }

  /// Sends recorded audio to the transcribe-audio Edge Function.
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

    // Fallback if offline
    return 'What did I miss?';
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
