import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/view_status.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../domain/entities/course_schedule_entity.dart';
import '../../domain/usecases/add_or_remove_course_usecase.dart';
import '../../domain/usecases/update_course_details_usecase.dart';
import '../../domain/usecases/watch_weekly_schedule_usecase.dart';
import 'schedule_state.dart';

/// Haftalık programı gün bazında gruplar, sıradaki derse kalan süreyi
/// hesaplar ve eğitmenin CRUD işlemlerini yönetir.
class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit({
    required this.watchWeeklyScheduleUseCase,
    required this.addOrRemoveCourseUseCase,
    required this.updateCourseDetailsUseCase,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(ScheduleState(selectedDay: _weekdayOf((clock ?? DateTime.now)())));

  final WatchWeeklyScheduleUseCase watchWeeklyScheduleUseCase;
  final AddOrRemoveCourseUseCase addOrRemoveCourseUseCase;
  final UpdateCourseDetailsUseCase updateCourseDetailsUseCase;
  final DateTime Function() _clock;

  StreamSubscription<dynamic>? _subscription;

  /// Hafta sonu ise programı Pazartesi'den başlat.
  static int _weekdayOf(DateTime d) => d.weekday > 5 ? 1 : d.weekday;

  void start() {
    emit(state.copyWith(status: ViewStatus.loading));
    _subscription?.cancel();
    _subscription = watchWeeklyScheduleUseCase().listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: failure.message)),
        (courses) => emit(state.copyWith(status: ViewStatus.loaded, courses: courses)),
      );
    });
  }

  void selectDay(int dayOfWeek) => emit(state.copyWith(selectedDay: dayOfWeek));

  /// "SS:DD" → bir sonraki haftalık başlangıç zamanı.
  DateTime nextStartOf(CourseScheduleEntity course) {
    final parts = course.startTime.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTimeHelper.nextLessonStart(dayOfWeek: course.dayOfWeek, hour: hour, minute: minute, now: _clock());
  }

  /// Tüm haftadaki en yakın ders (sayaç için). Ders yoksa null.
  CourseScheduleEntity? get nextCourse {
    CourseScheduleEntity? best;
    DateTime? bestTime;
    for (final c in state.courses) {
      final t = nextStartOf(c);
      if (bestTime == null || t.isBefore(bestTime)) {
        best = c;
        bestTime = t;
      }
    }
    return best;
  }

  /// [courseId] null ise yeni ders eklenir, değilse mevcut ders güncellenir.
  Future<bool> saveCourse({
    String? courseId,
    required String courseCode,
    required String courseName,
    required String instructorName,
    required String roomLocation,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final course = CourseScheduleEntity(
      courseId: courseId ?? '',
      courseCode: courseCode,
      courseName: courseName,
      instructorName: instructorName,
      roomLocation: roomLocation,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
    );
    final isNew = courseId == null || courseId.isEmpty;
    final result = isNew ? await addOrRemoveCourseUseCase.add(course) : await updateCourseDetailsUseCase(course);
    return result.fold(
      (failure) {
        emit(state.copyWith(actionMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(actionMessage: isNew ? 'Ders eklendi.' : 'Ders güncellendi.'));
        return true;
      },
    );
  }

  Future<void> removeCourse(String courseId) async {
    final result = await addOrRemoveCourseUseCase.remove(courseId);
    emit(state.copyWith(actionMessage: result.fold((f) => f.message, (_) => 'Ders programdan çıkarıldı.')));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
