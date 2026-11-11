import 'package:shared_preferences/shared_preferences.dart';

import '../../features/announcements/data/datasources/announcement_remote_datasource.dart';
import '../../features/announcements/data/repositories/announcement_repository_impl.dart';
import '../../features/announcements/domain/repositories/announcement_repository.dart';
import '../../features/announcements/domain/usecases/create_announcement_usecase.dart';
import '../../features/announcements/domain/usecases/send_instant_crisis_push_usecase.dart';
import '../../features/announcements/domain/usecases/watch_announcements_usecase.dart';
import '../../features/announcements/presentation/cubit/announcement_cubit.dart';
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
import '../../features/attendance/domain/usecases/generate_60s_qr_pin_usecase.dart';
import '../../features/attendance/domain/usecases/manage_attendance_record_usecase.dart';
import '../../features/attendance/domain/usecases/submit_live_attendance_usecase.dart';
import '../../features/attendance/domain/usecases/watch_live_attendance_roster_usecase.dart';
import '../../features/attendance/presentation/cubit/absence_control_cubit.dart';
import '../../features/attendance/presentation/cubit/live_attendance_cubit.dart';
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
import '../../features/grades/domain/usecases/manage_student_grade_usecase.dart';
import '../../features/grades/domain/usecases/watch_student_grades_usecase.dart';
import '../../features/grades/presentation/cubit/grades_cubit.dart';
import '../../features/notifications/presentation/cubit/notification_cubit.dart';
import '../../features/schedule/data/datasources/schedule_remote_datasource.dart';
import '../../features/schedule/data/repositories/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/schedule/domain/usecases/add_or_remove_course_usecase.dart';
import '../../features/schedule/domain/usecases/update_course_details_usecase.dart';
import '../../features/schedule/domain/usecases/watch_weekly_schedule_usecase.dart';
import '../../features/schedule/presentation/cubit/schedule_cubit.dart';
import '../network/network_info.dart';
import '../services/analytics_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/fcm_notification_service.dart';
import '../services/file_picker_service.dart';
import '../services/local_storage_service.dart';

/// Minimal servis bulucu: tekil (singleton) bağımlılıkları tip bazında tutar.
class ServiceLocator {
  final Map<Type, Object Function()> _factories = {};
  final Map<Type, Object> _singletons = {};

  void registerSingleton<T extends Object>(T instance) => _singletons[T] = instance;

  /// İlk istendiğinde oluşturulup saklanır.
  void registerLazySingleton<T extends Object>(T Function() create) => _factories[T] = create;

  /// Her istendiğinde yeniden oluşturulur (ör. Cubit'ler).
  void registerFactory<T extends Object>(T Function() create) => _factories[T] = () => _FactoryMarker<T>(create);

  T call<T extends Object>() => get<T>();

  T get<T extends Object>() {
    final existing = _singletons[T];
    if (existing != null) return existing as T;
    final factory = _factories[T];
    if (factory == null) throw StateError('$T kayıtlı değil. initDependencies() çağrıldı mı?');
    final created = factory();
    if (created is _FactoryMarker<T>) return created.create();
    _singletons[T] = created;
    return created as T;
  }

  bool isRegistered<T extends Object>() => _singletons.containsKey(T) || _factories.containsKey(T);

  void reset() {
    _factories.clear();
    _singletons.clear();
  }
}

class _FactoryMarker<T> {
  const _FactoryMarker(this.create);
  final T Function() create;
}

final ServiceLocator sl = ServiceLocator();

/// Tüm bağımlılıkları kaydeder ve yerel veritabanını hazırlar.
/// Testlerde `SharedPreferences.setMockInitialValues({})` sonrası çağrılabilir.
Future<void> initDependencies({SharedPreferences? preferences}) async {
  sl.reset();

  // ---------------------------------------------------------------------------
  // ÇEKİRDEK
  // ---------------------------------------------------------------------------
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final storage = LocalStorageService(prefs);
  await storage.init();

  sl
    ..registerSingleton<LocalStorageService>(storage)
    ..registerSingleton<NetworkInfo>(const LocalNetworkInfo())
    ..registerSingleton<AnalyticsService>(const AnalyticsService())
    ..registerSingleton<FilePickerService>(const PlatformFilePickerService())
    ..registerSingleton<AudioRecorderService>(const UnsupportedAudioRecorderService())
    ..registerLazySingleton<NotificationService>(() => NotificationService(sl()));

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------
  sl
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remote: LocalAuthRemoteDataSource(sl()), local: AuthLocalDataSourceImpl(sl())),
    )
    ..registerFactory<AuthCubit>(
      () => AuthCubit(
        getCurrentUser: GetCurrentUserUseCase(sl()),
        login: LoginWithStudentNoUseCase(sl()),
        register: RegisterUserUseCase(sl()),
        logout: LogoutUseCase(sl()),
        sendPasswordReset: SendPasswordResetMailUseCase(sl()),
      ),
    );

  // ---------------------------------------------------------------------------
  // DERS PROGRAMI
  // ---------------------------------------------------------------------------
  sl
    ..registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryImpl(LocalScheduleRemoteDataSource(sl())))
    ..registerFactory<ScheduleCubit>(
      () => ScheduleCubit(
        watchSchedule: WatchWeeklyScheduleUseCase(sl()),
        addOrRemoveCourse: AddOrRemoveCourseUseCase(sl()),
        updateCourse: UpdateCourseDetailsUseCase(sl()),
      ),
    );

  // ---------------------------------------------------------------------------
  // DUYURULAR
  // ---------------------------------------------------------------------------
  sl
    ..registerLazySingleton<AnnouncementRepository>(
      () => AnnouncementRepositoryImpl(remote: LocalAnnouncementRemoteDataSource(sl()), notifications: sl()),
    )
    ..registerFactory<AnnouncementCubit>(
      () => AnnouncementCubit(
        watchAnnouncements: WatchAnnouncementsUseCase(sl()),
        createAnnouncement: CreateAnnouncementUseCase(sl()),
        sendCrisisPush: SendInstantCrisisPushUseCase(sl()),
      ),
    );

  // ---------------------------------------------------------------------------
  // ÖDEVLER
  // ---------------------------------------------------------------------------
  sl
    ..registerLazySingleton<AssignmentRepository>(
      () => AssignmentRepositoryImpl(
        remote: LocalAssignmentRemoteDataSource(sl()),
        storage: const LocalAssignmentStorageDataSource(),
        notifications: sl(),
      ),
    )
    ..registerFactory<AssignmentCubit>(
      () => AssignmentCubit(
        repository: sl(),
        createAssignment: CreateAssignmentUseCase(sl()),
        uploadSubmission: UploadAssignmentSubmissionUseCase(sl()),
        gradeAndFeedback: GradeAndFeedbackUseCase(sl()),
      ),
    );

  // ---------------------------------------------------------------------------
  // YOKLAMA & DEVAMSIZLIK
  // ---------------------------------------------------------------------------
  sl
    ..registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(remote: LocalAttendanceRemoteDataSource(sl()), notifications: sl()),
    )
    ..registerFactory<LiveAttendanceCubit>(() {
      final pinGenerator = Generate60sQrPinUseCase(sl());
      return LiveAttendanceCubit(
        watchRoster: WatchLiveAttendanceRosterUseCase(sl()),
        pinGenerator: pinGenerator,
        submitAttendance: SubmitLiveAttendanceUseCase(sl()),
        manageRecords: ManageAttendanceRecordUseCase(sl(), pinGenerator: pinGenerator),
        authRepository: sl(),
      );
    })
    ..registerFactory<AbsenceControlCubit>(() => AbsenceControlCubit(repository: sl()));

  // ---------------------------------------------------------------------------
  // NOTLAR
  // ---------------------------------------------------------------------------
  sl
    ..registerLazySingleton<GradesRepository>(
      () => GradesRepositoryImpl(remote: LocalGradesRemoteDataSource(sl()), notifications: sl()),
    )
    ..registerFactory<GradesCubit>(
      () => GradesCubit(
        watchGrades: WatchStudentGradesUseCase(sl()),
        manageGrade: ManageStudentGradeUseCase(sl()),
        authRepository: sl(),
      ),
    );

  // ---------------------------------------------------------------------------
  // FORUM
  // ---------------------------------------------------------------------------
  sl
    ..registerLazySingleton<ForumRepository>(
      () => ForumRepositoryImpl(remote: LocalForumRemoteDataSource(sl()), notifications: sl()),
    )
    ..registerFactory<ForumCubit>(
      () => ForumCubit(
        watchQuestions: WatchForumQuestionsUseCase(sl()),
        askQuestion: AskQuestionWithPhotoUseCase(sl()),
        postAnswer: PostForumAnswerUseCase(sl()),
        markResolved: MarkAnswerAsResolvedUseCase(sl()),
      ),
    );
}

/// [NotificationCubit] oturumdaki [AuthCubit]'e bağlı olduğu için ayrı oluşturulur.
NotificationCubit createNotificationCubit(AuthCubit authCubit) =>
    NotificationCubit(service: sl(), authCubit: authCubit);
