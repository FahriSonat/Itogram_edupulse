import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_time_helper.dart';
import '../../../../core/enums/view_status.dart';
import '../../domain/entities/announcement_entity.dart';

class AnnouncementState extends Equatable {
  final ViewStatus status;
  final List<AnnouncementEntity> announcements;

  /// Takvimde seçilen gün. Null ise tüm duyurular listelenir.
  final DateTime? selectedDate;
  final String? errorMessage;

  const AnnouncementState({
    this.status = ViewStatus.initial,
    this.announcements = const [],
    this.selectedDate,
    this.errorMessage,
  });

  Set<DateTime> get eventDates => announcements.where((a) => !a.isCrisis).map((a) => a.eventDate).toSet();

  /// Kriz duyuruları son 3 günle sınırlı tutulur; eski krizler akışı kalabalıklaştırmaz.
  List<AnnouncementEntity> get visibleAnnouncements {
    final now = DateTime.now();
    final recent = announcements.where((a) => !a.isCrisis || now.difference(a.createdAt).inDays < 3);
    if (selectedDate == null) return recent.toList();
    return recent.where((a) => !a.isCrisis && DateTimeHelper.isSameDay(a.eventDate, selectedDate!)).toList();
  }

  AnnouncementState copyWith({
    ViewStatus? status,
    List<AnnouncementEntity>? announcements,
    DateTime? Function()? selectedDate,
    String? errorMessage,
  }) => AnnouncementState(
    status: status ?? this.status,
    announcements: announcements ?? this.announcements,
    selectedDate: selectedDate != null ? selectedDate() : this.selectedDate,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, announcements, selectedDate, errorMessage];
}
