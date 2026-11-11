import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/widgets/atmosphere/campus_scene.dart';
import '../../../../core/widgets/brand/edupulse_mark.dart';
import '../../../../core/widgets/dashboard/portal_avatar.dart';

// =============================================================================
// 1. ÇİFT PORTAL — kampüs sahnesi + öğrenci ↔ eğitmen arasında akan veri
// =============================================================================

/// Onboarding 1: Öğrenci ve Eğitmen karakterleri, aralarında iki yönlü akan
/// "veri noktaları" olan kesikli bir yay ve tepede EduPulse işareti.
class DualPortalIllustration extends StatefulWidget {
  const DualPortalIllustration({super.key});

  @override
  State<DualPortalIllustration> createState() => _DualPortalIllustrationState();
}

class _DualPortalIllustrationState extends State<DualPortalIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _flow.value = 0.35;
    } else if (!_flow.isAnimating) {
      _flow.repeat();
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final avatar = (h * 0.36).clamp(52.0, 84.0);
        final left = Offset(w * 0.24, h * 0.3);
        final right = Offset(w * 0.76, h * 0.3);
        final peak = Offset(w * 0.5, h * 0.3 - h * 0.2);
        const markSize = 30.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CampusScene(
                buildingHeight: h * 0.36,
                groundInset: h * 0.1,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _flow,
                builder: (context, _) => CustomPaint(
                  painter: _ArcLinkPainter(
                    from: left,
                    to: right,
                    control: Offset(w * 0.5, h * 0.3 - h * 0.4),
                    t: _flow.value,
                    color: isDark ? const Color(0xFF93C5FD) : EduPulseBrand.indigo,
                  ),
                ),
              ),
            ),
            Positioned(
              left: peak.dx - markSize / 2,
              top: peak.dy - markSize / 2,
              child: const SizedBox.square(
                dimension: markSize,
                child: CustomPaint(painter: EduPulseMarkPainter()),
              ),
            ),
            for (final (role, center, label) in [
              (UserRole.student, left, 'Öğrenci'),
              (UserRole.instructor, right, 'Eğitmen'),
            ])
              Positioned(
                left: center.dx - avatar / 2 - 12,
                top: center.dy - avatar / 2,
                width: avatar + 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PortalAvatar(role: role, size: avatar),
                    const SizedBox(height: 4),
                    _Tag(
                      label: label,
                      color: (role == UserRole.student) ? AppColors.primaryLight : AppColors.instructorRoleBadge,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ArcLinkPainter extends CustomPainter {
  _ArcLinkPainter({required this.from, required this.to, required this.control, required this.t, required this.color});

  final Offset from;
  final Offset to;
  final Offset control;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    final metric = path.computeMetrics().first;

    // Kesikli yay
    final dash = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double d = 0; d < metric.length; d += 10) {
      canvas.drawPath(metric.extractPath(d, math.min(d + 5, metric.length)), dash);
    }

    // İki yönlü akan veri noktaları (öğrenci → eğitmen ve tersi)
    for (final progress in [t, 1 - ((t + 0.5) % 1)]) {
      final pos = metric.getTangentForOffset(metric.length * progress)?.position;
      if (pos == null) continue;
      canvas.drawCircle(
        pos,
        10,
        Paint()
          ..shader = RadialGradient(colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: pos, radius: 10)),
      );
      canvas.drawCircle(pos, 3.5, Paint()..color = EduPulseBrand.gold);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcLinkPainter old) => old.t != t || old.color != color;
}

// =============================================================================
// 2. 60 SN QR / PIN — geri sayan halka + her turda yenilenen QR kodu
// =============================================================================

/// Onboarding 2: 60 saniyelik canlı yoklama kodu. Halka geri sayar, süre
/// dolunca QR deseni ve PIN yenilenir (Kural 1'in görsel anlatımı).
/// Gösterim için 60 sn, 6 sn'ye sıkıştırılmıştır.
class QrCountdownIllustration extends StatefulWidget {
  const QrCountdownIllustration({super.key});

  @override
  State<QrCountdownIllustration> createState() => _QrCountdownIllustrationState();
}

class _QrCountdownIllustrationState extends State<QrCountdownIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  int _cycle = 0;
  double _last = 0;

  @override
  void initState() {
    super.initState();
    _clock.addListener(() {
      if (_clock.value < _last) _cycle++;
      _last = _clock.value;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _clock.value = 0.25;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? const [Color(0xFF16213F), Color(0xFF1E1B4B)] : const [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AnimatedBuilder(
              animation: _clock,
              builder: (context, _) {
                final remaining = 1 - _clock.value;
                final seconds = (60 * remaining).ceil().clamp(1, 60);
                final pin = (1000 + math.Random(_cycle * 7 + 3).nextInt(9000)).toString();
                final urgent = remaining < 0.2;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size.square(150),
                            painter: _CountdownRingPainter(remaining: remaining, urgent: urgent, isDark: isDark),
                          ),
                          Container(
                            width: 88,
                            height: 88,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CustomPaint(painter: _QrPainter(seed: _cycle)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LiveChip(isDark: isDark),
                        const SizedBox(height: 8),
                        Text(
                          '$seconds sn',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: urgent ? AppColors.criticalAbsenceRed : null,
                          ),
                        ),
                        Text(
                          'kod geçerli',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final digit in pin.split(''))
                              Container(
                                width: 24,
                                height: 30,
                                margin: const EdgeInsets.only(right: 4),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0B1220) : Colors.white,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: (isDark ? const Color(0xFF60A5FA) : EduPulseBrand.blue).withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  digit,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                          ],
                        ),
                      ],
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

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.criticalAbsenceRed.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: AppColors.criticalAbsenceRed, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            'CANLI YOKLAMA',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.criticalAbsenceRed, fontWeight: FontWeight.w800, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({required this.remaining, required this.urgent, required this.isDark});

  final double remaining;
  final bool urgent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark ? Colors.white.withValues(alpha: 0.08) : EduPulseBrand.indigo.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    final sweep = 2 * math.pi * remaining;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    if (urgent) {
      arc.color = AppColors.criticalAbsenceRed;
    } else {
      arc.shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [EduPulseBrand.violet, EduPulseBrand.blue, Color(0xFF14B8A6)],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    }
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);

    // Halkanın ucundaki parlak düğme
    final end = -math.pi / 2 + sweep;
    final knob = center + Offset(math.cos(end), math.sin(end)) * radius;
    canvas.drawCircle(knob, 7, Paint()..color = Colors.white);
    canvas.drawCircle(knob, 4, Paint()..color = urgent ? AppColors.criticalAbsenceRed : EduPulseBrand.gold);
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter old) =>
      old.remaining != remaining || old.urgent != urgent || old.isDark != isDark;
}

/// Gerçek bir QR kodu değil; QR görünümünde, tohuma bağlı deterministik desen.
/// Ortada EduPulse işareti bulunur.
class _QrPainter extends CustomPainter {
  _QrPainter({required this.seed});

  final int seed;

  static const int _n = 21;

  @override
  void paint(Canvas canvas, Size size) {
    final m = size.shortestSide / _n;
    final dark = Paint()..color = const Color(0xFF0F172A);
    final light = Paint()..color = Colors.white;
    final rnd = math.Random(seed * 31 + 11);

    bool inFinder(int x, int y) => (x < 8 && y < 8) || (x >= _n - 8 && y < 8) || (x < 8 && y >= _n - 8);
    bool inLogo(int x, int y) => x >= 7 && x <= 13 && y >= 7 && y <= 13;

    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        if (inFinder(x, y) || inLogo(x, y)) continue;
        if (rnd.nextBool()) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x * m, y * m, m * 0.9, m * 0.9), Radius.circular(m * 0.25)),
            dark,
          );
        }
      }
    }

    for (final (fx, fy) in [(0, 0), (_n - 7, 0), (0, _n - 7)]) {
      final o = Offset(fx * m, fy * m);
      canvas.drawRRect(RRect.fromRectAndRadius(o & Size.square(7 * m), Radius.circular(m * 1.6)), dark);
      canvas.drawRRect(
        RRect.fromRectAndRadius((o + Offset(m, m)) & Size.square(5 * m), Radius.circular(m * 1.1)),
        light,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius((o + Offset(2 * m, 2 * m)) & Size.square(3 * m), Radius.circular(m * 0.8)),
        dark,
      );
    }

    final logoRect = Rect.fromLTWH(7.5 * m, 7.5 * m, 6 * m, 6 * m);
    canvas.save();
    canvas.translate(logoRect.left, logoRect.top);
    const EduPulseMarkPainter().paint(canvas, logoRect.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}

// =============================================================================
// 3. ÇAN EĞRİSİ & GPA — harf notu bölgeleri renklenen Gauss eğrisi
// =============================================================================

/// Onboarding 3: Kendini çizen sınıf çan eğrisi. Eğrinin altı harf notu
/// bölgelerine (FF, BB, BA, AA) göre renklenir; öğrencinin konumu işaretlenir.
class GradeCurveIllustration extends StatefulWidget {
  const GradeCurveIllustration({super.key, this.studentScore = 88, this.gpa = '3.42'});

  final double studentScore;
  final String gpa;

  @override
  State<GradeCurveIllustration> createState() => _GradeCurveIllustrationState();
}

class _GradeCurveIllustrationState extends State<GradeCurveIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final Animation<double> _t = CurvedAnimation(parent: _draw, curve: Curves.easeInOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draw.status != AnimationStatus.dismissed) return;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _draw.value = 1;
    } else {
      _draw.forward();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? const [Color(0xFF16213F), Color(0xFF111B2E)] : const [Color(0xFFF0FDF4), Color(0xFFEFF6FF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _t,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _BellCurvePainter(
                    progress: _t.value,
                    studentScore: widget.studentScore,
                    isDark: isDark,
                    labelStyle: theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (label, color) in [
                  ('AA', AppColors.gradeAA),
                  ('BA', AppColors.gradeBA),
                  ('BB', AppColors.gradeBB),
                  ('FF', AppColors.gradeFF),
                ])
                  _GradeChip(label: label, color: color),
                _GradeChip(label: 'GPA ${widget.gpa} / 4.00', color: EduPulseBrand.violet, filled: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: filled ? Colors.white : color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _BellCurvePainter extends CustomPainter {
  _BellCurvePainter({
    required this.progress,
    required this.studentScore,
    required this.isDark,
    required this.labelStyle,
  });

  final double progress;
  final double studentScore;
  final bool isDark;
  final TextStyle labelStyle;

  static const double _mean = 70;
  static const double _sd = 13;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final base = size.height - 4;
    final top = 26.0; // etiket için üst boşluk
    final amp = base - top;

    double xOf(double score) => w * score / 100;
    double yOf(double score) => base - amp * math.exp(-math.pow(score - _mean, 2) / (2 * _sd * _sd));

    final curve = Path()..moveTo(0, yOf(0));
    for (var s = 1.0; s <= 100; s += 1) {
      curve.lineTo(xOf(s), yOf(s));
    }
    final area = Path.from(curve)
      ..lineTo(w, base)
      ..lineTo(0, base)
      ..close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * progress, size.height));

    // Harf notu bölgeleri (eğrinin altı)
    for (final (from, to, color) in [
      (0.0, 50.0, AppColors.gradeFF),
      (50.0, 70.0, AppColors.gradeBB),
      (70.0, 85.0, AppColors.gradeBA),
      (85.0, 100.0, AppColors.gradeAA),
    ]) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(xOf(from), 0, xOf(to), size.height));
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: isDark ? 0.32 : 0.22));
      canvas.restore();
    }

    // Eğri çizgisi
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(colors: [EduPulseBrand.blue, EduPulseBrand.violet])
            .createShader(Offset.zero & size),
    );
    canvas.restore();

    // Taban çizgisi
    canvas.drawLine(
      Offset(0, base),
      Offset(w, base),
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)
        ..strokeWidth = 1,
    );

    // Öğrenci işareti (eğri o noktaya ulaşınca belirir)
    final sx = xOf(studentScore);
    if (w * progress >= sx) {
      final sy = yOf(studentScore);
      final marker = Paint()
        ..color = EduPulseBrand.violet
        ..strokeWidth = 1.5;
      for (double y = sy; y < base; y += 6) {
        canvas.drawLine(Offset(sx, y), Offset(sx, math.min(y + 3, base)), marker);
      }
      canvas.drawCircle(Offset(sx, sy), 6, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(sx, sy), 4, Paint()..color = EduPulseBrand.violet);

      final tp = TextPainter(
        text: TextSpan(
          text: 'Sen · ${studentScore.round()}',
          style: labelStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final chip = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset((sx).clamp(tp.width / 2 + 8, w - tp.width / 2 - 8), sy - 18),
          width: tp.width + 14,
          height: tp.height + 6,
        ),
        const Radius.circular(999),
      );
      canvas.drawRRect(chip, Paint()..color = EduPulseBrand.violet);
      tp.paint(canvas, Offset(chip.left + 7, chip.top + 3));
    }
  }

  @override
  bool shouldRepaint(covariant _BellCurvePainter old) =>
      old.progress != progress || old.studentScore != studentScore || old.isDark != isDark;
}
