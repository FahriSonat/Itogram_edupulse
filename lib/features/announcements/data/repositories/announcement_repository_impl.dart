import '../../../../core/enums/announcement_type.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_datasource.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({required this.remote, required this.notifications});

  final AnnouncementRemoteDataSource remote;
  final NotificationService notifications;

  @override
  Stream<List<AnnouncementEntity>> watchAnnouncements() => remote.watchAnnouncements();

  @override
  Future<AnnouncementEntity> createAnnouncement({
    required String title,
    required String content,
    required AnnouncementType type,
    required DateTime eventDate,
    required String authorUid,
    required String authorName,
    required String targetCourse,
  }) async {
    try {
      final model = AnnouncementModel(
        id: remote.newId(),
        title: title,
        content: content,
        type: type,
        eventDate: eventDate,
        authorUid: authorUid,
        authorName: authorName,
        targetCourse: targetCourse,
        createdAt: DateTime.now(),
      );
      await remote.saveAnnouncement(model);
      await notifications.send(
        title: '${type.displayName}: $title',
        body: content,
        kind: NotificationKind.announcement,
      );
      return model;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<AnnouncementEntity> sendInstantCrisisPush({
    required String title,
    required String message,
    required String targetCourse,
    required String authorUid,
    required String authorName,
  }) async {
    try {
      final now = DateTime.now();
      final model = AnnouncementModel(
        id: remote.newId(),
        title: title,
        content: message,
        type: AnnouncementType.crisis,
        eventDate: now,
        authorUid: authorUid,
        authorName: authorName,
        targetCourse: targetCourse,
        createdAt: now,
      );
      await remote.saveAnnouncement(model);
      await notifications.send(
        title: '🚨 $title',
        body: '$message\n($targetCourse)',
        kind: NotificationKind.crisis,
        targetRole: UserRole.student,
      );
      return model;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    try {
      await remote.deleteAnnouncement(id);
    } catch (e) {
      throw Failure.from(e);
    }
  }
}
