import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotifiService {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  static const String medicationChannelId =
      'medication_alarm_channel';

  static const String medicationChannelName =
      'Medication Alarms';

  static const String medicationChannelDescription =
      'Medication reminders with sound and vibration.';

  // ==================================================
  // Initialise notification service
  // ==================================================

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    // Your app and PHP server use Singapore time.
    tz.setLocalLocation(
      tz.getLocation('Asia/Singapore'),
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );

    await notifications.initialize(
      settings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) {
        // Tapping the alarm opens the application.
        //
        // Later, this payload can be used to open the
        // exact medication page automatically.
        final String? payload = response.payload;

        if (payload != null) {
          debugPrint(
            'Medication notification tapped: $payload',
          );
        }
      },
    );

    await requestPermissions();
  }

  // ==================================================
  // Ask Android for notification permissions
  // ==================================================

  static Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin?
        androidPlugin =
        notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin
        ?.requestNotificationsPermission();

    await androidPlugin
        ?.requestExactAlarmsPermission();
  }

  // ==================================================
  // Notification appearance and alarm behaviour
  // ==================================================

  static NotificationDetails get medicationDetails {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      medicationChannelId,
      medicationChannelName,
      channelDescription:
          medicationChannelDescription,

      importance: Importance.max,
      priority: Priority.max,

      category:
          AndroidNotificationCategory.alarm,

      playSound: true,
      enableVibration: true,
      enableLights: true,

      fullScreenIntent: true,

      visibility:
          NotificationVisibility.public,

      autoCancel: false,

      ticker: 'Medication reminder',
    );

    return const NotificationDetails(
      android: androidDetails,
    );
  }

  // ==================================================
  // Create a unique notification ID
  //
  // Each schedule may generate up to seven alarms,
  // one for each selected weekday.
  // ==================================================

  static int getDailyNotificationId(
    int scheduleId,
  ) {
    return scheduleId * 10;
  }

  static int getWeekdayNotificationId(
    int scheduleId,
    int weekday,
  ) {
    return scheduleId * 10 + weekday;
  }

  // ==================================================
  // Convert Mon/Tue/etc. to Dart weekday number
  // ==================================================

  static int? convertDayToWeekday(
    String day,
  ) {
    switch (day.trim()) {
      case 'Mon':
        return DateTime.monday;

      case 'Tue':
        return DateTime.tuesday;

      case 'Wed':
        return DateTime.wednesday;

      case 'Thu':
        return DateTime.thursday;

      case 'Fri':
        return DateTime.friday;

      case 'Sat':
        return DateTime.saturday;

      case 'Sun':
        return DateTime.sunday;

      default:
        return null;
    }
  }

  // ==================================================
  // Find next occurrence of an exact time
  // ==================================================

  static tz.TZDateTime nextTimeOfDay({
    required int hour,
    required int minute,
  }) {
    final tz.TZDateTime now =
        tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled =
        tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(
        const Duration(days: 1),
      );
    }

    return scheduled;
  }

  // ==================================================
  // Find next selected weekday and time
  // ==================================================

  static tz.TZDateTime nextWeekdayAndTime({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    tz.TZDateTime scheduled =
        nextTimeOfDay(
      hour: hour,
      minute: minute,
    );

    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(
        const Duration(days: 1),
      );
    }

    return scheduled;
  }

  // ==================================================
  // Schedule all alarms belonging to one medicine
  // ==================================================

  static Future<void> scheduleMedicationAlarms({
    required int medicationId,
    required String medicineName,
    required String dosage,
    required List<dynamic> schedules,
  }) async {
    for (final dynamic item in schedules) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final int scheduleId =
          int.tryParse(
            item['schedule_id']
                    ?.toString() ??
                '',
          ) ??
          0;

      if (scheduleId <= 0) {
        continue;
      }

      final String reminderTime =
          item['reminder_time']
                  ?.toString() ??
              '';

      final List<String> timeParts =
          reminderTime.split(':');

      if (timeParts.length < 2) {
        continue;
      }

      final int? hour =
          int.tryParse(timeParts[0]);

      final int? minute =
          int.tryParse(timeParts[1]);

      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        continue;
      }

      final String repeatType =
          item['repeat_type']
                  ?.toString() ??
              'daily';

      final String repeatDays =
          item['repeat_days']
                  ?.toString() ??
              '';

      if (repeatType == 'selected_days') {
        await scheduleSelectedDayAlarms(
          medicationId: medicationId,
          scheduleId: scheduleId,
          medicineName: medicineName,
          dosage: dosage,
          hour: hour,
          minute: minute,
          repeatDays: repeatDays,
        );
      } else {
        await scheduleDailyAlarm(
          medicationId: medicationId,
          scheduleId: scheduleId,
          medicineName: medicineName,
          dosage: dosage,
          hour: hour,
          minute: minute,
        );
      }
    }
  }

  // ==================================================
  // Daily medication alarm
  // ==================================================

  static Future<void> scheduleDailyAlarm({
    required int medicationId,
    required int scheduleId,
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
    final int notificationId =
        getDailyNotificationId(
      scheduleId,
    );

    await notifications.zonedSchedule(
      notificationId,

      'Medication Reminder',

      'It is time to take $medicineName — $dosage.',

      nextTimeOfDay(
        hour: hour,
        minute: minute,
      ),

      medicationDetails,

      androidScheduleMode:
          AndroidScheduleMode
              .exactAllowWhileIdle,

      matchDateTimeComponents:
          DateTimeComponents.time,

      payload:
          'medication_id=$medicationId'
          '&schedule_id=$scheduleId',
    );
  }

  // ==================================================
  // Selected weekday medication alarms
  // ==================================================

  static Future<void>
      scheduleSelectedDayAlarms({
    required int medicationId,
    required int scheduleId,
    required String medicineName,
    required String dosage,
    required int hour,
    required int minute,
    required String repeatDays,
  }) async {
    final List<String> dayNames =
        repeatDays
            .split(',')
            .map(
              (String day) => day.trim(),
            )
            .where(
              (String day) =>
                  day.isNotEmpty,
            )
            .toList();

    for (final String dayName
        in dayNames) {
      final int? weekday =
          convertDayToWeekday(dayName);

      if (weekday == null) {
        continue;
      }

      final int notificationId =
          getWeekdayNotificationId(
        scheduleId,
        weekday,
      );

      await notifications.zonedSchedule(
        notificationId,

        'Medication Reminder',

        'It is time to take '
            '$medicineName — $dosage.',

        nextWeekdayAndTime(
          weekday: weekday,
          hour: hour,
          minute: minute,
        ),

        medicationDetails,

        androidScheduleMode:
            AndroidScheduleMode
                .exactAllowWhileIdle,

        matchDateTimeComponents:
            DateTimeComponents
                .dayOfWeekAndTime,

        payload:
            'medication_id=$medicationId'
            '&schedule_id=$scheduleId',
      );
    }
  }

  // ==================================================
  // Cancel one schedule and all its possible alarms
  // ==================================================

  static Future<void> cancelScheduleAlarms(
    int scheduleId,
  ) async {
    await notifications.cancel(
      getDailyNotificationId(
        scheduleId,
      ),
    );

    for (
      int weekday = DateTime.monday;
      weekday <= DateTime.sunday;
      weekday++
    ) {
      await notifications.cancel(
        getWeekdayNotificationId(
          scheduleId,
          weekday,
        ),
      );
    }
  }

  // ==================================================
  // Cancel all alarms belonging to schedule records
  // ==================================================

  static Future<void> cancelMedicationAlarms({
    required List<dynamic> schedules,
  }) async {
    for (final dynamic item in schedules) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final int scheduleId =
          int.tryParse(
            item['schedule_id']
                    ?.toString() ??
                '',
          ) ??
          0;

      if (scheduleId > 0) {
        await cancelScheduleAlarms(
          scheduleId,
        );
      }
    }
  }

  // ==================================================
  // Useful while testing
  // ==================================================

  static Future<void> showTestAlarm() async {
    await notifications.show(
      999999,
      'Medication Alarm Test',
      'Your medication alarm is working.',
      medicationDetails,
    );
  }

  static Future<List<PendingNotificationRequest>>
      getPendingAlarms() async {
    return notifications
        .pendingNotificationRequests();
  }

  static Future<void> cancelAllAlarms() async {
    await notifications.cancelAll();
  }
}