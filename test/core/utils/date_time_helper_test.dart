// Geliştirici 1 (Fahri) — lib/core/utils/date_time_helper.dart testleri.
// Kural 1 (60 sn QR/PIN), Kural 2 (ödev son teslim) ve derse kalan süre.
// Tüm hesaplar sabit bir "now" ile yapılır; testler saate bağlı değildir.

import 'package:flutter_test/flutter_test.dart';
import 'package:itogram_edupulse/core/utils/date_time_helper.dart';

void main() {
  // 13 Kasım 2026 Cuma 10:00:00 (Demo Day)
  final DateTime friday = DateTime(2026, 11, 13, 10);

  group('Kural 1 — 60 saniyelik QR/PIN', () {
    test('geçerlilik süresi 60 saniyedir', () {
      expect(DateTimeHelper.qrPinValiditySeconds, 60);
      expect(DateTimeHelper.qrPinExpiry(friday), friday.add(const Duration(seconds: 60)));
    });

    test('59. saniyede kod geçerli, 61. saniyede süresi dolmuş', () {
      final expiresAt = DateTimeHelper.qrPinExpiry(friday);
      expect(DateTimeHelper.isQrPinExpired(expiresAt, now: friday.add(const Duration(seconds: 59))), isFalse);
      expect(DateTimeHelper.isQrPinExpired(expiresAt, now: friday.add(const Duration(seconds: 61))), isTrue);
    });

    test('tam 60. saniye (sınır) hâlâ geçerlidir', () {
      final expiresAt = DateTimeHelper.qrPinExpiry(friday);
      expect(DateTimeHelper.isQrPinExpired(expiresAt, now: expiresAt), isFalse);
      expect(
        DateTimeHelper.isQrPinExpired(expiresAt, now: expiresAt.add(const Duration(milliseconds: 1))),
        isTrue,
      );
    });

    test('kalan saniye doğru hesaplanır ve 0\'ın altına düşmez', () {
      final expiresAt = DateTimeHelper.qrPinExpiry(friday);
      expect(DateTimeHelper.qrPinRemainingSeconds(expiresAt, now: friday), 60);
      expect(DateTimeHelper.qrPinRemainingSeconds(expiresAt, now: friday.add(const Duration(seconds: 45))), 15);
      expect(DateTimeHelper.qrPinRemainingSeconds(expiresAt, now: friday.add(const Duration(minutes: 5))), 0);
    });
  });

  group('Kural 2 — isPastDue (ödev son teslim)', () {
    test('son teslimden önce teslim gecikmiş sayılmaz', () {
      expect(DateTimeHelper.isPastDue(friday, submittedAt: friday.subtract(const Duration(minutes: 1))), isFalse);
    });

    test('tam son teslim anında teslim gecikmiş sayılmaz', () {
      expect(DateTimeHelper.isPastDue(friday, submittedAt: friday), isFalse);
    });

    test('son teslimden 1 saniye sonra teslim gecikmiştir', () {
      expect(DateTimeHelper.isPastDue(friday, submittedAt: friday.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('timeUntil', () {
    test('gelecekteki hedefe kalan süre', () {
      expect(DateTimeHelper.timeUntil(friday.add(const Duration(hours: 2)), now: friday), const Duration(hours: 2));
    });

    test('geçmiş hedef için Duration.zero', () {
      expect(DateTimeHelper.timeUntil(friday.subtract(const Duration(hours: 2)), now: friday), Duration.zero);
    });
  });

  group('Geri sayım biçimleri', () {
    test('formatCountdown "SS:DD:SN" üretir', () {
      expect(DateTimeHelper.formatCountdown(const Duration(hours: 1, minutes: 5, seconds: 9)), '01:05:09');
      expect(DateTimeHelper.formatCountdown(const Duration(seconds: 59)), '00:00:59');
      expect(DateTimeHelper.formatCountdown(Duration.zero), '00:00:00');
    });

    test('formatCountdown 24 saati aşabilir', () {
      expect(DateTimeHelper.formatCountdown(const Duration(hours: 49, minutes: 5, seconds: 9)), '49:05:09');
    });

    test('negatif süre 00:00:00 gösterilir', () {
      expect(DateTimeHelper.formatCountdown(const Duration(seconds: -30)), '00:00:00');
      expect(DateTimeHelper.formatCountdownWithDays(const Duration(days: -1)), '00:00:00');
    });

    test('formatCountdownWithDays gün önekini ekler', () {
      expect(
        DateTimeHelper.formatCountdownWithDays(const Duration(days: 2, hours: 3, minutes: 15, seconds: 10)),
        '2g 03:15:10',
      );
      expect(DateTimeHelper.formatCountdownWithDays(const Duration(hours: 5)), '05:00:00');
    });
  });

  group('nextLessonStart / timeUntilLesson (Modül 1.1 — derse kalan süre)', () {
    test('aynı gün, saati henüz gelmemiş ders bugün başlar', () {
      final next = DateTimeHelper.nextLessonStart(dayOfWeek: DateTime.friday, hour: 13, minute: 30, now: friday);
      expect(next, DateTime(2026, 11, 13, 13, 30));
    });

    test('aynı gün, saati geçmiş ders bir sonraki haftaya kayar', () {
      final next = DateTimeHelper.nextLessonStart(dayOfWeek: DateTime.friday, hour: 9, minute: 0, now: friday);
      expect(next, DateTime(2026, 11, 20, 9));
    });

    test('tam başlama anındaysa bir sonraki haftayı verir', () {
      final next = DateTimeHelper.nextLessonStart(dayOfWeek: DateTime.friday, hour: 10, minute: 0, now: friday);
      expect(next, DateTime(2026, 11, 20, 10));
    });

    test('ileriki bir gün (Cuma → Pazartesi)', () {
      final next = DateTimeHelper.nextLessonStart(dayOfWeek: DateTime.monday, hour: 8, minute: 30, now: friday);
      expect(next, DateTime(2026, 11, 16, 8, 30));
    });

    test('ay sonunu doğru geçer (30 Kasım Pazartesi → 1 Aralık Salı)', () {
      final monday = DateTime(2026, 11, 30, 18);
      final next = DateTimeHelper.nextLessonStart(dayOfWeek: DateTime.tuesday, hour: 9, minute: 0, now: monday);
      expect(next, DateTime(2026, 12, 1, 9));
    });

    test('timeUntilLesson kalan süreyi verir', () {
      expect(
        DateTimeHelper.timeUntilLesson(dayOfWeek: DateTime.friday, hour: 10, minute: 45, now: friday),
        const Duration(minutes: 45),
      );
    });
  });
}
