import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Represents assignment submission states.
enum SubmissionStatus {
  pending,
  submitted,
  late;

  String get displayName {
    switch (this) {
      case SubmissionStatus.pending:
        return 'Bekliyor';
      case SubmissionStatus.submitted:
        return 'Teslim Edildi';
      case SubmissionStatus.late:
        return 'Gecikti (-10 Ceza)';
    }
  }

  Color get color {
    switch (this) {
      case SubmissionStatus.pending:
        return AppColors.warningAmber;
      case SubmissionStatus.submitted:
        return AppColors.secondaryLight;
      case SubmissionStatus.late:
        return AppColors.lateSubmissionOrange;
    }
  }

  IconData get icon {
    switch (this) {
      case SubmissionStatus.pending:
        return Icons.pending_outlined;
      case SubmissionStatus.submitted:
        return Icons.check_circle_outline_rounded;
      case SubmissionStatus.late:
        return Icons.access_time_filled_rounded;
    }
  }

  String toJson() => name;

  static SubmissionStatus fromJson(String? value) {
    if (value == null) return SubmissionStatus.pending;
    return SubmissionStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SubmissionStatus.pending,
    );
  }
}
