import 'package:equatable/equatable.dart';

import '../constants/app_strings.dart';
import 'exceptions.dart';

/// Domain ve sunum katmanına iletilen, kullanıcıya gösterilebilir hata.
///
/// Use case'ler ve repository'ler [Failure] fırlatır; Cubit'ler yakalayıp
/// [message] alanını ekrana basar.
abstract class Failure extends Equatable implements Exception {
  final String message;

  const Failure(this.message);

  /// Herhangi bir hatayı [Failure]'a çevirir.
  static Failure from(Object error) {
    if (error is Failure) return error;
    if (error is AuthException) return AuthFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is CacheException) return CacheFailure(error.message);
    if (error is AppException) return ServerFailure(error.message);
    return const ServerFailure();
  }

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = AppStrings.errorMessage]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Yerel veriye erişilemedi.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Kayıt bulunamadı.']);
}

/// İş kuralı ihlali (ör. süresi dolmuş PIN, geçersiz not aralığı).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Kural 5: Mutlak Rol Güvenliği — yetkisiz rol ile yapılan işlem.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = AppStrings.unauthorizedAccess]);
}
