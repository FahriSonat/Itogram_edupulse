// Bu dosyayı gerçek Firebase projesi oluşturulduktan sonra şu komutla yenileyin:
// flutterfire configure
// FlutterFire CLI, proje kimliklerini içeren eksiksiz dosyayı otomatik üretir.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return macos;
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_WEB'] ?? '',
    appId: dotenv.env['FIREBASE_APP_ID_WEB'] ?? '',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID_WEB'] ?? '',
    projectId: dotenv.env['FIREBASE_PROJECT_ID_WEB'] ?? '',
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN_WEB'] ?? '',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET_WEB'] ?? '',
    measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID_WEB'] ?? '',
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_MACOS'] ?? '',
    appId: dotenv.env['FIREBASE_APP_ID_MACOS'] ?? '',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID_MACOS'] ?? '',
    projectId: dotenv.env['FIREBASE_PROJECT_ID_MACOS'] ?? '',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET_MACOS'] ?? '',
    iosBundleId: dotenv.env['FIREBASE_MACOS_BUNDLE_ID'] ?? '',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_IOS'] ?? '',
    appId: dotenv.env['FIREBASE_APP_ID_IOS'] ?? '',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID_IOS'] ?? '',
    projectId: dotenv.env['FIREBASE_PROJECT_ID_IOS'] ?? '',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET_IOS'] ?? '',
    iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '',
    appId: dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID_ANDROID'] ?? '',
    projectId: dotenv.env['FIREBASE_PROJECT_ID_ANDROID'] ?? '',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET_ANDROID'] ?? '',
  );
}
