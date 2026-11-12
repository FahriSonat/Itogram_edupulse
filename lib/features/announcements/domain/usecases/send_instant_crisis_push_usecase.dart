import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/announcement_repository.dart';

/// Eğitmen için tüm kampüse veya belirli bir derse tek tuşla acil FCM push
/// bildirimi gönderir (Modül 2.4 — Anlık Kriz Yayını).
class SendInstantCrisisPushUseCase {
  const SendInstantCrisisPushUseCase(this._repository);

  final AnnouncementRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String title,
    required String message,
    String? targetCourseId,
  }) async {
    if (title.trim().isEmpty || message.trim().isEmpty) {
      return const Left(ServerFailure('Kriz yayını başlığı ve mesajı zorunludur.'));
    }
    try {
      await _repository.sendInstantCrisisPush(
        title: title.trim(),
        body: message.trim(),
        targetCourseId: targetCourseId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
