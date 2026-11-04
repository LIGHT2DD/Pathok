import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';

export 'app/app.dart' show PathokApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ReminderNotificationService.instance.initialize();
  } catch (e, stack) {
    debugPrint('Failed to initialize ReminderNotificationService at startup: $e\n$stack');
  }
  runApp(const PathokApp());
}
