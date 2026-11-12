import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/student_absence_record_entity.dart';
import '../repositories/attendance_repository.dart';

/// Kural 3: %20 devamsızlık sınırı motoru.
class EvaluateAbsenceRiskUseCase {
  const EvaluateAbsenceRiskUseCase(this._repository);

  final AttendanceRepository _repository;

  /// Şartname: toplam ders saatinin %20'si ve üzeri → Kritik Risk.
  static const double criticalThreshold = 20.0;

  static double percentage(int absentHours, int totalHours) =>
      totalHours <= 0 ? 0 : (absentHours / totalHours) * 100;

  static bool isCritical(int absentHours, int totalHours) => percentage(absentHours, totalHours) >= criticalThreshold;

  /// Riski yeniden hesaplar; aşım varsa repository öğrenciye FCM push gönderir.
  Future<Either<Failure, StudentAbsenceRecordEntity>> call(String courseId, String studentUid) =>
      guardFailure(() => _repository.evaluateAbsenceRisk(courseId, studentUid));

  /// Öğrencinin kendi ders bazlı devamsızlık özeti.
  Future<Either<Failure, StudentAbsenceRecordEntity>> studentRecord(String courseId, String studentUid) =>
      guardFailure(() => _repository.getStudentAbsenceRecord(courseId, studentUid));
}
