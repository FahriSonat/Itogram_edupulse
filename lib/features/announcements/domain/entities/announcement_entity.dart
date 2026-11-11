import 'package:equatable/equatable.dart';

import '../../../../core/enums/announcement_type.dart';

/// [AnnouncementEntity] kampüs duyurusu veya etkinliği (seminer, hackathon, tatil, kriz).
class AnnouncementEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final AnnouncementType type;
  final DateTime eventDate;
  final String authorUid;
  final String authorName;

  /// "Tüm Kampüs / Genel" veya ders adı.
  final String targetCourse;
  final DateTime createdAt;

  const AnnouncementEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.eventDate,
    required this.authorUid,
    required this.authorName,
    this.targetCourse = generalTarget,
    required this.createdAt,
  });

  static const String generalTarget = 'Tüm Kampüs / Genel';

  bool get isCrisis => type == AnnouncementType.crisis;

  @override
  List<Object?> get props => [id, title, content, type, eventDate, authorUid, authorName, targetCourse, createdAt];
}
