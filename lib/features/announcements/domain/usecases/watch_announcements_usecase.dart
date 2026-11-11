import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/announcement_entity.dart';
import '../repositories/announcement_repository.dart';

/// Takvimli duyuruları Firestore üzerinden canlı (snapshots) izler.
///
/// `transform` kullanılır: dinleyici iptal edildiğinde (Cubit.close) alttaki
/// Firestore aboneliği de hemen iptal edilir; hata olayları ise akışı
/// sonlandırmadan `Left(ServerFailure)` olarak iletilir.
class WatchAnnouncementsUseCase {
  const WatchAnnouncementsUseCase(this._repository);

  final AnnouncementRepository _repository;

  Stream<Either<Failure, List<AnnouncementEntity>>> call() {
    return _repository.watchAnnouncements().transform(
          StreamTransformer<List<AnnouncementEntity>, Either<Failure, List<AnnouncementEntity>>>.fromHandlers(
            handleData: (list, sink) => sink.add(Right(list)),
            handleError: (error, _, sink) => sink.add(Left(ServerFailure(error.toString()))),
          ),
        );
  }
}
