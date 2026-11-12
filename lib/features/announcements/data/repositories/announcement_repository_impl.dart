import '../../../../core/network/network_info.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_datasource.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final FcmNotificationService? fcmNotificationService;
  final AnalyticsService? analyticsService;

  AnnouncementRepositoryImpl({
    AnnouncementRemoteDataSource? remoteDataSource,
    NetworkInfo? networkInfo,
    this.fcmNotificationService,
    this.analyticsService,
  })  : _remoteDataSource = remoteDataSource ??
            AnnouncementRemoteDataSourceImpl(
              fcmNotificationService: fcmNotificationService,
            ),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  @override
  Stream<List<AnnouncementEntity>> watchAnnouncements() {
    return _remoteDataSource.watchAnnouncements();
  }

  @override
  Future<void> createAnnouncement(AnnouncementEntity announcement) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final model = announcement is AnnouncementModel
        ? announcement
        : AnnouncementModel(
            id: announcement.id,
            title: announcement.title,
            content: announcement.content,
            type: announcement.type,
            eventDate: announcement.eventDate,
            targetCourseId: announcement.targetCourseId,
            authorName: announcement.authorName,
          );

    await _remoteDataSource.createAnnouncement(model);
  }

  @override
  Future<void> sendInstantCrisisPush({
    required String title,
    required String body,
    String? targetCourseId,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    await _remoteDataSource.sendInstantCrisisPush(
      title: title,
      body: body,
      targetCourseId: targetCourseId,
    );

    await analyticsService?.logCrisisBroadcastSent(
      senderId: 'instructor',
      title: title,
      targetCourseId: targetCourseId,
    );
  }
}
