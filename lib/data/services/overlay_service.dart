import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverlayService {
  static const MethodChannel _methodChannel = MethodChannel('com.example.ben/overlay');

  static const String _keyOverlayEnabled = 'overlay_enabled';
  static const String _keyOverlayOpacity = 'overlay_opacity';

  /// Checks if SYSTEM_ALERT_WINDOW (display over other apps) is granted.
  static Future<bool> isOverlayPermissionGranted() async {
    if (kIsWeb) return false;
    try {
      final bool? granted = await _methodChannel.invokeMethod<bool>('isOverlayPermissionGranted');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the Android "Draw over other apps" settings screen.
  static Future<void> requestOverlayPermission() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  /// Shows the draggable floating assistant icon.
  static Future<bool> showOverlay() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await _methodChannel.invokeMethod<bool>('showOverlay');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOverlayEnabled, true);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Hides or disables the floating overlay.
  static Future<bool> hideOverlay() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await _methodChannel.invokeMethod<bool>('hideOverlay');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOverlayEnabled, false);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets the opacity of the floating assistant icon (0.2 to 1.0).
  static Future<void> setOpacity(double opacity) async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('setOpacity', {'opacity': opacity});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyOverlayOpacity, opacity);
    } catch (_) {}
  }

  /// Updates speaking animation state on the native overlay.
  static Future<void> setSpeakingState(bool isSpeaking) async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('setSpeakingState', {'isSpeaking': isSpeaking});
    } catch (_) {}
  }

  /// Loads saved user preference for overlay enabled.
  static Future<bool> isOverlayEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOverlayEnabled) ?? false;
  }

  /// Loads saved user preference for overlay opacity (default 0.9).
  static Future<double> getOverlayOpacityPref() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyOverlayOpacity) ?? 0.9;
  }
}
