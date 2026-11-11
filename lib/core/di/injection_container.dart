import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/announcements/data/datasources/announcement_remote_datasource.dart';
import '../../features/announcements/data/repositories/announcement_repository_impl.dart';
import '../../features/announcements/domain/repositories/announcement_repository.dart';
import '../../features/announcements/domain/usecases/create_announcement_usecase.dart';
import '../../features/announcements/domain/usecases/send_instant_crisis_push_usecase.dart';
import '../../features/announcements/domain/usecases/watch_announcements_usecase.dart';
import '../../features/announcements/presentation/cubit/announcement_cubit.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_with_student_no_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_user_usecase.dart';
import '../../features/auth/domain/usecases/send_password_reset_mail_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../network/network_info.dart';
import '../services/analytics_service.dart';
import '../services/fcm_notification_service.dart';
import '../services/local_storage_service.dart';
import '../theme/theme_cubit.dart';

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
  sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService(sl<SharedPreferences>()));
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(localStorageService: sl()));
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService(analytics: sl(), crashlytics: sl()));
  sl.registerLazySingleton<FcmNotificationService>(() => FcmNotificationService(firebaseMessaging: sl()));
  // TODO(Dev3): FilePickerService ve AudioRecorderService kayıtları.

  // ThemeCubit: MultiBlocProvider ile aynı örnek kullanılmalı -> LazySingleton.
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));
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
  // DataSource (Dev3)
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(localStorageService: sl()));
  // Repository (Dev3)
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
        fcmService: sl(),
        analyticsService: sl(),
      ));
  // UseCase (Dev5)
  sl.registerLazySingleton(() => LoginWithStudentNoUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUserUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetMailUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  // Cubit (Dev5) — GoRouter (RoleGuard) ile aynı örnek -> LazySingleton.
  // Oluşturulur oluşturulmaz oturumu kontrol eder; Splash bekleme durumundan çıkar.
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(
        loginWithStudentNoUseCase: sl(),
        registerUserUseCase: sl(),
        sendPasswordResetMailUseCase: sl(),
        getCurrentUserUseCase: sl(),
        logoutUseCase: sl(),
      )..checkAuthStatus());
}

void _initAnnouncements() {
  sl.registerLazySingleton<AnnouncementRemoteDataSource>(
      () => AnnouncementRemoteDataSourceImpl(firestore: sl(), fcmNotificationService: sl()));
  sl.registerLazySingleton<AnnouncementRepository>(() => AnnouncementRepositoryImpl(
        remoteDataSource: sl(),
        networkInfo: sl(),
        fcmNotificationService: sl(),
        analyticsService: sl(),
      ));
  sl.registerLazySingleton(() => WatchAnnouncementsUseCase(sl()));
  sl.registerLazySingleton(() => CreateAnnouncementUseCase(sl()));
  sl.registerLazySingleton(() => SendInstantCrisisPushUseCase(sl()));
  sl.registerFactory(() => AnnouncementCubit(
        watchAnnouncementsUseCase: sl(),
        createAnnouncementUseCase: sl(),
        sendInstantCrisisPushUseCase: sl(),
      ));
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
