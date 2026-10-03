import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../core/notifications/notification_preferences.dart';

/// This file was previously 0 bytes — flutter_local_notifications was a
/// declared dependency that was never actually wired up, so medication
/// "reminders" only ever showed up if the user had the app open and
/// happened to look at the Medication Reminders screen. This service
/// schedules a real local notification for each reminder.
class MedicationNotificationService {
  MedicationNotificationService._();
  static final MedicationNotificationService instance =
      MedicationNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    await Permission.notification.request();
    _initialized = true;
  }

  /// Deterministic int id derived from the Firestore doc id, so the same
  /// reminder always maps to the same scheduled notification and can be
  /// cancelled/rescheduled on edit.
  int _idFor(String reminderDocId) => reminderDocId.hashCode & 0x7fffffff;

  Future<void> scheduleReminder({
    required String reminderDocId,
    required String medicationName,
    required DateTime reminderTime,
  }) async {
    await init();

    final remindersEnabled =
        await NotificationPreferencesController.readMedicationRemindersEnabled();
    if (!remindersEnabled) {
      // The user has turned medication reminder notifications off in
      // Profile > Notifications. Make sure any previously-scheduled
      // notification for this reminder is also cleared, so toggling the
      // preference off actually stops notifications instead of just
      // affecting future ones.
      await cancelReminder(reminderDocId);
      return;
    }

    final id = _idFor(reminderDocId);
    await _plugin.zonedSchedule(
      id,
      'Medication reminder',
      "It's time to take $medicationName",
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders to take your medication',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String reminderDocId) async {
    await init();
    await _plugin.cancel(_idFor(reminderDocId));
  }
}
