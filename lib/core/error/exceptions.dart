/// Veri katmanında (datasource) fırlatılan ham istisnalar.
///
/// Repository implementasyonları bu istisnaları yakalayıp kullanıcıya
/// gösterilebilir [Failure] nesnelerine dönüştürür.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

/// Kalıcı depolama (SharedPreferences / yerel veritabanı) okuma-yazma hatası.
class CacheException extends AppException {
  const CacheException([super.message = 'Yerel veriye erişilemedi.']);
}

/// Sunucu / backend tarafı hata (yerel backend'de iş kuralı ihlalleri dahil).
class ServerException extends AppException {
  const ServerException([super.message = 'İşlem sırasında bir hata oluştu.']);
}

/// Kimlik doğrulama hatası (hatalı şifre, kayıtlı olmayan kullanıcı vb.).
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Kaydı bulunamayan kaynak.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Kayıt bulunamadı.']);
}
