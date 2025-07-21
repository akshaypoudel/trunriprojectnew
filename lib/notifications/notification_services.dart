import 'package:flutter_local_notifications_plus/flutter_local_notifications_plus.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (details) {
      // Handle notification tap logic here if needed
    });
  }

  static Future<void> showNotification(
    String title,
    String body,
  ) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription:
            'This channel is used for chat message notifications.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }
}
