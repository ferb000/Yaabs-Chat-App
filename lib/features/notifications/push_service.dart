// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_navigation_service.dart';

// class PushService {
//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   bool _listenersAttached = false;

//   static const String _webVapidKey =
//       'BKXJqbMxo1rMGLQIzepHxkInnk12s_qUXqBG_g_JxHQfv_axUdaOpTkvuMq0QpPd0KkUmAjy84rBcTHBb0tslMM';

//   Future<String?> init() async {
//     var settings = await _messaging.getNotificationSettings();
//     debugPrint(
//       'Push permission status (before): ${settings.authorizationStatus}',
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
//       settings = await _messaging.requestPermission(
//         alert: true,
//         announcement: false,
//         badge: true,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: false,
//         sound: true,
//       );
//     }

//     debugPrint(
//       'Push permission status (after): ${settings.authorizationStatus}',
//     );

//     final allowed =
//         settings.authorizationStatus == AuthorizationStatus.authorized ||
//         settings.authorizationStatus == AuthorizationStatus.provisional;
//     if (!allowed) {
//       return null;
//     }

//     await _messaging.setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     // final token = await _messaging.getToken();
//     // debugPrint('FCM token: $token');

//     String? token;
//     try {
//       if (kIsWeb) {
//         token = await _messaging.getToken(vapidKey: _webVapidKey);
//         debugPrint('FCM token: $token');
//       } else {
//         token = await _messaging.getToken();
//         debugPrint('FCM token: $token');
//       }
//       debugPrint('FCM TOKEN => $token');
//     } catch (e, st) {
//       debugPrint('FCM getToken failed: $e');
//       debugPrintStack(stackTrace: st);
//     }

//     if (!_listenersAttached) {
//       _listenersAttached = true;
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         debugPrint('Foreground push: ${message.notification?.title}');
//         debugPrint('Foreground push body: ${message.notification?.body}');
//         debugPrint('Foreground push data: ${message.data}');
//       });

//       FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//         debugPrint('User opened notification: ${message.data}');
//       });
//     }

//     return token;
//   }
// }

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  bool _listenersAttached = false;
  String? _cachedToken;

  static const String _webVapidKey =
      'BKXJqbMxo1rMGLQIzepHxkInnk12s_qUXqBG_g_JxHQfv_axUdaOpTkvuMq0QpPd0KkUmAjy84rBcTHBb0tslMM';

  Future<String?> init() async {
    if (_initialized) {
      return _cachedToken;
    }

    final before = await _messaging.getNotificationSettings();
    debugPrint(
      'Push permission status (before): ${before.authorizationStatus}',
    );

    final settings = await _messaging.requestPermission();
    debugPrint(
      'Push permission status (after): ${settings.authorizationStatus}',
    );

    String? token;
    try {
      if (kIsWeb) {
        token = await _messaging.getToken(vapidKey: _webVapidKey);
      } else {
        token = await _messaging.getToken();
      }
      debugPrint('FCM TOKEN => $token');
    } catch (e, st) {
      debugPrint(
        'FCM getToken failed: $e. On Android emulators this usually means the system image does not have Google Play services or Firebase Installations cannot reach Google services.',
      );
      debugPrintStack(stackTrace: st);
    }

    if (!_listenersAttached) {
      _listenersAttached = true;

      // App is open
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground push title: ${message.notification?.title}');
        debugPrint('Foreground push body: ${message.notification?.body}');
        debugPrint('Foreground push data: ${message.data}');
      });

      // App in background, user taps notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        NotificationNavigationService.handleData(message.data);
      });

      // App was terminated, opened by tapping notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        NotificationNavigationService.handleData(initialMessage.data);
      }
    }

    _cachedToken = token;
    _initialized = true;
    return token;
  }
}
