import 'dart:math' as math;

import '../../../../core/enums/attendance_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../entities/attendance_session_entity.dart';
import '../entities/student_absence_record_entity.dart';
import '../repositories/attendance_repository.dart';
import 'evaluate_absence_risk_usecase.dart';
import 'generate_60s_qr_pin_usecase.dart';

/// Yoklama oturumu kapanış özeti.
typedef AttendanceSummary = ({int present, int absent, int excused, int newlyCritical});

/// Eğitmenin yoklama oturumunu başlatması, öğrenci durumlarını elle düzeltmesi
/// ve oturumu kapatıp devamsızlıkları işlemesi (tümü Kural 5 ile korunur).
class ManageAttendanceRecordUseCase {
  ManageAttendanceRecordUseCase(
    this._repository, {
    required this._pinGenerator,
    this._riskEvaluator = const EvaluateAbsenceRiskUseCase(),
  });

  final AttendanceRepository _repository;
  final Generate60sQrPinUseCase _pinGenerator;
  final EvaluateAbsenceRiskUseCase _riskEvaluator;

  /// Ders süresini devamsızlık saatine çevirir (45 dk = 1 ders saati).
  static int sessionHoursFor(CourseScheduleEntity course) {
    final minutes = course.endMinutes - course.startMinutes;
    return math.max(1, (minutes / 45).round());
  }

  Future<AttendanceSessionEntity> start({
    required UserEntity actor,
    required CourseScheduleEntity course,
    required List<UserEntity> students,
  }) async {
    RoleGuard.requireInstructor(actor.role);
    final running = _repository.getActiveSessions().where((s) => s.instructorUid == actor.uid).firstOrNull;
    if (running != null) {
      if (running.courseCode == course.courseCode) return running;
      throw ValidationFailure('Önce devam eden "${running.courseName}" yoklamasını bitiriniz.');
    }

    final id = _repository.newSessionId();
    final code = _pinGenerator.generate(sessionId: id);
    final session = AttendanceSessionEntity(
      id: id,
      courseId: course.id,
      courseCode: course.courseCode,
      courseName: course.courseName,
      instructorUid: actor.uid,
      instructorName: actor.fullName,
      startedAt: DateTime.now(),
      pinCode: code.pin,
      qrToken: code.qrToken,
      pinExpiresAt: code.expiresAt,
      sessionHours: sessionHoursFor(course),
      marks: [
        for (final s in students) AttendanceMark(studentUid: s.uid, studentName: s.fullName, studentNo: s.schoolNo),
      ],
    );
    await _repository.saveSession(session);
    return session;
  }

  Future<void> setStatus({
    required UserEntity actor,
    required String sessionId,
    required String studentUid,
    required AttendanceStatus status,
  }) async {
    RoleGuard.requireInstructor(actor.role);
    final session = _requireActive(sessionId);
    final marks = [
      for (final m in session.marks)
        m.studentUid == studentUid ? m.copyWith(status: status, recordedAt: DateTime.now()) : m,
    ];
    await _repository.saveSession(session.copyWith(marks: marks));
  }

  /// Oturumu kapatır; "Gelmeyen" öğrencilerin devamsızlığına oturum saatini ekler
  /// ve %20 eşiğini yeni aşan öğrencilere uyarı gönderir (Kural 3).
  Future<AttendanceSummary> end({required UserEntity actor, required String sessionId}) async {
    RoleGuard.requireInstructor(actor.role);
    final session = _requireActive(sessionId);
    final now = DateTime.now();

    final existing = {for (final r in _repository.getAbsenceRecords()) r.id: r};
    final updates = <StudentAbsenceRecordEntity>[];
    final newlyCritical = <StudentAbsenceRecordEntity>[];

    for (final mark in session.marks.where((m) => m.status == AttendanceStatus.absent)) {
      final recordId = StudentAbsenceRecordEntity.buildId(mark.studentUid, _courseKey(session, existing, mark));
      final before =
          existing[recordId] ??
          StudentAbsenceRecordEntity(
            id: recordId,
            studentUid: mark.studentUid,
            studentName: mark.studentName,
            studentNo: mark.studentNo,
            courseId: session.courseId,
            courseCode: session.courseCode,
            courseName: session.courseName,
            absentHours: 0,
            totalHours: 40,
          );
      final after = before.copyWith(absentHours: before.absentHours + session.sessionHours);
      updates.add(after);
      if (_riskEvaluator.crossedCriticalThreshold(before, after)) newlyCritical.add(after);
    }

    if (updates.isNotEmpty) await _repository.saveAbsenceRecords(updates);
    await _repository.saveSession(session.copyWith(isActive: false, endedAt: now, pinExpiresAt: now));
    for (final record in newlyCritical) {
      await _repository.sendAbsenceWarning(record: record, senderName: actor.fullName);
    }

    return (
      present: session.countOf(AttendanceStatus.present),
      absent: session.countOf(AttendanceStatus.absent),
      excused: session.countOf(AttendanceStatus.excused),
      newlyCritical: newlyCritical.length,
    );
  }

  /// Aynı ders kodunun (ör. teori + lab) devamsızlığı tek kayıtta toplanır.
  String _courseKey(
    AttendanceSessionEntity session,
    Map<String, StudentAbsenceRecordEntity> existing,
    AttendanceMark mark,
  ) {
    for (final r in existing.values) {
      if (r.studentUid == mark.studentUid && r.courseCode == session.courseCode) return r.courseId;
    }
    return session.courseId;
  }

  AttendanceSessionEntity _requireActive(String sessionId) {
    final session = _repository.getSession(sessionId);
    if (session == null || !session.isActive) {
      throw const ValidationFailure('Yoklama oturumu bulunamadı veya kapatılmış.');
    }
    return session;
  }
}
