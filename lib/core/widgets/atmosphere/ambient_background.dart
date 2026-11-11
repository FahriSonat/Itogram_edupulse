import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// [AmbientBackground] sayfanın arkasına mockup'taki "ortam ışığını" çizer.
///
/// - Aydınlık: üstte sıcak krem bant, sağ üstte gök mavisi, sol altta şeftali ışık.
/// - Karanlık: derin lacivert zemin üzerinde mavi ve mor yumuşak haleler.
///
/// Kullanım: `AmbientBackground(child: Scaffold(backgroundColor: Colors.transparent, ...))`
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _AmbientGlowPainter(isDark: isDark),
      child: RepaintBoundary(child: child),
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  _AmbientGlowPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;

    canvas.drawRect(rect, Paint()..color = isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    if (isDark) {
      _blob(canvas, rect, Offset(w * 0.95, h * 0.04), w * 0.95, AppColors.ambientGlowBlueDark.withValues(alpha: 0.22));
      _blob(canvas, rect, Offset(w * 0.0, h * 0.9), w * 0.9, AppColors.ambientGlowVioletDark.withValues(alpha: 0.12));
      return;
    }

    final topBand = Rect.fromLTWH(0, 0, w, h * 0.42);
    canvas.drawRect(
      topBand,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.ambientTopLight, AppColors.ambientTopLight.withValues(alpha: 0)],
        ).createShader(topBand),
    );
    _blob(canvas, rect, Offset(w * 0.98, h * 0.06), w * 0.75, AppColors.ambientGlowBlueLight.withValues(alpha: 0.85));
    _blob(canvas, rect, Offset(w * 0.0, h * 0.86), w * 0.85, AppColors.ambientGlowPeachLight.withValues(alpha: 0.5));
  }

  void _blob(Canvas canvas, Rect bounds, Offset center, double radius, Color color) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter old) => old.isDark != isDark;
}
