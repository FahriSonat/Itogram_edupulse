import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/course_grade_entity.dart';
import '../../domain/usecases/manage_student_grade_usecase.dart';
import '../../domain/usecases/watch_student_grades_usecase.dart';
import 'grades_state.dart';

class GradesCubit extends Cubit<GradesState> {
  GradesCubit({required this._watchGrades, required this._manageGrade, required this._authRepository})
    : super(const GradesState()) {
    start();
  }

  final WatchStudentGradesUseCase _watchGrades;
  final ManageStudentGradeUseCase _manageGrade;
  final AuthRepository _authRepository;
  StreamSubscription<List<CourseGradeEntity>>? _sub;

  void start() {
    emit(state.copyWith(status: ViewStatus.loading));
    _sub?.cancel();
    _sub = _watchGrades().listen(
      (grades) => emit(state.copyWith(status: ViewStatus.loaded, grades: grades)),
      onError: (Object e) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: Failure.from(e).message)),
    );
  }

  Future<List<UserEntity>> loadStudents() => _authRepository.getStudents();

  /// Öğrenciyi ad veya numarayla bulur (not giriş modalındaki serbest metin için).
  Future<UserEntity> resolveStudent(String nameOrNo) async {
    final query = nameOrNo.trim().toLowerCase();
    final students = await _authRepository.getStudents();
    final match = students.where((s) => s.fullName.toLowerCase() == query || s.schoolNo == query).firstOrNull;
    if (match == null) {
      throw ValidationFailure('"$nameOrNo" adında / numarasında kayıtlı öğrenci bulunamadı.');
    }
    return match;
  }

  Future<void> saveGrade({
    required UserEntity actor,
    required UserEntity student,
    required String courseCode,
    required String courseName,
    required int credit,
    String? courseId,
    required double midterm,
    required double finalExam,
    required double bonus,
  }) => _manageGrade.save(
    actor: actor,
    student: student,
    courseCode: courseCode,
    courseName: courseName,
    credit: credit,
    courseId: courseId,
    midterm: midterm,
    finalExam: finalExam,
    bonus: bonus,
  );

  Future<void> deleteGrade({required UserEntity actor, required String gradeId}) =>
      _manageGrade.delete(actor: actor, gradeId: gradeId);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
