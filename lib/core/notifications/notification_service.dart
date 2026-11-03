import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/prescription/models/medicine_reminder.dart';

class ReminderNotificationService {
  ReminderNotificationService._();

  static final instance = ReminderNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const int _audioNotificationId = 999999;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> schedule(MedicineReminder reminder) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine reminders',
      channelDescription: 'User-confirmed medicine reminder times',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.private,
      enableVibration: true,
      playSound: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_taken',
          'খেয়েছি (Mark as Taken)',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_snooze',
          '১০ মি. পর (Snooze 10m)',
          showsUserInterface: false,
        ),
      ],
    );

    try {
      await _plugin.zonedSchedule(
        id: notificationId(reminder),
        title: 'পাঠক ওষুধ অনুস্মারক (Pathok)',
        body: 'ওষুধ খাওয়ার সময় হয়েছে: ${reminder.medicineName} (${reminder.instructions})',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback for devices restricting exact alarms
      await _plugin.zonedSchedule(
        id: notificationId(reminder),
        title: 'পাঠক ওষুধ অনুস্মারক (Pathok)',
        body: 'ওষুধ খাওয়ার সময় হয়েছে: ${reminder.medicineName} (${reminder.instructions})',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Shows ongoing lock-screen and notification shade playback controls
  Future<void> showAudioPlaybackNotification({
    required String title,
    required bool isPlaying,
    required String voiceLabel,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'pathok_audio_reader',
      'Pathok Audio Reader',
      channelDescription: 'Ongoing audio reader playback controls',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: isPlaying,
      autoCancel: false,
      showWhen: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'audio_toggle',
          isPlaying ? 'বিরতি (Pause)' : 'চালু (Resume)',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'audio_stop',
          'থামুন (Stop)',
          showsUserInterface: true,
        ),
      ],
    );

    await _plugin.show(
      id: _audioNotificationId,
      title: title,
      body: isPlaying ? 'পাঠক ভয়েস পড়ছে ($voiceLabel)' : 'ভয়েস স্থগিত আছে ($voiceLabel)',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  /// Cancels the ongoing lock-screen and status-bar audio notification
  Future<void> cancelAudioPlaybackNotification() async {
    await _plugin.cancel(id: _audioNotificationId);
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancel(MedicineReminder reminder) {
    return _plugin.cancel(id: notificationId(reminder));
  }

  int notificationId(MedicineReminder reminder) {
    return (reminder.id.isNotEmpty ? reminder.id : '${reminder.medicineName}|${reminder.hour}:${reminder.minute}').hashCode & 0x7fffffff;
  }
}
