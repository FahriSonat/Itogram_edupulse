import 'package:equatable/equatable.dart';

import '../../../../core/enums/view_status.dart';
import '../../../schedule/domain/entities/course_schedule_entity.dart';
import '../../domain/entities/student_absence_record_entity.dart';

/// Sınıf Vize-Final çan eğrisi için özet istatistik.
class GradeDistribution extends Equatable {
  const GradeDistribution({
    required this.midtermAverage,
    required this.finalAverage,
    required this.midtermStd,
    required this.finalStd,
    required this.sampleSize,
  });

  static const GradeDistribution empty =
      GradeDistribution(midtermAverage: 0, finalAverage: 0, midtermStd: 0, finalStd: 0, sampleSize: 0);

  final double midtermAverage;
  final double finalAverage;
  final double midtermStd;
  final double finalStd;
  final int sampleSize;

  @override
  List<Object?> get props => <Object?>[midtermAverage, finalAverage, midtermStd, finalStd, sampleSize];
}

class AbsenceControlState extends Equatable {
  const AbsenceControlState({
    this.status = ViewStatus.initial,
    this.courses = const <CourseScheduleEntity>[],
    this.selectedCourseId,
    this.records = const <StudentAbsenceRecordEntity>[],
    this.distribution = GradeDistribution.empty,
    this.errorMessage,
    this.actionMessage,
  });

  final ViewStatus status;
  final List<CourseScheduleEntity> courses;
  final String? selectedCourseId;

  /// Öğrenci: kendi ders bazlı kayıtları. Eğitmen: seçili dersin tüm öğrencileri.
  final List<StudentAbsenceRecordEntity> records;

  final GradeDistribution distribution;
  final String? errorMessage;
  final String? actionMessage;

  /// Kural 3: %20 ve üzeri devamsızlık → Kritik Risk (Kırmızı Liste).
  List<StudentAbsenceRecordEntity> get criticalRecords =>
      records.where((r) => r.isCriticalRisk || r.absencePercentage >= 20).toList()
        ..sort((a, b) => b.absencePercentage.compareTo(a.absencePercentage));

  AbsenceControlState copyWith({
    ViewStatus? status,
    List<CourseScheduleEntity>? courses,
    String? selectedCourseId,
    List<StudentAbsenceRecordEntity>? records,
    GradeDistribution? distribution,
    String? errorMessage,
    String? actionMessage,
  }) {
    return AbsenceControlState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      selectedCourseId: selectedCourseId ?? this.selectedCourseId,
      records: records ?? this.records,
      distribution: distribution ?? this.distribution,
      errorMessage: errorMessage,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[status, courses, selectedCourseId, records, distribution, errorMessage, actionMessage];
}
