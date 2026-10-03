import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/onboarding_state.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/home/presentation/app_shell.dart';
import '../../features/guardian/presentation/guardian_screen.dart';
import '../../features/social/presentation/video_call_screen.dart';
import '../../features/notifications/presentation/notification_preferences_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/help/presentation/help_support_screen.dart';
import '../../features/home/presentation/home_dashboard_screen.dart';
import '../../features/home/presentation/wellness_tab_screen.dart';
import '../../features/home/presentation/activities_tab_screen.dart';
import '../../features/home/presentation/connect_tab_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

import '../../screens/fitness_screen.dart';
import '../../screens/breathing_exercise_screen.dart';
import '../../screens/meditation_screen.dart';
import '../../screens/meditation_video_screen.dart';
import '../../screens/yoga_screen.dart';
import '../../screens/medication_reminders_screen.dart';
import '../../MedicationIntakeScreen.dart';
import '../../screens/helpline_screen.dart';
import '../../screens/games_screen.dart';
import '../../screens/tic_tac_toe_screen.dart';
import '../../screens/dots_and_boxes_screen.dart';
import '../../screens/memory_screen.dart' show SimonSaysScreen;
import '../../screens/music_screen.dart';
import '../../screens/quotes_screen.dart';
import '../../screens/devotional_screen.dart';
import '../../screens/devotional_music_screen.dart';
import '../../screens/entertainment_screen.dart';

/// Small wrapper that turns AsyncValue<bool> from onboardingSeenProvider into
/// a value app_router's synchronous redirect can read without awaiting.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(onboardingSeenProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final onboardingState = ref.read(onboardingSeenProvider);
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';
      final onOnboarding = state.matchedLocation == '/onboarding';
      final onSplash = state.matchedLocation == '/splash';

      // Still resolving auth/onboarding state from disk.
      if (authState.isLoading || onboardingState.isLoading) {
        return onSplash ? null : '/splash';
      }

      final isLoggedIn = authState.value != null;
      final hasSeenOnboarding = onboardingState.value ?? false;

      if (!hasSeenOnboarding) {
        return onOnboarding ? null : '/onboarding';
      }
      if (!isLoggedIn) {
        return loggingIn ? null : '/login';
      }
      if (isLoggedIn && (loggingIn || onOnboarding || onSplash)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Bottom-nav shell: each tab keeps its own state while you switch.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/wellness', builder: (context, state) => const WellnessTabScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/activities', builder: (context, state) => const ActivitiesTabScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/connect', builder: (context, state) => const ConnectTabScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),

      // Wellness sub-features
      GoRoute(path: '/wellness/fitness', builder: (context, state) => FitnessScreen()),
      GoRoute(path: '/wellness/breathing', builder: (context, state) => const BreathingExerciseScreen()),
      GoRoute(path: '/wellness/meditation', builder: (context, state) => MeditationScreen()),
      GoRoute(path: '/wellness/meditation-video', builder: (context, state) => const MeditationVideoScreen()),
      GoRoute(path: '/wellness/yoga', builder: (context, state) =>  YogaScreen()),
      GoRoute(path: '/wellness/medication-reminders', builder: (context, state) => MedicationRemindersScreen()),
      GoRoute(path: '/wellness/medication-intake', builder: (context, state) => MedicationIntakeScreen()),
      GoRoute(path: '/wellness/helpline', builder: (context, state) => const HelplineScreen()),

      // Activities sub-features
      GoRoute(path: '/activities/games', builder: (context, state) => GamesScreen()),
      GoRoute(path: '/activities/games/tic-tac-toe', builder: (context, state) => const TicTacToeScreen()),
      GoRoute(path: '/activities/games/dots-and-boxes', builder: (context, state) => const DotsAndBoxesScreen()),
      GoRoute(path: '/activities/memory', builder: (context, state) => const SimonSaysScreen()),
      GoRoute(path: '/activities/music', builder: (context, state) => MusicScreen()),
      GoRoute(path: '/activities/quotes', builder: (context, state) => const QuotesScreen()),
      GoRoute(path: '/activities/devotional', builder: (context, state) => const DevotionalScreen()),
      GoRoute(path: '/activities/devotional-music', builder: (context, state) => const DevotionalMusicScreen()),
      GoRoute(path: '/activities/entertainment', builder: (context, state) => const EntertainmentScreen()),

      // Connect sub-features
      GoRoute(path: '/connect/guardian', builder: (context, state) => const GuardianScreen()),
      GoRoute(
        path: '/connect/video-call/:channel',
        builder: (context, state) => VideoCallScreen(
          channelName: state.pathParameters['channel']!,
        ),
      ),

      // Profile sub-features
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (context, state) => const HelpSupportScreen(),
      ),
    ],
  );
});
