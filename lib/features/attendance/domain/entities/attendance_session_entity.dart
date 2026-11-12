import 'package:equatable/equatable.dart';
import '../../../../core/enums/attendance_status.dart';

class AttendanceSessionEntity extends Equatable {
  final String sessionId;
  final String courseId;
  final String qrCodeToken;
  final String pinCode;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final Map<String, AttendanceStatus> studentStatusMap;

  const AttendanceSessionEntity({
    required this.sessionId,
    required this.courseId,
    required this.qrCodeToken,
    required this.pinCode,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.studentStatusMap,
  });

  @override
  List<Object?> get props => [
        sessionId,
        courseId,
        qrCodeToken,
        pinCode,
        createdAt,
        expiresAt,
        isActive,
        studentStatusMap,
      ];
}