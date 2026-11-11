import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/fcm_notification_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class NotificationState extends Equatable {
  final String? uid;
  final List<AppNotification> notifications;

  const NotificationState({this.uid, this.notifications = const []});

  int get unreadCount => uid == null ? 0 : notifications.where((n) => !n.isReadBy(uid!)).length;

  @override
  List<Object?> get props => [uid, notifications];
}

/// Oturumdaki kullanıcının bildirim kutusunu dinler; kullanıcı değiştiğinde
/// (giriş / çıkış) aboneliği otomatik yeniler.
class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({required this._service, required AuthCubit authCubit}) : super(const NotificationState()) {
    _bind(authCubit.state);
    _authSub = authCubit.stream.listen(_bind);
  }

  final NotificationService _service;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<List<AppNotification>>? _sub;
  UserEntity? _user;

  void _bind(AuthState auth) {
    final user = auth.isAuthenticated ? auth.user : null;
    if (user?.uid == _user?.uid) return;
    _user = user;
    _sub?.cancel();
    if (user == null) {
      emit(const NotificationState());
      return;
    }
    _sub = _service
        .watchFor(uid: user.uid, role: user.role)
        .listen((list) => emit(NotificationState(uid: user.uid, notifications: list)));
  }

  Future<void> markAllRead() async {
    final user = _user;
    if (user == null) return;
    await _service.markAllRead(uid: user.uid, role: user.role);
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    _sub?.cancel();
    return super.close();
  }
}
