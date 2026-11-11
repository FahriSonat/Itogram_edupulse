import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/letter_grade.dart';

/// [CourseGradeDetailCard] renkli AA / BA / BB / FF rozetli ders not kartıdır.
/// Vize (%40), Final (%60), Bonus, Başarı Notu (Max 100) ve 4.00 katsayısını gösterir; eğitmen düzenler/siler.
class CourseGradeDetailCard extends StatelessWidget {
  final String courseCode;
  final String courseName;
  final int credit;
  final double midtermScore;
  final double finalExamScore;
  final double bonusScore;
  final double totalAverage;
  final LetterGrade letterGrade;
  final bool isInstructor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CourseGradeDetailCard({
    super.key,
    required this.courseCode,
    required this.courseName,
    required this.credit,
    required this.midtermScore,
    required this.finalExamScore,
    this.bonusScore = 0.0,
    required this.totalAverage,
    required this.letterGrade,
    this.isInstructor = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radius16,
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: AppDimensions.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$courseCode • $credit AKTS / Kredi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.p8),
                _buildLetterGradeBadge(isDark),
              ],
            ),
            const SizedBox(height: AppDimensions.p16),
            // Scores Grid Breakdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: AppDimensions.radius12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreColumn('Vize (%40)', midtermScore.toStringAsFixed(0), isDark),
                  _buildScoreColumn('Final (%60)', finalExamScore.toStringAsFixed(0), isDark),
                  if (bonusScore > 0) _buildScoreColumn('Bonus', '+${bonusScore.toStringAsFixed(0)}', isDark),
                  _buildScoreColumn(
                    'Ortalama',
                    totalAverage.toStringAsFixed(1),
                    isDark,
                    isHighlighted: true,
                    highlightColor: AppColors.forLetterGrade(letterGrade),
                  ),
                ],
              ),
            ),
            if (isInstructor) ...[
              const SizedBox(height: AppDimensions.p10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Notu Düzenle', style: TextStyle(fontSize: 12)),
                  ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.criticalAbsenceRed),
                      label: const Text('Sil', style: TextStyle(fontSize: 12, color: AppColors.criticalAbsenceRed)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLetterGradeBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.forLetterGrade(letterGrade).withValues(alpha: isDark ? 0.25 : 0.15),
        borderRadius: AppDimensions.radiusFull,
        border: Border.all(color: AppColors.forLetterGrade(letterGrade), width: 1.2),
      ),
      child: Text(
        '${letterGrade.name} • ${gradePointFor(letterGrade).toStringAsFixed(1)}',
        style: TextStyle(color: AppColors.forLetterGrade(letterGrade), fontWeight: FontWeight.w900, fontSize: 15),
      ),
    );
  }

  Widget _buildScoreColumn(
    String label,
    String value,
    bool isDark, {
    bool isHighlighted = false,
    Color? highlightColor,
  }) {
    // Dar ekranlarda ve büyük yazı boyutunda sütunlar taşmak yerine küçülür.
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: _scoreColumnBody(label, value, isDark, isHighlighted: isHighlighted, highlightColor: highlightColor),
      ),
    );
  }

  Widget _scoreColumnBody(
    String label,
    String value,
    bool isDark, {
    required bool isHighlighted,
    Color? highlightColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: isHighlighted ? highlightColor : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

/// 4.00'lük katsayılar: AA 4.0, BA 3.5, BB 3.0, …, FF 0.0, NA 0.0.
double gradePointFor(LetterGrade grade) => switch (grade) {
  LetterGrade.AA => 4.0,
  LetterGrade.BA => 3.5,
  LetterGrade.BB => 3.0,
  LetterGrade.CB => 2.5,
  LetterGrade.CC => 2.0,
  LetterGrade.DC => 1.5,
  LetterGrade.DD => 1.0,
  LetterGrade.FD => 0.5,
  LetterGrade.FF => 0.0,
  LetterGrade.NA => 0.0,
};
