/// Süre hesaplama yardımcıları. Tüm metodlar test edilebilmesi için
/// opsiyonel [now] parametresi alır.
class DateTimeHelper {
  DateTimeHelper._();

  /// Kural 1: QR/PIN geçerlilik süresi (saniye).
  static const int qrPinValiditySeconds = 60;

  /// QR/PIN oluşturulma anından bitiş zamanını üretir.
  static DateTime qrPinExpiry(DateTime createdAt) =>
      createdAt.add(const Duration(seconds: qrPinValiditySeconds));

  /// Kural 1: Kodun süresi dolduysa true.
  /// Sınır: tam [expiresAt] anında henüz geçerlidir, sonrası geçersizdir.
  static bool isQrPinExpired(DateTime expiresAt, {DateTime? now}) =>
      (now ?? DateTime.now()).isAfter(expiresAt);

  /// QR/PIN için kalan saniye (0'ın altına düşmez).
  static int qrPinRemainingSeconds(DateTime expiresAt, {DateTime? now}) {
    final int seconds = expiresAt.difference(now ?? DateTime.now()).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  /// Hedef zamana kalan süre (negatifse Duration.zero).
  static Duration timeUntil(DateTime target, {DateTime? now}) {
    final Duration diff = target.difference(now ?? DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Ödev son teslim tarihi geçti mi? (Kural 2: submittedAt.isAfter(dueDate))
  static bool isPastDue(DateTime dueDate, {DateTime? submittedAt}) =>
      (submittedAt ?? DateTime.now()).isAfter(dueDate);

  /// "SS:DD:SN" biçimi (saat 24'ü geçebilir: 49:05:09).
  static String formatCountdown(Duration duration) {
    final Duration d = duration.isNegative ? Duration.zero : duration;
    final String h = d.inHours.toString().padLeft(2, '0');
    final String m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final String s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// "2g 03:15:10" biçimi (ödev son teslim sayacı için).
  static String formatCountdownWithDays(Duration duration) {
    final Duration d = duration.isNegative ? Duration.zero : duration;
    final int days = d.inDays;
    final Duration rest = d - Duration(days: days);
    final String clock = formatCountdown(rest);
    return days > 0 ? '${days}g $clock' : clock;
  }

  /// Haftalık tekrar eden dersin bir sonraki başlangıç zamanı.
  /// [dayOfWeek]: 1 = Pazartesi ... 7 = Pazar (DateTime.weekday ile aynı).
  static DateTime nextLessonStart({
    required int dayOfWeek,
    required int hour,
    required int minute,
    DateTime? now,
  }) {
    assert(dayOfWeek >= 1 && dayOfWeek <= 7, 'dayOfWeek 1..7 olmalı');
    final DateTime current = now ?? DateTime.now();
    final int dayDiff = (dayOfWeek - current.weekday) % 7;
    DateTime candidate = DateTime(
      current.year,
      current.month,
      current.day + dayDiff,
      hour,
      minute,
    );
    if (!candidate.isAfter(current)) {
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + 7,
        hour,
        minute,
      );
    }
    return candidate;
  }

  /// Derse kalan süre.
  static Duration timeUntilLesson({
    required int dayOfWeek,
    required int hour,
    required int minute,
    DateTime? now,
  }) {
    final DateTime current = now ?? DateTime.now();
    return nextLessonStart(
      dayOfWeek: dayOfWeek,
      hour: hour,
      minute: minute,
      now: current,
    ).difference(current);
  }
}
