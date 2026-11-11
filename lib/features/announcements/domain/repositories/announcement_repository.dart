import '../../../../core/enums/announcement_type.dart';
import '../entities/announcement_entity.dart';

abstract class AnnouncementRepository {
  Stream<List<AnnouncementEntity>> watchAnnouncements();

  Future<AnnouncementEntity> createAnnouncement({
    required String title,
    required String content,
    required AnnouncementType type,
    required DateTime eventDate,
    required String authorUid,
    required String authorName,
    required String targetCourse,
  });

  /// Kriz duyurusunu kaydeder ve tüm öğrencilere anlık bildirim gönderir.
  Future<AnnouncementEntity> sendInstantCrisisPush({
    required String title,
    required String message,
    required String targetCourse,
    required String authorUid,
    required String authorName,
  });

  Future<void> deleteAnnouncement(String id);
}
