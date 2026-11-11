import 'package:equatable/equatable.dart';

import '../../../../core/enums/view_status.dart';
import '../../domain/entities/course_schedule_entity.dart';

class ScheduleState extends Equatable {
  final ViewStatus status;
  final List<CourseScheduleEntity> courses;

  /// 1 = Pazartesi … 7 = Pazar
  final int selectedDay;
  final String? errorMessage;

  const ScheduleState({
    this.status = ViewStatus.initial,
    this.courses = const [],
    required this.selectedDay,
    this.errorMessage,
  });

  List<CourseScheduleEntity> coursesForDay(int day) => courses.where((c) => c.dayOfWeek == day).toList();

  List<CourseScheduleEntity> get selectedDayCourses => coursesForDay(selectedDay);

  List<CourseScheduleEntity> todaysCourses([DateTime? now]) => coursesForDay((now ?? DateTime.now()).weekday);

  /// Haftanın şu andan sonraki ilk dersi (devam eden ders dahil değil).
  CourseScheduleEntity? nextCourse([DateTime? now]) {
    if (courses.isEmpty) return null;
    final ref = now ?? DateTime.now();
    final sorted = [...courses]..sort((a, b) => a.nextStart(ref).compareTo(b.nextStart(ref)));
    return sorted.first;
  }

  /// Şu anda işlenen ders (yoklama için önerilir).
  CourseScheduleEntity? ongoingCourse([DateTime? now]) {
    for (final c in courses) {
      if (c.isOngoing(now)) return c;
    }
    return null;
  }

  /// Ders koduna göre tekilleştirilmiş dersler (ör. teori + lab tek ders).
  List<CourseScheduleEntity> get uniqueCourses {
    final seen = <String>{};
    return [
      for (final c in courses)
        if (seen.add(c.courseCode)) c,
    ];
  }

  List<String> get courseNames => uniqueCourses.map((c) => c.courseName).toList();

  ScheduleState copyWith({
    ViewStatus? status,
    List<CourseScheduleEntity>? courses,
    int? selectedDay,
    String? errorMessage,
  }) => ScheduleState(
    status: status ?? this.status,
    courses: courses ?? this.courses,
    selectedDay: selectedDay ?? this.selectedDay,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, courses, selectedDay, errorMessage];
}
