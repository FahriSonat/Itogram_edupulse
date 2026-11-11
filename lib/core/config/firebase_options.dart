// Bu dosyayı gerçek Firebase projesi oluşturulduktan sonra şu komutla yenileyin:
// flutterfire configure
// FlutterFire CLI, proje kimliklerini içeren eksiksiz dosyayı otomatik üretir.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

final class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase seçenekleri FlutterFire CLI ile eklenmelidir.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError('Android Firebase seçeneklerini flutterfire configure ile üretin.');
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS Firebase seçeneklerini flutterfire configure ile üretin.');
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Bu platform EduPulse Firebase yapılandırmasında desteklenmiyor.');
    }
  }
}