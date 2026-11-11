import 'package:equatable/equatable.dart';

import '../../../../core/enums/view_status.dart';
import '../../../../core/utils/grade_calculator.dart';
import '../../domain/entities/course_grade_entity.dart';
import '../../domain/usecases/calculate_gpa_simulation_usecase.dart';

/// Bir dersin sınıf istatistikleri (çan eğrisi için).
typedef ClassStats = ({double mean, double standardDeviation, int count, double passRate});

class GradesState extends Equatable {
  final ViewStatus status;
  final List<CourseGradeEntity> grades;
  final String? errorMessage;

  const GradesState({this.status = ViewStatus.initial, this.grades = const [], this.errorMessage});

  static const CalculateGpaSimulationUseCase _gpa = CalculateGpaSimulationUseCase();

  List<CourseGradeEntity> gradesFor(String studentUid) => grades.where((g) => g.studentUid == studentUid).toList();

  List<CourseGradeEntity> currentTermGradesFor(String studentUid) =>
      gradesFor(studentUid).where((g) => g.isCurrentTerm).toList();

  GpaSummary gpaFor(String studentUid) => _gpa(gradesFor(studentUid));

  /// Dersteki (bu dönem) tüm öğrenci notları.
  List<CourseGradeEntity> courseGrades(String courseCode) {
    final list = grades.where((g) => g.courseCode == courseCode && g.isCurrentTerm).toList();
    list.sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  ClassStats statsFor(String courseCode) {
    final totals = courseGrades(courseCode).map((g) => g.total).toList();
    final passing = courseGrades(courseCode).where((g) => g.letterGrade.isPassing).length;
    return (
      mean: GradeCalculator.mean(totals),
      standardDeviation: GradeCalculator.standardDeviation(totals),
      count: totals.length,
      passRate: totals.isEmpty ? 0 : passing / totals.length * 100,
    );
  }

  /// Eğitmen paneli "Sınıf Analizi": bu dönemki tüm notlarda geçme oranı (%).
  double get overallPassRate {
    final current = grades.where((g) => g.isCurrentTerm).toList();
    if (current.isEmpty) return 0;
    return current.where((g) => g.letterGrade.isPassing).length / current.length * 100;
  }

  GradesState copyWith({ViewStatus? status, List<CourseGradeEntity>? grades, String? errorMessage}) =>
      GradesState(status: status ?? this.status, grades: grades ?? this.grades, errorMessage: errorMessage);

  @override
  List<Object?> get props => [status, grades, errorMessage];
}
