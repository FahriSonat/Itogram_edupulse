/// Form alanlarında `validator:` parametresine verilecek doğrulayıcılar.
///
/// Her metod geçerli girişte `null`, geçersiz girişte Türkçe hata mesajı döner.
/// Kullanım: `TextFormField(validator: Validators.email)`.
abstract final class Validators {
  static const int studentNoMinLength = 6;
  static const int studentNoMaxLength = 12;
  static const int passwordMinLength = 8;
  static const double minGrade = 0;
  static const double maxGrade = 100;

  static final RegExp _digitsOnly = RegExp(r'^\d+$');
  static final RegExp _email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'\d');

  /// Alanın boş bırakılmadığını kontrol eder.
  static String? required(String? value, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName boş bırakılamaz';
    }
    return null;
  }

  /// Öğrenci / sicil numarası: sadece rakam, 6-12 hane.
  static String? studentNo(String? value) {
    final String input = value?.trim() ?? '';
    if (input.isEmpty) return 'Öğrenci numarası boş bırakılamaz';
    if (!_digitsOnly.hasMatch(input)) {
      return 'Öğrenci numarası sadece rakamlardan oluşmalıdır';
    }
    if (input.length < studentNoMinLength || input.length > studentNoMaxLength) {
      return 'Öğrenci numarası $studentNoMinLength-$studentNoMaxLength haneli olmalıdır';
    }
    return null;
  }

  /// E-posta formatı kontrolü.
  static String? email(String? value) {
    final String input = value?.trim() ?? '';
    if (input.isEmpty) return 'E-posta boş bırakılamaz';
    if (!_email.hasMatch(input)) return 'Geçerli bir e-posta adresi giriniz';
    return null;
  }

  /// Güçlü şifre: en az 8 karakter, büyük harf, küçük harf ve rakam.
  static String? password(String? value) {
    final String input = value ?? '';
    if (input.isEmpty) return 'Şifre boş bırakılamaz';
    if (input.length < passwordMinLength) {
      return 'Şifre en az $passwordMinLength karakter olmalıdır';
    }
    if (!_upper.hasMatch(input)) return 'Şifre en az bir büyük harf içermelidir';
    if (!_lower.hasMatch(input)) return 'Şifre en az bir küçük harf içermelidir';
    if (!_digit.hasMatch(input)) return 'Şifre en az bir rakam içermelidir';
    return null;
  }

  /// Kayıt ekranındaki "Şifre Tekrar" alanı: ilk şifreyle eşleşmeli.
  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) return 'Şifre tekrarı boş bırakılamaz';
    if (value != original) return 'Şifreler eşleşmiyor';
    return null;
  }

  /// Not girişi: 0-100 arası sayı.
  static String? grade(String? value) {
    final String input = value?.trim().replaceAll(',', '.') ?? '';
    if (input.isEmpty) return 'Not boş bırakılamaz';
    final double? parsed = double.tryParse(input);
    if (parsed == null) return 'Not sayısal bir değer olmalıdır';
    if (parsed < minGrade || parsed > maxGrade) {
      return 'Not 0 ile 100 arasında olmalıdır';
    }
    return null;
  }
}
