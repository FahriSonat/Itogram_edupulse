import 'package:flutter/foundation.dart';

enum Flavor { dev, prod }

/// Dev ve Prod (Demo Day) ortam ayarları.
/// Çalıştırma:
///   flutter run --dart-define=FLAVOR=prod
class FlavorConfig {
  FlavorConfig._(this.flavor);

  final Flavor flavor;

  static FlavorConfig _instance = FlavorConfig._(Flavor.dev);

  static void initialize(Flavor flavor) => _instance = FlavorConfig._(flavor);

  static FlavorConfig get instance => _instance;

  static bool get isDev => _instance.flavor == Flavor.dev;
  static bool get isProd => _instance.flavor == Flavor.prod;

  static String get name => _instance.flavor.name;

  /// Debug banner ve loglar sadece dev ortamında açık.
  static bool get showBanner => isDev;
  static bool get enableLogging => isDev;

  /// Dev'de Crashlytics kapalı, Prod'da açık.
  static bool get enableCrashlytics => isProd;

  static Flavor fromEnvironment() {
    const String value = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    return value == 'prod' ? Flavor.prod : Flavor.dev;
  }

  static void log(String message) {
    if (enableLogging) {
      debugPrint('[EduPulse/$name] $message');
    }
  }
}
