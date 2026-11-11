import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global Service Locator.
final GetIt sl = GetIt.instance;

/// main.dart içinde runApp'ten önce çağrılır.
///
/// Merge conflict çıkmaması için HER MODÜLÜN KAYDI KENDİ FONKSİYONUNDA:
///   Dev3 -> _initCoreServices, her modülün datasource/repository kaydı
///   Dev5 -> UseCase ve Cubit kayıtları
///   Dev2 -> ThemeCubit (core)
///
/// Kurallar:
///   Firebase nesneleri, servisler, repository, usecase -> registerLazySingleton
///   Cubit -> registerFactory
///   İSTİSNA: AuthCubit ve ThemeCubit -> registerLazySingleton
///   (GoRouter ve MultiBlocProvider aynı instance'ı kullanmak zorunda.)
Future<void> initDependencies() async {
  await _initExternal();
  _initCoreServices();

  _initAuth();
  _initAnnouncements();
  _initSchedule();
  _initAttendance();
  _initAssignments();
  _initGrades();
  _initForum();
}

// ---------------------------------------------------------------------------
// Dış bağımlılıklar (Dev1)
// ---------------------------------------------------------------------------
Future<void> _initExternal() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);
  sl.registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance);
  sl.registerLazySingleton<FirebaseCrashlytics>(
      () => FirebaseCrashlytics.instance);
}

// ---------------------------------------------------------------------------
// Core servisleri (Dev3 / Dev2) — örnek:
//   sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService(sl()));
//   sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
//   sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService(sl(), sl()));
//   sl.registerLazySingleton<FCMNotificationService>(() => FCMNotificationService(sl()));
//   sl.registerLazySingleton<FilePickerService>(() => FilePickerService());
//   sl.registerLazySingleton<AudioRecorderService>(() => AudioRecorderService());
//   sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));
// ---------------------------------------------------------------------------
void _initCoreServices() {
  // TODO(Dev3, Dev2): Yukarıdaki örneklere göre kayıtları buraya ekleyin.
}

// ---------------------------------------------------------------------------
// Modül kayıtları — her sahip kendi fonksiyonunu doldurur. Örnek (auth):
//   // Cubit  (Dev5)
//   sl.registerLazySingleton<AuthCubit>(() => AuthCubit(...usecases));
//   // UseCase (Dev5)
//   sl.registerLazySingleton(() => LoginWithStudentNoUseCase(sl()));
//   // Repository (Dev3)
//   sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(...));
//   // DataSource (Dev3)
//   sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl(), sl()));
// ---------------------------------------------------------------------------
void _initAuth() {
  // TODO(Dev3, Dev5)
}

void _initAnnouncements() {
  // TODO(Dev3, Dev5)
}

void _initSchedule() {
  // TODO(Dev3, Dev5)
}

void _initAttendance() {
  // TODO(Dev3, Dev5)
}

void _initAssignments() {
  // TODO(Dev3, Dev5)
}

void _initGrades() {
  // TODO(Dev3, Dev5)
}

void _initForum() {
  // TODO(Dev3, Dev5)
}
