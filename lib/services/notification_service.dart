import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:quit_drinking/constants/app_constants.dart';

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

  // ── Initialization ──────────────────────────────────────────────────────

  /// Initialize the notification plugin, request permissions, and set up
  /// the timezone database. Must be called once before any scheduling.
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database
    await _configureLocalTimeZone();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('ic_launcher');

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

    await _plugin.initialize(
      settings: initSettings,
    );

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request permissions on iOS
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    _initialized = true;
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

  NotificationDetails _dailyDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyReminderChannelId,
        _dailyReminderChannelName,
        channelDescription: 'Daily reminder to check in with your sobriety journey',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher',
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

  // ── Scheduling ──────────────────────────────────────────────────────────

  /// Schedule a daily notification at [hour]:[minute] local time.
  ///
  /// Cancels any previously scheduled daily reminder first to avoid
  /// duplicates, then creates a new repeating schedule using
  /// [DateTimeComponents.time] so it fires at the same clock time every day.
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await cancelDailyReminder();
    if (!_initialized) await init();

    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: AppConstants.appName,
      body: 'Time for your daily check-in. Stay strong!',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _dailyDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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

  /// Cancel the daily reminder notification.
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: _dailyReminderId);
  }

  /// Cancel all notifications scheduled by this app.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Convenience ─────────────────────────────────────────────────────────

  /// Check whether the app has the necessary notification permissions.
  Future<bool> hasPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.areNotificationsEnabled();
    return granted ?? false;
  }

  /// Restore the daily reminder schedule after app restart.
  ///
  /// Reads the saved preferences and re-schedules if the reminder was
  /// enabled. Call this on app start, after [init].
  Future<void> restoreDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? false;
    if (enabled) {
      final savedTime = prefs.getString('reminder_time');
      if (savedTime != null) {
        final parts = savedTime.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 20;
          final minute = int.tryParse(parts[1]) ?? 0;
          await scheduleDailyReminder(hour, minute);
        }
      }
    }
  }
}
