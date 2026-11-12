import 'package:equatable/equatable.dart';
import '../../../../core/enums/announcement_type.dart';

class AnnouncementEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final AnnouncementType type;
  final DateTime? eventDate;
  final String? targetCourseId;
  final String authorName;

  const AnnouncementEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.eventDate,
    this.targetCourseId,
    required this.authorName,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        type,
        eventDate,
        targetCourseId,
        authorName,
      ];
}