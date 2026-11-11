// Firebase bu projede henüz yapılandırılmadı.
//
// Uygulama şu an tüm verileri cihazdaki yerel veritabanında
// (lib/core/services/local_storage_service.dart) tutar ve kurulum gerektirmeden
// çalışır. Firebase'e geçmek için:
//   1. `dart pub global activate flutterfire_cli`
//   2. `flutterfire configure` (bu dosyayı otomatik üretir)
//   3. firebase_core / cloud_firestore paketlerini ekleyip datasource
//      implementasyonlarını Firestore'a yönlendirin.

/// Firebase yapılandırmasının mevcut olup olmadığı.
const bool kFirebaseConfigured = false;
