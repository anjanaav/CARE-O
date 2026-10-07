import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/guardian/presentation/guardian_alerts_screen.dart';
import '../../features/guardian/presentation/guardian_calls_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/guardian/presentation/guardian_dashboard_screen.dart';
import '../../features/guardian/presentation/guardian_seniors_screen.dart';
import '../../features/guardian/presentation/guardian_screen.dart';
import '../../features/social/presentation/video_call_screen.dart';
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

      // Wait for Firebase authentication state.
      if (authState.isLoading) {
        return null;
      }

      final user = authState.valueOrNull;

      // ------------------------------------------------------------
      // SIGNED OUT
      // ------------------------------------------------------------

      if (user == null) {
        const publicRoutes = {
          '/login',
          '/signup',
        };

        if (publicRoutes.contains(location)) {
          return null;
        }

        return '/login';
      }

      // ------------------------------------------------------------
      // PROFILE
      // ------------------------------------------------------------

      if (profileState.isLoading) {
        return null;
      }

      final profile = profileState.valueOrNull;

      if (profile == null) {
        return '/login';
      }

      final role = profile['role'] as String?;

      if (role != 'senior' && role != 'guardian') {
        return '/login';
      }

      // ------------------------------------------------------------
      // ROOT
      // ------------------------------------------------------------

      if (location == '/' || location.isEmpty) {
        return role == 'guardian' ? '/guardian' : '/home';
      }

      // ------------------------------------------------------------
      // GUARDIAN ROUTE PROTECTION
      // ------------------------------------------------------------

      final isGuardianRoute =
          location == '/guardian' || location.startsWith('/guardian/');

      if (role == 'guardian' && !isGuardianRoute) {
        return '/guardian';
      }

      // ------------------------------------------------------------
      // SENIOR ROUTE PROTECTION
      // ------------------------------------------------------------

      if (role == 'senior' && isGuardianRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // ============================================================
      // ROOT
      // ============================================================

      GoRoute(
        path: '/',
        builder: (context, state) {
          return const SizedBox.shrink();
        },
      ),

      // ============================================================
      // AUTH
      // ============================================================

      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginScreen();
        },
      ),

      GoRoute(
        path: '/signup',
        builder: (context, state) {
          return const SignupScreen();
        },
      ),

      // ============================================================
      // SENIOR APPLICATION
      // ============================================================

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

      // ============================================================
      // PROFILE SUB-PAGES
      // ============================================================

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

      // ============================================================
      // GUARDIAN APPLICATION
      // ============================================================

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return GuardianAppShell(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // DASHBOARD
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

          // SENIORS
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
// ALERTS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guardian/alerts',
                builder: (context, state) {
                  return GuardianAlertsScreen();
                },
              ),
            ],
          ),

          // CALLS
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/guardian/calls',
      builder: (context, state) {
        return const GuardianCallsScreen();
      },
    ),
  ],
),

          // GUARDIAN PROFILE
          //
          // Dedicated Guardian profile screen does not exist yet.
          // Use the existing ProfileScreen.
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

      // ============================================================
      // VIDEO CALL
      // ============================================================

      GoRoute(
        path: '/connect/video-call/:channel',
        builder: (context, state) {
          final channelName = state.pathParameters['channel'] ?? '';

          return VideoCallScreen(
            channelName: channelName,
          );
        },
      ),
    ],
  );
});
