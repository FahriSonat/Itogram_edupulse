// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Represents the 4-level letter grading scale specified in EduPulse.
/// Coefficients: AA = 4.0, BA = 3.5, BB = 3.0, FF = 0.0.
enum LetterGrade {
  AA(coefficient: 4.0, minScore: 90.0),
  BA(coefficient: 3.5, minScore: 80.0),
  BB(coefficient: 3.0, minScore: 70.0),
  FF(coefficient: 0.0, minScore: 0.0);

  final double coefficient;
  final double minScore;

  const LetterGrade({required this.coefficient, required this.minScore});

  Color get color {
    switch (this) {
      case LetterGrade.AA:
        return AppColors.gradeAA;
      case LetterGrade.BA:
        return AppColors.gradeBA;
      case LetterGrade.BB:
        return AppColors.gradeBB;
      case LetterGrade.FF:
        return AppColors.gradeFF;
    }
  }

  bool get isPassing => this != LetterGrade.FF;

  static LetterGrade fromScore(double score) {
    if (score >= 90.0) return LetterGrade.AA;
    if (score >= 80.0) return LetterGrade.BA;
    if (score >= 70.0) return LetterGrade.BB;
    return LetterGrade.FF;
  }

  String toJson() => name;

  static LetterGrade fromJson(String? value) {
    if (value == null) return LetterGrade.FF;
    return LetterGrade.values.firstWhere(
      (g) => g.name.toUpperCase() == value.toUpperCase(),
      orElse: () => LetterGrade.FF,
    );
  }
}
