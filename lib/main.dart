// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:app_links/app_links.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

import 'routing/app_router.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initFirebaseMessaging();

  runApp(const ProviderScope(child: SkillSeedApp()));
}

class SkillSeedApp extends StatefulWidget {
  const SkillSeedApp({super.key});
  @override
  State<SkillSeedApp> createState() => _AppState();
}

class _AppState extends State<SkillSeedApp> {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _dlSub;

  final router = appRouter;

  bool get _supportsDeepLinks =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();

    // Handle taps on push notifications that opened the app
    NotificationService.instance.bindNotificationClicks((initialRoute) {
      if (initialRoute != null) router.go(initialRoute);
    });

    // Deep links (app_links): listen for incoming links while app is running
    if (_supportsDeepLinks) {
      _appLinks = AppLinks();
      _dlSub = _appLinks!.uriLinkStream.listen(
        _handleUri,
        onError: (_) {},
      );
    }
  }

  void _handleUri(Uri uri) {
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'join') {
      final sid = uri.queryParameters['sessionId'];
      final url = uri.queryParameters['url'];
      if (sid != null) {
        router.go('/live/join?sessionId=$sid&url=$url');
      }
    }
  }

  @override
  void dispose() {
    _dlSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C89FF),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
              transitionType: SharedAxisTransitionType.scaled),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
              transitionType: SharedAxisTransitionType.scaled),
        },
      ),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SkillSeed',
      theme: base.copyWith(
        appBarTheme: base.appBarTheme.copyWith(centerTitle: true, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          isDense: true,
        ),
      ),
      routerConfig: router,
    );
  }
}
