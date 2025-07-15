// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class LocalNotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: DarwinInitializationSettings(),
//     );

//     await _notificationsPlugin.initialize(initSettings);
//   }

//   static Future<void> showNotification(String title, String body) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'chat_channel',
//       'Chat Notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const NotificationDetails details =
//         NotificationDetails(android: androidDetails);

//     await _notificationsPlugin.show(0, title, body, details);
//   }
// }
