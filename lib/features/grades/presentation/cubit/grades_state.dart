import 'package:equatable/equatable.dart';

import '../../../../core/enums/letter_grade.dart';
import '../../../../core/enums/view_status.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../domain/entities/course_grade_entity.dart';
import '../../domain/usecases/manage_student_grade_usecase.dart';

class GradesState extends Equatable {
  const GradesState({
    this.status = ViewStatus.initial,
    this.grades = const <CourseGradeEntity>[],
    this.gpa = 0,
    this.simulatedGpa = 0,
    this.totalCredits = 0,
    this.overrides = const <String, LetterGrade>{},
    this.courses = const <CourseScheduleEntity>[],
    this.selectedCourseId,
    this.students = const <RegisteredStudent>[],
    this.errorMessage,
    this.actionMessage,
  });

  final ViewStatus status;

  /// Öğrenci: kendi notları. Eğitmen: seçili dersteki tüm notlar.
  final List<CourseGradeEntity> grades;

  /// Gerçek notlarla 4.00 üzerinden GPA.
  final double gpa;

  /// Simülatördeki varsayımsal notlarla GPA (simülasyon yoksa = [gpa]).
  final double simulatedGpa;
  final int totalCredits;

  /// courseId → varsayımsal harf notu.
  final Map<String, LetterGrade> overrides;

  final List<CourseScheduleEntity> courses;
  final String? selectedCourseId;
  final List<RegisteredStudent> students;
  final String? errorMessage;
  final String? actionMessage;

  bool get isSimulating => overrides.isNotEmpty;

  CourseScheduleEntity? get selectedCourse {
    for (final c in courses) {
      if (c.courseId == selectedCourseId) return c;
    }
    return null;
  }

  GradesState copyWith({
    ViewStatus? status,
    List<CourseGradeEntity>? grades,
    double? gpa,
    double? simulatedGpa,
    int? totalCredits,
    Map<String, LetterGrade>? overrides,
    List<CourseScheduleEntity>? courses,
    String? selectedCourseId,
    List<RegisteredStudent>? students,
    String? errorMessage,
    String? actionMessage,
  }) {
    return GradesState(
      status: status ?? this.status,
      grades: grades ?? this.grades,
      gpa: gpa ?? this.gpa,
      simulatedGpa: simulatedGpa ?? this.simulatedGpa,
      totalCredits: totalCredits ?? this.totalCredits,
      overrides: overrides ?? this.overrides,
      courses: courses ?? this.courses,
      selectedCourseId: selectedCourseId ?? this.selectedCourseId,
      students: students ?? this.students,
      errorMessage: errorMessage,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        grades,
        gpa,
        simulatedGpa,
        totalCredits,
        overrides,
        courses,
        selectedCourseId,
        students,
        errorMessage,
        actionMessage,
      ];
}
