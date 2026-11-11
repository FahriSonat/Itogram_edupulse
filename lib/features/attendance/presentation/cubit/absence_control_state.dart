import 'package:equatable/equatable.dart';

import '../../../../core/enums/view_status.dart';
import '../../domain/entities/student_absence_record_entity.dart';
import '../../domain/usecases/evaluate_absence_risk_usecase.dart';

class AbsenceControlState extends Equatable {
  final ViewStatus status;
  final List<StudentAbsenceRecordEntity> records;
  final String? errorMessage;

  const AbsenceControlState({this.status = ViewStatus.initial, this.records = const [], this.errorMessage});

  static const EvaluateAbsenceRiskUseCase _risk = EvaluateAbsenceRiskUseCase();

  List<StudentAbsenceRecordEntity> recordsFor(String studentUid) {
    final list = records.where((r) => r.studentUid == studentUid).toList();
    list.sort((a, b) => b.percentage.compareTo(a.percentage));
    return list;
  }

  /// Öğrencinin genel katılım oranı (%).
  double attendanceRateFor(String studentUid) => _risk.attendanceRate(recordsFor(studentUid));

  List<StudentAbsenceRecordEntity> get criticalRecords => _risk.criticalRecords(records);

  List<StudentAbsenceRecordEntity> criticalFor(String studentUid) =>
      recordsFor(studentUid).where((r) => r.isCritical).toList();

  /// Ders koduna göre gruplanmış kayıtlar (eğitmen görünümü).
  Map<String, List<StudentAbsenceRecordEntity>> get byCourse {
    final map = <String, List<StudentAbsenceRecordEntity>>{};
    for (final r in records) {
      map.putIfAbsent(r.courseName, () => []).add(r);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.percentage.compareTo(a.percentage));
    }
    return map;
  }

  AbsenceControlState copyWith({ViewStatus? status, List<StudentAbsenceRecordEntity>? records, String? errorMessage}) =>
      AbsenceControlState(status: status ?? this.status, records: records ?? this.records, errorMessage: errorMessage);

  @override
  List<Object?> get props => [status, records, errorMessage];
}
