import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../animations/fade_slide_in.dart';
import '../atmosphere/campus_scene.dart';

/// [PortalHeroHeader] Ana Sayfa'nın en üstündeki sahneli karşılama alanıdır.
///
/// Arka planda [CampusScene] (gündüz / gece), solda "Merhaba, {isim}!" + alt başlık,
/// sağda karakter avatarı bulunur. Sahne, altına gelen karta [overlap] kadar
/// taşar; böylece mockup'taki "kart sahnenin üstüne biniyor" katmanlı görünüm
/// sabit yükseklik kullanmadan (metin büyütmede taşma olmadan) elde edilir.
class PortalHeroHeader extends StatelessWidget {
  const PortalHeroHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.subtitle,
    required this.avatar,
    this.overlap = 28,
    this.sceneBand = 96,
  });

  final String greeting;
  final String name;
  final String subtitle;
  final Widget avatar;

  /// Sahnenin hemen altındaki widget'ın arkasına uzandığı mesafe.
  final double overlap;

  /// Metnin altında binanın göründüğü bant yüksekliği.
  final double sceneBand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleStyle = theme.textTheme.headlineLarge?.copyWith(
      fontSize: 25,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.3,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: -overlap,
          child: FadeSlideIn(
            duration: const Duration(milliseconds: 700),
            offset: const Offset(0, 16),
            child: CampusScene(
              buildingCenterX: 0.5,
              buildingHeight: 72,
              groundInset: overlap + 10,
              fadeTop: true,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 16, sceneBand),
          child: Row(
            children: [
              Expanded(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  offset: const Offset(-20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(greeting, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(name, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? const Color(0xFFB6C2D9) : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                offset: const Offset(0, 10),
                beginScale: 0.82,
                curve: Curves.easeOutBack,
                child: avatar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
