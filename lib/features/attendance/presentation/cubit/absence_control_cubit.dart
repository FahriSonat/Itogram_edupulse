import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/attendance_status.dart';
import '../../../../core/enums/view_status.dart';
import '../../../grades/domain/entities/course_grade_entity.dart';
import '../../../grades/domain/usecases/watch_student_grades_usecase.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../../schedule/domain/usecases/watch_weekly_schedule_usecase.dart';
import '../../domain/entities/student_absence_record_entity.dart';
import '../../domain/usecases/evaluate_absence_risk_usecase.dart';
import '../../domain/usecases/manage_attendance_record_usecase.dart';
import 'absence_control_state.dart';

/// Öğrenci için ders bazlı devamsızlık saat/yüzde verilerini; eğitmen için
/// %20 sınırını aşan kırmızı listeyi ve sınıf çan eğrisi verilerini yönetir.
class AbsenceControlCubit extends Cubit<AbsenceControlState> {
  AbsenceControlCubit({
    required this.watchWeeklyScheduleUseCase,
    required this.evaluateAbsenceRiskUseCase,
    required this.manageAttendanceRecordUseCase,
    required this.watchStudentGradesUseCase,
  }) : super(const AbsenceControlState());

  final WatchWeeklyScheduleUseCase watchWeeklyScheduleUseCase;
  final EvaluateAbsenceRiskUseCase evaluateAbsenceRiskUseCase;
  final ManageAttendanceRecordUseCase manageAttendanceRecordUseCase;
  final WatchStudentGradesUseCase watchStudentGradesUseCase;

  StreamSubscription<dynamic>? _scheduleSub;
  StreamSubscription<dynamic>? _recordsSub;
  StreamSubscription<dynamic>? _gradesSub;

  /// Aynı ders farklı günlerde tekrar edebilir; ders bazında tekilleştirir.
  static List<CourseScheduleEntity> _uniqueCourses(List<CourseScheduleEntity> all) {
    final seen = <String>{};
    return <CourseScheduleEntity>[for (final c in all) if (seen.add(c.courseId)) c];
  }

  // ---------------------------------------------------------------- Öğrenci

  void loadForStudent(String studentUid) {
    emit(state.copyWith(status: ViewStatus.loading));
    _scheduleSub?.cancel();
    _scheduleSub = watchWeeklyScheduleUseCase().listen((result) async {
      await result.fold(
        (failure) async => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (all) async {
          final courses = _uniqueCourses(all);
          final results = await Future.wait(
            courses.map((c) => evaluateAbsenceRiskUseCase.studentRecord(c.courseId, studentUid)),
          );
          if (isClosed) return;
          final records = <StudentAbsenceRecordEntity>[
            for (final r in results) ...r.fold((_) => const <StudentAbsenceRecordEntity>[], (rec) => [rec]),
          ];
          emit(state.copyWith(status: ViewStatus.loaded, courses: courses, records: records));
        },
      );
    });
  }

  // ---------------------------------------------------------------- Eğitmen

  void loadForInstructor() {
    emit(state.copyWith(status: ViewStatus.loading));
    _scheduleSub?.cancel();
    _scheduleSub = watchWeeklyScheduleUseCase().listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (all) {
          final courses = _uniqueCourses(all);
          emit(state.copyWith(courses: courses, status: courses.isEmpty ? ViewStatus.loaded : null));
          final selected = state.selectedCourseId;
          if (courses.isNotEmpty && (selected == null || courses.every((c) => c.courseId != selected))) {
            selectCourse(courses.first.courseId);
          }
        },
      );
    });
  }

  void selectCourse(String courseId) {
    emit(state.copyWith(selectedCourseId: courseId, status: ViewStatus.loading));
    _recordsSub?.cancel();
    _recordsSub = manageAttendanceRecordUseCase.watchClass(courseId).listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (records) => emit(state.copyWith(status: ViewStatus.loaded, records: records)),
      );
    });
    _gradesSub?.cancel();
    _gradesSub = watchStudentGradesUseCase.course(courseId).listen((result) {
      result.fold((_) {}, (grades) => emit(state.copyWith(distribution: distributionOf(grades))));
    });
  }

  /// Eğitmenin manuel yoklama eklemesi / değiştirmesi; ardından %20 riski
  /// yeniden hesaplanır (aşım varsa repository FCM push gönderir).
  Future<void> markAttendance(String studentUid, AttendanceStatus status) async {
    final courseId = state.selectedCourseId;
    if (courseId == null) return;
    final result = await manageAttendanceRecordUseCase(courseId: courseId, studentUid: studentUid, status: status);
    await result.fold(
      (failure) async => emit(state.copyWith(actionMessage: failure.message)),
      (_) async {
        await evaluateAbsenceRiskUseCase(courseId, studentUid);
        if (!isClosed) emit(state.copyWith(actionMessage: 'Yoklama kaydı güncellendi.'));
      },
    );
  }

  /// Kritik risk listesindeki öğrenciye uyarı push bildirimini yeniden tetikler.
  Future<void> sendRiskWarning(String studentUid) async {
    final courseId = state.selectedCourseId;
    if (courseId == null) return;
    final result = await evaluateAbsenceRiskUseCase(courseId, studentUid);
    emit(state.copyWith(
      actionMessage: result.fold((f) => f.message, (_) => 'Kritik devamsızlık uyarısı gönderildi.'),
    ));
  }

  /// Vize / Final ortalaması ve standart sapması (çan eğrisi).
  static GradeDistribution distributionOf(List<CourseGradeEntity> grades) {
    final mids = <double>[for (final g in grades) if (g.midtermScore != null) g.midtermScore!];
    final fins = <double>[for (final g in grades) if (g.finalScore != null) g.finalScore!];
    double mean(List<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
    double std(List<double> v) {
      if (v.length < 2) return 0;
      final m = mean(v);
      return math.sqrt(v.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / v.length);
    }

    return GradeDistribution(
      midtermAverage: mean(mids),
      finalAverage: mean(fins),
      midtermStd: std(mids),
      finalStd: std(fins),
      sampleSize: math.max(mids.length, fins.length),
    );
  }

  @override
  Future<void> close() {
    _scheduleSub?.cancel();
    _recordsSub?.cancel();
    _gradesSub?.cancel();
    return super.close();
  }
}
