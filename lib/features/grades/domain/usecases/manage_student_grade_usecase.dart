import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/either_guard.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../entities/course_grade_entity.dart';
import '../repositories/grades_repository.dart';

typedef RegisteredStudent = ({String uid, String name, String studentNo});

/// Kural 4 Uygulayıcısı: Vize %40 + Final %60 + Bonus (max 100) → harf notu.
class ManageStudentGradeUseCase {
  const ManageStudentGradeUseCase(this._repository);

  final GradesRepository _repository;

  /// Girilen notlardan ortalama + harf notu hesaplanmış kaydı üretir.
  static CourseGradeEntity buildGrade({
    required String courseId,
    required String courseName,
    required int credit,
    required RegisteredStudent student,
    required double midterm,
    required double finalScore,
    required double bonus,
  }) {
    final average = GradeCalculator.calculateCourseAverage(midterm, finalScore, bonus);
    return CourseGradeEntity(
      gradeId: student.uid,
      courseId: courseId,
      courseName: courseName,
      credit: credit,
      studentUid: student.uid,
      studentName: student.name,
      studentNo: student.studentNo,
      midtermScore: midterm,
      finalScore: finalScore,
      bonusScore: bonus,
      totalAverage: average,
      letterGrade: GradeCalculator.getLetterGrade(average),
    );
  }

  Future<Either<Failure, CourseGradeEntity>> save({
    required String courseId,
    required String courseName,
    required int credit,
    required RegisteredStudent student,
    required double midterm,
    required double finalScore,
    required double bonus,
  }) async {
    bool outOfRange(double v) => v < 0 || v > 100;
    if (outOfRange(midterm) || outOfRange(finalScore)) {
      return const Left(ServerFailure('Vize ve Final 0-100 arasında olmalıdır.'));
    }
    if (bonus < 0) return const Left(ServerFailure('Bonus negatif olamaz.'));

    final grade = buildGrade(
      courseId: courseId,
      courseName: courseName,
      credit: credit,
      student: student,
      midterm: midterm,
      finalScore: finalScore,
      bonus: bonus,
    );
    return guardFailure(() async {
      await _repository.manageStudentGrade(grade);
      return grade;
    });
  }

  Future<Either<Failure, Unit>> delete({required String gradeId, required String courseId}) =>
      guardFailure(() async {
        await _repository.deleteStudentGrade(gradeId, courseId);
        return unit;
      });

  Future<Either<Failure, List<RegisteredStudent>>> registeredStudents() =>
      guardFailure(_repository.getRegisteredStudents);
}
