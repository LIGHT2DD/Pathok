import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'prescription_service.dart';

class ReminderNotificationService {
  ReminderNotificationService._();

  static final instance = ReminderNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
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

    await _plugin.zonedSchedule(
      id: _notificationId(reminder),
      title: 'পাঠক reminder',
      body: reminder.medicineName,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine reminders',
          channelDescription: 'User-confirmed medicine reminder times',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancel(MedicineReminder reminder) {
    return _plugin.cancel(id: _notificationId(reminder));
  }

  int notificationId(MedicineReminder reminder) => _notificationId(reminder);

  int _notificationId(MedicineReminder reminder) {
    return '${reminder.medicineName}|${reminder.hour}:${reminder.minute}'
            .hashCode &
        0x7fffffff;
  }
}
