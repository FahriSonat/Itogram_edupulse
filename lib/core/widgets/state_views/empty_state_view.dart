import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';

/// [EmptyStateView] — 4 Durum Kalkanı: **Empty**.
///
/// Liste boş olduğunda `CustomPainter` ile çizilmiş illüstrasyonlu bilgi ekranı
/// gösterir. İsteğe bağlı bir eylem butonu ([actionLabel] + [onAction]) içerir.
/// İçerik kaydırılabilir olduğundan küçük alanlarda taşma üretmez.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Center(
      child: SingleChildScrollView(
        padding: AppDimensions.paddingAll24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 120,
              child: CustomPaint(
                painter: EmptyIllustrationPainter(isDark: isDark, accent: accent),
                child: Align(
                  alignment: const Alignment(0, -0.15),
                  child: Icon(
                    icon,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textMutedLight,
                    size: AppDimensions.iconXl,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.p16),
            Text(
              title ?? AppStrings.emptyListTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.p8),
            Text(
              message ?? AppStrings.emptyListSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.p20),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(minimumSize: const Size(160, AppDimensions.buttonHeightSm)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Boş durum illüstrasyonu: zemin gölgesi, yumuşak daire, boş klasör kartı ve
/// etrafında küçük parıltılar.
class EmptyIllustrationPainter extends CustomPainter {
  EmptyIllustrationPainter({required this.isDark, required this.accent});

  final bool isDark;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.45);

    // Zemin gölgesi
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.92), width: w * 0.62, height: h * 0.1),
      Paint()..color = (isDark ? Colors.black : AppColors.textPrimaryLight).withValues(alpha: isDark ? 0.35 : 0.06),
    );

    // Arka plan dairesi
    canvas.drawCircle(center, h * 0.42, Paint()..color = accent.withValues(alpha: isDark ? 0.16 : 0.08));

    // Boş klasör/kart
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w * 0.46, height: h * 0.5),
      const Radius.circular(12),
    );
    canvas.drawRRect(cardRect, Paint()..color = isDark ? AppColors.cardDark : Colors.white);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = isDark ? AppColors.borderDark : AppColors.borderLight,
    );

    // Klasör sekmesi
    final tab = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardRect.left + 8, cardRect.top - 7, w * 0.16, 10),
      const Radius.circular(4),
    );
    canvas.drawRRect(tab, Paint()..color = accent.withValues(alpha: 0.55));

    // Parıltılar
    final sparkle = Paint()..color = AppColors.accentLight.withValues(alpha: 0.9);
    _drawSparkle(canvas, Offset(w * 0.18, h * 0.22), 5, sparkle);
    _drawSparkle(canvas, Offset(w * 0.84, h * 0.3), 4, sparkle..color = accent.withValues(alpha: 0.8));
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.12),
      2.5,
      Paint()..color = AppColors.secondaryLight.withValues(alpha: 0.8),
    );
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EmptyIllustrationPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.accent != accent;
}
