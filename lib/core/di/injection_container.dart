import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/assignments/data/datasources/assignment_remote_datasource.dart';
import '../../features/assignments/data/datasources/assignment_storage_datasource.dart';
import '../../features/assignments/data/repositories/assignment_repository_impl.dart';
import '../../features/assignments/domain/repositories/assignment_repository.dart';
import '../../features/assignments/domain/usecases/create_assignment_usecase.dart';
import '../../features/assignments/domain/usecases/grade_and_feedback_usecase.dart';
import '../../features/assignments/domain/usecases/upload_assignment_submission_usecase.dart';
import '../../features/assignments/presentation/cubit/assignment_cubit.dart';
import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/evaluate_absence_risk_usecase.dart';
import '../../features/attendance/domain/usecases/generate_60s_qr_pin_usecase.dart';
import '../../features/attendance/domain/usecases/manage_attendance_record_usecase.dart';
import '../../features/attendance/domain/usecases/submit_live_attendance_usecase.dart';
import '../../features/attendance/domain/usecases/watch_live_attendance_roster_usecase.dart';
import '../../features/attendance/presentation/cubit/absence_control_cubit.dart';
import '../../features/attendance/presentation/cubit/live_attendance_cubit.dart';
import '../../features/forum/data/datasources/forum_remote_datasource.dart';
import '../../features/forum/data/repositories/forum_repository_impl.dart';
import '../../features/forum/domain/repositories/forum_repository.dart';
import '../../features/forum/domain/usecases/ask_question_with_photo_usecase.dart';
import '../../features/forum/domain/usecases/mark_answer_as_resolved_usecase.dart';
import '../../features/forum/domain/usecases/post_forum_answer_usecase.dart';
import '../../features/forum/domain/usecases/watch_forum_questions_usecase.dart';
import '../../features/forum/presentation/cubit/forum_cubit.dart';
import '../../features/grades/data/datasources/grades_remote_datasource.dart';
import '../../features/grades/data/repositories/grades_repository_impl.dart';
import '../../features/grades/domain/repositories/grades_repository.dart';
import '../../features/grades/domain/usecases/calculate_gpa_simulation_usecase.dart';
import '../../features/grades/domain/usecases/manage_student_grade_usecase.dart';
import '../../features/grades/domain/usecases/watch_student_grades_usecase.dart';
import '../../features/grades/presentation/cubit/grades_cubit.dart';
import '../../features/schedule/data/datasources/schedule_remote_datasource.dart';
import '../../features/schedule/data/repositories/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/schedule/domain/usecases/add_or_remove_course_usecase.dart';
import '../../features/schedule/domain/usecases/update_course_details_usecase.dart';
import '../../features/schedule/domain/usecases/watch_weekly_schedule_usecase.dart';
import '../../features/schedule/presentation/cubit/schedule_cubit.dart';
import '../services/audio_recorder_service.dart';
import '../services/file_picker_service.dart';
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
  sl.registerLazySingleton<FilePickerService>(() => FilePickerService());
  sl.registerLazySingleton<AudioRecorderService>(() => AudioRecorderService());

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
  // Oturum kontrolünü (checkAuthStatus) SplashPage başlatır.
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(
        loginWithStudentNoUseCase: sl(),
        registerUserUseCase: sl(),
        sendPasswordResetMailUseCase: sl(),
        getCurrentUserUseCase: sl(),
        logoutUseCase: sl(),
      ));
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
  sl.registerLazySingleton<ScheduleRemoteDataSource>(() => ScheduleRemoteDataSourceImpl(firestore: sl()));
  sl.registerLazySingleton<ScheduleRepository>(
      () => ScheduleRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()));
  sl.registerLazySingleton(() => WatchWeeklyScheduleUseCase(sl()));
  sl.registerLazySingleton(() => AddOrRemoveCourseUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCourseDetailsUseCase(sl()));
  sl.registerFactory(() => ScheduleCubit(
        watchWeeklyScheduleUseCase: sl(),
        addOrRemoveCourseUseCase: sl(),
        updateCourseDetailsUseCase: sl(),
      ));
}

void _initAttendance() {
  sl.registerLazySingleton<AttendanceRemoteDataSource>(() => AttendanceRemoteDataSourceImpl(firestore: sl()));
  sl.registerLazySingleton<AttendanceRepository>(() => AttendanceRepositoryImpl(
        remoteDataSource: sl(),
        networkInfo: sl(),
        analyticsService: sl(),
        fcmNotificationService: sl(),
      ));
  sl.registerLazySingleton(() => Generate60sQrPinUseCase(sl()));
  sl.registerLazySingleton(() => SubmitLiveAttendanceUseCase(sl()));
  sl.registerLazySingleton(() => WatchLiveAttendanceRosterUseCase(sl()));
  sl.registerLazySingleton(() => ManageAttendanceRecordUseCase(sl()));
  sl.registerLazySingleton(() => EvaluateAbsenceRiskUseCase(sl()));
  sl.registerFactory(() => LiveAttendanceCubit(
        generate60sQrPinUseCase: sl(),
        submitLiveAttendanceUseCase: sl(),
        watchLiveAttendanceRosterUseCase: sl(),
        manageAttendanceRecordUseCase: sl(),
      ));
  // Schedule ve Grades use case'lerine de bağlıdır; GetIt tembel çözdüğü
  // için kayıt sırası önemli değildir.
  sl.registerFactory(() => AbsenceControlCubit(
        watchWeeklyScheduleUseCase: sl(),
        evaluateAbsenceRiskUseCase: sl(),
        manageAttendanceRecordUseCase: sl(),
        watchStudentGradesUseCase: sl(),
      ));
}

void _initAssignments() {
  sl.registerLazySingleton<AssignmentRemoteDataSource>(() => AssignmentRemoteDataSourceImpl(firestore: sl()));
  sl.registerLazySingleton<AssignmentStorageDataSource>(() => AssignmentStorageDataSourceImpl(storage: sl()));
  sl.registerLazySingleton<AssignmentRepository>(() => AssignmentRepositoryImpl(
        remoteDataSource: sl(),
        storageDataSource: sl(),
        networkInfo: sl(),
        analyticsService: sl(),
      ));
  sl.registerLazySingleton(() => CreateAssignmentUseCase(sl()));
  sl.registerLazySingleton(() => UploadAssignmentSubmissionUseCase(sl()));
  sl.registerLazySingleton(() => GradeAndFeedbackUseCase(sl()));
  sl.registerFactory(() => AssignmentCubit(
        watchWeeklyScheduleUseCase: sl(),
        createAssignmentUseCase: sl(),
        uploadAssignmentSubmissionUseCase: sl(),
        gradeAndFeedbackUseCase: sl(),
        audioRecorderService: sl(),
      ));
}

void _initGrades() {
  sl.registerLazySingleton<GradesRemoteDataSource>(() => GradesRemoteDataSourceImpl(firestore: sl()));
  sl.registerLazySingleton<GradesRepository>(() => GradesRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()));
  sl.registerLazySingleton(() => WatchStudentGradesUseCase(sl()));
  sl.registerLazySingleton(() => ManageStudentGradeUseCase(sl()));
  sl.registerLazySingleton(() => const CalculateGpaSimulationUseCase());
  sl.registerFactory(() => GradesCubit(
        watchStudentGradesUseCase: sl(),
        manageStudentGradeUseCase: sl(),
        calculateGpaSimulationUseCase: sl(),
        watchWeeklyScheduleUseCase: sl(),
      ));
}

void _initForum() {
  sl.registerLazySingleton<ForumRemoteDataSource>(() => ForumRemoteDataSourceImpl(firestore: sl(), storage: sl()));
  sl.registerLazySingleton<ForumRepository>(() => ForumRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()));
  sl.registerLazySingleton(() => WatchForumQuestionsUseCase(sl()));
  sl.registerLazySingleton(() => AskQuestionWithPhotoUseCase(sl()));
  sl.registerLazySingleton(() => PostForumAnswerUseCase(sl()));
  sl.registerLazySingleton(() => MarkAnswerAsResolvedUseCase(sl()));
  sl.registerFactory(() => ForumCubit(
        watchForumQuestionsUseCase: sl(),
        askQuestionWithPhotoUseCase: sl(),
        postForumAnswerUseCase: sl(),
        markAnswerAsResolvedUseCase: sl(),
      ));
}
