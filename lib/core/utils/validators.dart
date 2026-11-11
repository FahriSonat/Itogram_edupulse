import '../constants/app_strings.dart';
import 'date_time_helper.dart';

/// [Validators] form alanları için ortak doğrulayıcılar (TextFormField.validator).
abstract final class Validators {
  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final RegExp _digitsRegex = RegExp(r'^\d+$');

  static String? required(String? value, [String message = 'Bu alan zorunludur.']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fullNameRequired;
    if (value.trim().length < 3) return 'Ad Soyad en az 3 karakter olmalıdır.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.emailRequired;
    if (!_emailRegex.hasMatch(value.trim())) return AppStrings.emailInvalid;
    return null;
  }

  static String? studentNo(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.studentNoRequired;
    if (!_digitsRegex.hasMatch(value.trim())) return AppStrings.studentNoInvalid;
    if (value.trim().length < 4) return 'Numara en az 4 haneli olmalıdır.';
    return null;
  }

  /// Giriş ekranı: öğrenci/sicil numarası veya kurumsal e-posta kabul eder.
  static String? loginIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.studentNoRequired;
    final v = value.trim();
    if (v.contains('@')) return email(v);
    if (!_digitsRegex.hasMatch(v)) return AppStrings.studentNoInvalid;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.passwordRequired;
    if (value.length < 6) return AppStrings.passwordTooShort;
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return AppStrings.passwordRequired;
    if (value != original) return AppStrings.passwordsDoNotMatch;
    return null;
  }

  static String? pin(String? value) {
    if (value == null || !RegExp(r'^\d{4}$').hasMatch(value.trim())) return AppStrings.pinCodeLengthError;
    return null;
  }

  static String? score(String? value) {
    final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0 || parsed > 100) return AppStrings.scoreRangeError;
    return null;
  }

  static String? time(String? value) {
    if (value == null || DateTimeHelper.parseTime(value) == null) return 'Saat SS:DD biçiminde olmalı (ör. 10:30).';
    return null;
  }
}
