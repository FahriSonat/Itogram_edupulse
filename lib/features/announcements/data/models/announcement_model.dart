import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../../../core/enums/announcement_type.dart';

class AnnouncementModel extends AnnouncementEntity {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.content,
    required super.type,
    super.eventDate,
    super.targetCourseId,
    required super.authorName,
  });

  factory AnnouncementModel.fromFirestore(Map<String, dynamic> json, String id) {
    final rawDate = json['eventDate'];
    DateTime? parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return AnnouncementModel(
      id: id,
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      type: AnnouncementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnnouncementType.general,
      ),
      eventDate: parsedDate,
      targetCourseId: json['targetCourseId'] as String?,
      authorName: (json['authorName'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'type': type.name,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'targetCourseId': targetCourseId,
      'authorName': authorName,
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    AnnouncementType? type,
    DateTime? eventDate,
    String? targetCourseId,
    String? authorName,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      eventDate: eventDate ?? this.eventDate,
      targetCourseId: targetCourseId ?? this.targetCourseId,
      authorName: authorName ?? this.authorName,
    );
  }
}