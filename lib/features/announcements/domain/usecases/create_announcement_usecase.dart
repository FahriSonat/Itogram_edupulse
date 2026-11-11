import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/announcement_entity.dart';
import '../repositories/announcement_repository.dart';

/// Yeni etkinlik / tatil / seminer duyurusu ekler (yalnızca eğitmen —
/// firestore.rules ayrıca engeller).
class CreateAnnouncementUseCase {
  const CreateAnnouncementUseCase(this._repository);

  final AnnouncementRepository _repository;

  Future<Either<Failure, Unit>> call(AnnouncementEntity announcement) async {
    if (announcement.title.trim().isEmpty) {
      return const Left(ServerFailure('Duyuru başlığı boş olamaz.'));
    }
    try {
      await _repository.createAnnouncement(announcement);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
