import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// [ForumQuestionCard] kampüs forumu akışındaki soru özet kartıdır.
///
/// Ders / konu etiketleri, yazar, tarih, cevap sayısı ve **Çözüldü** rozeti
/// içerir. [imageUrl] verilirse fotoğraf küçük önizlemesi [heroTag] ile
/// `Hero` sarılı çizilir; detay sayfası aynı etiketle büyütme animasyonu yapar.
class ForumQuestionCard extends StatelessWidget {
  const ForumQuestionCard({
    super.key,
    required this.authorName,
    required this.courseTag,
    required this.topicTag,
    required this.questionText,
    required this.createdAt,
    this.isResolved = false,
    this.hasImage = false,
    this.imageUrl,
    this.heroTag,
    this.answerCount = 0,
    this.onTap,
    this.onImageTap,
  });

  final String authorName;
  final String courseTag;
  final String topicTag;
  final String questionText;
  final DateTime createdAt;
  final bool isResolved;
  final bool hasImage;

  /// Soru fotoğrafının (Storage) adresi; verilirse önizleme gösterilir.
  final String? imageUrl;

  /// Fotoğraf `Hero` etiketi (ör. `forum_image_<questionId>`).
  final Object? heroTag;
  final int answerCount;
  final VoidCallback? onTap;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p6),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radius16,
        side: BorderSide(
          color: isResolved
              ? AppColors.resolvedGreen.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isResolved ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.radius16,
        child: Padding(
          padding: AppDimensions.paddingAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: AppDimensions.radiusFull,
                      ),
                      child: Text(
                        courseTag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '#$topicTag',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted),
                    ),
                  ),
                  if (isResolved) ...[const SizedBox(width: 6), const _ResolvedBadge()],
                ],
              ),
              const SizedBox(height: AppDimensions.p10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      questionText,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                    const SizedBox(width: AppDimensions.p12),
                    _Thumbnail(url: imageUrl!, heroTag: heroTag, onTap: onImageTap),
                  ],
                ],
              ),
              const SizedBox(height: AppDimensions.p12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: primary.withValues(alpha: 0.2),
                    child: Text(
                      authorName.isNotEmpty ? authorName.characters.first.toUpperCase() : 'Ö',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}',
                    style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                  const Spacer(),
                  if (hasImage) ...[Icon(Icons.image_outlined, size: 14, color: muted), const SizedBox(width: 8)],
                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: muted),
                  const SizedBox(width: 4),
                  Text(
                    '$answerCount',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolvedBadge extends StatelessWidget {
  const _ResolvedBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.resolvedGreen.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: AppDimensions.radiusFull,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.resolvedGreen),
          SizedBox(width: 4),
          Text(
            'Çözüldü',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.resolvedGreen),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.heroTag, required this.onTap});

  final String url;
  final Object? heroTag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = ClipRRect(
      borderRadius: AppDimensions.radius12,
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        semanticLabel: 'Soru fotoğrafı',
        errorBuilder: (context, error, stackTrace) => Container(
          width: 64,
          height: 64,
          color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
          child: const Icon(Icons.broken_image_outlined, size: 20),
        ),
      ),
    );
    final child = heroTag == null ? image : Hero(tag: heroTag!, child: image);
    return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
  }
}
