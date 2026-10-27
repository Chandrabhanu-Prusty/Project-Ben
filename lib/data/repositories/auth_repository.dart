import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';

/// Authentication repository wrapping Supabase Auth with fallback/development resilience.
class AuthRepository {
  final SupabaseClient? _client;
  bool _isMock = false;
  User? _mockUser;

  AuthRepository({SupabaseClient? client}) : _client = client ?? _getSupabaseClient();

  static SupabaseClient? _getSupabaseClient() {
    try {
      if (AppConfig.isConfigured) {
        return Supabase.instance.client;
      }
    } catch (_) {
      // Supabase not yet initialized
    }
    return null;
  }

  /// Initialize Supabase Flutter SDK if configured.
  static Future<void> initialize() async {
    if (AppConfig.isConfigured) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
      );
    }
  }

  /// Enables a development mock user session for testing without remote network credentials.
  void enableDevMockUser({String id = 'dev_user_01', String email = 'tester@ben.ai'}) {
    _isMock = true;
    _mockUser = User(
      id: id,
      appMetadata: {},
      userMetadata: {'full_name': 'Test User'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
  }

  User? get currentUser => _isMock ? _mockUser : _client?.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  /// Email & Password Sign Up. Triggers verification OTP email.
  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isMock || _client == null) {
      enableDevMockUser(email: email);
      return null;
    }

    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Email & Password Sign In.
  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isMock || _client == null) {
      enableDevMockUser(email: email);
      return null;
    }

    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Verify Email OTP token.
  Future<AuthResponse?> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    if (_isMock || _client == null) {
      enableDevMockUser(email: email);
      return null;
    }

    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  /// Mobile Number Sign Up.
  Future<AuthResponse?> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    if (_isMock || _client == null) {
      enableDevMockUser(id: 'phone_user_01', email: '$phone@phone.ben.ai');
      return null;
    }

    return await _client.auth.signUp(
      phone: phone,
      password: password,
    );
  }

  /// Mobile Number Sign In.
  Future<AuthResponse?> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    if (_isMock || _client == null) {
      enableDevMockUser(id: 'phone_user_01', email: '$phone@phone.ben.ai');
      return null;
    }

    return await _client.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  /// Verify Phone SMS OTP.
  Future<AuthResponse?> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    if (_isMock || _client == null) {
      enableDevMockUser(id: 'phone_user_01', email: '$phone@phone.ben.ai');
      return null;
    }

    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Google OAuth Sign In.
  Future<bool> signInWithGoogle() async {
    if (_isMock || _client == null) {
      enableDevMockUser(email: 'google_user@gmail.com');
      return true;
    }

    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.example.ben://login-callback',
    );
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    if (_isMock || _client == null) return;
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Update password after OTP recovery.
  Future<UserResponse?> resetPassword(String newPassword) async {
    if (_isMock || _client == null) return null;
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    if (_isMock) {
      _mockUser = null;
      _isMock = false;
      return;
    }
    await _client?.auth.signOut();
  }
}
