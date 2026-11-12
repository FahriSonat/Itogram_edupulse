import '../../../../core/enums/attendance_status.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../domain/entities/student_absence_record_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

export '../datasources/attendance_remote_datasource.dart'
    show ExpiredQrPinException;

/// Kritik İş Kuralı 1 & 3 Uygulayıcısı:
/// 1) Öğrenci 4 haneli PIN veya QR okuttuğunda Firestore Transaction içinde tüm okumaları
///    yazmalardan önce yapar ve sunucu zamanını kontrol eder; `now > expiresAt` (60 sn dolmuşsa)
///    veya oturum kapalıysa [ExpiredQrPinException] fırlatır.
/// 2) Eğitmen yoklama kaydını güncellediğinde veya devamsızlık eklediğinde öğrencinin
///    toplam devamsızlık yüzdesini hesaplar; %20'yi aşıyorsa `isCriticalRisk = true`
///    yapar ve [FcmNotificationService] üzerinden öğrenciye otomatik
///    "Kritik Devamsızlık Riski!" push bildirimi gönderir.
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final AnalyticsService? analyticsService;
  final FcmNotificationService? fcmNotificationService;

  AttendanceRepositoryImpl({
    AttendanceRemoteDataSource? remoteDataSource,
    NetworkInfo? networkInfo,
    this.analyticsService,
    this.fcmNotificationService,
  })  : _remoteDataSource =
            remoteDataSource ?? AttendanceRemoteDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  @override
  Future<AttendanceSessionEntity> generateAttendanceSession(
    String courseId,
  ) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final session =
        await _remoteDataSource.generateAttendanceSession(courseId);

    await analyticsService?.logAttendanceStarted(
      courseId: courseId,
      sessionId: session.sessionId,
      instructorId: 'instructor',
    );

    return session;
  }

  @override
  Future<void> submitLiveAttendance({
    required String sessionId,
    required String studentUid,
    required String code,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    await _remoteDataSource.submitLiveAttendance(
      sessionId: sessionId,
      studentUid: studentUid,
      code: code,
    );

    await analyticsService?.logAttendanceSubmitted(
      courseId: '',
      sessionId: sessionId,
      method: code.trim().length == 4 ? 'pin' : 'qr',
    );
  }

  @override
  Stream<AttendanceSessionEntity?> watchLiveAttendanceRoster(
    String sessionId,
  ) {
    return _remoteDataSource.watchLiveAttendanceRoster(sessionId);
  }

  @override
  Future<void> updateAttendanceRecord({
    required String courseId,
    required String studentUid,
    required AttendanceStatus status,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final updatedRecord = await _remoteDataSource.updateAttendanceRecord(
      courseId: courseId,
      studentUid: studentUid,
      status: status,
    );

    if (updatedRecord.isCriticalRisk) {
      await fcmNotificationService?.showAbsenceLimitWarningNotification(
        courseName: updatedRecord.courseName,
        absencePercentage: updatedRecord.absencePercentage / 100.0,
        studentId: studentUid,
        absentHours: updatedRecord.absentHours,
        maxAllowedHours: (updatedRecord.totalCourseHours * 0.20).floor(),
      );
    }
  }

  @override
  Future<StudentAbsenceRecordEntity> evaluateAbsenceRisk(
    String courseId,
    String studentUid,
  ) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final evaluatedRecord = await _remoteDataSource.evaluateAbsenceRisk(
      courseId,
      studentUid,
    );

    if (evaluatedRecord.isCriticalRisk) {
      await fcmNotificationService?.showAbsenceLimitWarningNotification(
        courseName: evaluatedRecord.courseName,
        absencePercentage: evaluatedRecord.absencePercentage / 100.0,
        studentId: studentUid,
        absentHours: evaluatedRecord.absentHours,
        maxAllowedHours: (evaluatedRecord.totalCourseHours * 0.20).floor(),
      );
    }

    return evaluatedRecord;
  }

  @override
  Stream<List<StudentAbsenceRecordEntity>> watchClassAbsenceRecords(
    String courseId,
  ) {
    return _remoteDataSource.watchClassAbsenceRecords(courseId);
  }

  @override
  Future<StudentAbsenceRecordEntity> getStudentAbsenceRecord(
    String courseId,
    String studentUid,
  ) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    return _remoteDataSource.getStudentAbsenceRecord(courseId, studentUid);
  }
}
