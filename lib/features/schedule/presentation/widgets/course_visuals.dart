import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Ders koduna göre kart ikonu ve rengi.
abstract final class CourseVisuals {
  static IconData iconFor(String courseCode) {
    final code = courseCode.toUpperCase();
    if (code.startsWith('MOB101')) return Icons.flutter_dash_rounded;
    if (code.startsWith('MOB')) return Icons.smartphone_rounded;
    if (code.startsWith('CS')) return Icons.code_rounded;
    if (code.startsWith('CLD')) return Icons.cloud_outlined;
    if (code.startsWith('UX')) return Icons.palette_outlined;
    if (code.startsWith('MAT')) return Icons.functions_rounded;
    return Icons.menu_book_rounded;
  }

  static Color colorFor(String courseCode) {
    final code = courseCode.toUpperCase();
    if (code.startsWith('MOB101')) return AppColors.primaryLight;
    if (code.startsWith('MOB')) return AppColors.secondaryLight;
    if (code.startsWith('CS')) return AppColors.accentDark;
    if (code.startsWith('CLD')) return AppColors.infoBlue;
    if (code.startsWith('UX')) return AppColors.metricPink;
    return AppColors.metricPurple;
  }
}
