import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/course_grade_entity.dart';
import '../repositories/grades_repository.dart';

/// Eğitmenin öğrenci notu girmesi / güncellemesi / silmesi.
///
/// Kural 4: Başarı notu ve harf notu istemciden gelen değere güvenilmeden
/// burada yeniden hesaplanır: (Vize * 0.40) + (Final * 0.60) + Bonus, en fazla 100.
class ManageStudentGradeUseCase {
  const ManageStudentGradeUseCase(this._repository);

  final GradesRepository _repository;

  Future<CourseGradeEntity> save({
    required UserEntity actor,
    required UserEntity student,
    required String courseCode,
    required String courseName,
    required int credit,
    String? courseId,
    String term = CourseGradeEntity.currentTerm,
    required double midterm,
    required double finalExam,
    double bonus = 0,
  }) async {
    RoleGuard.requireInstructor(actor.role);
    if (!student.isStudent) throw const ValidationFailure('Not yalnızca öğrencilere girilebilir.');
    for (final score in [midterm, finalExam]) {
      if (!GradeCalculator.isValidScore(score)) throw const ValidationFailure(AppStrings.scoreRangeError);
    }
    if (bonus < 0 || bonus > 100) throw const ValidationFailure(AppStrings.scoreRangeError);

    final total = GradeCalculator.calculateTotal(midterm: midterm, finalExam: finalExam, bonus: bonus);
    final existing = _repository
        .getGrades()
        .where((g) => g.studentUid == student.uid && g.courseCode == courseCode && g.term == term)
        .firstOrNull;

    final grade = CourseGradeEntity(
      id: existing?.id ?? CourseGradeEntity.buildId(student.uid, courseCode, term),
      studentUid: student.uid,
      studentName: student.fullName,
      studentNo: student.schoolNo,
      courseId: courseId,
      courseCode: courseCode,
      courseName: courseName,
      credit: credit,
      term: term,
      midterm: midterm,
      finalExam: finalExam,
      bonus: bonus,
      total: total,
      letterGrade: GradeCalculator.letterFor(total),
      updatedAt: DateTime.now(),
    );
    await _repository.saveGrade(grade);
    return grade;
  }

  Future<void> delete({required UserEntity actor, required String gradeId}) {
    RoleGuard.requireInstructor(actor.role);
    return _repository.deleteGrade(gradeId);
  }
}
