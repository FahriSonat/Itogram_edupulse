import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// [StorageUploadProgressBar] canlı Firebase Storage yükleme barıdır: `UploadTask.snapshotEvents`
/// akışından gelen [progress] (0.0 → 1.0) değerini, dosya adını ve yükleme / hata durumunu gösterir.
class StorageUploadProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String fileName;
  final String? fileSize;
  final bool isUploading;
  final bool isCompleted;
  final String? errorMessage;
  final VoidCallback? onCancel;

  const StorageUploadProgressBar({
    super.key,
    required this.progress,
    required this.fileName,
    this.fileSize,
    this.isUploading = true,
    this.isCompleted = false,
    this.errorMessage,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final percentage = (progress * 100).clamp(0, 100).toInt();

    final Color statusColor = errorMessage != null
        ? AppColors.criticalAbsenceRed
        : (isCompleted ? AppColors.secondaryLight : (isDark ? AppColors.primaryDark : AppColors.primaryLight));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.p8),
      padding: AppDimensions.paddingAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: AppDimensions.radius16,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.p8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppDimensions.radius8,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : (errorMessage != null ? Icons.error_outline_rounded : Icons.file_present_rounded),
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppDimensions.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fileSize != null)
                      Text(
                        fileSize!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.p8),
              Text(
                isCompleted ? '%100' : '%$percentage',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
              ),
              if (isUploading && !isCompleted && onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onCancel,
                  tooltip: 'Yüklemeyi İptal Et',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.p10),
          ClipRRect(
            borderRadius: AppDimensions.radiusFull,
            child: LinearProgressIndicator(
              value: isCompleted ? 1.0 : progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              errorMessage!,
              style: const TextStyle(color: AppColors.criticalAbsenceRed, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
