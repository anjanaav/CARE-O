import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingSeenKey = 'careo_onboarding_seen';

/// Tracks whether the user has completed the first-run onboarding flow.
/// `null` = still loading from disk (router should not redirect yet).
class OnboardingSeenController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
    state = const AsyncData(true);
  }
}

final onboardingSeenProvider =
    AsyncNotifierProvider<OnboardingSeenController, bool>(
  OnboardingSeenController.new,
);
