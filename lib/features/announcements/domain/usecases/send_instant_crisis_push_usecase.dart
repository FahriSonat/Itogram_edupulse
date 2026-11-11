import '../../../../core/error/failures.dart';
import '../../../../core/router/role_guard.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/announcement_entity.dart';
import '../repositories/announcement_repository.dart';

/// Eğitmenin tüm öğrencilere anlık kriz bildirimi fırlatması (Kural 5: yalnızca eğitmen).
class SendInstantCrisisPushUseCase {
  const SendInstantCrisisPushUseCase(this._repository);

  final AnnouncementRepository _repository;

  Future<AnnouncementEntity> call({
    required UserEntity actor,
    required String title,
    required String message,
    required String targetCourse,
  }) {
    RoleGuard.requireInstructor(actor.role);
    if (title.trim().isEmpty || message.trim().isEmpty) {
      throw const ValidationFailure('Başlık ve mesaj boş bırakılamaz.');
    }
    return _repository.sendInstantCrisisPush(
      title: title.trim(),
      message: message.trim(),
      targetCourse: targetCourse,
      authorUid: actor.uid,
      authorName: actor.fullName,
    );
  }
}
