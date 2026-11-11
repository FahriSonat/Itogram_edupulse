import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// [EduCard] EduPulse'un ortak kart yüzeyidir; mockup'taki kart dokusunu tek yerde toplar.
///
/// - Aydınlık: kenarlıksız beyaz (veya [tint] ile pastel) zemin + çok yumuşak gölge.
/// - Karanlık: lacivert zemin, [glowColor] tonunda ince kenarlık; [highlighted]
///   veya [gradient] verildiğinde mavi hale (glow).
/// - [gradient]: "Yoklamayı Başlat", "Sıradaki Ders (Dark)" gibi tam renkli kartlar.
class EduCard extends StatelessWidget {
  const EduCard({
    super.key,
    required this.child,
    this.padding = AppDimensions.paddingAll16,
    this.margin,
    this.borderRadius = AppDimensions.radius20,
    this.onTap,
    this.tint,
    this.glowColor,
    this.gradient,
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  /// Aydınlık temada kart zemini (pastel). Karanlık temada yok sayılır.
  final Color? tint;

  /// Karanlık temada kenarlık/hale rengi. Aydınlık temada gölge tonunu belirler.
  final Color? glowColor;

  final Gradient? gradient;

  /// Karanlık temada güçlü hale + belirgin kenarlık (seçili/öne çıkan kart).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = glowColor ?? AppColors.glowBlue;
    final hasGradient = gradient != null;

    final Color? background = hasGradient ? null : (isDark ? AppColors.cardDark : (tint ?? AppColors.cardLight));

    final BoxBorder? border;
    if (isDark) {
      border = Border.all(
        color: highlighted
            ? accent.withValues(alpha: 0.55)
            : (glowColor != null ? accent.withValues(alpha: 0.26) : AppColors.borderDark),
      );
    } else if (!hasGradient && tint == null) {
      border = Border.all(color: AppColors.dividerLight);
    } else {
      border = null;
    }

    final List<BoxShadow> shadows;
    if (hasGradient) {
      final shadowColor = gradient!.colors.last;
      shadows = [
        BoxShadow(
          color: shadowColor.withValues(alpha: isDark ? 0.35 : 0.32),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
    } else if (isDark) {
      shadows = [
        if (highlighted)
          BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 22, offset: const Offset(0, 6))
        else
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: tint != null ? AppColors.softShadowLight.withValues(alpha: 0.04) : AppColors.softShadowLight,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: background,
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
