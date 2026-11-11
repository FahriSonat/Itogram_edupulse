import 'package:equatable/equatable.dart';

import '../../../../core/enums/attendance_status.dart';

/// Canlı yoklama oturumunda tek bir öğrencinin durumu.
class AttendanceMark extends Equatable {
  final String studentUid;
  final String studentName;
  final String studentNo;
  final AttendanceStatus status;

  /// PIN/QR ile katıldığı veya eğitmenin durumu değiştirdiği an.
  final DateTime? recordedAt;

  const AttendanceMark({
    required this.studentUid,
    required this.studentName,
    required this.studentNo,
    this.status = AttendanceStatus.absent,
    this.recordedAt,
  });

  AttendanceMark copyWith({AttendanceStatus? status, DateTime? recordedAt}) => AttendanceMark(
    studentUid: studentUid,
    studentName: studentName,
    studentNo: studentNo,
    status: status ?? this.status,
    recordedAt: recordedAt ?? this.recordedAt,
  );

  @override
  List<Object?> get props => [studentUid, studentName, studentNo, status, recordedAt];
}

/// [AttendanceSessionEntity] eğitmenin başlattığı canlı yoklama oturumu.
///
/// Kural 1 (60 Sn Yoklama Kalkanı): [pinCode] ve [qrToken] yalnızca
/// [pinExpiresAt] anına kadar geçerlidir; süre dolunca eğitmen panosu yeni
/// kod üretir ve eski kod reddedilir.
class AttendanceSessionEntity extends Equatable {
  final String id;
  final String courseId;
  final String courseCode;
  final String courseName;
  final String instructorUid;
  final String instructorName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String pinCode;
  final String qrToken;
  final DateTime pinExpiresAt;

  /// Oturumun devamsızlığa yansıyan ders saati (ör. 90 dk = 2 saat).
  final int sessionHours;
  final bool isActive;
  final List<AttendanceMark> marks;

  const AttendanceSessionEntity({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.instructorUid,
    required this.instructorName,
    required this.startedAt,
    this.endedAt,
    required this.pinCode,
    required this.qrToken,
    required this.pinExpiresAt,
    this.sessionHours = 2,
    this.isActive = true,
    this.marks = const [],
  });

  /// PIN'in kalan geçerlilik süresi (0–60 sn).
  int remainingSeconds([DateTime? now]) {
    final diff = pinExpiresAt.difference(now ?? DateTime.now()).inMilliseconds;
    return (diff / 1000).ceil().clamp(0, 60);
  }

  bool isPinExpired([DateTime? now]) => !(now ?? DateTime.now()).isBefore(pinExpiresAt);

  /// Girilen PIN veya okutulan QR bu oturumun güncel kodu mu?
  bool matchesCode(String code) {
    final c = code.trim();
    return c.isNotEmpty && (c == pinCode || c == qrToken);
  }

  int countOf(AttendanceStatus status) => marks.where((m) => m.status == status).length;

  AttendanceMark? markFor(String studentUid) {
    for (final m in marks) {
      if (m.studentUid == studentUid) return m;
    }
    return null;
  }

  AttendanceSessionEntity copyWith({
    DateTime? endedAt,
    String? pinCode,
    String? qrToken,
    DateTime? pinExpiresAt,
    bool? isActive,
    List<AttendanceMark>? marks,
  }) => AttendanceSessionEntity(
    id: id,
    courseId: courseId,
    courseCode: courseCode,
    courseName: courseName,
    instructorUid: instructorUid,
    instructorName: instructorName,
    startedAt: startedAt,
    endedAt: endedAt ?? this.endedAt,
    pinCode: pinCode ?? this.pinCode,
    qrToken: qrToken ?? this.qrToken,
    pinExpiresAt: pinExpiresAt ?? this.pinExpiresAt,
    sessionHours: sessionHours,
    isActive: isActive ?? this.isActive,
    marks: marks ?? this.marks,
  );

  @override
  List<Object?> get props => [
    id,
    courseId,
    courseCode,
    courseName,
    instructorUid,
    instructorName,
    startedAt,
    endedAt,
    pinCode,
    qrToken,
    pinExpiresAt,
    sessionHours,
    isActive,
    marks,
  ];
}
