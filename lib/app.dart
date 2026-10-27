import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/services/speech_service.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/navigation/main_scaffold.dart';
import 'features/onboarding/permission_screen.dart';
import 'features/onboarding/privacy_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'state/assistant_state.dart';
import 'state/auth_state.dart';
import 'state/notification_state.dart';

class BenApp extends StatelessWidget {
  const BenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStateController()),
        ChangeNotifierProvider(create: (_) => NotificationStateController()),
        ChangeNotifierProvider(create: (_) => AssistantStateController()),
        ChangeNotifierProvider(create: (_) => SpeechService()),
      ],
      child: Consumer<AuthStateController>(
        builder: (context, authState, child) {
          // Sync authenticated user ID to notification and assistant controllers
          final notifController = context.read<NotificationStateController>();
          final assistantController = context.read<AssistantStateController>();

          if (authState.userId != null) {
            notifController.setUserId(authState.userId);
            assistantController.setUserId(authState.userId);
          }

          return MaterialApp(
            title: 'Ben',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            initialRoute: '/splash',
            routes: {
              '/splash': (ctx) => const SplashScreen(),
              '/welcome': (ctx) => const WelcomeScreen(),
              '/auth/login': (ctx) => const LoginScreen(),
              '/auth/signup': (ctx) => const SignupScreen(),
              '/auth/forgot-password': (ctx) => const ForgotPasswordScreen(),
              '/auth/reset-password': (ctx) => const ResetPasswordScreen(),
              '/onboarding/privacy': (ctx) => const PrivacyIntroductionScreen(),
              '/onboarding/permissions': (ctx) => const PermissionSetupScreen(),
              '/dashboard': (ctx) => const MainScaffold(initialIndex: 0),
              '/assistant': (ctx) => const MainScaffold(initialIndex: 1),
              '/history': (ctx) => const MainScaffold(initialIndex: 2),
              '/settings': (ctx) => const MainScaffold(initialIndex: 3),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/auth/verify-email') {
                final args = settings.arguments as Map<String, dynamic>?;
                final email = args?['email'] as String? ?? '';
                return MaterialPageRoute(
                  builder: (ctx) => OtpVerificationScreen(
                    isPhone: false,
                    destination: email,
                  ),
                );
              } else if (settings.name == '/auth/verify-phone') {
                final args = settings.arguments as Map<String, dynamic>?;
                final phone = args?['phone'] as String? ?? '';
                return MaterialPageRoute(
                  builder: (ctx) => OtpVerificationScreen(
                    isPhone: true,
                    destination: phone,
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
