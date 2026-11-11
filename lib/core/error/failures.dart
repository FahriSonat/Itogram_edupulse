import 'package:equatable/equatable.dart';

/// Domain ve Presentation katmanlarının haberleştiği hata sınıfları.
abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Sunucu hatası oluştu.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Yerel veri okunamadı.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'İnternet bağlantısı yok.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Giriş işlemi başarısız.']);
}

class ExpiredCodeFailure extends Failure {
  const ExpiredCodeFailure(
      [super.message = 'QR/PIN kodunun süresi doldu. Yeni kod isteyin.']);
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([super.message = 'Bu işlem için yetkiniz yok.']);
}
