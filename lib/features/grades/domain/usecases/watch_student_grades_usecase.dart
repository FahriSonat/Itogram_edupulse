import '../entities/course_grade_entity.dart';
import '../repositories/grades_repository.dart';

/// Not kayıtlarını dinler. [studentUid] verilirse yalnızca o öğrencinin notları gelir.
class WatchStudentGradesUseCase {
  const WatchStudentGradesUseCase(this._repository);

  final GradesRepository _repository;

  Stream<List<CourseGradeEntity>> call({String? studentUid}) => _repository.watchGrades().map((grades) {
    final list = studentUid == null ? grades : grades.where((g) => g.studentUid == studentUid).toList();
    list.sort((a, b) {
      final byTerm = b.term.compareTo(a.term);
      return byTerm != 0 ? byTerm : a.courseCode.compareTo(b.courseCode);
    });
    return list;
  });
}
