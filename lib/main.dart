import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/SplashScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trunriproject/chat_module/community/components/chat_provider.dart';
import 'package:trunriproject/chat_module/services/presence_service.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/notifications/notification_services.dart';
import 'package:trunriproject/subscription/subscription_data.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();
// Future<void> notificationSetup() async {
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'chat_messages', // id
//     'Chat Messages', // title
//     description: 'This channel is used for chat message notifications.',
//     importance: Importance.high,
//   );
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);
//   await FirebaseMessaging.instance.requestPermission();
//   await NotificationService.initialize();
//   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//     final notification = message.notification;
//     if (notification != null) {
//       NotificationService.showNotification(
//         notification.title ?? 'New message',
//         notification.body ?? 'You have received a new chat message!',
//       );
//     }
//   });
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GoogleFonts.pendingFonts([
    GoogleFonts.caveat().fontFamily,
  ]);
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await PresenceService.setUserOnline();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void monitorUserPresenceIfInternetActive() {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((status) {
      if (status.contains(ConnectivityResult.none)) {
        PresenceService.setUserOffline();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PresenceService.setUserOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PresenceService.setUserOnline();
    } else if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      Future.delayed(
        const Duration(seconds: 5),
        () {
          PresenceService.setUserOffline();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubscriptionData()),
        ChangeNotifierProvider(create: (_) => LocationData()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: GetMaterialApp(
        title: 'TruNri',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            scrolledUnderElevation: 0.0,
            elevation: 0.0,
            surfaceTintColor:
                Colors.transparent, // Important for Material 3 to avoid tinting
          ),
        ),
        routingCallback: (routing) {
          if (routing?.isBack == true) {
            // Unfocus when navigating back
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        home: const SplashScreen(),
      ),
    );
  }
}
