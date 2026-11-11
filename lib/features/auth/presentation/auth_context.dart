import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/user_entity.dart';
import 'cubit/auth_cubit.dart';

extension AuthContext on BuildContext {
  /// Oturum açmış kullanıcı (yalnızca kimliği doğrulanmış ekranlarda kullanın).
  UserEntity get currentUser => read<AuthCubit>().requireUser;
}
