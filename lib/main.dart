import 'package:itogram_edupulse/app.dart';
import 'package:itogram_edupulse/core/config/firebase_options.dart';
import 'package:itogram_edupulse/core/config/flavor_config.dart';
import 'package:itogram_edupulse/core/di/injection_container.dart';
import 'package:itogram_edupulse/core/services/analytics_service.dart';
import 'package:itogram_edupulse/core/services/fcm_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // 1) Binding
  WidgetsFlutterBinding.ensureInitialized();

  // 2) Ortam (dev / prod):  flutter run --dart-define=FLAVOR=prod
  FlavorConfig.initialize(FlavorConfig.fromEnvironment());

  // 3) DotEnv (.env) Dosyasını Yükleme <-- 2. İşlem eklendi (Firebase'den önce olmalı)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    FlavorConfig.log('dotenv load warning: $e');
  }

  // 4) Firebase
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  }

  // 5) Crashlytics: Flutter + platform hataları
  await _setupCrashlytics();

  // 6) Dependency Injection
  await initDependencies();

  // 7) Analytics + FCM + yerel bildirim kurulumu
  try {
    await sl<AnalyticsService>().initialize();
  } catch (e) {
    FlavorConfig.log('AnalyticsService init warning: $e');
  }
  try {
    await sl<FcmNotificationService>().initialize();
  } catch (e) {
    FlavorConfig.log('FcmNotificationService init warning: $e');
  }

  // 8) Uygulama
  runApp(const EduPulseApp());
}

Future<void> _setupCrashlytics() async {
  if (kIsWeb) return;
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