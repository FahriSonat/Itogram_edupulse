import '../../domain/entities/course_schedule_entity.dart';

class CourseScheduleModel extends CourseScheduleEntity {
  const CourseScheduleModel({
    required super.id,
    required super.courseCode,
    required super.courseName,
    super.instructorUid,
    required super.instructorName,
    required super.roomLocation,
    required super.dayOfWeek,
    required super.startTime,
    required super.endTime,
    super.credit,
    super.totalHours,
  });

  factory CourseScheduleModel.fromEntity(CourseScheduleEntity e) => CourseScheduleModel(
    id: e.id,
    courseCode: e.courseCode,
    courseName: e.courseName,
    instructorUid: e.instructorUid,
    instructorName: e.instructorName,
    roomLocation: e.roomLocation,
    dayOfWeek: e.dayOfWeek,
    startTime: e.startTime,
    endTime: e.endTime,
    credit: e.credit,
    totalHours: e.totalHours,
  );

  factory CourseScheduleModel.fromJson(Map<String, dynamic> json) => CourseScheduleModel(
    id: json['id'] as String,
    courseCode: json['courseCode'] as String? ?? '',
    courseName: json['courseName'] as String? ?? '',
    instructorUid: json['instructorUid'] as String? ?? '',
    instructorName: json['instructorName'] as String? ?? '',
    roomLocation: json['roomLocation'] as String? ?? '',
    dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
    startTime: json['startTime'] as String? ?? '09:00',
    endTime: json['endTime'] as String? ?? '10:00',
    credit: (json['credit'] as num?)?.toInt() ?? 4,
    totalHours: (json['totalHours'] as num?)?.toInt() ?? 40,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseCode': courseCode,
    'courseName': courseName,
    'instructorUid': instructorUid,
    'instructorName': instructorName,
    'roomLocation': roomLocation,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'credit': credit,
    'totalHours': totalHours,
  };
}
