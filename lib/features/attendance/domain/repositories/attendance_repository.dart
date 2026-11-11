import '../entities/attendance_session_entity.dart';
import '../entities/student_absence_record_entity.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceSessionEntity>> watchSessions();

  List<AttendanceSessionEntity> getActiveSessions();

  AttendanceSessionEntity? getSession(String sessionId);

  Future<void> saveSession(AttendanceSessionEntity session);

  String newSessionId();

  Stream<List<StudentAbsenceRecordEntity>> watchAbsenceRecords();

  List<StudentAbsenceRecordEntity> getAbsenceRecords();

  Future<void> saveAbsenceRecords(List<StudentAbsenceRecordEntity> records);

  /// Kural 3: Öğrenciye kritik devamsızlık bildirimi gönderir.
  Future<void> sendAbsenceWarning({required StudentAbsenceRecordEntity record, String? senderName});
}
