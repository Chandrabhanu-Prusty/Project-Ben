/// Application configuration loaded from environment variables or compile-time declarations.
class AppConfig {
  AppConfig._();

  static const String appName = 'Ben';
  static const String appTagline = 'Your phone, your notifications, your personal AI assistant.';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tikyjyokcrwqdkgjioxe.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpa3lqeW9rY3J3cWRrZ2ppb3hlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwOTEwNTksImV4cCI6MjEwODY2NzA1OX0.Gkb_YLOsZQXkdOBEUz4Dck24HNKLQiotwE52VuuIhD0',
  );

  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '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',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('placeholder') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('placeholder');
}
