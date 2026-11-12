import 'package:equatable/equatable.dart';

import '../../../../core/enums/attendance_status.dart';
import '../../domain/entities/attendance_session_entity.dart';

enum LiveAttendanceStatus {
  /// Eğitmen henüz yoklama başlatmadı / öğrenci kod girmedi.
  idle,
  starting,

  /// Eğitmen: QR/PIN yayında.
  active,

  /// Öğrenci: kod gönderiliyor.
  submitting,

  /// Öğrenci: yoklama başarıyla alındı.
  submitted,
  failure,
}

typedef RosterStudent = ({String name, String studentNo});

class LiveAttendanceState extends Equatable {
  const LiveAttendanceState({
    this.status = LiveAttendanceStatus.idle,
    this.courseId,
    this.session,
    this.remainingSeconds = 0,
    this.statuses = const <String, AttendanceStatus>{},
    this.students = const <String, RosterStudent>{},
    this.message,
    this.isCodeExpired = false,
  });

  final LiveAttendanceStatus status;
  final String? courseId;
  final AttendanceSessionEntity? session;

  /// Aktif QR/PIN'in kalan saniyesi (60 → 0).
  final int remainingSeconds;

  /// Ders boyunca biriken durumlar: kod yenilense de "Geldi" kaybolmaz.
  final Map<String, AttendanceStatus> statuses;

  /// uid → ad / numara (sınıf devamsızlık kayıtlarından).
  final Map<String, RosterStudent> students;

  final String? message;

  /// Öğrencinin girdiği kodun 60 saniyesi dolmuştu (Kural 1).
  final bool isCodeExpired;

  int countOf(AttendanceStatus s) => statuses.values.where((v) => v == s).length;

  LiveAttendanceState copyWith({
    LiveAttendanceStatus? status,
    String? courseId,
    AttendanceSessionEntity? session,
    int? remainingSeconds,
    Map<String, AttendanceStatus>? statuses,
    Map<String, RosterStudent>? students,
    String? message,
    bool? isCodeExpired,
  }) {
    return LiveAttendanceState(
      status: status ?? this.status,
      courseId: courseId ?? this.courseId,
      session: session ?? this.session,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      statuses: statuses ?? this.statuses,
      students: students ?? this.students,
      message: message,
      isCodeExpired: isCodeExpired ?? false,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[status, courseId, session, remainingSeconds, statuses, students, message, isCodeExpired];
}
