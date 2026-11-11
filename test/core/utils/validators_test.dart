import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('dolu alan geçerlidir', () {
      expect(Validators.required('Merve'), isNull);
    });

    test('null, boş ve sadece boşluk geçersizdir', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('hata mesajında alan adı geçer', () {
      expect(
        Validators.required('', fieldName: 'Ad-Soyad'),
        contains('Ad-Soyad'),
      );
    });
  });

  group('Validators.studentNo', () {
    test('6-12 haneli rakam geçerlidir', () {
      expect(Validators.studentNo('123456'), isNull);
      expect(Validators.studentNo('202612345678'), isNull);
      expect(Validators.studentNo(' 20261234 '), isNull);
    });

    test('boş numara geçersizdir', () {
      expect(Validators.studentNo(null), isNotNull);
      expect(Validators.studentNo(''), isNotNull);
    });

    test('harf veya sembol içeren numara geçersizdir', () {
      expect(Validators.studentNo('2026A123'), isNotNull);
      expect(Validators.studentNo('2026-1234'), isNotNull);
    });

    test('çok kısa veya çok uzun numara geçersizdir', () {
      expect(Validators.studentNo('12345'), isNotNull);
      expect(Validators.studentNo('1234567890123'), isNotNull);
    });
  });

  group('Validators.email', () {
    test('geçerli e-postalar kabul edilir', () {
      expect(Validators.email('ogrenci@softito.com'), isNull);
      expect(Validators.email('ad.soyad+test@uni.edu.tr'), isNull);
    });

    test('boş e-posta geçersizdir', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('hatalı formatlar reddedilir', () {
      expect(Validators.email('ogrenci'), isNotNull);
      expect(Validators.email('ogrenci@'), isNotNull);
      expect(Validators.email('@softito.com'), isNotNull);
      expect(Validators.email('ogrenci@softito'), isNotNull);
      expect(Validators.email('ogr enci@softito.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('güçlü şifre geçerlidir', () {
      expect(Validators.password('Edupulse1'), isNull);
    });

    test('boş şifre geçersizdir', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('8 karakterden kısa şifre geçersizdir', () {
      expect(Validators.password('Edu1'), isNotNull);
    });

    test('büyük harf, küçük harf veya rakam eksikse geçersizdir', () {
      expect(Validators.password('edupulse1'), isNotNull);
      expect(Validators.password('EDUPULSE1'), isNotNull);
      expect(Validators.password('Edupulsee'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('aynı şifreler eşleşir', () {
      expect(Validators.confirmPassword('Edupulse1', 'Edupulse1'), isNull);
    });

    test('farklı şifreler eşleşmez', () {
      expect(Validators.confirmPassword('Edupulse1', 'Edupulse2'), isNotNull);
    });

    test('boş tekrar alanı geçersizdir', () {
      expect(Validators.confirmPassword(null, 'Edupulse1'), isNotNull);
      expect(Validators.confirmPassword('', 'Edupulse1'), isNotNull);
    });
  });

  group('Validators.grade', () {
    test('0-100 arası notlar geçerlidir (sınırlar dahil)', () {
      expect(Validators.grade('0'), isNull);
      expect(Validators.grade('55'), isNull);
      expect(Validators.grade('100'), isNull);
      expect(Validators.grade('85.5'), isNull);
      expect(Validators.grade('85,5'), isNull);
    });

    test('boş not geçersizdir', () {
      expect(Validators.grade(null), isNotNull);
      expect(Validators.grade(''), isNotNull);
    });

    test('sayı olmayan not geçersizdir', () {
      expect(Validators.grade('AA'), isNotNull);
    });

    test('aralık dışındaki notlar geçersizdir', () {
      expect(Validators.grade('-1'), isNotNull);
      expect(Validators.grade('100.1'), isNotNull);
      expect(Validators.grade('150'), isNotNull);
    });
  });
}
