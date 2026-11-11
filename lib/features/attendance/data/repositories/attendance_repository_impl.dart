import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../domain/entities/student_absence_record_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_session_model.dart';
import '../models/student_absence_record_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl({required this.remote, required this.notifications});

  final AttendanceRemoteDataSource remote;
  final NotificationService notifications;

  @override
  Stream<List<AttendanceSessionEntity>> watchSessions() => remote.watchSessions();

  @override
  List<AttendanceSessionEntity> getActiveSessions() => remote.getSessions().where((s) => s.isActive).toList();

  @override
  AttendanceSessionEntity? getSession(String sessionId) => remote.getSession(sessionId);

  @override
  Future<void> saveSession(AttendanceSessionEntity session) async {
    try {
      await remote.saveSession(AttendanceSessionModel.fromEntity(session));
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  String newSessionId() => remote.newId();

  @override
  Stream<List<StudentAbsenceRecordEntity>> watchAbsenceRecords() => remote.watchAbsenceRecords();

  @override
  List<StudentAbsenceRecordEntity> getAbsenceRecords() => remote.getAbsenceRecords();

  @override
  Future<void> saveAbsenceRecords(List<StudentAbsenceRecordEntity> records) async {
    try {
      await remote.saveAbsenceRecords(records.map(StudentAbsenceRecordModel.fromEntity).toList());
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<void> sendAbsenceWarning({required StudentAbsenceRecordEntity record, String? senderName}) async {
    try {
      final from = senderName == null ? '' : ' — $senderName';
      await notifications.send(
        title: 'Kritik Devamsızlık Uyarısı',
        body:
            '${record.courseName}: %${record.percentage.toStringAsFixed(1)} devamsızlık '
            '(${record.absentHours}/${record.totalHours} saat). ${AppStrings.criticalRiskNotification}$from',
        kind: NotificationKind.absence,
        targetUid: record.studentUid,
      );
    } catch (e) {
      throw Failure.from(e);
    }
  }
}
