import '../../../../core/enums/attendance_status.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../datasources/attendance_remote_datasource.dart';

export '../datasources/attendance_remote_datasource.dart'
    show ExpiredQrPinException;

/// Kritik İş Kuralı 1 & 3 Uygulayıcısı:
/// 1) Öğrenci PIN veya QR okuttuğunda Firestore Transaction içinde sunucu zamanını
///    kontrol eder; `now > expiresAt` (60 sn dolmuşsa) veya oturum kapalıysa
///    [ExpiredQrPinException] fırlatır.
/// 2) Eğitmen yoklamayı kapattığında veya manuel devamsızlık eklediğinde öğrencinin
///    toplam devamsızlık yüzdesini hesaplar; %20'yi aşıyorsa `isCriticalRisk = true`
///    yapar ve [FcmNotificationService] üzerinden öğrenciye otomatik
///    "Kritik Devamsızlık Riski!" push bildirimi gönderir.
class AttendanceRepositoryImpl {
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

  Future<Map<String, dynamic>> generate60sQrPinSession({
    required String courseId,
    required String instructorId,
    String? sessionId,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final session = await _remoteDataSource.createOrRefresh60sQrPinSession(
      courseId: courseId,
      instructorId: instructorId,
      sessionId: sessionId,
      validitySeconds: 60,
    );

    await analyticsService?.logAttendanceStarted(
      courseId: courseId,
      sessionId: session['id']?.toString() ?? '',
      instructorId: instructorId,
    );

    return session;
  }

  Future<Map<String, dynamic>> submitLiveAttendance({
    required String courseId,
    required String sessionId,
    required String studentId,
    required String studentName,
    required String studentNo,
    String? pinOrQrToken,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final result = await _remoteDataSource.submitLiveAttendance(
      courseId: courseId,
      sessionId: sessionId,
      studentId: studentId,
      studentName: studentName,
      studentNo: studentNo,
      pinOrQrToken: pinOrQrToken,
    );

    await analyticsService?.logAttendanceSubmitted(
      courseId: courseId,
      sessionId: sessionId,
      method: (pinOrQrToken != null && pinOrQrToken.length == 6) ? 'pin' : 'qr',
    );

    return result;
  }

  /// Eğitmen yoklamayı kapattığında devamsızlık yüzdesi %20'yi aşan öğrencileri
  /// `isCriticalRisk = true` olarak işaretler ve otomatik "Kritik Devamsızlık Riski!"
  /// push bildirimi gönderir.
  Future<List<Map<String, dynamic>>> closeAttendanceSession({
    required String courseId,
    required String sessionId,
    String? courseName,
    int sessionHours = 1,
    int totalCourseHours = 14,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final criticalStudents = await _remoteDataSource.closeAttendanceSession(
      courseId: courseId,
      sessionId: sessionId,
      sessionHours: sessionHours,
      totalCourseHours: totalCourseHours,
    );

    for (final student in criticalStudents) {
      final ratio = (student['absencePercentage'] as num?)?.toDouble() ?? 0.21;
      await fcmNotificationService?.showAbsenceLimitWarningNotification(
        courseName: courseName ?? courseId,
        absencePercentage: ratio,
        studentId: student['studentId']?.toString(),
        absentHours: student['absentHours'] as int?,
        maxAllowedHours: student['maxAllowedAbsentHours'] as int?,
      );
    }

    return criticalStudents;
  }

  Stream<Map<String, dynamic>?> watchLiveAttendanceRoster({
    required String courseId,
    required String sessionId,
  }) {
    return _remoteDataSource.watchLiveAttendanceSession(
      courseId: courseId,
      sessionId: sessionId,
    );
  }

  Stream<List<Map<String, dynamic>>> watchCourseAttendanceRecords({
    required String courseId,
  }) {
    return _remoteDataSource.watchCourseAttendanceRecords(courseId: courseId);
  }

  /// Manuel devamsızlık ekleme/güncelleme sonrası devamsızlık yüzdesini hesaplar;
  /// %20'yi aşıyorsa `isCriticalRisk = true` yapar ve öğrenciye otomatik
  /// "Kritik Devamsızlık Riski!" push bildirimi gönderir.
  Future<Map<String, dynamic>> manageAttendanceRecord({
    required String courseId,
    required String studentId,
    required String studentName,
    required String studentNo,
    required AttendanceStatus status,
    required int totalSessions,
    required int absentHours,
    required int maxAllowedAbsentHours,
    String? courseName,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final updatedRecord =
        await _remoteDataSource.updateStudentAttendanceRecord(
      courseId: courseId,
      studentId: studentId,
      studentName: studentName,
      studentNo: studentNo,
      status: status,
      totalSessions: totalSessions,
      absentHours: absentHours,
      maxAllowedAbsentHours: maxAllowedAbsentHours,
    );

    final isCriticalRisk = updatedRecord['isCriticalRisk'] as bool? ?? false;
    final absencePercentage =
        (updatedRecord['absencePercentage'] as num?)?.toDouble() ?? 0.0;

    if (isCriticalRisk) {
      await fcmNotificationService?.showAbsenceLimitWarningNotification(
        courseName: courseName ?? courseId,
        absencePercentage: absencePercentage,
        studentId: studentId,
        absentHours: absentHours,
        maxAllowedHours: maxAllowedAbsentHours,
      );
    }

    return updatedRecord;
  }
}
