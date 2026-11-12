import 'package:flutter/services.dart';

/// Sadece rakam kabul eden ve en fazla [maxLength] karakter tutan formatter.
///
/// Yapıştırılan metindeki rakam olmayan karakterler atılır, fazlası kesilir.
class DigitsOnlyInputFormatter extends TextInputFormatter {
  DigitsOnlyInputFormatter({this.maxLength});

  final int? maxLength;

  static final RegExp _nonDigit = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(_nonDigit, '');
    final int? limit = maxLength;
    if (limit != null && digits.length > limit) {
      digits = digits.substring(0, limit);
    }
    if (digits == newValue.text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// Öğrenci numarası alanı: sadece rakam, en fazla 12 hane.
class StudentNoInputFormatter extends DigitsOnlyInputFormatter {
  StudentNoInputFormatter() : super(maxLength: 12);
}

/// Canlı yoklama PIN alanı: sadece rakam, en fazla 4 hane.
class PinCodeInputFormatter extends DigitsOnlyInputFormatter {
  PinCodeInputFormatter() : super(maxLength: pinLength);

  static const int pinLength = 4;
}

/// Not girişi alanı: sadece tam sayı, 0-100 arası.
///
/// 100'ü aşacak bir giriş yapılırsa önceki değer korunur.
class GradeInputFormatter extends TextInputFormatter {
  static const int maxGrade = 100;
  static final RegExp _digitsOnly = RegExp(r'^\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!_digitsOnly.hasMatch(text)) return oldValue;
    final int? value = int.tryParse(text);
    if (value == null || value > maxGrade) return oldValue;
    return newValue;
  }
}
