import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';

export 'app/app.dart' show PathokApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderNotificationService.instance.initialize();
  runApp(const PathokApp());
}
