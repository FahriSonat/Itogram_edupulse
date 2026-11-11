/// Data katmanında fırlatılan istisnalar.
abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class ServerException extends AppException {
  const ServerException([super.message = 'Sunucu hatası oluştu.']);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Yerel önbellek hatası oluştu.']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Kimlik doğrulama hatası.']);
}

/// Kural 1: 60 saniyesi dolmuş / kapalı yoklama kodu.
class ExpiredQrPinException extends AppException {
  const ExpiredQrPinException(
      [super.message = 'QR/PIN kodunun süresi doldu. Yeni kod isteyin.']);
}

/// Kural 5: Yetkisiz rol erişimi.
class UnauthorizedRoleException extends AppException {
  const UnauthorizedRoleException(
      [super.message = 'Bu işlem için yetkiniz yok.']);
}
