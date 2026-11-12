enum SubmissionStatus {
  pending,
  submitted,
  graded,
  late,
  missing,
}

extension SubmissionStatusX on SubmissionStatus {
  String toJson() => name;

  String get label {
    switch (this) {
      case SubmissionStatus.pending:
        return 'Bekliyor';
      case SubmissionStatus.submitted:
        return 'Teslim Edildi';
      case SubmissionStatus.graded:
        return 'Notlandırıldı';
      case SubmissionStatus.late:
        return 'Gecikti';
      case SubmissionStatus.missing:
        return 'Eksik';
    }
  }

  static SubmissionStatus fromJson(String? value) {
    return SubmissionStatus.values.firstWhere(
      (SubmissionStatus status) => status.name == value,
      orElse: () => SubmissionStatus.pending,
    );
  }
}
