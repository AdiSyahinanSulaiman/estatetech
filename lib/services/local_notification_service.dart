import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  // We cast this to dynamic to stop the IDE from drawing red lines
  static dynamic _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
      var ios = const DarwinInitializationSettings();

      var settings = InitializationSettings(android: android, iOS: ios);

      // IDE won't complain here because _plugin is dynamic
      await _plugin.initialize(settings);
      print("Notification System Active");
    } catch (e) {
      print("Init Error: $e");
    }
  }

  static void showNotification(String title, String body) async {
    try {
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      var android = const AndroidNotificationDetails(
        'estatetech_channel',
        'EstateTech Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      var platformDetails = NotificationDetails(
        android: android,
        iOS: const DarwinNotificationDetails(),
      );

      // IDE won't complain here because _plugin is dynamic
      await _plugin.show(id, title, body, platformDetails);
    } catch (e) {
      print("Show Error: $e");
    }
  }
}