import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:startingfive/services/session_manager.dart';

// Background Message Handler 
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  
  await Firebase.initializeApp();
  print("Handling background message ID: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Define a high-importance channel for Android
  final AndroidNotificationChannel _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  Future<void> initNotifications() async {
    // 1. Request user permission (Critical for iOS and Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions.');
    }

    // 2. Fetch the unique device Token
    String? fcmToken = await _fcm.getToken();
    print("FCM Device Token: $fcmToken");

    print("FCM Token: $fcmToken");
    await SessionManager.setFcmToken(fcmToken!);

    // 3. Initialize Local Notifications for Foreground Alerts
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(initSettings);

    // Create the Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 4. Set up Message Listeners
    _initMessageHandlers();
  }

  void _initMessageHandlers() {
    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Handler for when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // Trigger local notification to display in foreground
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher', 
            ),
          ),
        );
      }
    });

    // Handler for when the user taps a background notification to open the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened via notification payload: ${message.data}");
    });
  }
}