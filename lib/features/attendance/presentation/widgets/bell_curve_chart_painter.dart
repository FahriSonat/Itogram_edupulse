import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Çan eğrisinde çizilen tek dağılım (ör. Vize veya Final).
class BellCurveSeries {
  const BellCurveSeries({
    required this.label,
    required this.mean,
    required this.standardDeviation,
    required this.color,
    this.marker,
  });

  /// Sınav notlarından ortalama ve standart sapmayı hesaplar.
  factory BellCurveSeries.fromScores({
    required String label,
    required Iterable<double> scores,
    required Color color,
    double? marker,
  }) {
    final list = scores.toList();
    final mean = list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
    final variance = list.length < 2
        ? 0.0
        : list.map((s) => math.pow(s - mean, 2).toDouble()).reduce((a, b) => a + b) / list.length;
    return BellCurveSeries(
      label: label,
      mean: mean,
      standardDeviation: math.sqrt(variance),
      color: color,
      marker: marker,
    );
  }

  final String label;
  final double mean;
  final double standardDeviation;
  final Color color;

  /// İsteğe bağlı işaretçi (ör. öğrencinin kendi notu).
  final double? marker;

  /// Sapma 0 (tek not / herkes aynı) ise eğri çizilebilsin diye kullanılan değer.
  static const double fallbackDeviation = 10.0;

  double get effectiveDeviation => standardDeviation <= 0.5 ? fallbackDeviation : standardDeviation;
  double get clampedMean => mean.clamp(0.0, 100.0);

  /// Normal dağılım olasılık yoğunluğu.
  double density(double x) {
    final sigma = effectiveDeviation;
    final z = (x - clampedMean) / sigma;
    return math.exp(-0.5 * z * z) / (sigma * math.sqrt(2 * math.pi));
  }

  double get peakDensity => density(clampedMean);
}

/// [BellCurveChartPainter] — Material 3 `CustomPainter` ile sıfırdan çizilen
/// **Sınıf Vize-Final Çan Eğrisi Grafiği**.
///
/// Her [BellCurveSeries] için Gauss eğrisi + yarı saydam dolgu + kesikli ortalama
/// çizgisi çizer; tüm eğriler ortak ölçekte (en yüksek tepe noktası) gösterilir.
/// X ekseni 0–100 puan aralığıdır; altta AA / BA / BB / FF harf notu bölgeleri yer alır.
class BellCurveChartPainter extends CustomPainter {
  BellCurveChartPainter({required this.series, this.isDark = false, this.gradeThresholds = defaultGradeThresholds});

  /// BB, BA ve AA harf notlarının başladığı puanlar (FF bunların altıdır).
  static const List<double> defaultGradeThresholds = [70, 80, 90];
  static const List<String> gradeLabels = ['FF', 'BB', 'BA', 'AA'];
  static const double axisLabelHeight = 22;

  final List<BellCurveSeries> series;
  final bool isDark;
  final List<double> gradeThresholds;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= axisLabelHeight) return;

    final width = size.width;
    final plotHeight = size.height - axisLabelHeight;
    double xOf(double score) => (score.clamp(0.0, 100.0) / 100.0) * width;

    _drawGradeZones(canvas, width, plotHeight, xOf);

    if (series.isNotEmpty) {
      final maxPeak = series.map((s) => s.peakDensity).reduce(math.max);
      double yOf(BellCurveSeries s, double score) => plotHeight - (s.density(score) / maxPeak) * (plotHeight * 0.88);

      for (final s in series) {
        _drawCurve(canvas, s, width, plotHeight, xOf, (score) => yOf(s, score));
      }
      for (final s in series) {
        final meanX = xOf(s.clampedMean);
        _drawDashedVertical(
          canvas,
          meanX,
          yOf(s, s.clampedMean),
          plotHeight,
          Paint()
            ..color = s.color.withValues(alpha: 0.8)
            ..strokeWidth = 1.4,
        );
        if (s.marker != null) {
          final mx = xOf(s.marker!);
          final my = yOf(s, s.marker!.clamp(0.0, 100.0));
          canvas.drawCircle(Offset(mx, my), 6, Paint()..color = s.color);
          canvas.drawCircle(Offset(mx, my), 3, Paint()..color = Colors.white);
        }
      }
    }

    // Taban çizgisi
    canvas.drawLine(
      Offset(0, plotHeight),
      Offset(width, plotHeight),
      Paint()
        ..color = isDark ? AppColors.borderDark : AppColors.borderLight
        ..strokeWidth = 1,
    );
  }

  void _drawGradeZones(Canvas canvas, double width, double plotHeight, double Function(double) xOf) {
    final bounds = [0.0, ...gradeThresholds, 100.0];
    final separator = Paint()
      ..color = (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.9)
      ..strokeWidth = 1;

    for (var i = 0; i < gradeLabels.length && i + 1 < bounds.length; i++) {
      final start = xOf(bounds[i]);
      final end = xOf(bounds[i + 1]);
      if (i > 0) canvas.drawLine(Offset(start, 0), Offset(start, plotHeight), separator);

      final label = gradeLabels[i];
      final color = switch (label) {
        'AA' => AppColors.gradeAA,
        'BA' => AppColors.gradeBA,
        'BB' => AppColors.gradeBB,
        _ => AppColors.gradeFF,
      };
      // Bölge zemini (çok hafif)
      canvas.drawRect(
        Rect.fromLTRB(start, 0, end, plotHeight),
        Paint()..color = color.withValues(alpha: isDark ? 0.06 : 0.04),
      );

      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = ((start + end) / 2 - painter.width / 2).clamp(0.0, width - painter.width);
      painter.paint(canvas, Offset(x, plotHeight + 5));
    }
  }

  void _drawCurve(
    Canvas canvas,
    BellCurveSeries s,
    double width,
    double plotHeight,
    double Function(double) xOf,
    double Function(double) yOf,
  ) {
    const steps = 120;
    final curve = Path();
    final fill = Path()..moveTo(0, plotHeight);
    for (var i = 0; i <= steps; i++) {
      final score = i / steps * 100;
      final point = Offset(xOf(score), yOf(score));
      if (i == 0) {
        curve.moveTo(point.dx, point.dy);
      } else {
        curve.lineTo(point.dx, point.dy);
      }
      fill.lineTo(point.dx, point.dy);
    }
    fill
      ..lineTo(width, plotHeight)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [
            s.color.withValues(alpha: isDark ? 0.32 : 0.22),
            s.color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, width, plotHeight)),
    );
    canvas.drawPath(
      curve,
      Paint()
        ..color = s.color
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawDashedVertical(Canvas canvas, double x, double fromY, double toY, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;
    var y = fromY;
    while (y < toY) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + dash, toY)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant BellCurveChartPainter oldDelegate) {
    if (oldDelegate.isDark != isDark || oldDelegate.series.length != series.length) return true;
    if (oldDelegate.gradeThresholds.join(',') != gradeThresholds.join(',')) return true;
    for (var i = 0; i < series.length; i++) {
      final a = oldDelegate.series[i];
      final b = series[i];
      if (a.mean != b.mean ||
          a.standardDeviation != b.standardDeviation ||
          a.marker != b.marker ||
          a.color != b.color) {
        return true;
      }
    }
    return false;
  }
}

/// [BellCurveChartWidget] Sınıf Vize-Final çan eğrisini kart içinde, lejant ve
/// ortalama rozetleriyle gösterir. Öğrenci görünümünde kendi notları işaretlenebilir.
class BellCurveChartWidget extends StatelessWidget {
  const BellCurveChartWidget({
    super.key,
    required this.midtermAverage,
    required this.finalAverage,
    this.midtermStandardDeviation = 0,
    this.finalStandardDeviation = 0,
    this.studentMidterm,
    this.studentFinal,
    this.sampleSize,
    this.title = 'Sınıf Vize-Final Çan Eğrisi',
    this.gradeThresholds = BellCurveChartPainter.defaultGradeThresholds,
    this.chartHeight = 170,
  });

  /// Ham sınav notlarından (her öğrencinin vize ve final puanı) grafik üretir.
  factory BellCurveChartWidget.fromScores({
    Key? key,
    required Iterable<double> midtermScores,
    required Iterable<double> finalScores,
    double? studentMidterm,
    double? studentFinal,
    String title = 'Sınıf Vize-Final Çan Eğrisi',
    List<double> gradeThresholds = BellCurveChartPainter.defaultGradeThresholds,
  }) {
    final midterm = BellCurveSeries.fromScores(label: 'Vize', scores: midtermScores, color: midtermColor);
    final finals = BellCurveSeries.fromScores(label: 'Final', scores: finalScores, color: finalColor);
    return BellCurveChartWidget(
      key: key,
      midtermAverage: midterm.mean,
      midtermStandardDeviation: midterm.standardDeviation,
      finalAverage: finals.mean,
      finalStandardDeviation: finals.standardDeviation,
      studentMidterm: studentMidterm,
      studentFinal: studentFinal,
      sampleSize: math.max(midtermScores.length, finalScores.length),
      title: title,
      gradeThresholds: gradeThresholds,
    );
  }

  static const Color midtermColor = AppColors.primaryLight;
  static const Color finalColor = AppColors.metricPurple;

  final double midtermAverage;
  final double finalAverage;
  final double midtermStandardDeviation;
  final double finalStandardDeviation;
  final double? studentMidterm;
  final double? studentFinal;
  final int? sampleSize;
  final String title;
  final List<double> gradeThresholds;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final midColor = isDark ? AppColors.primaryDark : midtermColor;
    const finColor = finalColor;

    final series = [
      BellCurveSeries(
        label: 'Vize',
        mean: midtermAverage,
        standardDeviation: midtermStandardDeviation,
        color: midColor,
        marker: studentMidterm,
      ),
      BellCurveSeries(
        label: 'Final',
        mean: finalAverage,
        standardDeviation: finalStandardDeviation,
        color: finColor,
        marker: studentFinal,
      ),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radius16,
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: AppDimensions.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppDimensions.p8),
            Wrap(
              spacing: AppDimensions.p8,
              runSpacing: AppDimensions.p6,
              children: [
                _StatChip(label: 'Vize Ort.', value: midtermAverage, color: midColor, isDark: isDark),
                _StatChip(label: 'Final Ort.', value: finalAverage, color: finColor, isDark: isDark),
                if (sampleSize != null) _CountChip(count: sampleSize!, isDark: isDark),
              ],
            ),
            const SizedBox(height: AppDimensions.p12),
            Semantics(
              label:
                  'Çan eğrisi: vize ortalaması ${midtermAverage.toStringAsFixed(1)}, '
                  'final ortalaması ${finalAverage.toStringAsFixed(1)}',
              child: SizedBox(
                height: chartHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: BellCurveChartPainter(series: series, isDark: isDark, gradeThresholds: gradeThresholds),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.p8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 4,
              children: [
                _LegendItem(label: 'Vize (%40)', color: midColor),
                const _LegendItem(label: 'Final (%60)', color: finColor),
                if (studentMidterm != null || studentFinal != null)
                  const _LegendItem(label: 'Senin notun', color: Colors.white, outlined: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color, required this.isDark});

  final String label;
  final double value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: AppDimensions.radiusFull,
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(1)}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white : color),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count, required this.isDark});

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        borderRadius: AppDimensions.radiusFull,
      ),
      child: Text(
        '$count öğrenci',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color, this.outlined = false});

  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: outlined ? Border.all(color: borderColor, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
