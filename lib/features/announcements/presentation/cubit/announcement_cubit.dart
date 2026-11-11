import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/announcement_type.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/usecases/create_announcement_usecase.dart';
import '../../domain/usecases/send_instant_crisis_push_usecase.dart';
import '../../domain/usecases/watch_announcements_usecase.dart';
import 'announcement_state.dart';

class AnnouncementCubit extends Cubit<AnnouncementState> {
  final WatchAnnouncementsUseCase watchAnnouncementsUseCase;
  final CreateAnnouncementUseCase createAnnouncementUseCase;
  final SendInstantCrisisPushUseCase sendInstantCrisisPushUseCase;

  StreamSubscription? _announcementsSubscription;

  AnnouncementCubit({
    required this.watchAnnouncementsUseCase,
    required this.createAnnouncementUseCase,
    required this.sendInstantCrisisPushUseCase,
  }) : super(AnnouncementInitial());

  void startWatchingAnnouncements() {
    emit(AnnouncementLoading());
    _announcementsSubscription?.cancel();
    _announcementsSubscription = watchAnnouncementsUseCase().listen(
      (result) {
        result.fold(
          (failure) => emit(AnnouncementError(failure.message)),
          (list) {
            emit(AnnouncementLoaded(
              allAnnouncements: list,
              filteredAnnouncements: list,
            ));
          },
        );
      },
    );
  }

  void filterByDate(DateTime? date) {
    if (state is! AnnouncementLoaded) return;
    final currentState = state as AnnouncementLoaded;

    if (date == null) {
      final filtered = _applyFilters(currentState.allAnnouncements, null, currentState.selectedType);
      emit(currentState.copyWith(
        filteredAnnouncements: filtered,
        clearDate: true,
      ));
      return;
    }

    final filtered = _applyFilters(currentState.allAnnouncements, date, currentState.selectedType);
    emit(currentState.copyWith(
      filteredAnnouncements: filtered,
      selectedDate: date,
    ));
  }

  void filterByType(AnnouncementType? type) {
    if (state is! AnnouncementLoaded) return;
    final currentState = state as AnnouncementLoaded;

    if (type == null) {
      final filtered = _applyFilters(currentState.allAnnouncements, currentState.selectedDate, null);
      emit(currentState.copyWith(
        filteredAnnouncements: filtered,
        clearType: true,
      ));
      return;
    }

    final filtered = _applyFilters(currentState.allAnnouncements, currentState.selectedDate, type);
    emit(currentState.copyWith(
      filteredAnnouncements: filtered,
      selectedType: type,
    ));
  }

  List<AnnouncementEntity> _applyFilters(
    List<AnnouncementEntity> list,
    DateTime? date,
    AnnouncementType? type,
  ) {
    return list.where((item) {
      final matchesType = type == null || item.type == type;
      final matchesDate = date == null ||
          (item.eventDate.year == date.year &&
              item.eventDate.month == date.month &&
              item.eventDate.day == date.day);
      return matchesType && matchesDate;
    }).toList();
  }

  Future<void> addAnnouncement(AnnouncementEntity announcement) async {
    final result = await createAnnouncementUseCase(announcement);
    result.fold(
      (failure) => emit(AnnouncementError(failure.message)),
      (_) {},
    );
  }

  Future<void> sendCrisisBroadcast({
    required String title,
    required String message,
    String? targetCourseId,
  }) async {
    final previousState = state;
    emit(CrisisPushSending());
    final result = await sendInstantCrisisPushUseCase(
      title: title,
      message: message,
      targetCourseId: targetCourseId,
    );
    result.fold(
      (failure) => emit(AnnouncementError(failure.message)),
      (_) {
        emit(CrisisPushSentSuccess());
        if (previousState is AnnouncementLoaded) {
          emit(previousState);
        }
      },
    );
  }

  @override
  Future<void> close() {
    _announcementsSubscription?.cancel();
    return super.close();
  }
}