import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/enums/view_status.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/course_schedule_entity.dart';
import '../../domain/usecases/add_or_remove_course_usecase.dart';
import '../../domain/usecases/update_course_details_usecase.dart';
import '../../domain/usecases/watch_weekly_schedule_usecase.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit({required this._watchSchedule, required this._addOrRemoveCourse, required this._updateCourse})
    : super(ScheduleState(selectedDay: _defaultDay())) {
    start();
  }

  final WatchWeeklyScheduleUseCase _watchSchedule;
  final AddOrRemoveCourseUseCase _addOrRemoveCourse;
  final UpdateCourseDetailsUseCase _updateCourse;
  StreamSubscription<List<CourseScheduleEntity>>? _sub;

  /// Hafta içi ise bugün, hafta sonu ise Pazartesi.
  static int _defaultDay() {
    final today = DateTime.now().weekday;
    return today <= 5 ? today : 1;
  }

  void start() {
    emit(state.copyWith(status: ViewStatus.loading));
    _sub?.cancel();
    _sub = _watchSchedule().listen(
      (courses) => emit(state.copyWith(status: ViewStatus.loaded, courses: courses)),
      onError: (Object e) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: Failure.from(e).message)),
    );
  }

  void selectDay(int day) => emit(state.copyWith(selectedDay: day));

  /// Ekleme veya güncelleme. Hata durumunda [Failure] fırlatır (modal gösterir).
  Future<void> saveCourse({required UserRole actorRole, required CourseScheduleEntity course}) async {
    if (course.id.isEmpty) {
      await _addOrRemoveCourse.add(actorRole: actorRole, course: course);
    } else {
      await _updateCourse(actorRole: actorRole, course: course);
    }
    if (course.dayOfWeek <= 5) selectDay(course.dayOfWeek);
  }

  Future<void> deleteCourse({required UserRole actorRole, required String courseId}) =>
      _addOrRemoveCourse.remove(actorRole: actorRole, courseId: courseId);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
