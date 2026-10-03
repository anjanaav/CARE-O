import 'package:flutter/material.dart';

/// Shown briefly while the router's redirect logic resolves the
/// auth-state and onboarding-seen streams (see core/routing/app_router.dart).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('CARE-O', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Where United as a Family',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
