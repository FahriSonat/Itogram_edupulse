import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Represents attendance presence states for students during a live lecture session.
enum AttendanceStatus {
  present,
  absent,
  excused;

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Gelen';
      case AttendanceStatus.absent:
        return 'Gelmeyen';
      case AttendanceStatus.excused:
        return 'İzinli';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return AppColors.secondaryLight;
      case AttendanceStatus.absent:
        return AppColors.criticalAbsenceRed;
      case AttendanceStatus.excused:
        return AppColors.accentLight;
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present:
        return Icons.check_circle_outline_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_outlined;
      case AttendanceStatus.excused:
        return Icons.info_outline_rounded;
    }
  }

  String toJson() => name;

  static AttendanceStatus fromJson(String? value) {
    if (value == null) return AttendanceStatus.absent;
    return AttendanceStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AttendanceStatus.absent,
    );
  }
}
