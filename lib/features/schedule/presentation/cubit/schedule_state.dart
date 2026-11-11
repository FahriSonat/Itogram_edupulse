import 'package:equatable/equatable.dart';

import '../../../../core/enums/view_status.dart';
import '../../domain/entities/course_schedule_entity.dart';

class ScheduleState extends Equatable {
  const ScheduleState({
    this.status = ViewStatus.initial,
    this.courses = const <CourseScheduleEntity>[],
    this.selectedDay = 1,
    this.errorMessage,
    this.actionMessage,
  });

  final ViewStatus status;
  final List<CourseScheduleEntity> courses;

  /// 1 = Pazartesi ... 7 = Pazar.
  final int selectedDay;

  /// Liste yüklenemediğinde (Error durumu).
  final String? errorMessage;

  /// Ekle / düzenle / sil sonrası tek seferlik bilgi (SnackBar).
  final String? actionMessage;

  /// Seçili günün dersleri, başlangıç saatine göre sıralı.
  List<CourseScheduleEntity> get coursesOfSelectedDay =>
      courses.where((c) => c.dayOfWeek == selectedDay).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

  ScheduleState copyWith({
    ViewStatus? status,
    List<CourseScheduleEntity>? courses,
    int? selectedDay,
    String? errorMessage,
    String? actionMessage,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      selectedDay: selectedDay ?? this.selectedDay,
      errorMessage: errorMessage,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, courses, selectedDay, errorMessage, actionMessage];
}
