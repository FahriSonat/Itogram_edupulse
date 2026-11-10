import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../../../core/enums/attendance_status.dart';

class AttendanceSessionModel extends AttendanceSessionEntity {
  const AttendanceSessionModel({
    required super.sessionId,
    required super.courseId,
    required super.qrCodeToken,
    required super.pinCode,
    required super.createdAt,
    required super.expiresAt,
    required super.isActive,
    required super.studentStatusMap,
  });

  factory AttendanceSessionModel.fromFirestore(Map<String, dynamic> json, String id) {
    final Map<String, dynamic> statusMapRaw = json['studentStatusMap'] as Map<String, dynamic>? ?? {};
    final Map<String, AttendanceStatus> parsedStatusMap = {};
    
    statusMapRaw.forEach((key, value) {
      parsedStatusMap[key] = AttendanceStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AttendanceStatus.absent,
      );
    });

    return AttendanceSessionModel(
      sessionId: id,
      courseId: json['courseId'] as String,
      qrCodeToken: json['qrCodeToken'] as String,
      pinCode: json['pinCode'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? false,
      studentStatusMap: parsedStatusMap,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, String> statusMapJson = {};
    studentStatusMap.forEach((key, value) {
      statusMapJson[key] = value.name;
    });

    return {
      'courseId': courseId,
      'qrCodeToken': qrCodeToken,
      'pinCode': pinCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'studentStatusMap': statusMapJson,
    };
  }

  AttendanceSessionModel copyWith({
    String? sessionId,
    String? courseId,
    String? qrCodeToken,
    String? pinCode,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    Map<String, AttendanceStatus>? studentStatusMap,
  }) {
    return AttendanceSessionModel(
      sessionId: sessionId ?? this.sessionId,
      courseId: courseId ?? this.courseId,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      pinCode: pinCode ?? this.pinCode,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      studentStatusMap: studentStatusMap ?? this.studentStatusMap,
    );
  }
}