import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/utils/input_formatters.dart';

TextEditingValue _value(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

String _apply(TextInputFormatter formatter, String oldText, String newText) =>
    formatter.formatEditUpdate(_value(oldText), _value(newText)).text;

void main() {
  group('StudentNoInputFormatter', () {
    final StudentNoInputFormatter formatter = StudentNoInputFormatter();

    test('rakamlar olduğu gibi kabul edilir', () {
      expect(_apply(formatter, '2026', '20261'), '20261');
    });

    test('harf ve semboller atılır', () {
      expect(_apply(formatter, '', '20a26-1b'), '20261');
    });

    test('12 haneden fazlası kesilir', () {
      expect(_apply(formatter, '', '12345678901234'), '123456789012');
    });

    test('düzeltilen metinde imleç sona alınır', () {
      final TextEditingValue result =
          formatter.formatEditUpdate(_value(''), _value('1a2'));
      expect(result.selection.baseOffset, 2);
    });
  });

  group('PinCodeInputFormatter', () {
    final PinCodeInputFormatter formatter = PinCodeInputFormatter();

    test('4 haneli PIN kabul edilir', () {
      expect(_apply(formatter, '123', '1234'), '1234');
    });

    test('5. hane girilemez', () {
      expect(_apply(formatter, '1234', '12345'), '1234');
    });

    test('rakam olmayan karakterler atılır', () {
      expect(_apply(formatter, '', '1a2b'), '12');
    });

    test('alan silinip boşaltılabilir', () {
      expect(_apply(formatter, '1', ''), '');
    });
  });

  group('GradeInputFormatter', () {
    final GradeInputFormatter formatter = GradeInputFormatter();

    test('0-100 arası değerler kabul edilir', () {
      expect(_apply(formatter, '', '0'), '0');
      expect(_apply(formatter, '8', '85'), '85');
      expect(_apply(formatter, '10', '100'), '100');
    });

    test('100 üzeri değer yazılamaz, eski değer korunur', () {
      expect(_apply(formatter, '10', '101'), '10');
      expect(_apply(formatter, '100', '1000'), '100');
    });

    test('harf, eksi ve nokta yazılamaz', () {
      expect(_apply(formatter, '8', '8a'), '8');
      expect(_apply(formatter, '', '-5'), '');
      expect(_apply(formatter, '85', '85.'), '85');
    });

    test('alan silinip boşaltılabilir', () {
      expect(_apply(formatter, '85', ''), '');
    });
  });
}
