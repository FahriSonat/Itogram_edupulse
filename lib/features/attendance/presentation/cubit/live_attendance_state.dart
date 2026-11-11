import 'package:equatable/equatable.dart';

import '../../../../core/enums/attendance_status.dart';
import '../../../../core/enums/view_status.dart';
import '../../domain/entities/attendance_session_entity.dart';

class LiveAttendanceState extends Equatable {
  final ViewStatus status;
  final List<AttendanceSessionEntity> sessions;

  /// Başlatma / bitirme gibi uzun süren bir işlem sürüyor.
  final bool isBusy;
  final String? errorMessage;

  const LiveAttendanceState({
    this.status = ViewStatus.initial,
    this.sessions = const [],
    this.isBusy = false,
    this.errorMessage,
  });

  List<AttendanceSessionEntity> get activeSessions => sessions.where((s) => s.isActive).toList();

  AttendanceSessionEntity? activeSessionFor(String instructorUid) {
    for (final s in sessions) {
      if (s.isActive && s.instructorUid == instructorUid) return s;
    }
    return null;
  }

  /// Eğitmenin kapattığı son oturumlar.
  List<AttendanceSessionEntity> pastSessionsBy(String instructorUid) =>
      sessions.where((s) => !s.isActive && s.instructorUid == instructorUid).take(5).toList();

  /// Öğrencinin "Gelen" olarak kaydedildiği oturumlar (en yeni üstte).
  List<AttendanceSessionEntity> attendedBy(String studentUid) =>
      sessions.where((s) => s.markFor(studentUid)?.status == AttendanceStatus.present).take(5).toList();

  LiveAttendanceState copyWith({
    ViewStatus? status,
    List<AttendanceSessionEntity>? sessions,
    bool? isBusy,
    String? errorMessage,
  }) => LiveAttendanceState(
    status: status ?? this.status,
    sessions: sessions ?? this.sessions,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, sessions, isBusy, errorMessage];
}
