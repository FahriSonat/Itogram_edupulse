import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/attendance_session_entity.dart';
import '../repositories/attendance_repository.dart';

/// Öğrencinin 4 haneli PIN (veya QR jetonu) ile canlı derse katılması.
///
/// Kural 1: Kod yalnızca üretildiği andan sonraki 60 saniye içinde kabul edilir.
class SubmitLiveAttendanceUseCase {
  SubmitLiveAttendanceUseCase(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AttendanceRepository _repository;
  final DateTime Function() _clock;

  static const String noActiveSessionError = 'Şu anda aktif bir yoklama oturumu bulunmuyor.';
  static const String wrongCodeError = 'PIN kodu hatalı. Lütfen eğitmenin ekranındaki güncel kodu giriniz.';
  static const String alreadyPresentError = 'Bu ders için yoklamanız zaten alındı.';

  /// Saf doğrulama: kod bu oturuma ait ve süresi dolmamış mı?
  /// Hata yoksa null, varsa kullanıcıya gösterilecek mesajı döndürür.
  static String? validateCode(AttendanceSessionEntity session, String code, DateTime now) {
    if (!session.isActive) return noActiveSessionError;
    if (!session.matchesCode(code)) return wrongCodeError;
    if (session.isPinExpired(now)) return AppStrings.qrExpiredError;
    return null;
  }

  Future<AttendanceSessionEntity> call({required UserEntity actor, required String code}) async {
    RoleGuard.requireStudent(actor.role);
    final trimmed = code.trim();
    if (trimmed.isEmpty) throw const ValidationFailure(AppStrings.pinCodeLengthError);

    final now = _clock();
    final active = _repository.getActiveSessions();
    if (active.isEmpty) throw const ValidationFailure(noActiveSessionError);

    // Yalnızca her oturumun güncel kodu saklanır; yenilenmiş (eski) bir kod hiçbir oturumla eşleşmez.
    final session = active.where((s) => s.matchesCode(trimmed)).firstOrNull;
    if (session == null) throw const ValidationFailure(wrongCodeError);

    final error = validateCode(session, trimmed, now);
    if (error != null) throw ValidationFailure(error);

    final existing = session.markFor(actor.uid);
    if (existing?.status == AttendanceStatus.present) throw const ValidationFailure(alreadyPresentError);

    final mark = AttendanceMark(
      studentUid: actor.uid,
      studentName: actor.fullName,
      studentNo: actor.schoolNo,
      status: AttendanceStatus.present,
      recordedAt: now,
    );
    final marks = [
      for (final m in session.marks)
        if (m.studentUid != actor.uid) m,
      mark,
    ];
    final updated = session.copyWith(marks: marks);
    await _repository.saveSession(updated);
    return updated;
  }
}
