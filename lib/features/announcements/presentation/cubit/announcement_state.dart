import 'package:equatable/equatable.dart';

import '../../../../core/enums/announcement_type.dart';
import '../../domain/entities/announcement_entity.dart';

sealed class AnnouncementState extends Equatable {
  const AnnouncementState();

  @override
  List<Object?> get props => <Object?>[];
}

class AnnouncementInitial extends AnnouncementState {
  const AnnouncementInitial();
}

class AnnouncementLoading extends AnnouncementState {
  const AnnouncementLoading();
}

class AnnouncementLoaded extends AnnouncementState {
  const AnnouncementLoaded({
    required this.allAnnouncements,
    required this.filteredAnnouncements,
    this.selectedDate,
    this.selectedType,
  });

  final List<AnnouncementEntity> allAnnouncements;
  final List<AnnouncementEntity> filteredAnnouncements;

  /// Takvimde seçili gün (null = tüm günler).
  final DateTime? selectedDate;

  /// Seçili kategori (null = tüm türler).
  final AnnouncementType? selectedType;

  AnnouncementLoaded copyWith({
    List<AnnouncementEntity>? allAnnouncements,
    List<AnnouncementEntity>? filteredAnnouncements,
    DateTime? selectedDate,
    AnnouncementType? selectedType,
    bool clearDate = false,
    bool clearType = false,
  }) {
    return AnnouncementLoaded(
      allAnnouncements: allAnnouncements ?? this.allAnnouncements,
      filteredAnnouncements: filteredAnnouncements ?? this.filteredAnnouncements,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
    );
  }

  @override
  List<Object?> get props => <Object?>[allAnnouncements, filteredAnnouncements, selectedDate, selectedType];
}

class AnnouncementError extends AnnouncementState {
  const AnnouncementError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class CrisisPushSending extends AnnouncementState {
  const CrisisPushSending();
}

class CrisisPushSentSuccess extends AnnouncementState {
  const CrisisPushSentSuccess();
}
