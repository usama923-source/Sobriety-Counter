import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:quit_drinking/core/services/firebase_service.dart';

/// Service responsible for scheduling, cancelling, and displaying daily
/// reminder notifications.
///
/// Uses [flutter_local_notifications] with [timezone] support so the
/// notification fires at the user's chosen local time every day.
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── IDs ─────────────────────────────────────────────────────────────────
  static const int _dailyReminderId = 1001;
  static const String _dailyReminderChannelId = 'daily_reminder';
  static const String _dailyReminderChannelName = 'Daily Reminder';

  // ── SharedPreferences keys ─────────────────────────────────────────────
  static const String _enabledKey = 'reminder_enabled';
  static const String _timeKey = 'reminder_time';

  /// Debug helper: sends one handheld notification so the user can verify
  /// the plugin + permissions + channel are all wired up correctly.
  static Future<void> _sendTestNotification() async {
    if (kIsWeb) return;
    try {
      await _instance.initialize();
      await _instance._plugin.zonedSchedule(
        id: 9999,
        title: 'Test Reminder',
        androidScheduleMode: await _instance._resolveScheduleMode(
          logWhenInexact: true,
        ),
        body: 'This is a test notification to confirm the daily reminder is working.',
        scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyReminderChannelId,
            _dailyReminderChannelName,
            channelDescription: 'Test notification for QuitDrink Ai',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] test notification failed: $e');
    }
  }

  // ── Initialization ──────────────────────────────────────────────────────

  /// Initialize the notification plugin and set up the timezone database.
  /// Must be called once before any scheduling.
  ///
  /// This never asks for notification permission: the request is made when
  /// the user enables the daily reminder (see [scheduleDailyReminder]).
  Future<void> initialize() async {
    if (kIsWeb) return; // notifications not supported on web
    if (_initialized) return;

    // Initialize timezone database
    await _configureLocalTimeZone();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Create the notification channel up-front so it exists before any
    // reminder is scheduled (required on Android 8+).
    await _createDailyChannel();

    // Report (and fall back from) inexact scheduling when exact alarms are
    // not permitted on this device. Exact alarm permission cannot be
    // requested at runtime, so repeated announcements at the same clock time
    // every day use AndroidScheduleMode.inexactAllowWhileIdle instead.
    await _resolveScheduleMode(logWhenInexact: true);

    _initialized = true;
  }

  /// Ask for notification permission (Android 13+ and iOS/macOS).
  ///
  /// Called only from [scheduleDailyReminder], i.e. after the user explicitly
  /// turns the daily reminder on — never during app startup.
  Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Configure the local timezone from the device.
  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) return;
    tz.initializeTimeZones();
    if (!kIsWeb && Platform.isWindows) return;

    try {
      final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      // Fallback to UTC if timezone detection fails
      tz.setLocalLocation(tz.UTC);
    }
  }

  // ── Notification Details ────────────────────────────────────────────────

  /// Create the Android notification channel used for daily reminders.
  /// Created before scheduling so the channel is guaranteed to exist.
  Future<void> _createDailyChannel() async {
    if (kIsWeb || !Platform.isAndroid) return;
    const channel = AndroidNotificationChannel(
      _dailyReminderChannelId,
      _dailyReminderChannelName,
      description: 'Daily reminder to check in with your sobriety journey',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  NotificationDetails _dailyDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyReminderChannelId,
        _dailyReminderChannelName,
        channelDescription: 'Daily reminder to check in with your sobriety journey',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        showWhen: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Resolve the [AndroidScheduleMode] to use for a scheduled notification.
  ///
  /// Returns [AndroidScheduleMode.exactAllowWhileIdle] by default, falling
  /// back to [AndroidScheduleMode.inexactAllowWhileIdle] on Android when the
  /// user has not granted the exact-alarm permission. [logWhenInexact]
  /// controls whether that fallback is reported to the debug log.
  ///
  /// v22.3.1 removed isExactAlarmPermissionGranted(); this uses
  /// canScheduleExactNotifications(), which returns `Future<bool?>`.
  Future<AndroidScheduleMode> _resolveScheduleMode({
    bool logWhenInexact = false,
  }) async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return AndroidScheduleMode.exactAllowWhileIdle;

    final canScheduleExact =
        await androidImpl.canScheduleExactNotifications();
    if (canScheduleExact ?? false) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    if (logWhenInexact) {
      debugPrint(
        '[NotificationService] exact alarm denied — using inexact fallback',
      );
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  // ── Scheduling ──────────────────────────────────────────────────────────

  /// Schedule a daily notification at [time] local time and persist the
  /// preference. Cancels any previously scheduled reminder first to avoid
  /// duplicates, then creates a new repeating schedule using
  /// [DateTimeComponents.time] so it fires at the same clock time every day.
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    if (kIsWeb) return; // notifications not supported on web
    try {
      await cancelReminder();
      if (!_initialized) await initialize();

      // The user just enabled the reminder, so ask for permission now rather
      // than at app startup.
      await _requestPermissions();

      // Schedule the next daily occurrence. If today's time has already
      // passed, roll to tomorrow so the notification fires on time.
      final scheduledDate = _nextInstanceOfTime(time.hour, time.minute);

      // Try exact alarm mode first, but fall back to inexact if the user
      // denied the exact-alarm permission. Repeated daily reminders at the
      // same clock time work with either mode.
      final scheduleMode = await _resolveScheduleMode(logWhenInexact: true);

      await _plugin.zonedSchedule(
        id: _dailyReminderId,
        title: 'Stay Strong! 💪',
        body: 'Check in with your sobriety journey today.',
        scheduledDate: scheduledDate,
        notificationDetails: _dailyDetails(),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Persist the reminder preference so it survives restarts.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, true);
      await prefs.setString(_timeKey, '${time.hour}:${time.minute}');

      // Record the reminder as its own analytics event. If the analytics
      // request fails, the local reminder is still valid, so we just log the
      // failure.
      try {
        await FirebaseService().logReminderScheduled();
      } catch (e) {
        debugPrint('[NotificationService] could not log reminder enable: $e');
      }
    } catch (e) {
      debugPrint('[NotificationService] scheduleDailyReminder failed: $e');
    }
  }

  /// Manual test: sends one hand-held notification to verify the plugin,
  /// permissions, channel and timezone are all configured correctly.
  Future<void> sendTestNotification() async {
    await _sendTestNotification();
  }

  /// Cancel the daily reminder and clear the saved preference.
  Future<void> cancelReminder() async {
    if (kIsWeb) return; // notifications not supported on web
    try {
      await _plugin.cancel(id: _dailyReminderId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, false);
    } catch (e) {
      debugPrint('[NotificationService] cancelReminder failed: $e');
    }
  }

  /// Compute the next [tz.TZDateTime] that matches [hour]:[minute] local time.
  /// If that time has already passed today, returns tomorrow's instance.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Re-read the saved reminder time and reschedule it. Used by the
  /// onboarding screen and any flow that resets the app.
  Future<void> syncScheduledReminder() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_enabledKey) ?? false;
      if (!enabled) return;

      final savedTime = prefs.getString(_timeKey);
      if (savedTime == null || savedTime.isEmpty) return;

      final parts = savedTime.split(':');
      if (parts.length != 2) return;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return;
      }

      await cancelReminder();
      if (!_initialized) await initialize();

      final scheduledDate = _nextInstanceOfTime(hour, minute);

      // Fall back to inexact mode if exact alarm permission was denied.
      final scheduleMode = await _resolveScheduleMode();

      await _plugin.zonedSchedule(
        id: _dailyReminderId,
        title: 'Stay Strong! 💪',
        body: 'Check in with your sobriety journey today.',
        scheduledDate: scheduledDate,
        notificationDetails: _dailyDetails(),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[NotificationService] syncScheduledReminder failed: $e');
    }
  }
}
