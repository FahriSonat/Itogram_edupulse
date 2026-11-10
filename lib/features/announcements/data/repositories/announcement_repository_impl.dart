import '../../../../core/enums/announcement_type.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../datasources/announcement_remote_datasource.dart';

class AnnouncementRepositoryImpl {
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

  Stream<List<Map<String, dynamic>>> watchAnnouncements({
    AnnouncementType? filterType,
    String? courseId,
  }) {
    return _remoteDataSource.watchAnnouncements(
      filterType: filterType,
      courseId: courseId,
    );
  }

  Future<List<Map<String, dynamic>>> getAnnouncementsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }
    return _remoteDataSource.getAnnouncementsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Eğitmen yeni bir duyuru oluşturduğunda veritabanına yazar ve
  /// ilgili FCM Topic kanalına (topic_all_campus veya topic_course_101) bildirim tetikler.
  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String content,
    required AnnouncementType type,
    required String authorId,
    required String authorName,
    String? courseId,
    String? courseName,
    DateTime? eventDate,
    bool isPinned = false,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    return _remoteDataSource.createAnnouncement(
      title: title,
      content: content,
      type: type,
      authorId: authorId,
      authorName: authorName,
      courseId: courseId,
      courseName: courseName,
      eventDate: eventDate,
      isPinned: isPinned,
    );
  }

  /// Modül 2.4: Anlık Kriz Yayını oluşturur, ilgili FCM Topic kanalına
  /// (Örn: topic_all_campus veya topic_course_101) anlık bildirim ve
  /// Analytics `crisis_broadcast_sent` event'ini tetikler.
  Future<Map<String, dynamic>> sendInstantCrisisPush({
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    String? targetCourseId,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }

    final announcement = await _remoteDataSource.sendInstantCrisisPush(
      title: title,
      message: message,
      senderId: senderId,
      senderName: senderName,
      targetCourseId: targetCourseId,
    );

    await analyticsService?.logCrisisBroadcastSent(
      senderId: senderId,
      title: title,
      targetCourseId: targetCourseId,
    );

    return announcement;
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('İnternet bağlantısı bulunamadı.');
    }
    await _remoteDataSource.deleteAnnouncement(announcementId);
  }
}
