import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';

import '../../features/home/presentation/app_shell.dart';
import '../../features/home/presentation/home_dashboard_screen.dart';
import '../../features/home/presentation/wellness_tab_screen.dart';
import '../../features/home/presentation/activities_tab_screen.dart';
import '../../features/home/presentation/connect_tab_screen.dart';

import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';

import '../../features/notifications/presentation/notification_preferences_screen.dart';
import '../../features/help/presentation/help_support_screen.dart';

import '../../features/guardian/presentation/guardian_app_shell.dart';
import '../../features/guardian/presentation/guardian_dashboard_screen.dart';
import '../../features/guardian/presentation/guardian_seniors_screen.dart';
import '../../features/guardian/presentation/guardian_screen.dart';

import '../../features/social/presentation/video_call_screen.dart';

/// Refreshes GoRouter whenever authentication or the user's
/// Firestore profile changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });

    ref.listen(profileProvider, (_, __) {
      notifyListeners();
    });

    ref.onDispose(dispose);
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',

    refreshListenable: refreshNotifier,

    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final profileState = ref.read(profileProvider);

      final location = state.matchedLocation;

      // Wait until Firebase authentication state is known.
      if (authState.isLoading) {
        return null;
      }

      final user = authState.valueOrNull;

      // Public routes.
      const publicRoutes = {
        '/login',
        '/signup',
      };

      // Not signed in.
      if (user == null) {
        if (publicRoutes.contains(location)) {
          return null;
        }

        return '/login';
      }

      // Signed in, but profile is still loading.
      if (profileState.isLoading) {
        return null;
      }

      final profile = profileState.valueOrNull;

      // A signed-in user should have a Firestore profile.
      if (profile == null) {
        return '/login';
      }

      final role = profile['role'] as String?;

      // Only supported roles are allowed.
      if (role != 'senior' && role != 'guardian') {
        return '/login';
      }

      // Root route.
      if (location == '/' || location.isEmpty) {
        return role == 'guardian' ? '/guardian' : '/home';
      }

      final isGuardianRoute =
          location == '/guardian' || location.startsWith('/guardian/');

      final isSeniorRoute =
          location == '/home' ||
          location.startsWith('/home/') ||
          location == '/wellness' ||
          location.startsWith('/wellness/') ||
          location == '/activities' ||
          location.startsWith('/activities/') ||
          location == '/connect' ||
          location.startsWith('/connect/') ||
          location == '/profile' ||
          location.startsWith('/profile/');

      // Guardian accounts should stay inside Guardian navigation.
      if (role == 'guardian' && isSeniorRoute) {
        return '/guardian';
      }

      // Senior accounts cannot enter Guardian navigation.
      if (role == 'senior' && isGuardianRoute) {
        return '/home';
      }

      return null;
    },

    routes: [
      // ------------------------------------------------------------
      // ROOT
      // ------------------------------------------------------------
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),

      // ------------------------------------------------------------
      // AUTH
      // ------------------------------------------------------------
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // ------------------------------------------------------------
      // SENIOR APP
      // ------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // HOME
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) {
                  return const HomeDashboardScreen();
                },
              ),
            ],
          ),

          // WELLNESS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wellness',
                builder: (context, state) {
                  return const WellnessTabScreen();
                },
              ),
            ],
          ),

          // ACTIVITIES
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activities',
                builder: (context, state) {
                  return const ActivitiesTabScreen();
                },
              ),
            ],
          ),

          // CONNECT
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/connect',
                builder: (context, state) {
                  return const ConnectTabScreen();
                },
                routes: [
                  GoRoute(
                    path: 'guardian',
                    builder: (context, state) {
                      return const GuardianScreen();
                    },
                  ),
                ],
              ),
            ],
          ),

          // PROFILE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  return const ProfileScreen();
                },
              ),
            ],
          ),
        ],
      ),

      // ------------------------------------------------------------
      // SENIOR PROFILE SUB-PAGES
      // ------------------------------------------------------------
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          return const EditProfileScreen();
        },
      ),

      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) {
          return const NotificationPreferencesScreen();
        },
      ),

      GoRoute(
        path: '/profile/help',
        builder: (context, state) {
          return const HelpSupportScreen();
        },
      ),

      // ------------------------------------------------------------
      // GUARDIAN APP
      // ------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return GuardianAppShell(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // GUARDIAN DASHBOARD
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guardian',
                builder: (context, state) {
                  return const GuardianDashboardScreen();
                },
              ),
            ],
          ),

          // CONNECTED SENIORS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guardian/seniors',
                builder: (context, state) {
                  return const GuardianSeniorsScreen();
                },
              ),
            ],
          ),

          // ALERTS
          //
          // The original GuardianAlertsScreen file is empty,
          // so we use a temporary functional screen instead
          // of referencing a nonexistent class.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guardian/alerts',
                builder: (context, state) {
                  return const _GuardianPlaceholderScreen(
                    title: 'Alerts',
                    icon: Icons.notifications_none,
                  );
                },
              ),
            ],
          ),

          // CALLS
          //
          // The original GuardianCallsScreen file is empty,
          // so we use a temporary screen here.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guardian/calls',
                builder: (context, state) {
                  return const _GuardianPlaceholderScreen(
                    title: 'Calls',
                    icon: Icons.video_call_outlined,
                  );
                },
              ),
            ],
          ),

          // GUARDIAN PROFILE
          //
          // guardian_profile_screen.dart is empty, so use the
          // existing ProfileScreen until a dedicated Guardian
          // ProfileScreen is implemented.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guardian/profile',
                builder: (context, state) {
                  return const ProfileScreen();
                },
              ),
            ],
          ),
        ],
      ),

      // ------------------------------------------------------------
      // VIDEO CALL
      // ------------------------------------------------------------
      GoRoute(
        path: '/connect/video-call/:channel',
        builder: (context, state) {
          final channelName =
              state.pathParameters['channel'] ?? '';

          return VideoCallScreen(
            channelName: channelName,
          );
        },
      ),
    ],
  );
});

/// Temporary screen for Guardian sections whose dedicated
/// implementation files are currently empty.
class _GuardianPlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _GuardianPlaceholderScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: colors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This section is ready for implementation.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}