import '../entities/announcement_entity.dart';

abstract class AnnouncementRepository {
  Stream<List<AnnouncementEntity>> watchAnnouncements();
  
  Future<void> createAnnouncement(AnnouncementEntity announcement);
  
  Future<void> sendInstantCrisisPush({
    required String title,
    required String body,
    String? targetCourseId,
  });
}