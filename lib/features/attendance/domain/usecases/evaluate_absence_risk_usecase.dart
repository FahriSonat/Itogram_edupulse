import '../entities/student_absence_record_entity.dart';

/// Kural 3 (Devamsızlık Uyarı Motoru): %20 sınırına ulaşan öğrencileri belirler.
class EvaluateAbsenceRiskUseCase {
  const EvaluateAbsenceRiskUseCase();

  /// Kritik risk listesindeki kayıtlar (en yüksek oran en üstte).
  List<StudentAbsenceRecordEntity> criticalRecords(Iterable<StudentAbsenceRecordEntity> records) {
    final list = records.where((r) => r.isCritical).toList();
    list.sort((a, b) => b.percentage.compareTo(a.percentage));
    return list;
  }

  /// Öğrencinin tüm derslerdeki genel katılım oranı (%0–100).
  double attendanceRate(Iterable<StudentAbsenceRecordEntity> studentRecords) {
    var absent = 0;
    var total = 0;
    for (final r in studentRecords) {
      absent += r.absentHours;
      total += r.totalHours;
    }
    if (total == 0) return 100;
    return ((total - absent) / total * 100).clamp(0, 100).toDouble();
  }

  /// Devamsızlık eklendikten sonra kaydın kritik eşiği yeni geçip geçmediği.
  bool crossedCriticalThreshold(StudentAbsenceRecordEntity before, StudentAbsenceRecordEntity after) =>
      !before.isCritical && after.isCritical;
}
