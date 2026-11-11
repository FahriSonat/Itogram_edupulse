import '../../../../core/enums/announcement_type.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/announcement_entity.dart';
import '../repositories/announcement_repository.dart';

/// Eğitmenin seminer / hackathon / tatil duyurusu yayınlaması.
class CreateAnnouncementUseCase {
  const CreateAnnouncementUseCase(this._repository);

  final AnnouncementRepository _repository;

  Future<AnnouncementEntity> call({
    required UserEntity actor,
    required String title,
    required String content,
    required AnnouncementType type,
    required DateTime eventDate,
    String targetCourse = AnnouncementEntity.generalTarget,
  }) {
    RoleGuard.requireInstructor(actor.role);
    if (title.trim().isEmpty) throw const ValidationFailure('Duyuru başlığı boş olamaz.');
    if (content.trim().isEmpty) throw const ValidationFailure('Duyuru içeriği boş olamaz.');
    return _repository.createAnnouncement(
      title: title.trim(),
      content: content.trim(),
      type: type,
      eventDate: eventDate,
      authorUid: actor.uid,
      authorName: actor.fullName,
      targetCourse: targetCourse,
    );
  }
}
