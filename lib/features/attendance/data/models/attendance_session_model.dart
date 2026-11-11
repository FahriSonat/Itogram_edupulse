import '../../../../core/enums/attendance_status.dart';
import '../../domain/entities/attendance_session_entity.dart';

class AttendanceSessionModel extends AttendanceSessionEntity {
  const AttendanceSessionModel({
    required super.id,
    required super.courseId,
    required super.courseCode,
    required super.courseName,
    required super.instructorUid,
    required super.instructorName,
    required super.startedAt,
    super.endedAt,
    required super.pinCode,
    required super.qrToken,
    required super.pinExpiresAt,
    super.sessionHours,
    super.isActive,
    super.marks,
  });

  factory AttendanceSessionModel.fromEntity(AttendanceSessionEntity e) => AttendanceSessionModel(
    id: e.id,
    courseId: e.courseId,
    courseCode: e.courseCode,
    courseName: e.courseName,
    instructorUid: e.instructorUid,
    instructorName: e.instructorName,
    startedAt: e.startedAt,
    endedAt: e.endedAt,
    pinCode: e.pinCode,
    qrToken: e.qrToken,
    pinExpiresAt: e.pinExpiresAt,
    sessionHours: e.sessionHours,
    isActive: e.isActive,
    marks: e.marks,
  );

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) => AttendanceSessionModel(
    id: json['id'] as String,
    courseId: json['courseId'] as String? ?? '',
    courseCode: json['courseCode'] as String? ?? '',
    courseName: json['courseName'] as String? ?? '',
    instructorUid: json['instructorUid'] as String? ?? '',
    instructorName: json['instructorName'] as String? ?? '',
    startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
    endedAt: DateTime.tryParse(json['endedAt'] as String? ?? ''),
    pinCode: json['pinCode'] as String? ?? '',
    qrToken: json['qrToken'] as String? ?? '',
    pinExpiresAt: DateTime.tryParse(json['pinExpiresAt'] as String? ?? '') ?? DateTime.now(),
    sessionHours: (json['sessionHours'] as num?)?.toInt() ?? 2,
    isActive: json['isActive'] as bool? ?? false,
    marks: [
      for (final m in (json['marks'] as List<dynamic>? ?? const []))
        AttendanceMark(
          studentUid: (m as Map)['studentUid'] as String? ?? '',
          studentName: m['studentName'] as String? ?? '',
          studentNo: m['studentNo'] as String? ?? '',
          status: AttendanceStatus.fromJson(m['status'] as String?),
          recordedAt: DateTime.tryParse(m['recordedAt'] as String? ?? ''),
        ),
    ],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'courseCode': courseCode,
    'courseName': courseName,
    'instructorUid': instructorUid,
    'instructorName': instructorName,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'pinCode': pinCode,
    'qrToken': qrToken,
    'pinExpiresAt': pinExpiresAt.toIso8601String(),
    'sessionHours': sessionHours,
    'isActive': isActive,
    'marks': [
      for (final m in marks)
        {
          'studentUid': m.studentUid,
          'studentName': m.studentName,
          'studentNo': m.studentNo,
          'status': m.status.toJson(),
          'recordedAt': m.recordedAt?.toIso8601String(),
        },
    ],
  };
}
