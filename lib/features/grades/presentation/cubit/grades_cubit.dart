import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/letter_grade.dart';
import '../../../../core/enums/view_status.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../../schedule/domain/usecases/watch_weekly_schedule_usecase.dart';
import '../../domain/entities/course_grade_entity.dart';
import '../../domain/usecases/calculate_gpa_simulation_usecase.dart';
import '../../domain/usecases/manage_student_grade_usecase.dart';
import '../../domain/usecases/watch_student_grades_usecase.dart';
import 'grades_state.dart';

/// Öğrencinin gerçek notlarını ve GPA simülatöründeki deneme hesaplamalarını;
/// eğitmenin ise öğrenci seçimi + not CRUD işlemlerini yönetir.
class GradesCubit extends Cubit<GradesState> {
  GradesCubit({
    required this.watchStudentGradesUseCase,
    required this.manageStudentGradeUseCase,
    required this.calculateGpaSimulationUseCase,
    required this.watchWeeklyScheduleUseCase,
  }) : super(const GradesState());

  final WatchStudentGradesUseCase watchStudentGradesUseCase;
  final ManageStudentGradeUseCase manageStudentGradeUseCase;
  final CalculateGpaSimulationUseCase calculateGpaSimulationUseCase;
  final WatchWeeklyScheduleUseCase watchWeeklyScheduleUseCase;

  /// Program kartlarında kredi bilgisi yok; yeni not kaydında varsayılan kredi.
  static const int defaultCredit = 3;

  StreamSubscription<dynamic>? _gradesSub;
  StreamSubscription<dynamic>? _scheduleSub;

  // ---------------------------------------------------------------- Öğrenci

  void loadForStudent(String studentUid) {
    emit(state.copyWith(status: ViewStatus.loading));
    _gradesSub?.cancel();
    _gradesSub = watchStudentGradesUseCase(studentUid).listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (grades) => _emitGrades(grades),
      );
    });
  }

  void _emitGrades(List<CourseGradeEntity> grades) {
    emit(state.copyWith(
      status: ViewStatus.loaded,
      grades: grades,
      gpa: calculateGpaSimulationUseCase(grades),
      simulatedGpa: calculateGpaSimulationUseCase(grades, overrides: state.overrides),
      totalCredits: calculateGpaSimulationUseCase.totalCredits(grades),
    ));
  }

  /// GPA simülatörü: "bu dersten [letter] alırsam ortalamam ne olur?"
  void simulate(String courseId, LetterGrade letter) {
    final overrides = <String, LetterGrade>{...state.overrides, courseId: letter};
    emit(state.copyWith(
      overrides: overrides,
      simulatedGpa: calculateGpaSimulationUseCase(state.grades, overrides: overrides),
    ));
  }

  void resetSimulation() => emit(state.copyWith(overrides: const {}, simulatedGpa: state.gpa));

  // ---------------------------------------------------------------- Eğitmen

  Future<void> loadForInstructor() async {
    emit(state.copyWith(status: ViewStatus.loading));
    _scheduleSub?.cancel();
    _scheduleSub = watchWeeklyScheduleUseCase().listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (all) {
          final seen = <String>{};
          final courses = <CourseScheduleEntity>[for (final c in all) if (seen.add(c.courseId)) c];
          emit(state.copyWith(courses: courses, status: courses.isEmpty ? ViewStatus.loaded : null));
          final selected = state.selectedCourseId;
          if (courses.isNotEmpty && (selected == null || courses.every((c) => c.courseId != selected))) {
            selectCourse(courses.first.courseId);
          }
        },
      );
    });
    final students = await manageStudentGradeUseCase.registeredStudents();
    if (isClosed) return;
    students.fold(
      (failure) => emit(state.copyWith(actionMessage: failure.message)),
      (list) => emit(state.copyWith(students: list)),
    );
  }

  void selectCourse(String courseId) {
    emit(state.copyWith(selectedCourseId: courseId, status: ViewStatus.loading));
    _gradesSub?.cancel();
    _gradesSub = watchStudentGradesUseCase.course(courseId).listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (grades) => emit(state.copyWith(status: ViewStatus.loaded, grades: grades)),
      );
    });
  }

  /// Kural 4: (Vize*0.40)+(Final*0.60)+Bonus → max 100 → harf notu.
  Future<bool> saveGrade({
    required RegisteredStudent student,
    required double midterm,
    required double finalScore,
    required double bonus,
  }) async {
    final course = state.selectedCourse;
    if (course == null) return false;
    int credit = defaultCredit;
    for (final g in state.grades) {
      if (g.studentUid == student.uid) credit = g.credit;
    }
    final result = await manageStudentGradeUseCase.save(
      courseId: course.courseId,
      courseName: course.courseName,
      credit: credit,
      student: student,
      midterm: midterm,
      finalScore: finalScore,
      bonus: bonus,
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(actionMessage: failure.message));
        return false;
      },
      (grade) {
        emit(state.copyWith(actionMessage: '${grade.studentName}: ${grade.letterGrade?.name} kaydedildi.'));
        return true;
      },
    );
  }

  Future<void> deleteGrade(CourseGradeEntity grade) async {
    final result = await manageStudentGradeUseCase.delete(gradeId: grade.gradeId, courseId: grade.courseId);
    emit(state.copyWith(actionMessage: result.fold((f) => f.message, (_) => 'Not silindi.')));
  }

  @override
  Future<void> close() {
    _gradesSub?.cancel();
    _scheduleSub?.cancel();
    return super.close();
  }
}
