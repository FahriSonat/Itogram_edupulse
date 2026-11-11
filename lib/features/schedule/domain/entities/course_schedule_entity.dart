import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_time_helper.dart';

/// [CourseScheduleEntity] haftalık ders programındaki tek bir ders oturumu.
class CourseScheduleEntity extends Equatable {
  final String id;
  final String courseCode;
  final String courseName;
  final String instructorUid;
  final String instructorName;
  final String roomLocation;

  /// 1 = Pazartesi … 7 = Pazar
  final int dayOfWeek;

  /// "10:30"
  final String startTime;
  final String endTime;
  final int credit;

  /// Dönem boyunca toplam ders saati (devamsızlık oranı hesabı için).
  final int totalHours;

  const CourseScheduleEntity({
    required this.id,
    required this.courseCode,
    required this.courseName,
    this.instructorUid = '',
    required this.instructorName,
    required this.roomLocation,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.credit = 4,
    this.totalHours = 40,
  });

  int get startMinutes => DateTimeHelper.minutesOf(startTime);
  int get endMinutes => DateTimeHelper.minutesOf(endTime);

  /// Bir sonraki başlangıç anı (haftalık tekrar).
  DateTime nextStart([DateTime? now]) =>
      DateTimeHelper.nextOccurrence(dayOfWeek: dayOfWeek, startTime: startTime, now: now);

  /// Ders şu anda işleniyor mu?
  bool isOngoing([DateTime? now]) {
    final ref = now ?? DateTime.now();
    if (ref.weekday != dayOfWeek) return false;
    final minutes = ref.hour * 60 + ref.minute;
    return minutes >= startMinutes && minutes < endMinutes;
  }

  String get timeRange => '$startTime - $endTime';

  CourseScheduleEntity copyWith({
    String? id,
    String? courseCode,
    String? courseName,
    String? instructorUid,
    String? instructorName,
    String? roomLocation,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? credit,
    int? totalHours,
  }) => CourseScheduleEntity(
    id: id ?? this.id,
    courseCode: courseCode ?? this.courseCode,
    courseName: courseName ?? this.courseName,
    instructorUid: instructorUid ?? this.instructorUid,
    instructorName: instructorName ?? this.instructorName,
    roomLocation: roomLocation ?? this.roomLocation,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    credit: credit ?? this.credit,
    totalHours: totalHours ?? this.totalHours,
  );

  @override
  List<Object?> get props => [
    id,
    courseCode,
    courseName,
    instructorUid,
    instructorName,
    roomLocation,
    dayOfWeek,
    startTime,
    endTime,
    credit,
    totalHours,
  ];
}
