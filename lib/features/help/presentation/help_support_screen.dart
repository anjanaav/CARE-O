import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

const _faqs = [
  _Faq(
    'What is CARE-O?',
    'CARE-O is a wellness companion. It brings together medication '
        'reminders, gentle exercise, breathing and meditation, music, games '
        'and a way to stay connected with family. It does not replace advice '
        'from a doctor or other health professional.',
  ),
  _Faq(
    'How do I add a medication reminder?',
    'Open the Wellness tab, choose Medication Reminders, then tap the add '
        'button. Enter the medicine name and time. You can edit or delete a '
        'reminder at any time.',
  ),
  _Faq(
    'Why am I not getting reminder notifications?',
    'Check that notifications are allowed for CARE-O in your phone settings, '
        'and that reminders are turned on under Profile > Notifications. On '
        'some phones you may also need to allow exact alarms or disable '
        'battery restrictions for the app.',
  ),
  _Faq(
    'How do I add a family member or guardian?',
    'Open the Connect tab and choose Guardian. Tap the add button and enter '
        'their name and contact details. Only you can see the people you add.',
  ),
  _Faq(
    'How do I switch to dark mode or change the theme?',
    'Go to Profile > Appearance and choose Light, Dark or Use system '
        'setting. Your choice is remembered.',
  ),
  _Faq(
    'How do I change my name?',
    'Go to Profile > Edit profile, update your name and tap Save changes.',
  ),
  _Faq(
    'I forgot my password.',
    'On the Log In screen tap Forgot password, enter your email and we will '
        'send you a link to choose a new one.',
  ),
  _Faq(
    'What should I do in an emergency?',
    'CARE-O is not an emergency service. If you or someone else is in '
        'danger or needs urgent medical help, call your local emergency '
        'number straight away.',
  ),
];

/// Frequently asked questions plus a short note on where to get help.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text('Frequently asked questions',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                for (final faq in _faqs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          childrenPadding: const EdgeInsets.fromLTRB(
                              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          title: Text(faq.question,
                              style: theme.textTheme.titleMedium),
                          children: [
                            Text(faq.answer, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.support_agent,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          "Still need help? Ask a family member or guardian to "
                          "look through these answers with you.",
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
