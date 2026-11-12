import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import 'edupulse_mark.dart';

/// [EduPulseLogo] özgün "Nabızlı Kep" işareti + "EduPulse" yazı markası.
///
/// [isAnimated] true ise ilk gösterimde nabız çizgisi soldan sağa kendini çizer
/// (tek seferlik; sürekli animasyon pil tüketmesin diye tekrarlanmaz).
/// Sistem "hareketi azalt" ayarı açıksa animasyon atlanır.
class EduPulseLogo extends StatefulWidget {
  const EduPulseLogo({
    super.key,
    this.size = 40.0,
    this.showText = true,
    this.isAnimated = true,
    this.color,
    this.textStyle,
  });

  /// İşaretin kenar uzunluğu. Yazı boyutu buna göre ölçeklenir.
  final double size;
  final bool showText;
  final bool isAnimated;

  /// "Edu" kelimesinin rengi (varsayılan: tema metin rengi).
  final Color? color;
  final TextStyle? textStyle;

  @override
  State<EduPulseLogo> createState() => _EduPulseLogoState();
}

class _EduPulseLogoState extends State<EduPulseLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.isAnimated && !reduceMotion) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mark = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: EduPulseMarkPainter(pulseProgress: _pulse.value),
        ),
      ),
    );

    return Semantics(
      label: 'EduPulse',
      image: true,
      child: ExcludeSemantics(
        child: widget.showText
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  mark,
                  SizedBox(width: widget.size * 0.26),
                  EduPulseWordmark(fontSize: widget.size * 0.62, color: widget.color, style: widget.textStyle),
                ],
              )
            : mark,
      ),
    );
  }
}

/// "Edu" (metin rengi) + "Pulse" (marka gradyanı) yazı markası.
class EduPulseWordmark extends StatelessWidget {
  const EduPulseWordmark({super.key, this.fontSize = 24, this.color, this.style});

  final double fontSize;
  final Color? color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = (style ?? theme.textTheme.headlineLarge ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.04 * fontSize,
      height: 1.1,
    );
    final gradient = isDark ? EduPulseBrand.wordmarkDark : EduPulseBrand.wordmarkLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'Edu',
          style: base.copyWith(color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text('Pulse', style: base.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}
