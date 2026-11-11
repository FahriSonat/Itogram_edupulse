import 'dart:ui';

import 'package:itogram_edupulse/app.dart';
import 'package:itogram_edupulse/core/config/firebase_options.dart';
import 'package:itogram_edupulse/core/config/flavor_config.dart';
import 'package:itogram_edupulse/core/di/injection_container.dart';
import 'package:itogram_edupulse/core/services/fcm_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  // 1) Binding
  WidgetsFlutterBinding.ensureInitialized();

  // 2) Ortam (dev / prod):  flutter run --dart-define=FLAVOR=prod
  FlavorConfig.initialize(FlavorConfig.fromEnvironment());

  // 3) Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 4) Crashlytics: Flutter + platform hataları
  await _setupCrashlytics();

  // 5) FCM arka plan dinleyicisi (top-level fonksiyon olmak zorunda)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 6) Dependency Injection
  await initDependencies();

  // 7) FCM + yerel bildirim kurulumu (Dev3'ün servisi)
  await sl<FCMNotificationService>().initialize();

  // 8) Uygulama
  runApp(const EduPulseApp());
}

Future<void> _setupCrashlytics() async {
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(FlavorConfig.enableCrashlytics);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlavorConfig.log('FlutterError: ${details.exceptionAsString()}');
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FlavorConfig.log('PlatformError: $error');
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
