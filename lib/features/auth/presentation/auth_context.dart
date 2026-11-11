import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/enums/user_role.dart';
import '../domain/entities/user_entity.dart';
import 'cubit/auth_cubit.dart';
import 'cubit/auth_state.dart';

/// Sayfaların giriş yapan kullanıcıya kısa yoldan erişimi.
/// Router (RoleGuard) oturumsuz kullanıcıyı korumalı sayfalara sokmaz;
/// yine de güvenli tarafta kalmak için en düşük yetki (öğrenci) varsayılır.
extension AuthContextX on BuildContext {
  UserEntity? get currentUser {
    final state = watch<AuthCubit>().state;
    return state is Authenticated ? state.user : null;
  }

  UserRole get currentRole => currentUser?.role ?? UserRole.student;

  /// build dışında (callback içinde) kullanılacak sürüm.
  UserEntity? readCurrentUser() {
    final state = read<AuthCubit>().state;
    return state is Authenticated ? state.user : null;
  }
}
