import 'package:equatable/equatable.dart';

class CourseScheduleEntity extends Equatable {
  final String courseId;
  final String courseCode;
  final String courseName;
  final String instructorName;
  final String roomLocation;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  const CourseScheduleEntity({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.instructorName,
    required this.roomLocation,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [
        courseId,
        courseCode,
        courseName,
        instructorName,
        roomLocation,
        dayOfWeek,
        startTime,
        endTime,
      ];
}