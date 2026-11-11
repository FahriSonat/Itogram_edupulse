import 'package:flutter/services.dart';

/// [AppInputFormatters] form alanlarında ortak kullanılan giriş biçimlendiricileri.
abstract final class AppInputFormatters {
  static final TextInputFormatter digitsOnly = FilteringTextInputFormatter.digitsOnly;

  /// Kural 1: 4 haneli PIN.
  static final List<TextInputFormatter> pin = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(4),
  ];

  /// Öğrenci / sicil numarası (en fazla 12 rakam).
  static final List<TextInputFormatter> studentNo = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(12),
  ];

  /// 0-100 arası not (en fazla bir ondalık basamak).
  static final List<TextInputFormatter> score = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([.,]\d?)?')),
    const ScoreRangeFormatter(),
  ];
}

/// 100'ün üzerindeki not girişlerini engeller.
class ScoreRangeFormatter extends TextInputFormatter {
  const ScoreRangeFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final parsed = double.tryParse(newValue.text.replaceAll(',', '.'));
    if (parsed == null || parsed > 100) return oldValue;
    return newValue;
  }
}
