import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/announcement_entity.dart';
import '../repositories/announcement_repository.dart';

/// Takvimli duyuruları Firestore üzerinden canlı (snapshots) izler.
class WatchAnnouncementsUseCase {
  const WatchAnnouncementsUseCase(this._repository);

  final AnnouncementRepository _repository;

  Stream<Either<Failure, List<AnnouncementEntity>>> call() async* {
    try {
      await for (final list in _repository.watchAnnouncements()) {
        yield Right(list);
      }
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }
}
