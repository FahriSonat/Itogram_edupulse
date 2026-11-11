import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Distinguishes announcement and event types in EduPulse.
enum AnnouncementType {
  seminar,
  hackathon,
  holiday,
  crisis;

  String get displayName {
    switch (this) {
      case AnnouncementType.seminar:
        return 'Seminer';
      case AnnouncementType.hackathon:
        return 'Hackathon';
      case AnnouncementType.holiday:
        return 'Resmi Tatil';
      case AnnouncementType.crisis:
        return 'Anlık Kriz';
    }
  }

  Color get color {
    switch (this) {
      case AnnouncementType.seminar:
        return AppColors.primaryLight;
      case AnnouncementType.hackathon:
        return AppColors.accentDark;
      case AnnouncementType.holiday:
        return AppColors.secondaryLight;
      case AnnouncementType.crisis:
        return AppColors.criticalAbsenceRed;
    }
  }

  IconData get icon {
    switch (this) {
      case AnnouncementType.seminar:
        return Icons.school_outlined;
      case AnnouncementType.hackathon:
        return Icons.code_rounded;
      case AnnouncementType.holiday:
        return Icons.celebration_outlined;
      case AnnouncementType.crisis:
        return Icons.warning_amber_rounded;
    }
  }

  String toJson() => name;

  static AnnouncementType fromJson(String? value) {
    if (value == null) return AnnouncementType.seminar;
    return AnnouncementType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AnnouncementType.seminar,
    );
  }
}
