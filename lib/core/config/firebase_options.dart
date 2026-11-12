// Bu dosyayı gerçek Firebase projesi oluşturulduktan sonra şu komutla yenileyin:
// flutterfire configure
// FlutterFire CLI, proje kimliklerini içeren eksiksiz dosyayı otomatik üretir.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB6Yca2-0WJSsI3plmqJcMci9I8lIvsGI8',
    appId: '1:993809855286:web:67dc2b3f08196303a73997',
    messagingSenderId: '993809855286',
    projectId: 'edupulse-e5a4d',
    authDomain: 'edupulse-e5a4d.firebaseapp.com',
    storageBucket: 'edupulse-e5a4d.firebasestorage.app',
    measurementId: 'G-0JTLRCF3C8',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD3Rvj7qSxkz_RJulkbC-pqMyie2swSiTQ',
    appId: '1:993809855286:ios:55886036a1b79507a73997',
    messagingSenderId: '993809855286',
    projectId: 'edupulse-e5a4d',
    storageBucket: 'edupulse-e5a4d.firebasestorage.app',
    iosBundleId: 'com.example.itogramEdupulse',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD3Rvj7qSxkz_RJulkbC-pqMyie2swSiTQ',
    appId: '1:993809855286:ios:55886036a1b79507a73997',
    messagingSenderId: '993809855286',
    projectId: 'edupulse-e5a4d',
    storageBucket: 'edupulse-e5a4d.firebasestorage.app',
    iosBundleId: 'com.example.itogramEdupulse',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCIJ-3gxPZ1LHHE_l_V-6WNJDaXh4iUew',
    appId: '1:993809855286:android:b324e76e0f16b932a73997',
    messagingSenderId: '993809855286',
    projectId: 'edupulse-e5a4d',
    storageBucket: 'edupulse-e5a4d.firebasestorage.app',
  );
}
