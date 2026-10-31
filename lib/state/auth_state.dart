import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/app_database.dart';
import '../data/repositories/auth_repository.dart';

class AuthStateController extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _isLoading = false;
  String? _errorMessage;
  bool _onboardingCompleted = false;

  AuthStateController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository() {
    _init();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get onboardingCompleted => _onboardingCompleted;

  User? get user => _authRepository.currentUser;
  String? get userId => _authRepository.currentUserId;
  bool get isAuthenticated => _authRepository.isAuthenticated;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _authRepository.signInWithEmail(email: email, password: password);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _authRepository.signUpWithEmail(email: email, password: password);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyEmailOtp(String email, String token) async {
    _setLoading(true);
    try {
      await _authRepository.verifyEmailOtp(email: email, token: token);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithPhone(String phone, String password) async {
    _setLoading(true);
    try {
      await _authRepository.signInWithPhone(phone: phone, password: password);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithPhone(String phone, String password) async {
    _setLoading(true);
    try {
      await _authRepository.signUpWithPhone(phone: phone, password: password);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyPhoneOtp(String phone, String token) async {
    _setLoading(true);
    try {
      await _authRepository.verifyPhoneOtp(phone: phone, token: token);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final success = await _authRepository.signInWithGoogle();
      _errorMessage = null;
      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _authRepository.sendPasswordResetEmail(email);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    _setLoading(true);
    try {
      await _authRepository.resetPassword(newPassword);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    return resetPassword(newPassword);
  }

  Future<void> signOut() async {
    _setLoading(true);
    final previousUserId = userId;
    try {
      await _authRepository.signOut();
      // Apply user's selected choice: Delete local SQLite data immediately on logout (strictest privacy)
      if (previousUserId != null) {
        await AppDatabase.instance.clearUserData(previousUserId);
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
