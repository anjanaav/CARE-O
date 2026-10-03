import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _medicationRemindersKey = 'careo_medication_reminders_enabled';
const _missedMedicationAlertsKey = 'careo_missed_medication_alerts_enabled';

/// User-controlled notification preferences, persisted on-device.
///
/// This is deliberately split into two different things that were
/// previously conflated:
///   - [medicationRemindersEnabled] controls whether *this device* schedules
///     local reminder notifications at all. This is the "Notifications"
///     settings tile that used to say "Coming soon" and do nothing.
///   - [missedMedicationAlertsEnabled] is a master switch for whether missed
///     doses get queued for the Family & Care Circle at all. It works
///     together with, not instead of, each guardian's own
///     `notifyMissedMedication` permission (see GuardianRepository) — a
///     guardian only actually gets alerted if BOTH this is on AND that
///     specific guardian has consented to missed-medication alerts.
class NotificationPreferences {
  final bool medicationRemindersEnabled;
  final bool missedMedicationAlertsEnabled;

  const NotificationPreferences({
    this.medicationRemindersEnabled = true,
    this.missedMedicationAlertsEnabled = true,
  });

  NotificationPreferences copyWith({
    bool? medicationRemindersEnabled,
    bool? missedMedicationAlertsEnabled,
  }) {
    return NotificationPreferences(
      medicationRemindersEnabled:
          medicationRemindersEnabled ?? this.medicationRemindersEnabled,
      missedMedicationAlertsEnabled:
          missedMedicationAlertsEnabled ?? this.missedMedicationAlertsEnabled,
    );
  }
}

class NotificationPreferencesController extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() {
    _restore();
    return const NotificationPreferences();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationPreferences(
      medicationRemindersEnabled:
          prefs.getBool(_medicationRemindersKey) ?? true,
      missedMedicationAlertsEnabled:
          prefs.getBool(_missedMedicationAlertsKey) ?? true,
    );
  }

  Future<void> setMedicationRemindersEnabled(bool value) async {
    state = state.copyWith(medicationRemindersEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_medicationRemindersKey, value);
  }

  Future<void> setMissedMedicationAlertsEnabled(bool value) async {
    state = state.copyWith(missedMedicationAlertsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_missedMedicationAlertsKey, value);
  }

  /// Static read, for services (like MedicationNotificationService) that
  /// aren't part of the widget tree and can't watch a Riverpod provider.
  /// Kept here, next to the storage key, so the two never drift apart.
  static Future<bool> readMedicationRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_medicationRemindersKey) ?? true;
  }

  static Future<bool> readMissedMedicationAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_missedMedicationAlertsKey) ?? true;
  }
}

final notificationPreferencesProvider = NotifierProvider<
    NotificationPreferencesController, NotificationPreferences>(
  NotificationPreferencesController.new,
);
