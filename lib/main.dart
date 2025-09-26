import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/SplashScreen.dart';
import 'package:trunriproject/chat_module/community/components/chat_provider.dart';
import 'package:trunriproject/chat_module/services/internet_checker.dart';
import 'package:trunriproject/chat_module/services/presence_service.dart';
import 'package:trunriproject/home/favourites/favourite_provider.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/subscription/subscription_data.dart';

void main() async {
  // GoogleFonts.config.allowRuntimeFetching = false;
  WidgetsFlutterBinding.ensureInitialized();
  InternetChecker().startMonitoring();
  await Firebase.initializeApp();
  // await GoogleFonts.pendingFonts([
  //   GoogleFonts.caveat().fontFamily,
  // ]);
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
        ChangeNotifierProvider(create: (_) => FavouritesProvider()),
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
