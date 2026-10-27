import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentFilePath;

  bool get isRecording => _isRecording;
  String? get currentFilePath => _currentFilePath;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Starts recording microphone audio to a temporary cache file.
  Future<bool> startRecording() async {
    try {
      final permitted = await hasPermission();
      if (!permitted) return false;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentFilePath = '${tempDir.path}/ben_audio_$timestamp.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentFilePath!,
      );

      _isRecording = true;
      return true;
    } catch (_) {
      _isRecording = false;
      return false;
    }
  }

  /// Stops recording and returns the recorded audio file path.
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path ?? _currentFilePath;
    } catch (_) {
      _isRecording = false;
      return null;
    }
  }

  /// Cancels recording and cleans up temporary file.
  Future<void> cancelRecording() async {
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    _isRecording = false;
    cleanupAudioFile();
  }

  /// Deletes the temporary recorded audio file to protect privacy.
  void cleanupAudioFile() {
    if (_currentFilePath != null) {
      try {
        final file = File(_currentFilePath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
      _currentFilePath = null;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
