import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/SplashScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trunriproject/chat_module/services/presence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GoogleFonts.pendingFonts([
    GoogleFonts.caveat().fontFamily,
  ]);
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await PresenceService.setUserOnline(); // only for current user
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
    // PresenceService.setUserOnline();
  }

  void monitorUserPresenceIfInternetActive() {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((status) {
      if (status.contains(ConnectivityResult.none)) {
        PresenceService.setUserOffline();
      } else {
        PresenceService.setUserOnline();
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
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      PresenceService.setUserOffline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
