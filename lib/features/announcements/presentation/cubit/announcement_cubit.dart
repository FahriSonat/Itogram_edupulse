import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/announcement_type.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/date_time_helper.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/enums/view_status.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/usecases/create_announcement_usecase.dart';
import '../../domain/usecases/send_instant_crisis_push_usecase.dart';
import '../../domain/usecases/watch_announcements_usecase.dart';
import 'announcement_state.dart';

class AnnouncementCubit extends Cubit<AnnouncementState> {
  AnnouncementCubit({
    required this._watchAnnouncements,
    required this._createAnnouncement,
    required this._sendCrisisPush,
  }) : super(const AnnouncementState()) {
    start();
  }

  final WatchAnnouncementsUseCase _watchAnnouncements;
  final CreateAnnouncementUseCase _createAnnouncement;
  final SendInstantCrisisPushUseCase _sendCrisisPush;
  StreamSubscription<List<AnnouncementEntity>>? _sub;

  void start() {
    emit(state.copyWith(status: ViewStatus.loading));
    _sub?.cancel();
    _sub = _watchAnnouncements().listen(
      (items) => emit(state.copyWith(status: ViewStatus.loaded, announcements: items)),
      onError: (Object e) => emit(state.copyWith(status: ViewStatus.failure, errorMessage: Failure.from(e).message)),
    );
  }

  /// Aynı güne tekrar dokunulursa filtre kaldırılır.
  void selectDate(DateTime date) {
    final current = state.selectedDate;
    if (current != null && DateTimeHelper.isSameDay(current, date)) {
      clearDateFilter();
    } else {
      emit(state.copyWith(selectedDate: () => date));
    }
  }

  /// Günü seçer; aynı gün zaten seçiliyse filtre korunur.
  void focusDate(DateTime date) => emit(state.copyWith(selectedDate: () => date));

  void clearDateFilter() => emit(state.copyWith(selectedDate: () => null));

  Future<void> createAnnouncement({
    required UserEntity actor,
    required String title,
    required String content,
    required AnnouncementType type,
    required DateTime eventDate,
    required String targetCourse,
  }) => _createAnnouncement(
    actor: actor,
    title: title,
    content: content,
    type: type,
    eventDate: eventDate,
    targetCourse: targetCourse,
  );

  Future<void> broadcastCrisis({
    required UserEntity actor,
    required String title,
    required String message,
    required String targetCourse,
  }) => _sendCrisisPush(actor: actor, title: title, message: message, targetCourse: targetCourse);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
