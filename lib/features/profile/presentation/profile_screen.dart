import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Profile: account summary, appearance, settings, help and logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final user = authRepository.currentUser;
    final themeMode = ref.watch(themeModeProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Builder(
        builder: (context) {
          final fullName = profile.valueOrNull?['fullName'] as String? ??
              user?.displayName ??
              'CARE-O User';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (profile.isLoading && !profile.hasValue)
                      const SizedBox(
                        height: 48,
                        child: LoadingState(),
                      )
                    else ...[
                      Text(fullName, style: Theme.of(context).textTheme.titleLarge),
                      if (user?.email != null)
                        Text(user!.email!, style: Theme.of(context).textTheme.bodyMedium),
                      if (profile.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: TextButton.icon(
                            onPressed: () => ref.invalidate(profileProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text("Couldn't load your details. Retry"),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (mode) =>
                          ref.read(themeModeProvider.notifier).setThemeMode(mode!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (mode) =>
                          ref.read(themeModeProvider.notifier).setThemeMode(mode!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Use system setting'),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (mode) =>
                          ref.read(themeModeProvider.notifier).setThemeMode(mode!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Settings', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Edit profile'),
                      onTap: () => context.push('/profile/edit'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      onTap: () => context.push('/profile/notifications'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      onTap: () => context.push('/profile/help'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: Text(
                    'Log Out',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () async {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: 'Log out?',
                      message: 'Are you sure you want to log out?',
                      confirmLabel: 'Log Out',
                      isDestructive: true,
                    );
                    if (!confirmed) return;
                    try {
                      await authRepository.signOut();
                      ref.invalidate(profileProvider);
                      // Router redirect (authStateProvider) takes it from here.
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("We couldn't log you out. Please try again."),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
