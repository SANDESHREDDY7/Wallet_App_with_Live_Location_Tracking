import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Load all timezone data
    tz_data.initializeTimeZones();

    // 2. Get the device's REAL local timezone (e.g., "Asia/Kolkata") and set it.
    //    Without this, tz.local == UTC, and scheduled alarms fire at wrong times!
    try {
      final String localTimezone = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(localTimezone));
      debugPrint('[Notification] Device timezone set to: $localTimezone');
    } catch (e) {
      debugPrint('[Notification] Could not get device timezone, falling back to UTC: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[Notification] Tapped: ${response.payload}');
      },
    );

    // 3. Request permissions for Android 13+
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }

    _initialized = true;
    debugPrint('[Notification] Service initialized successfully');
  }

  /// Show a notification immediately (for testing and overdue/due-today alerts).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'bill_reminders_v2',
            'Bill Reminders',
            channelDescription: 'Payment reminders for your bills',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/launcher_icon',
            color: const Color(0xFF7C3AED),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('[Notification] Showed immediate notification: $title');
    } catch (e) {
      debugPrint('[Notification] Error showing notification: $e');
    }
  }

  /// Schedule a notification for a future date.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);

      // If in the past, fire it immediately instead of silently dropping it
      if (scheduledTime.isBefore(now)) {
        debugPrint('[Notification] Scheduled time is in the past — showing immediately');
        await showNow(id: id, title: title, body: body);
        return;
      }

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'bill_reminders_v2',
            'Bill Reminders',
            channelDescription: 'Payment reminders for your bills',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/launcher_icon',
            color: const Color(0xFF7C3AED),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[Notification] Scheduled notification "$title" for $scheduledTime');
    } catch (e) {
      debugPrint('[Notification] Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
}

