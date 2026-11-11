import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';

/// [LoadingStateView] — 4 Durum Kalkanı: **Loading**.
///
/// Varsayılan olarak içerik kartlarının yerini tutan **shimmer iskelet**
/// animasyonu gösterir ([isShimmer] = true). Küçük alanlarda veya tam ekran
/// oturum kontrolünde `isShimmer: false` ile dairesel gösterge + mesaj çizilir.
/// İskelet, verilen alana sığdığı kadar satır çizer ve hiçbir boyutta
/// `RenderFlex overflow` üretmez.
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.message, this.isShimmer = true, this.skeletonItemCount = 4});

  final String? message;
  final bool isShimmer;

  /// Shimmer modunda çizilecek en fazla iskelet kartı sayısı.
  final int skeletonItemCount;

  @override
  Widget build(BuildContext context) {
    final label = message ?? AppStrings.loadingMessage;
    if (isShimmer) {
      return Semantics(
        label: label,
        liveRegion: true,
        child: ExcludeSemantics(child: _ShimmerSkeletonList(itemCount: skeletonItemCount)),
      );
    }
    return _SpinnerLoading(message: label);
  }
}

class _SpinnerLoading extends StatelessWidget {
  const _SpinnerLoading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Center(
      child: SingleChildScrollView(
        padding: AppDimensions.paddingAll24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(strokeWidth: 3.5, valueColor: AlwaysStoppedAnimation<Color>(primary)),
              ),
            ),
            const SizedBox(height: AppDimensions.p16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Soldan sağa kayan parlama (shimmer) ile iskelet kart listesi.
class _ShimmerSkeletonList extends StatefulWidget {
  const _ShimmerSkeletonList({required this.itemCount});

  final int itemCount;

  @override
  State<_ShimmerSkeletonList> createState() => _ShimmerSkeletonListState();
}

class _ShimmerSkeletonListState extends State<_ShimmerSkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1A2440) : const Color(0xFFE8EDF5);
    final highlight = isDark ? const Color(0xFF2A3A63) : const Color(0xFFF8FAFD);
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.dividerLight;

    // Kaydırılamaz kaydırma alanı: içerik alana sığmazsa kırpılır, taşma hatası üretmez.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Parlama yalnızca "kemik" (bone) şekillerine uygulanır: ShaderMask'ın
          // çocuğunda kart zemini yoktur, sadece opak iskelet çizgileri vardır.
          Shader shimmer(Rect bounds) => LinearGradient(
            begin: Alignment(-3.0 + 4 * t, 0),
            end: Alignment(-1.0 + 4 * t, 0),
            colors: [base, highlight, base],
          ).createShader(bounds);

          return Column(
            children: [
              for (var i = 0; i < widget.itemCount; i++)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: AppDimensions.p6),
                  padding: AppDimensions.paddingAll16,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: AppDimensions.radius16,
                    border: Border.all(color: border),
                  ),
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: shimmer,
                    child: Row(
                      children: [
                        _bone(base, width: 44, height: 44, radius: AppDimensions.radius12),
                        const SizedBox(width: AppDimensions.p12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: i.isEven ? 0.7 : 0.55,
                                child: _bone(base, height: 12),
                              ),
                              const SizedBox(height: AppDimensions.p8),
                              FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: 0.9,
                                child: _bone(base, height: 10),
                              ),
                              const SizedBox(height: AppDimensions.p6),
                              FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: 0.4,
                                child: _bone(base, height: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _bone(Color color, {double? width, required double height, BorderRadius radius = AppDimensions.radius4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: radius),
    );
  }
}
