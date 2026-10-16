
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:startingfive/screens/splash_screen.dart';
import 'package:startingfive/services/notification_services.dart';
import 'package:flutter/services.dart';
import '../services/session_manager.dart';

/// Background Notification Handler
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
  print("Background Message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// -----------------------------------
  /// STRIPE INITIALIZATION
  /// -----------------------------------
  Stripe.publishableKey = //"pk_live_N2Iv1VFI2TgItttTdlNMCMEA";
      "pk_test_51JMWebSIh5ESgj82I81ylSfCNu87Z1monNQQonn79tpk9dzSvzwmNPwYuVpnefjbcZm0pY0kXok4IZLohBkXl5sr00yQPpJ3f0";

  Stripe.merchantIdentifier = "merchant.com.ogrelogic.startingfive";

  try {
    await Stripe.instance.applySettings();
  } catch (e) {
    print("Stripe init failed: $e");
  }

  /// -----------------------------------
  /// FIREBASE INITIALIZATION
  /// -----------------------------------
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
  } catch (e) {
    print("Firebase init failed: $e");
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const MyApp());

  try {
    await NotificationService().initNotifications();
    await setupFCM();
  } catch (e) {
    print("Notification setup failed: $e");
  }
}

Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  /// -----------------------------------
  /// IOS FOREGROUND PRESENTATION OPTIONS
  /// -----------------------------------
  // This explicitly forces iOS to show the native banner, play sound, and update badge
  // while the app is in the foreground. Android safely ignores this configuration.
  if (Platform.isIOS) {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true, // Required for foreground banners on iOS
      badge: true, // Updates app icon badge in foreground
      sound: true, // Plays sound in foreground
      
    );
    
  }

  /// -----------------------------------
  /// REQUEST PERMISSION
  /// -----------------------------------
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  print("Permission Status: ${settings.authorizationStatus}");

  /// -----------------------------------
  /// APNS TOKEN (iOS ONLY)
  /// -----------------------------------
  if (Platform.isIOS) {
    String? token;
    int retry = 0;

    // Retry loop to wait for APNS registration (Extended slightly for slow network handshakes)
    while (token == null && retry < 8) {
      await Future.delayed(const Duration(seconds: 1));
      token = await messaging.getAPNSToken();
      retry++;
      print("Checking APNS Token (Attempt $retry)...");
    }

    print("APNS Token: ${token ?? 'Not found/failed'}");

    if (token == null) {
      print("Warning: Real device failed to fetch APNS token within timeout. FCM registration might be delayed.");
    }
  }

  /// -----------------------------------
  /// FCM TOKEN WITH ERROR HANDLING
  /// -----------------------------------
  String? fcmToken;
  try {
    fcmToken = await messaging.getToken();
  } catch (e) {
    // This safely catches the [firebase_messaging/apns-token-not-set] error without crashing
    print("Caught FCM Token generation error: $e");
  }

  /// Simulator fallback / Fail-safe
  fcmToken ??= "dummy_fcm_token";

  print("FCM Token: $fcmToken");
  await SessionManager.setFcmToken(fcmToken);

  /// -----------------------------------
  /// FOREGROUND NOTIFICATION
  /// -----------------------------------
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) {
      print("Foreground Notification: ${message.notification?.title}");
      print("Foreground Data: ${message.data}");
      
      // If you ever want to perform in-app actions (like showing an in-app dialog or updating state)
      // when a notification arrives while they are using the app, handle that logic here.
    },
  );

  /// -----------------------------------
  /// NOTIFICATION CLICK
  /// -----------------------------------
  FirebaseMessaging.onMessageOpenedApp.listen(
    (RemoteMessage message) {
      print("Notification Clicked");
      print(message.data);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Starting Five',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
      ),

      /// -----------------------------------
      /// SPLASH SCREEN
      /// -----------------------------------
      home: const SplashScreen(),
    );
  }
}
