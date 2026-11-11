/// [DateTimeHelper] Türkçe tarih biçimlendirme ve ders saati hesaplamaları.
///
/// `intl` paketine bağımlı olmadan, uygulamanın ihtiyaç duyduğu biçimleri üretir.
abstract final class DateTimeHelper {
  static const List<String> monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static const List<String> shortMonthNames = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  /// 1 = Pazartesi … 7 = Pazar
  static const List<String> dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  static String dayName(int dayOfWeek) => dayNames[(dayOfWeek - 1).clamp(0, 6)];

  static String two(int v) => v.toString().padLeft(2, '0');

  /// 12 Kasım 2026
  static String formatDate(DateTime d) => '${d.day} ${monthNames[d.month - 1]} ${d.year}';

  /// 12 Kas 2026, 14:30
  static String formatDateTime(DateTime d) =>
      '${d.day} ${shortMonthNames[d.month - 1]} ${d.year}, ${two(d.hour)}:${two(d.minute)}';

  /// 14:30
  static String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// "az önce", "5 dk önce", "3 saat önce", "2 gün önce"
  static String relative(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.isNegative || diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return formatDate(d);
  }

  /// "10:30" → (10, 30). Geçersiz girdide null döner.
  static (int hour, int minute)? parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    if (h > 23 || m > 59) return null;
    return (h, m);
  }

  /// Saat metnini dakikaya çevirir (sıralama için). Geçersizse 0.
  static int minutesOf(String time) {
    final t = parseTime(time);
    return t == null ? 0 : t.$1 * 60 + t.$2;
  }

  /// Haftalık tekrar eden bir dersin [now]'dan sonraki ilk başlangıç anı.
  /// Ders bugün ve henüz başlamadıysa bugünü döndürür.
  static DateTime nextOccurrence({required int dayOfWeek, required String startTime, DateTime? now}) {
    final ref = now ?? DateTime.now();
    final t = parseTime(startTime) ?? (0, 0);
    var daysAhead = (dayOfWeek - ref.weekday) % 7;
    var candidate = DateTime(ref.year, ref.month, ref.day + daysAhead, t.$1, t.$2);
    if (!candidate.isAfter(ref)) {
      daysAhead += 7;
      candidate = DateTime(ref.year, ref.month, ref.day + daysAhead, t.$1, t.$2);
    }
    return candidate;
  }

  /// Bugünün belirtilen saatteki anı.
  static DateTime todayAt(String time, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final t = parseTime(time) ?? (0, 0);
    return DateTime(ref.year, ref.month, ref.day, t.$1, t.$2);
  }
}
