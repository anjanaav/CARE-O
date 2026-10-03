import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_preferences.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final controller = ref.read(notificationPreferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('On this device', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Medication reminders'),
              subtitle: const Text(
                "Get a notification on this device when it's time to take a medication.",
              ),
              value: prefs.medicationRemindersEnabled,
              onChanged: controller.setMedicationRemindersEnabled,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Family & Care Circle', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Alert my circle about missed medication'),
              subtitle: const Text(
                'When you miss a dose, let people in your Family & Care Circle know — '
                'only the members you\'ve specifically allowed to see missed-medication '
                'alerts will be notified. You can control that per person on the '
                'Family & Care Circle screen.',
              ),
              value: prefs.missedMedicationAlertsEnabled,
              onChanged: controller.setMissedMedicationAlertsEnabled,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'Delivering these alerts as a text message, email, or push notification '
              'depends on the account owner having configured a messaging provider on '
              'the delivery backend. If that hasn\'t been set up yet, alerts are queued '
              'and will be sent automatically as soon as it is — nothing is lost in the '
              'meantime.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
