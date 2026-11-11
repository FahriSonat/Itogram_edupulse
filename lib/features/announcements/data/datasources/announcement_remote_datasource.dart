import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/announcement_type.dart';
import '../../../../core/services/fcm_notification_service.dart';

/// Firestore `announcements` koleksiyonunu gerçek zamanlı (`snapshots()`) dinler.
/// Eğitmen yeni bir duyuru veya Kriz Yayını oluşturduğunda veritabanına yazar ve
/// ilgili FCM Topic kanalına (Örn: `topic_all_campus` veya `topic_course_101`)
/// anlık bildirim tetikler.
abstract class AnnouncementRemoteDataSource {
  Stream<List<Map<String, dynamic>>> watchAnnouncements({
    AnnouncementType? filterType,
    String? courseId,
  });

  Future<List<Map<String, dynamic>>> getAnnouncementsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

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
  });

  Future<Map<String, dynamic>> sendInstantCrisisPush({
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    String? targetCourseId,
  });

  Future<void> deleteAnnouncement(String announcementId);
}

class AnnouncementRemoteDataSourceImpl implements AnnouncementRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FcmNotificationService? fcmNotificationService;

  AnnouncementRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    this.fcmNotificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _announcementsRef =>
      _firestore.collection(FirestorePaths.announcements);

  @override
  Stream<List<Map<String, dynamic>>> watchAnnouncements({
    AnnouncementType? filterType,
    String? courseId,
  }) {
    Query<Map<String, dynamic>> query = _announcementsRef;

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
    }
    if (courseId != null && courseId.isNotEmpty) {
      query = query.where('courseId', isEqualTo: courseId);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _normalizeMap(data);
      }).toList();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getAnnouncementsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _announcementsRef
        .where(
          'eventDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          'eventDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        )
        .orderBy('eventDate')
        .get();

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return _normalizeMap(data);
    }).toList();
  }

  @override
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
    final docRef = _announcementsRef.doc();
    final now = DateTime.now();

    final targetTopic = (courseId != null && courseId.isNotEmpty)
        ? FcmNotificationService.courseTopic(courseId)
        : FcmNotificationService.topicAllCampus;

    final payload = <String, dynamic>{
      'id': docRef.id,
      'title': title.trim(),
      'content': content.trim(),
      'type': type.name,
      'authorId': authorId,
      'authorName': authorName,
      'courseId': courseId,
      'courseName': courseName,
      'targetTopic': targetTopic,
      'isPinned': isPinned,
      'isCrisis': type == AnnouncementType.urgent,
      'eventDate':
          eventDate != null ? Timestamp.fromDate(eventDate) : null,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await docRef.set(payload);

    await fcmNotificationService?.triggerTopicNotification(
      topic: targetTopic,
      title: title.trim(),
      body: content.trim(),
      isCrisis: type == AnnouncementType.urgent,
      extraData: {
        'announcementId': docRef.id,
        'courseId': ?courseId,
      },
    );

    return _normalizeMap(payload);
  }

  @override
  Future<Map<String, dynamic>> sendInstantCrisisPush({
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    String? targetCourseId,
  }) async {
    return createAnnouncement(
      title: title,
      content: message,
      type: AnnouncementType.urgent,
      authorId: senderId,
      authorName: senderName,
      courseId: targetCourseId,
      isPinned: true,
    );
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) async {
    await _announcementsRef.doc(announcementId).delete();
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}
