import '../entities/attendance_session_entity.dart';
import '../entities/student_absence_record_entity.dart';
import '../../../../core/enums/attendance_status.dart';

abstract class AttendanceRepository {
  Future<AttendanceSessionEntity> generateAttendanceSession(String courseId);
  
  Future<void> submitLiveAttendance({
    required String sessionId,
    required String studentUid,
    required String code,
  });
  
  Stream<AttendanceSessionEntity?> watchLiveAttendanceRoster(String sessionId);
  
  Future<void> updateAttendanceRecord({
    required String courseId,
    required String studentUid,
    required AttendanceStatus status,
  });
  
  Future<StudentAbsenceRecordEntity> evaluateAbsenceRisk(String courseId, String studentUid);
  
  Stream<List<StudentAbsenceRecordEntity>> watchClassAbsenceRecords(String courseId);
  
  Future<StudentAbsenceRecordEntity> getStudentAbsenceRecord(String courseId, String studentUid);
}