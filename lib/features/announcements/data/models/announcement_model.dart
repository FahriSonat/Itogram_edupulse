import '../../../../core/enums/announcement_type.dart';
import '../../domain/entities/announcement_entity.dart';

class AnnouncementModel extends AnnouncementEntity {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.content,
    required super.type,
    required super.eventDate,
    required super.authorUid,
    required super.authorName,
    super.targetCourse,
    required super.createdAt,
  });

  factory AnnouncementModel.fromEntity(AnnouncementEntity e) => AnnouncementModel(
    id: e.id,
    title: e.title,
    content: e.content,
    type: e.type,
    eventDate: e.eventDate,
    authorUid: e.authorUid,
    authorName: e.authorName,
    targetCourse: e.targetCourse,
    createdAt: e.createdAt,
  );

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) => AnnouncementModel(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    type: AnnouncementType.fromJson(json['type'] as String?),
    eventDate: DateTime.tryParse(json['eventDate'] as String? ?? '') ?? DateTime.now(),
    authorUid: json['authorUid'] as String? ?? '',
    authorName: json['authorName'] as String? ?? 'Akademi Yönetimi',
    targetCourse: json['targetCourse'] as String? ?? AnnouncementEntity.generalTarget,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'type': type.toJson(),
    'eventDate': eventDate.toIso8601String(),
    'authorUid': authorUid,
    'authorName': authorName,
    'targetCourse': targetCourse,
    'createdAt': createdAt.toIso8601String(),
  };
}
