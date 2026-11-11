import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/announcement_type.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../models/announcement_model.dart';

/// Firestore `announcements` koleksiyonunu gerçek zamanlı (`snapshots()`) dinler.
/// Eğitmen yeni bir duyuru veya Kriz Yayını oluşturduğunda veritabanına yazar ve
/// ilgili FCM Topic kanalına (Örn: `topic_all_campus` veya `topic_course_101`)
/// anlık bildirim tetikler.
abstract class AnnouncementRemoteDataSource {
  Stream<List<AnnouncementModel>> watchAnnouncements();

  Future<void> createAnnouncement(AnnouncementModel announcement);

  Future<void> sendInstantCrisisPush({
    required String title,
    required String body,
    String? targetCourseId,
    String authorName = 'Eğitmen',
  });
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
  Stream<List<AnnouncementModel>> watchAnnouncements() {
    return _announcementsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    final docRef = announcement.id.isNotEmpty
        ? _announcementsRef.doc(announcement.id)
        : _announcementsRef.doc();

    final targetTopic = (announcement.targetCourseId != null &&
            announcement.targetCourseId!.isNotEmpty)
        ? FcmNotificationService.courseTopic(announcement.targetCourseId!)
        : FcmNotificationService.topicAllCampus;

    await docRef.set(announcement.toJson());

    await fcmNotificationService?.triggerTopicNotification(
      topic: targetTopic,
      title: announcement.title,
      body: announcement.content,
      isCrisis: announcement.type == AnnouncementType.urgent,
      extraData: {
        'announcementId': docRef.id,
        'targetCourseId': ?announcement.targetCourseId,
      },
    );
  }

  @override
  Future<void> sendInstantCrisisPush({
    required String title,
    required String body,
    String? targetCourseId,
    String authorName = 'Eğitmen',
  }) async {
    final docRef = _announcementsRef.doc();
    final crisisModel = AnnouncementModel(
      id: docRef.id,
      title: title.trim(),
      content: body.trim(),
      type: AnnouncementType.urgent,
      eventDate: DateTime.now(),
      targetCourseId: targetCourseId,
      authorName: authorName,
    );

    await createAnnouncement(crisisModel);
  }
}
