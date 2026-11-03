import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/prescription/models/medicine_reminder.dart';

class ReminderNotificationService {
  ReminderNotificationService._();

  static final instance = ReminderNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

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
    );

    try {
      await _plugin.zonedSchedule(
        id: notificationId(reminder),
        title: 'Pathok reminder',
        body: 'Time to check your medicine schedule: ${reminder.medicineName}',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback for devices restricting exact alarms
      await _plugin.zonedSchedule(
        id: notificationId(reminder),
        title: 'Pathok reminder',
        body: 'Time to check your medicine schedule: ${reminder.medicineName}',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancel(MedicineReminder reminder) {
    return _plugin.cancel(id: notificationId(reminder));
  }

  int notificationId(MedicineReminder reminder) {
    return (reminder.id.isNotEmpty ? reminder.id : '${reminder.medicineName}|${reminder.hour}:${reminder.minute}').hashCode & 0x7fffffff;
  }
}

