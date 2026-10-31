import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  SpeechService() {
    _initTts();
  }

  bool get isSpeaking => _isSpeaking;

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    // 0.85 gives a deep, confident masculine resonance
    await _flutterTts.setPitch(0.85);

    try {
      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        dynamic maleVoice;
        for (final v in voices) {
          if (v is Map) {
            final name = (v['name'] ?? '').toString().toLowerCase();
            final locale = (v['locale'] ?? '').toString().toLowerCase();
            if (locale.contains('en-us') || locale.contains('en_us')) {
              if (name.contains('male') ||
                  name.contains('#male') ||
                  name.contains('en-us-x-sfg') ||
                  name.contains('en-us-x-tpd') ||
                  name.contains('en-us-x-iol')) {
                maleVoice = v;
                break;
              }
            }
          }
        }
        if (maleVoice != null && maleVoice is Map) {
          await _flutterTts.setVoice({
            'name': maleVoice['name'].toString(),
            'locale': maleVoice['locale'].toString(),
          });
        }
      }
    } catch (_) {}

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
