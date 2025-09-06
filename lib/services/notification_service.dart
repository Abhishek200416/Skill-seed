import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationRouteResolver = void Function(String? route);

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _fcm = FirebaseMessaging.instance;
  String? _lastRouteTapped;
  NotificationRouteResolver? _onTap;

  Future<void> initFirebaseMessaging() async {
    tz.initializeTimeZones();

    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(init,
        onDidReceiveNotificationResponse: (resp) async {
      _onTap?.call(_lastRouteTapped);
      _lastRouteTapped = null;
    });

    // Android notification channel
    const channel = AndroidNotificationChannel(
      'live_classes',
      'Live Classes',
      description: 'Reminders & push notifications for live classes',
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Ask user permission where required (iOS, macOS, web, Android 13+)
    await _fcm.requestPermission();

    // Foreground messages: show as local notifications
    FirebaseMessaging.onMessage.listen((msg) async {
      final note = msg.notification;
      final android = note?.android;
      final title = note?.title ?? (msg.data['title'] ?? 'Notification');
      final body = note?.body ?? (msg.data['body'] ?? '');
      _lastRouteTapped =
          msg.data['route']; // optional deep link route in data payload

      await _plugin.show(
        msg.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails('live_classes', 'Live Classes',
              channelDescription: 'Live & reminders'),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    // If the app is opened from a background notification
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _onTap?.call(msg.data['route']);
    });

    // Initial message if app was terminated
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onTap?.call(initial.data['route']);

    // Optional: get FCM token for this device (log or store as needed)
    final token = await _fcm.getToken();
    // print('FCM token: $token');
  }

  void bindNotificationClicks(NotificationRouteResolver onTap) {
    _onTap = onTap;
  }

  Future<void> now(String title, String body) async {
    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails('live_classes', 'Live Classes'),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> fiveMinBefore(DateTime startAt,
      {required String title, required String body}) async {
    final when = startAt.subtract(const Duration(minutes: 5));
    await _plugin.zonedSchedule(
      startAt.millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('live_classes', 'Live Classes'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
