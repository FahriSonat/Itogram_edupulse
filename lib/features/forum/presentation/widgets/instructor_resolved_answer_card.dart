import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';

/// [InstructorResolvedAnswerCard] forum cevap kartıdır.
///
/// Eğitmenin onayladığı cevap (`isInstructorApproved`) **"Çözüldü / Eğitmen
/// Onaylı Cevap"** yeşil vurgusuyla çizilir. Eğitmen görünümünde
/// ([canMarkAsResolved]) diğer cevaplarda "Çözüldü Olarak İşaretle" butonu bulunur.
class InstructorResolvedAnswerCard extends StatelessWidget {
  const InstructorResolvedAnswerCard({
    super.key,
    required this.responderName,
    required this.responderRole,
    required this.answerText,
    required this.answeredAt,
    this.isInstructorApproved = false,
    this.canMarkAsResolved = false,
    this.onMarkAsResolved,
  });

  static const String approvedLabel = 'Çözüldü / Eğitmen Onaylı Cevap';

  final String responderName;
  final UserRole responderRole;
  final String answerText;
  final DateTime answeredAt;
  final bool isInstructorApproved;
  final bool canMarkAsResolved;
  final VoidCallback? onMarkAsResolved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isInstructor = responderRole == UserRole.instructor;
    final roleColor = isInstructor ? AppColors.instructorRoleBadge : AppColors.studentRoleBadge;

    final cardBorderColor = isInstructorApproved
        ? AppColors.resolvedGreen
        : (isDark ? AppColors.borderDark : AppColors.borderLight);
    final cardBgColor = isInstructorApproved
        ? AppColors.resolvedGreen.withValues(alpha: isDark ? 0.15 : 0.06)
        : (isDark ? AppColors.cardDark : Colors.white);

    String two(int v) => v.toString().padLeft(2, '0');
    final dateText =
        '${two(answeredAt.day)}.${two(answeredAt.month)}.${answeredAt.year} - '
        '${two(answeredAt.hour)}:${two(answeredAt.minute)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      padding: AppDimensions.paddingAll16,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: AppDimensions.radius16,
        border: Border.all(color: cardBorderColor, width: isInstructorApproved ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isInstructorApproved) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.resolvedGreen, borderRadius: AppDimensions.radiusFull),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      approvedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p10),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isInstructorApproved ? AppColors.resolvedGreen : roleColor,
                child: Text(
                  responderName.isNotEmpty ? responderName.characters.first.toUpperCase() : 'C',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppDimensions.p10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            responderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            borderRadius: AppDimensions.radius4,
                          ),
                          child: Text(
                            AppStrings.roleName(responderRole),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Color.lerp(roleColor, Colors.white, 0.35) : roleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p12),
          Text(answerText, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
          if (canMarkAsResolved && !isInstructorApproved && onMarkAsResolved != null) ...[
            const SizedBox(height: AppDimensions.p8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: onMarkAsResolved,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.resolvedGreen),
                label: const Text(
                  'Çözüldü Olarak İşaretle',
                  style: TextStyle(color: AppColors.resolvedGreen, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
