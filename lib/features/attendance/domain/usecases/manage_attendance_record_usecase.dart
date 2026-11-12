import 'package:dartz/dartz.dart';

import '../../../../core/enums/attendance_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../entities/student_absence_record_entity.dart';
import '../repositories/attendance_repository.dart';

/// Eğitmenin manuel yoklama eklemesi / değiştirmesi ve sınıf devamsızlık listesini izlemesi.
class ManageAttendanceRecordUseCase {
  const ManageAttendanceRecordUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String courseId,
    required String studentUid,
    required AttendanceStatus status,
  }) =>
      guardFailure(() async {
        await _repository.updateAttendanceRecord(courseId: courseId, studentUid: studentUid, status: status);
        return unit;
      });

  Stream<Either<Failure, List<StudentAbsenceRecordEntity>>> watchClass(String courseId) =>
      guardStream(_repository.watchClassAbsenceRecords(courseId));
}
