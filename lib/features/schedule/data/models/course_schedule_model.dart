import '../../domain/entities/course_schedule_entity.dart';

class CourseScheduleModel extends CourseScheduleEntity {
  const CourseScheduleModel({
    required super.courseId,
    required super.courseCode,
    required super.courseName,
    required super.instructorName,
    required super.roomLocation,
    required super.dayOfWeek,
    required super.startTime,
    required super.endTime,
  });

  factory CourseScheduleModel.fromFirestore(Map<String, dynamic> json, String id) {
    return CourseScheduleModel(
      courseId: id,
      courseCode: (json['courseCode'] ?? '').toString(),
      courseName: (json['courseName'] ?? '').toString(),
      instructorName: (json['instructorName'] ?? '').toString(),
      roomLocation: (json['roomLocation'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'instructorName': instructorName,
      'roomLocation': roomLocation,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  CourseScheduleModel copyWith({
    String? courseId,
    String? courseCode,
    String? courseName,
    String? instructorName,
    String? roomLocation,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
  }) {
    return CourseScheduleModel(
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      instructorName: instructorName ?? this.instructorName,
      roomLocation: roomLocation ?? this.roomLocation,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}