import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ben/data/repositories/auth_repository.dart';
import 'package:ben/state/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthStateController Unit Tests', () {
    test('Initial state is unauthenticated with onboarding incomplete', () {
      final repo = AuthRepository();
      final auth = AuthStateController(authRepository: repo);

      expect(auth.isAuthenticated, isFalse);
      expect(auth.user, isNull);
      expect(auth.userId, isNull);
      expect(auth.isLoading, isFalse);
    });

    test('Email sign up and sign in establishes user session', () async {
      final repo = AuthRepository();
      final auth = AuthStateController(authRepository: repo);

      final success = await auth.signUpWithEmail('student@college.edu', 'secretPass123');
      expect(success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.email, 'student@college.edu');
    });

    test('Mobile number sign up establishes user session', () async {
      final repo = AuthRepository();
      final auth = AuthStateController(authRepository: repo);

      final success = await auth.signUpWithPhone('+919876543210', 'secretPass123');
      expect(success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.userId, 'phone_user_01');
    });

    test('Google OAuth sign in establishes user session', () async {
      final repo = AuthRepository();
      final auth = AuthStateController(authRepository: repo);

      final success = await auth.signInWithGoogle();
      expect(success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.email, 'google_user@gmail.com');
    });

    test('completeOnboarding sets flag and persists', () async {
      final repo = AuthRepository();
      final auth = AuthStateController(authRepository: repo);

      expect(auth.onboardingCompleted, isFalse);
      await auth.completeOnboarding();
      expect(auth.onboardingCompleted, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });
  });
}
