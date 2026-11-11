import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/atmosphere/ambient_background.dart';
import '../../../../core/widgets/atmosphere/campus_scene.dart';
import '../../../../core/widgets/brand/edupulse_logo.dart';
import '../../../../core/widgets/brand/edupulse_mark.dart';

/// [SplashPage] EduPulse'un animasyonlu açılış ekranı (~2.6 sn):
///
/// 1. Kampüs sahnesi (gündüz/gece) alttan yükselir.
/// 2. "Nabızlı Kep" logosu esneyerek belirir; arkasından kalp atışı halkaları yayılır.
/// 3. Logodaki nabız çizgisi soldan sağa kendini çizer.
/// 4. "EduPulse" yazısı ve slogan sırayla gelir; ilerleme çubuğu dolar.
///
/// Ekrana dokunmak açılışı atlar. Sistem "hareketi azalt" ayarı açıksa kayma ve
/// ölçek efektleri kapatılır, yalnızca yumuşak geçişler kalır.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  late final Animation<double> _scene = _interval(0.0, 0.35, Curves.easeOutCubic);
  late final Animation<double> _badge = _interval(0.08, 0.4, Curves.easeOutBack);
  late final Animation<double> _badgeFade = _interval(0.08, 0.25, Curves.easeOut);
  late final Animation<double> _pulse = _interval(0.28, 0.62, Curves.easeInOutCubic);
  late final Animation<double> _wordmark = _interval(0.45, 0.7, Curves.easeOutCubic);
  late final Animation<double> _tagline = _interval(0.6, 0.85, Curves.easeOut);

  bool _finished = false;

  Animation<double> _interval(double begin, double end, Curve curve) => CurvedAnimation(
    parent: _intro,
    curve: Interval(begin, end, curve: curve),
  );

  @override
  void initState() {
    super.initState();
    _intro
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
    _ripple.repeat();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinish();
  }

  @override
  void dispose() {
    _intro.dispose();
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final calm = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final screen = MediaQuery.sizeOf(context);
    final sceneHeight = (screen.height * 0.34).clamp(170.0, 320.0);
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Semantics(
          button: true,
          label: 'Açılışı geç',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _finish,
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _ripple]),
              builder: (context, _) {
                double slide(Animation<double> a, double px) => calm ? 0 : px * (1 - a.value);

                return Stack(
                  children: [
                    // 1. Kampüs sahnesi
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: sceneHeight,
                      child: Opacity(
                        opacity: _scene.value,
                        child: Transform.translate(
                          offset: Offset(0, slide(_scene, 48)),
                          child: CampusScene(
                            fadeTop: true,
                            buildingHeight: sceneHeight * 0.5,
                            groundInset: sceneHeight * 0.16,
                          ),
                        ),
                      ),
                    ),

                    // 2-4. Logo, yazı markası, slogan, ilerleme
                    SafeArea(
                      child: Align(
                        alignment: const Alignment(0, -0.3),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size.square(200),
                                      painter: _HeartbeatRipplePainter(
                                        progress: _ripple.value,
                                        opacity: _badgeFade.value,
                                        color: isDark ? const Color(0xFF60A5FA) : EduPulseBrand.blue,
                                      ),
                                    ),
                                    Opacity(
                                      opacity: _badgeFade.value,
                                      child: Transform.scale(
                                        scale: calm ? 1 : 0.6 + 0.4 * _badge.value,
                                        child: _MarkWithShadow(pulseProgress: _pulse.value),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Opacity(
                                opacity: _wordmark.value,
                                child: Transform.translate(
                                  offset: Offset(0, slide(_wordmark, 18)),
                                  child: const EduPulseWordmark(fontSize: 38),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Opacity(
                                opacity: _tagline.value,
                                child: Text(
                                  AppStrings.appTagline,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: muted,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              _ProgressBar(value: _intro.value, isDark: isDark),
                              const SizedBox(height: 10),
                              Opacity(
                                opacity: _tagline.value,
                                child: Text(
                                  'SoftITO Akademi • ${AppStrings.appVersion}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Gölgeli logo işareti (nabız çizgisi [pulseProgress] oranında çizilir).
class _MarkWithShadow extends StatelessWidget {
  const _MarkWithShadow({required this.pulseProgress});

  final double pulseProgress;

  static const double _size = 112;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_size * EduPulseMarkPainter.cornerRatio),
        boxShadow: [
          BoxShadow(color: EduPulseBrand.violet.withValues(alpha: 0.35), blurRadius: 32, offset: const Offset(0, 14)),
        ],
      ),
      child: CustomPaint(
        size: const Size.square(_size),
        painter: EduPulseMarkPainter(pulseProgress: pulseProgress),
      ),
    );
  }
}

/// Logonun arkasından yayılan iki "kalp atışı" halkası.
class _HeartbeatRipplePainter extends CustomPainter {
  _HeartbeatRipplePainter({required this.progress, required this.opacity, required this.color});

  final double progress;
  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final center = size.center(Offset.zero);
    final minR = size.shortestSide * 0.3;
    final maxR = size.shortestSide * 0.5;
    for (final phase in [0.0, 0.5]) {
      final t = (progress + phase) % 1.0;
      final radius = minR + (maxR - minR) * Curves.easeOut.transform(t);
      final alpha = (1 - t) * 0.35 * opacity;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeartbeatRipplePainter old) =>
      old.progress != progress || old.opacity != opacity || old.color != color;
}

/// Açılış süresine bağlı, gradyanlı ilerleme çubuğu.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.isDark});

  final double value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isDark ? EduPulseBrand.wordmarkDark : EduPulseBrand.wordmarkLight,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
