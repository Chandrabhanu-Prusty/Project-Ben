/// Application configuration loaded from environment variables or compile-time declarations.
/// Never store secret keys here.
class AppConfig {
  AppConfig._();

  static const String appName = 'Ben';
  static const String appTagline = 'Your phone, your notifications, your personal AI assistant.';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'placeholder-anon-key',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isConfigured =>
      supabaseUrl != 'https://placeholder-project.supabase.co' &&
      supabaseAnonKey != 'placeholder-anon-key';
}
