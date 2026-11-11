import '../entities/announcement_entity.dart';
import '../repositories/announcement_repository.dart';

/// Duyuruları dinler: kriz duyuruları en üstte, ardından etkinlik tarihine göre sıralı.
class WatchAnnouncementsUseCase {
  const WatchAnnouncementsUseCase(this._repository);

  final AnnouncementRepository _repository;

  Stream<List<AnnouncementEntity>> call() => _repository.watchAnnouncements().map(sortForFeed);

  static List<AnnouncementEntity> sortForFeed(List<AnnouncementEntity> items) {
    final crisis = items.where((a) => a.isCrisis).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final events = items.where((a) => !a.isCrisis).toList()..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return [...crisis, ...events];
  }
}
