import 'dart:math';

import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/attendance_session_entity.dart';
import '../repositories/attendance_repository.dart';

/// Üretilen tek kullanımlık yoklama kodu.
typedef QrPinCode = ({String pin, String qrToken, DateTime expiresAt});

/// Kural 1 (60 Sn Yoklama Kalkanı): 4 haneli PIN ve QR jetonu üretir;
/// kod üretildiği andan itibaren yalnızca [validity] süresince geçerlidir.
class Generate60sQrPinUseCase {
  Generate60sQrPinUseCase(this._repository, {Random? random, DateTime Function()? clock})
    : _random = random ?? Random.secure(),
      _clock = clock ?? DateTime.now;

  static const Duration validity = Duration(seconds: 60);

  final AttendanceRepository _repository;
  final Random _random;
  final DateTime Function() _clock;

  /// Saf üretim: yeni PIN + QR jetonu + son geçerlilik anı.
  QrPinCode generate({required String sessionId, String? previousPin}) {
    final now = _clock();
    var pin = _randomPin();
    // Art arda aynı PIN gelmesin (eski kodla yeni kod karışmasın).
    while (pin == previousPin) {
      pin = _randomPin();
    }
    final token = 'EDUPULSE-$sessionId-$pin-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    return (pin: pin, qrToken: token, expiresAt: now.add(validity));
  }

  /// Oturumun kodunu yeniler (yalnızca oturumu başlatan eğitmen).
  Future<AttendanceSessionEntity> refresh({required UserEntity actor, required String sessionId}) async {
    RoleGuard.requireInstructor(actor.role);
    final session = _repository.getSession(sessionId);
    if (session == null || !session.isActive) {
      throw const ValidationFailure('Aktif yoklama oturumu bulunamadı.');
    }
    final code = generate(sessionId: sessionId, previousPin: session.pinCode);
    final updated = session.copyWith(pinCode: code.pin, qrToken: code.qrToken, pinExpiresAt: code.expiresAt);
    await _repository.saveSession(updated);
    return updated;
  }

  String _randomPin() => _random.nextInt(10000).toString().padLeft(4, '0');
}
